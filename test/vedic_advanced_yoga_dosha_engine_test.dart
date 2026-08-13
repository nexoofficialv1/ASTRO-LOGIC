import 'package:astro_logic/src/models/calculation_output_snapshot.dart';
import 'package:astro_logic/src/models/kundli_analysis.dart';
import 'package:astro_logic/src/vedic/vedic_advanced_yoga_dosha_engine.dart';
import 'package:astro_logic/src/vedic/vedic_lagna_judgment_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const engine = VedicAdvancedYogaDoshaEngine();

  test('detects ninth-tenth lord conjunction Raja Yoga without High confidence', () {
    final findings = engine.build(
      _output(
        ascendantSign: 0,
        planetSigns: const {
          'jupiter': 8,
          'saturn': 8,
        },
      ),
    );
    final finding = findings.firstWhere(
      (value) =>
          value.code == 'vedic.yoga.raja.dharma_karma_lords_conjunction.v1',
    );

    expect(finding.polarity, AnalysisPolarity.supportive);
    expect(finding.confidence, AnalysisConfidence.medium);
    expect(finding.evidence.first.ruleId, contains('phaladeepika.6.37'));
  });

  test('keeps ninth-tenth conjunction outside enabled auspicious houses as candidate', () {
    final findings = engine.build(
      _output(
        ascendantSign: 0,
        planetSigns: const {
          'jupiter': 1,
          'saturn': 1,
        },
      ),
    );
    final finding = findings.firstWhere(
      (value) => value.code ==
          'vedic.yoga.raja.dharma_karma_lords_conjunction.candidate.v1',
    );

    expect(finding.polarity, AnalysisPolarity.mixed);
    expect(finding.confidence, AnalysisConfidence.low);
    expect(finding.titleEn, contains('candidate'));
  });

  test('detects BPHS 41.2 great-affluence Dhana formation', () {
    final findings = engine.build(
      _output(
        ascendantSign: 9,
        planetSigns: const {
          'venus': 1,
          'mars': 7,
        },
      ),
    );

    final finding = findings.firstWhere(
      (value) => value.code == 'vedic.yoga.dhana.bphs41.2.v1',
    );
    expect(finding.area, LifeArea.finance);
    expect(finding.confidence, isNot(AnalysisConfidence.high));
  });

  test('detects Harsha structural profile for sixth lord in a dusthana', () {
    final findings = engine.build(
      _output(
        ascendantSign: 0,
        planetSigns: const {'mercury': 7},
      ),
    );
    final finding = findings.firstWhere(
      (value) => value.code == 'vedic.yoga.vipareeta.harsha.v1',
    );

    expect(finding.area, LifeArea.obstacles);
    expect(finding.narrativeEn, contains('Phaladeepika VI.57'));
  });

  test('records Neecha-bhanga conditions without erasing D1 debilitation', () {
    final findings = engine.build(
      _output(
        ascendantSign: 6,
        planetSigns: const {
          'sun': 6,
          'venus': 9,
          'mars': 0,
          'moon': 6,
        },
      ),
    );
    final finding = findings.firstWhere(
      (value) => value.code == 'vedic.yoga.neechabhanga.sun.v1',
    );

    expect(finding.polarity, AnalysisPolarity.mixed);
    expect(finding.narrativeEn, contains('not erased'));
    expect(finding.evidence, isNotEmpty);
    expect(finding.confidence, isNot(AnalysisConfidence.high));
  });

  test('Kuja multi-reference review preserves mitigation as review-only', () {
    final findings = engine.build(
      _output(
        ascendantSign: 0,
        planetSigns: const {
          'mars': 0,
          'moon': 6,
          'venus': 9,
          'jupiter': 8,
        },
      ),
    );
    final finding = findings.firstWhere(
      (value) => value.code == 'vedic.dosha.kuja.multi_reference.v1',
    );

    expect(finding.polarity, AnalysisPolarity.mixed);
    expect(finding.narrativeEn, contains('not treated as automatic cancellation'));
    expect(finding.narrativeEn, contains('must never be used alone'));
  });

  test('multi-yoga synthesis preserves contradiction instead of majority voting', () {
    final synthesis = engine.synthesize([
      _finding('vedic.yoga.one', AnalysisPolarity.supportive),
      _finding('vedic.yoga.two', AnalysisPolarity.supportive),
      _finding('vedic.dosha.review', AnalysisPolarity.mixed),
    ]);

    expect(synthesis, isNotNull);
    expect(synthesis!.polarity, AnalysisPolarity.mixed);
    expect(synthesis.confidence, AnalysisConfidence.low);
    expect(synthesis.narrativeEn, contains('does not use majority voting'));
  });

  test('aligned Yoga synthesis remains capped at Medium confidence', () {
    final synthesis = engine.synthesize([
      _finding('vedic.yoga.one', AnalysisPolarity.supportive),
      _finding('vedic.yoga.two', AnalysisPolarity.supportive),
    ]);

    expect(synthesis, isNotNull);
    expect(synthesis!.polarity, AnalysisPolarity.supportive);
    expect(synthesis.confidence, AnalysisConfidence.medium);
  });

  test('main Vedic judgment integrates advanced engine and bumps schema', () async {
    const judgment = VedicLagnaJudgmentEngine();
    final analysis = await judgment.analyze(
      _output(
        ascendantSign: 0,
        planetSigns: const {
          'jupiter': 8,
          'saturn': 8,
          'mercury': 7,
        },
      ),
    );

    expect(judgment.engineVersion, '32.0.0');
    expect(judgment.analysisSchemaVersion, 'kundli-analysis-v32');
    expect(
      analysis.findings.any(
        (value) =>
            value.code == 'vedic.yoga.raja.dharma_karma_lords_conjunction.v1',
      ),
      isTrue,
    );
    expect(
      analysis.findings.any(
        (value) => value.code == 'vedic.yoga.synthesis.advanced_v1',
      ),
      isTrue,
    );
  });
}

ChartFinding _finding(String code, AnalysisPolarity polarity) => ChartFinding(
      code: code,
      area: LifeArea.overall,
      polarity: polarity,
      confidence: AnalysisConfidence.medium,
      titleEn: code,
      titleBn: code,
      narrativeEn: code,
      narrativeBn: code,
      evidence: const [
        ChartEvidence(
          ruleId: 'fixture',
          outputPath: r'$.planets[*]',
          kind: EvidenceKind.yoga,
          descriptionEn: 'fixture',
          descriptionBn: 'fixture',
        ),
      ],
    );

CalculationOutputSnapshot _output({
  required int ascendantSign,
  Map<String, int> planetSigns = const {},
  Set<String> retrogradePlanets = const {},
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
      'retrograde': retrogradePlanets.contains(entry.key),
    };
  }).toList(growable: false);

  return CalculationOutputSnapshot(
    id: 60,
    consultationId: 1,
    inputSnapshotId: 1,
    engineId: 'fixture-vedic',
    engineVersion: '10',
    outputSchemaVersion: 'vedic-chart-v1',
    output: {
      'metadata': {'utcDateTime': DateTime.utc(1984, 3, 12, 18, 42).toIso8601String()},
      'ascendant': {
        'signIndex': ascendantSign,
        'siderealLongitude': ascendantSign * 30.0 + 15.0,
      },
      'planets': planets,
    },
    outputHash: List.filled(64, 'b').join(),
    createdAt: DateTime.utc(2026, 8, 9),
  );
}
