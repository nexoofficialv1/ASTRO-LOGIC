import 'package:astro_logic/src/models/calculation_output_snapshot.dart';
import 'package:astro_logic/src/models/kundli_analysis.dart';
import 'package:astro_logic/src/vedic/vedic_dashamsa_interpretation_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const engine = VedicDashamsaInterpretationEngine();

  test('builds twelve D10 house records plus D1-D10 career synthesis', () {
    final result = engine.build(_output());

    expect(result.houses, hasLength(12));
    expect(result.houses.map((value) => value.houseNumber).toSet(), hasLength(12));
    expect(
      result.houses.every(
        (value) =>
            value.ruleVersion == 'dashamsa-career-interpretation-v1' &&
            value.confidence != AnalysisConfidence.high &&
            value.evidence.length >= 2,
      ),
      isTrue,
    );
    expect(result.careerSynthesis.d1TenthLord, 'saturn');
    expect(result.careerSynthesis.d1TenthLordD10House, 5);
    expect(result.careerSynthesis.d10TenthLord, 'jupiter');
    expect(result.careerSynthesis.polarity, AnalysisPolarity.supportive);
    expect(result.careerSynthesis.confidence, AnalysisConfidence.medium);
  });

  test('marks the principal career houses with career relevance', () {
    final houses = engine.build(_output()).houses;
    final relevant = houses
        .where((value) => value.careerRelevance)
        .map((value) => value.houseNumber)
        .toSet();

    expect(relevant, {1, 2, 6, 7, 10, 11});
    expect(houses[9].titleEn, contains('profession'));
  });

  test('keeps Rahu occupancy visible but directionally review-only', () {
    final eleventh = engine.build(_output()).houses[10];

    expect(eleventh.occupants, contains('rahu'));
    expect(
      eleventh.evidence.any(
        (value) => value.ruleId ==
            'vedic.dashamsa.house_occupancy.node_review.v1.rahu',
      ),
      isTrue,
    );
    expect(
      eleventh.evidence
          .firstWhere((value) => value.ruleId.contains('node_review.v1.rahu'))
          .descriptionEn,
      contains('no invented dignity, aspect or directional score'),
    );
  });

  test('does not create Rahu or Ketu full-sign aspects in D10', () {
    final aspectRules = engine
        .build(_output())
        .houses
        .expand((value) => value.evidence)
        .where((value) => value.ruleId.contains('full_sign_aspect'))
        .map((value) => value.ruleId)
        .toList(growable: false);

    expect(aspectRules.any((value) => value.contains('.rahu.')), isFalse);
    expect(aspectRules.any((value) => value.contains('.ketu.')), isFalse);
  });

  test('preserves D1 tenth-lord versus D10 tenth-house conflict as Mixed', () {
    final output = _output();
    final charts = output.output['divisionalCharts']! as Map<String, Object?>;
    final d10 = charts['d10']! as Map<String, Object?>;
    final d10Planets = (d10['planets']! as List).cast<Map<String, Object?>>();
    final natalPlanets =
        (output.output['planets']! as List).cast<Map<String, Object?>>();
    final jupiterD10 =
        d10Planets.firstWhere((value) => value['body'] == 'jupiter');
    final jupiterNatal =
        natalPlanets.firstWhere((value) => value['body'] == 'jupiter');
    // Gemini D10 ascendant: Pisces is the tenth house. Move its lord Jupiter
    // to Capricorn (house 8, debilitation) while D1 tenth lord Saturn remains
    // exalted in Libra (D10 house 5). The two structural families conflict.
    jupiterD10['signIndex'] = 9;
    jupiterNatal['dashamsaSignIndex'] = 9;

    final result = engine.build(output).careerSynthesis;
    expect(result.contradictorySignals, isTrue);
    expect(result.confidence, AnalysisConfidence.low);
    expect(result.polarity, AnalysisPolarity.mixed);
  });

  test('rejects pre-v10 output without explicit governed D10 chart', () {
    final legacy = _output(schema: 'vedic-chart-v9');
    expect(() => engine.build(legacy), throwsArgumentError);
  });

  test('rejects disagreement between explicit D10 and per-planet field', () {
    final output = _output();
    final charts = output.output['divisionalCharts']! as Map<String, Object?>;
    final d10 = charts['d10']! as Map<String, Object?>;
    final planets = (d10['planets']! as List).cast<Map<String, Object?>>();
    planets.firstWhere((value) => value['body'] == 'sun')['signIndex'] = 5;

    expect(() => engine.build(output), throwsStateError);
  });
}

CalculationOutputSnapshot _output({String schema = 'vedic-chart-v10'}) {
  const d10Signs = <String, int>{
    'sun': 4,
    'moon': 3,
    'mars': 0,
    'mercury': 2,
    'jupiter': 11,
    'venus': 1,
    'saturn': 6,
    'rahu': 0,
    'ketu': 6,
  };
  final planets = <Map<String, Object?>>[
    for (final entry in d10Signs.entries)
      {
        'body': entry.key,
        'signIndex': entry.key == 'saturn' ? 9 : 0,
        'siderealLongitude': entry.key == 'saturn' ? 285.0 : 1.0,
        'dashamsaSignIndex': entry.value,
      },
  ];
  return CalculationOutputSnapshot(
    id: 1,
    consultationId: 1,
    inputSnapshotId: 1,
    engineId: 'fixture-vedic',
    engineVersion: '1',
    outputSchemaVersion: schema,
    output: {
      'ascendant': {'signIndex': 0},
      'planets': planets,
      'divisionalCharts': {
        'd10': {
          'division': 10,
          'calculationProfile': 'bphs-dashamsa-odd-self-even-ninth-v1',
          'ascendant': {'signIndex': 2},
          'planets': [
            for (final entry in d10Signs.entries)
              {'body': entry.key, 'signIndex': entry.value},
          ],
        },
      },
    },
    outputHash: List.filled(64, 'a').join(),
    createdAt: DateTime.utc(2026, 8, 9),
  );
}
