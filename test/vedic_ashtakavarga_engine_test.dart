import 'package:astro_logic/src/models/calculation_output_snapshot.dart';
import 'package:astro_logic/src/models/kundli_analysis.dart';
import 'package:astro_logic/src/vedic/vedic_ashtakavarga_engine.dart';
import 'package:astro_logic/src/vedic/vedic_ashtakavarga_reduction_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const engine = VedicAshtakavargaEngine();

  test('reproduces the received-standard B.V. Raman reference distribution', () {
    final profile = engine.build(_ramanReferenceOutput());

    expect(profile.ruleVersion, 'ashtakavarga-foundation-v3');
    expect(profile.totalPositiveMarks, 337);
    expect(profile.averagePositiveMarks, closeTo(337 / 12.0, 1e-12));

    const expected = <String, List<int>>{
      'sun': [5, 3, 5, 4, 4, 4, 3, 5, 5, 0, 5, 5],
      'moon': [5, 3, 5, 5, 3, 2, 3, 4, 6, 5, 3, 5],
      'mars': [4, 3, 4, 3, 4, 1, 1, 5, 3, 2, 5, 4],
      'mercury': [4, 6, 4, 5, 5, 5, 3, 6, 4, 4, 5, 3],
      'jupiter': [3, 4, 7, 6, 4, 4, 6, 4, 5, 5, 4, 4],
      'venus': [7, 4, 4, 3, 3, 4, 5, 3, 4, 5, 4, 6],
      'saturn': [5, 2, 4, 4, 3, 3, 5, 2, 3, 3, 1, 4],
    };
    for (final bav in profile.bhinnashtakavarga) {
      expect(
        bav.signs.map((value) => value.positiveMarks).toList(),
        expected[bav.planet],
        reason: bav.planet,
      );
      expect(bav.totalPositiveMarks, bav.fixedTotalPositiveMarks);
      expect(
        bav.signs.every(
          (value) => value.positiveMarks == value.contributors.length,
        ),
        isTrue,
      );
    }
    expect(
      profile.sarvashtakavarga.map((value) => value.positiveMarks).toList(),
      [33, 25, 33, 30, 26, 23, 26, 29, 30, 24, 27, 31],
    );
    final reductions = profile.reductionProfile!;
    expect(reductions.ruleVersion, 'ashtakavarga-reductions-v1');
    expect(reductions.planets, hasLength(7));
    expect(
      reductions.reducedAggregateMarks,
      [8, 8, 14, 7, 3, 6, 7, 6, 4, 6, 8, 5],
    );
    expect(reductions.reducedAggregateTotal, 82);

    final pinda = profile.pindaProfile!;
    expect(pinda.ruleVersion, 'ashtakavarga-pinda-v1');
    expect(pinda.rashiMultipliers, <int>[7, 10, 8, 4, 10, 5, 7, 8, 9, 5, 11, 12]);
    expect(pinda.grahaMultipliers, <String, int>{
      'sun': 5,
      'moon': 5,
      'mars': 8,
      'mercury': 5,
      'jupiter': 10,
      'venus': 7,
      'saturn': 5,
    });
    const expectedPinda = <String, List<int>>{
      'sun': [96, 86, 182],
      'moon': [80, 20, 100],
      'mars': [126, 71, 197],
      'mercury': [97, 61, 158],
      'jupiter': [79, 45, 124],
      'venus': [61, 5, 66],
      'saturn': [108, 62, 170],
    };
    for (final planet in pinda.planets) {
      expect(
        <int>[planet.rashiPinda, planet.grahaPinda, planet.shodhyaPinda],
        expectedPinda[planet.planet],
        reason: planet.planet,
      );
      expect(planet.rashiContributions, hasLength(12));
      expect(planet.grahaContributions, hasLength(7));
      expect(
        planet.rashiContributions.fold<int>(0, (sum, value) => sum + value.product),
        planet.rashiPinda,
      );
      expect(
        planet.grahaContributions.fold<int>(0, (sum, value) => sum + value.product),
        planet.grahaPinda,
      );
      expect(planet.rashiPinda + planet.grahaPinda, planet.shodhyaPinda);
    }
  });

  test('maps SAV signs to whole-sign houses from Lagna', () {
    final profile = engine.build(_ramanReferenceOutput());
    // Capricorn Lagna: Capricorn is house 1, Aries is house 4.
    final capricorn = profile.sarvashtakavarga
        .firstWhere((value) => value.signIndex == 9);
    final aries = profile.sarvashtakavarga
        .firstWhere((value) => value.signIndex == 0);

    expect(capricorn.houseNumber, 1);
    expect(aries.houseNumber, 4);
  });

  test('uses the selected BPHS 72 SAV bands without event guarantees', () {
    final profile = engine.build(_ramanReferenceOutput());
    final aries = profile.sarvashtakavarga[0];
    final taurus = profile.sarvashtakavarga[1];
    final virgo = profile.sarvashtakavarga[5];

    expect(aries.positiveMarks, 33);
    expect(aries.band, 'favourable');
    expect(aries.polarity, AnalysisPolarity.supportive);
    expect(taurus.positiveMarks, 25);
    expect(taurus.band, 'medium');
    expect(taurus.polarity, AnalysisPolarity.mixed);
    expect(virgo.positiveMarks, 23);
    expect(virgo.band, 'adverse');
    expect(virgo.polarity, AnalysisPolarity.challenging);
    expect(aries.confidence, AnalysisConfidence.medium);
    expect(aries.narrativeEn, contains('not a guaranteed event'));
  });

  test('excludes Rahu and Ketu from the eight-reference BAV construction', () {
    final profile = engine.build(_ramanReferenceOutput(includeNodes: true));
    final references = profile.bhinnashtakavarga
        .expand((value) => value.signs)
        .expand((value) => value.contributors)
        .map((value) => value.reference)
        .toSet();

    expect(references, contains('lagna'));
    expect(references, isNot(contains('rahu')));
    expect(references, isNot(contains('ketu')));
    expect(references.length, 8);
  });

  test('Trikona Shodhana preserves zero groups, zeros equal groups and subtracts the minimum otherwise', () {
    const reducer = VedicAshtakavargaReductionEngine();
    final profile = reducer.reduce(
      bhinnashtakavarga: _syntheticBav(<int>[
        5, 4, 2, 4, 3, 2, 1, 4, 6, 1, 3, 4,
      ]),
      classicalPlanetSigns: _emptyOccupancyFixture(),
    );
    final first = profile.planets.first;

    // Fire 5/3/6 -> 2/0/3; Earth 4/2/1 -> 3/1/0;
    // Air 2/1/3 -> 1/0/2; Water 4/4/4 -> 0/0/0.
    expect(first.trikonaReducedMarks, <int>[2, 3, 1, 0, 0, 1, 0, 0, 3, 0, 2, 0]);
    expect(first.trikonaAudits[0].action, 'subtract_group_minimum');
    expect(first.trikonaAudits[3].action, 'all_equal_reduce_all_to_zero');
  });

  test('Trikona Shodhana does nothing when any trine member is already zero', () {
    const reducer = VedicAshtakavargaReductionEngine();
    final profile = reducer.reduce(
      bhinnashtakavarga: _syntheticBav(<int>[
        5, 4, 2, 4, 0, 2, 1, 3, 6, 1, 3, 5,
      ]),
      classicalPlanetSigns: _emptyOccupancyFixture(),
    );
    final audit = profile.planets.first.trikonaAudits.first;
    expect(audit.inputMarks, <int>[5, 0, 6]);
    expect(audit.outputMarks, <int>[5, 0, 6]);
    expect(audit.action, 'zero_present_no_reduction');
  });

  test('Ekadhipatya sets two empty unequal signs to the smaller value', () {
    final audit = _marsPairAudit(
      aries: 5,
      scorpio: 3,
      occupiedSigns: const <int>{4},
    );
    expect(audit.inputMarks, <int>[5, 3]);
    expect(audit.outputMarks, <int>[3, 3]);
    expect(audit.action, 'both_empty_unequal_set_both_to_smaller');
  });

  test('Ekadhipatya zeros two empty equal signs', () {
    final audit = _marsPairAudit(
      aries: 4,
      scorpio: 4,
      occupiedSigns: const <int>{4},
    );
    expect(audit.outputMarks, <int>[0, 0]);
    expect(audit.action, 'both_empty_equal_reduce_both_to_zero');
  });

  test('Ekadhipatya keeps an occupied smaller value and subtracts it from the empty sign', () {
    final audit = _marsPairAudit(
      aries: 3,
      scorpio: 7,
      occupiedSigns: const <int>{0, 4},
    );
    expect(audit.occupied, <bool>[true, false]);
    expect(audit.outputMarks, <int>[3, 4]);
    expect(audit.action, 'occupied_smaller_subtract_from_empty');
  });

  test('Ekadhipatya keeps an occupied greater/equal value and zeros the empty sign', () {
    final audit = _marsPairAudit(
      aries: 6,
      scorpio: 3,
      occupiedSigns: const <int>{0, 4},
    );
    expect(audit.outputMarks, <int>[6, 0]);
    expect(audit.action, 'occupied_greater_or_equal_reduce_empty_to_zero');
  });

  test('Ekadhipatya leaves two occupied nonzero signs unchanged', () {
    final audit = _marsPairAudit(
      aries: 6,
      scorpio: 3,
      occupiedSigns: const <int>{0, 7},
    );
    expect(audit.outputMarks, <int>[6, 3]);
    expect(audit.action, 'both_occupied_no_reduction');
  });

  test('Ekadhipatya is skipped when either paired sign is already zero', () {
    final audit = _marsPairAudit(
      aries: 0,
      scorpio: 3,
      occupiedSigns: const <int>{4},
    );
    expect(audit.outputMarks, <int>[0, 3]);
    expect(audit.action, 'zero_present_no_reduction');
  });

  test('reduced aggregate is a later-stage checksum and is not forced to raw SAV 337', () {
    final profile = engine.build(_ramanReferenceOutput());
    final reductions = profile.reductionProfile!;
    expect(reductions.reducedAggregateTotal, lessThan(profile.totalPositiveMarks));
    expect(profile.totalPositiveMarks, 337);
  });

  test('Pinda uses Ekadhipatya-reduced marks rather than raw or Trikona marks', () {
    final profile = engine.build(_ramanReferenceOutput());
    final reducedSun = profile.reductionProfile!.planets
        .firstWhere((value) => value.planet == 'sun');
    final sunPinda = profile.pindaProfile!.planets
        .firstWhere((value) => value.planet == 'sun');
    final taurus = sunPinda.rashiContributions
        .firstWhere((value) => value.signIndex == 1);

    expect(taurus.reducedMarks, reducedSun.ekadhipatyaReducedMarks[1]);
    expect(taurus.reducedMarks, 3);
    expect(taurus.multiplier, 10);
    expect(taurus.product, 30);
  });

  test('rejects a missing classical planet', () {
    final output = _ramanReferenceOutput();
    (output.output['planets'] as List).removeWhere(
      (value) => (value as Map)['body'] == 'saturn',
    );

    expect(() => engine.build(output), throwsStateError);
  });
}



