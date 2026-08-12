import 'package:astro_logic/src/models/calculation_output_snapshot.dart';
import 'package:astro_logic/src/models/kundli_analysis.dart';
import 'package:astro_logic/src/vedic/vedic_navamsa_interpretation_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const engine = VedicNavamsaInterpretationEngine();

  test('builds all twelve D9 house/lord/aspect interpretation records', () {
    final results = engine.build(_output());

    expect(results, hasLength(12));
    expect(results.map((value) => value.houseNumber).toSet(), hasLength(12));
    expect(results.every((value) => value.evidence.length >= 2), isTrue);
    expect(
      results.every(
        (value) => value.ruleVersion == 'navamsa-house-interpretation-v1',
      ),
      isTrue,
    );
    expect(results.every((value) => value.confidence != AnalysisConfidence.high), isTrue);
  });

  test('preserves explicit D9 component conflict as Mixed', () {
    final first = engine.build(_output()).first;

    expect(first.houseNumber, 1);
    expect(first.houseLord, 'mars');
    expect(first.lordHouse, 4);
    expect(first.lordDignity, 'debilitated');
    expect(first.contradictorySignals, isTrue);
    expect(first.polarity, AnalysisPolarity.mixed);
    expect(first.confidence, AnalysisConfidence.low);
    expect(first.narrativeEn, contains('preserved as Mixed'));
  });

  test('emits medium confidence only when multiple D9 components reinforce', () {
    final fifth = engine.build(_output())[4];

    expect(fifth.houseNumber, 5);
    expect(fifth.houseLord, 'sun');
    expect(fifth.lordHouse, 5);
    expect(fifth.lordDignity, 'ownSign');
    expect(fifth.polarity, AnalysisPolarity.supportive);
    expect(fifth.confidence, AnalysisConfidence.medium);
    expect(fifth.aspectors, contains('jupiter'));
  });

  test('keeps Rahu and Ketu occupancy visible but directionally neutral', () {
    final eleventh = engine.build(_output())[10];

    expect(eleventh.occupants, contains('rahu'));
    expect(
      eleventh.evidence.any(
        (value) => value.ruleId ==
            'vedic.navamsa.house_occupancy.node_review.v1.rahu',
      ),
      isTrue,
    );
    expect(
      eleventh.evidence.firstWhere(
        (value) => value.ruleId.contains('node_review.v1.rahu'),
      ).descriptionEn,
      contains('no invented dignity or directional score'),
    );
  });

  test('does not create Rahu or Ketu full-sign aspects', () {
    final results = engine.build(_output());
    final aspectRules = results
        .expand((value) => value.evidence)
        .where((value) => value.ruleId.contains('full_sign_aspect'))
        .map((value) => value.ruleId)
        .toList(growable: false);

    expect(aspectRules.any((value) => value.contains('.rahu.')), isFalse);
    expect(aspectRules.any((value) => value.contains('.ketu.')), isFalse);
  });

  test('rejects legacy output without explicit D9 chart', () {
    final legacy = _output(schema: 'vedic-chart-v1', includeD9: false);

    expect(() => engine.build(legacy), throwsArgumentError);
  });

  test('rejects disagreement between explicit D9 and per-planet Navamsha', () {
    final output = _output();
    final charts = output.output['divisionalCharts']! as Map<String, Object?>;
    final d9 = charts['d9']! as Map<String, Object?>;
    final planets = (d9['planets']! as List).cast<Map<String, Object?>>();
    final sun = planets.firstWhere((value) => value['body'] == 'sun');
    sun['signIndex'] = 5;

    expect(() => engine.build(output), throwsStateError);
  });
}

CalculationOutputSnapshot _output({
  String schema = 'vedic-chart-v4',
  bool includeD9 = true,
}) {
  const d9Signs = <String, int>{
    'sun': 4,
    'moon': 3,
    'mars': 3,
    'mercury': 2,
    'jupiter': 0,
    'venus': 1,
    'saturn': 9,
    'rahu': 10,
    'ketu': 4,
  };
  final natalPlanets = <Map<String, Object?>>[
    for (final entry in d9Signs.entries)
      {
        'body': entry.key,
        'signIndex': 0,
        'siderealLongitude': 1.0,
        'navamsaSignIndex': entry.value,
        'retrograde': false,
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
      'metadata': {'utcDateTime': DateTime.utc(1984, 3, 12).toIso8601String()},
      'ascendant': {'signIndex': 0, 'navamsaSignIndex': 0},
      'planets': natalPlanets,
      if (includeD9)
        'divisionalCharts': {
          'd9': {
            'division': 9,
            'ascendant': {'signIndex': 0},
            'planets': [
              for (final entry in d9Signs.entries)
                {'body': entry.key, 'signIndex': entry.value},
            ],
          },
        },
    },
    outputHash: List.filled(64, 'a').join(),
    createdAt: DateTime.utc(2026, 8, 7),
  );
}
