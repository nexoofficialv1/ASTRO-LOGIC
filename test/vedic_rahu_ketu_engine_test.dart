import 'package:astro_logic/src/models/calculation_output_snapshot.dart';
import 'package:astro_logic/src/models/kundli_analysis.dart';
import 'package:astro_logic/src/vedic/vedic_lagna_judgment_engine.dart';
import 'package:astro_logic/src/vedic/vedic_rahu_ketu_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const engine = VedicRahuKetuEngine();

  test('classifies source-bounded Rahu and Ketu natal house profiles', () {
    final findings = engine.build(
      _output(
        ascendantSign: 0,
        planetSigns: const {'rahu': 2, 'ketu': 8, 'jupiter': 7},
      ),
    );

    final rahu = findings.firstWhere((value) => value.code.contains('.rahu.'));
    final ketu = findings.firstWhere((value) => value.code.contains('.ketu.'));
    expect(rahu.code, 'vedic.node.natal.rahu.house3.v1');
    expect(rahu.polarity, AnalysisPolarity.supportive);
    expect(ketu.code, 'vedic.node.natal.ketu.house9.v1');
    expect(ketu.polarity, AnalysisPolarity.challenging);
    expect(rahu.confidence, isNot(AnalysisConfidence.high));
    expect(ketu.confidence, isNot(AnalysisConfidence.high));
  });

  test('preserves mixed Rahu career-house profile instead of forcing support', () {
    final findings = engine.build(
      _output(
        ascendantSign: 0,
        planetSigns: const {'rahu': 9, 'ketu': 3},
      ),
    );
    final rahu = findings.firstWhere((value) => value.code.contains('.rahu.'));
    expect(rahu.code, 'vedic.node.natal.rahu.house10.v1');
    expect(rahu.polarity, AnalysisPolarity.mixed);
    expect(rahu.area, LifeArea.career);
  });

  test('Kendra/Trikona same-sign connection softens challenge only to Mixed', () {
    final findings = engine.build(
      _output(
        ascendantSign: 0,
        planetSigns: const {
          'rahu': 0,
          'ketu': 6,
          'mars': 0,
        },
      ),
    );
    final rahu = findings.firstWhere((value) => value.code.contains('.rahu.'));
    expect(rahu.polarity, AnalysisPolarity.mixed);
    expect(
      rahu.evidence.any((value) => value.ruleId.contains('phaladeepika20.52')),
      isTrue,
    );
    expect(rahu.narrativeEn, contains('candidate'));
  });

  test('does not invent node dignity, exaltation or aspect claims', () {
    final finding = engine
        .build(_output(ascendantSign: 0))
        .firstWhere((value) => value.code.contains('.rahu.'));
    expect(finding.narrativeEn, contains('not invented'));
    expect(
      finding.evidence.any((value) => value.ruleId.contains('aspect')),
      isFalse,
    );
  });

  test('Rahu Dasha association uses carrier direction and preserves conflict', () {
    final positive = engine.buildDashaAdjustment(
      const NodeDashaContext(
        node: 'rahu',
        ascendantSign: 0,
        nodeSign: 8,
        nodeHouse: 9,
        dispositor: 'jupiter',
        classicalPlanets: [
          NodeDashaPlanetContext(
            body: 'jupiter',
            signIndex: 8,
            activationScore: 4,
            ownedHouses: [9, 12],
          ),
        ],
      ),
    );
    expect(positive.scoreModifier, greaterThan(0));
    expect(positive.internalConflict, isFalse);
    expect(
      positive.evidence.any((value) => value.ruleId.contains('phaladeepika20.39')),
      isTrue,
    );

    final conflict = engine.buildDashaAdjustment(
      const NodeDashaContext(
        node: 'rahu',
        ascendantSign: 0,
        nodeSign: 8,
        nodeHouse: 9,
        dispositor: 'jupiter',
        classicalPlanets: [
          NodeDashaPlanetContext(
            body: 'jupiter',
            signIndex: 8,
            activationScore: 4,
            ownedHouses: [9, 12],
          ),
          NodeDashaPlanetContext(
            body: 'saturn',
            signIndex: 8,
            activationScore: -3,
            ownedHouses: [10, 11],
          ),
        ],
      ),
    );
    expect(conflict.internalConflict, isTrue);
  });

  test('Ketu does not inherit Rahu-only associated-planet rule', () {
    final adjustment = engine.buildDashaAdjustment(
      const NodeDashaContext(
        node: 'ketu',
        ascendantSign: 0,
        nodeSign: 2,
        nodeHouse: 3,
        dispositor: 'mercury',
        classicalPlanets: [
          NodeDashaPlanetContext(
            body: 'mercury',
            signIndex: 2,
            activationScore: -4,
            ownedHouses: [3, 6],
          ),
        ],
      ),
    );
    expect(
      adjustment.evidence.any((value) => value.ruleId.contains('phaladeepika20.39')),
      isFalse,
    );
    expect(adjustment.internalConflict, isFalse);
  });

  test('main Vedic judgment integrates node findings and v2 node-Dasha evidence', () async {
    const judgment = VedicLagnaJudgmentEngine();
    final analysis = await judgment.analyze(
      _output(
        ascendantSign: 0,
        planetSigns: const {'rahu': 8, 'jupiter': 8},
      ),
    );

    expect(judgment.engineVersion, '32.0.0');
    expect(judgment.analysisSchemaVersion, 'kundli-analysis-v32');
    expect(
      analysis.findings.any((value) => value.code.startsWith('vedic.node.natal.rahu.')),
      isTrue,
    );
    final rahuProfile = analysis.dashaActivationProfiles
        .firstWhere((value) => value.lord == 'rahu');
    expect(
      rahuProfile.evidence.any((value) => value.ruleId.contains('vedic.node.dasha')),
      isTrue,
    );
  });
}

CalculationOutputSnapshot _output({
  required int ascendantSign,
  Map<String, int> planetSigns = const {},
}) {
  final signs = <String, int>{
    'sun': 4,
    'moon': 3,
    'mars': 0,
    'mercury': 2,
    'jupiter': 8,
    'venus': 1,
    'saturn': 9,
    'rahu': 10,
    'ketu': 4,
    ...planetSigns,
  };
  final planets = signs.entries.map((entry) {
    final longitude = entry.value * 30.0 + 15.0;
    return <String, Object?>{
      'body': entry.key,
      'signIndex': entry.value,
      'siderealLongitude': longitude,
      'tropicalLongitude': longitude,
      'navamsaSignIndex': ((longitude * 9.0) ~/ 30.0) % 12,
      'retrograde': entry.key == 'rahu' || entry.key == 'ketu',
    };
  }).toList(growable: false);

  return CalculationOutputSnapshot(
    id: 61,
    consultationId: 1,
    inputSnapshotId: 1,
    engineId: 'fixture-vedic',
    engineVersion: '10',
    outputSchemaVersion: 'vedic-chart-v1',
    output: {
      'metadata': {
        'utcDateTime': DateTime.utc(1984, 3, 12, 18, 42).toIso8601String(),
      },
      'ascendant': {
        'signIndex': ascendantSign,
        'siderealLongitude': ascendantSign * 30.0 + 15.0,
      },
      'planets': planets,
      'panchanga': const {'paksha': 'shukla'},
    },
    outputHash: List.filled(64, 'c').join(),
    createdAt: DateTime.utc(2026, 8, 9),
  );
}