AshtakavargaEkadhipatyaAudit _marsPairAudit({
  required int aries,
  required int scorpio,
  required Set<int> occupiedSigns,
}) {
  const reducer = VedicAshtakavargaReductionEngine();
  final marks = <int>[
    aries, 5, 4, 0, 0, 3, 2, scorpio, 4, 2, 3, 5,
  ];
  final placements = <String, int>{};
  const planets = <String>[
    'sun', 'moon', 'mars', 'mercury', 'jupiter', 'venus', 'saturn',
  ];
  final signs = occupiedSigns.toList(growable: false);
  for (var index = 0; index < planets.length; index += 1) {
    placements[planets[index]] = signs[index % signs.length];
  }
  final result = reducer.reduce(
    bhinnashtakavarga: _syntheticBav(marks),
    classicalPlanetSigns: placements,
  );
  return result.planets.first.ekadhipatyaAudits
      .firstWhere((value) => value.lord == 'mars');
}

List<BhinnashtakavargaPlanetProfile> _syntheticBav(List<int> marks) {
  const planets = <String>[
    'sun', 'moon', 'mars', 'mercury', 'jupiter', 'venus', 'saturn',
  ];
  return <BhinnashtakavargaPlanetProfile>[
    for (final planet in planets)
      BhinnashtakavargaPlanetProfile(
        planet: planet,
        fixedTotalPositiveMarks: marks.fold<int>(0, (a, b) => a + b),
        signs: <BhinnashtakavargaSignProfile>[
          for (var sign = 0; sign < 12; sign += 1)
            BhinnashtakavargaSignProfile(
              signIndex: sign,
              positiveMarks: marks[sign],
              contributors: const <AshtakavargaContribution>[],
            ),
        ],
      ),
  ];
}

Map<String, int> _emptyOccupancyFixture() => const <String, int>{
      'sun': 0,
      'moon': 0,
      'mars': 0,
      'mercury': 0,
      'jupiter': 0,
      'venus': 0,
      'saturn': 0,
    };

CalculationOutputSnapshot _ramanReferenceOutput({bool includeNodes = false}) {
  const signs = <String, int>{
    'sun': 5, // Virgo
    'moon': 10, // Aquarius
    'mars': 7, // Scorpio
    'mercury': 6, // Libra
    'jupiter': 2, // Gemini
    'venus': 5, // Virgo
    'saturn': 4, // Leo
  };
  return CalculationOutputSnapshot(
    id: 1,
    consultationId: 1,
    inputSnapshotId: 1,
    engineId: 'fixture-vedic',
    engineVersion: '1',
    outputSchemaVersion: 'vedic-chart-v9',
    output: <String, Object?>{
      'ascendant': const <String, Object?>{'signIndex': 9}, // Capricorn
      'planets': <Map<String, Object?>>[
        for (final entry in signs.entries)
          <String, Object?>{'body': entry.key, 'signIndex': entry.value},
        if (includeNodes) ...const [
          <String, Object?>{'body': 'rahu', 'signIndex': 1},
          <String, Object?>{'body': 'ketu', 'signIndex': 7},
        ],
      ],
    },
    outputHash: List.filled(64, 'a').join(),
    createdAt: DateTime.utc(2026, 8, 8),
  );
}
