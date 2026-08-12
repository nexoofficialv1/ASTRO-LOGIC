import 'package:astro_logic/src/models/kundli_analysis.dart';
import 'package:astro_logic/src/models/kundli_analysis_snapshot.dart';
import 'package:astro_logic/src/numerology/numerology_analysis_policy.dart';
import 'package:astro_logic/src/numerology/numerology_engine.dart';
import 'package:astro_logic/src/numerology/numerology_judgment_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const calculationEngine = NumerologyEngine();
  const judgmentEngine = NumerologyJudgmentEngine();

  test('creates v2 bilingual findings, three-year context and safe remedy', () {
    final profile = calculationEngine.calculate(
      NumerologyInput(
        fullNameLatin: 'Bappa Ray',
        birthDate: DateTime(1984, 3, 13),
        personalYear: 2026,
      ),
    );
    final analysis = judgmentEngine.analyze(profile);

    expect(analysis.analysisSchemaVersion, 'numerology-analysis-v3');
    expect(analysis.findings, hasLength(8));
    expect(analysis.crossSystemFindings, isEmpty);
    expect(analysis.timingWindows, hasLength(3));
    expect(analysis.remedyCandidates, hasLength(1));
    expect(analysis.professionalReviewRequired, isTrue);
    expect(
      analysis.confidenceSummary.predictionConfidence,
      AnalysisConfidence.low,
    );
    expect(analysis.confidenceSummary.arithmeticDeterministic, isTrue);
    expect(analysis.confidenceSummary.vedicCrossCheckCanRaiseConfidence, isFalse);

    final lifePath = analysis.findings.firstWhere(
      (value) => value.code == 'numerology.life_path.11',
    );
    expect(lifePath.titleEn, contains('Inspired sensitivity'));
    expect(lifePath.titleBn, contains('প্রেরণাময়'));
    expect(lifePath.polarity, AnalysisPolarity.mixed);
    expect(lifePath.confidence, AnalysisConfidence.low);

    final soulUrge = analysis.findings.firstWhere(
      (value) => value.code.startsWith('numerology.pythagorean.soul_urge.'),
    );
    final personality = analysis.findings.firstWhere(
      (value) => value.code.startsWith('numerology.pythagorean.personality.'),
    );
    final maturity = analysis.findings.firstWhere(
      (value) => value.code == 'numerology.maturity.1',
    );
    expect(soulUrge.titleEn, contains('Soul Urge'));
    expect(personality.titleEn, contains('Personality'));
    expect(maturity.titleEn, contains('Maturity'));

    final targetTiming = analysis.timingWindows.firstWhere(
      (value) => value.start.year == 2026,
    );
    expect(targetTiming.start, DateTime.utc(2026));
    expect(targetTiming.end, DateTime.utc(2027));
    expect(targetTiming.narrativeEn, contains('Personal Year 8'));
    expect(targetTiming.narrativeEn, contains('planning/reflection'));

    final remedy = analysis.remedyCandidates.single;
    expect(remedy.kind, AnalysisRemedyKind.behavioral);
    expect(remedy.targetPlanet, isNull);
    expect(remedy.actionEn, contains('cash flow'));
    expect(remedy.cautionEn, contains('not medical'));
    expect(remedy.cautionEn, contains('gemstone'));
    expect(
      analysis.remedyCandidates
          .any((value) => value.kind == AnalysisRemedyKind.gemstone),
      isFalse,
    );
    expect(() => NumerologyAnalysisPolicy.validate(analysis), returnsNormally);
  });

  test('does not treat different name-system totals as an automatic conflict', () {
    final profile = calculationEngine.calculate(
      NumerologyInput(
        fullNameLatin: 'Bappa Ray',
        birthDate: DateTime(1984, 3, 13),
        personalYear: 2026,
      ),
    );
    final analysis = judgmentEngine.analyze(profile);
    final comparison = analysis.findings.firstWhere(
      (value) => value.code == 'numerology.name.dual_system_comparison',
    );

    expect(comparison.polarity, AnalysisPolarity.mixed);
    expect(comparison.confidence, AnalysisConfidence.medium);
    expect(comparison.narrativeEn, contains('not automatically a conflict'));
    expect(comparison.narrativeEn, contains('does not justify changing'));
    expect(comparison.evidence, hasLength(2));
  });

  test('candidate comparison stays arithmetic-only and requires explicit human focus', () {
    final profile = calculationEngine.calculate(
      NumerologyInput(
        fullNameLatin: 'Bappa Ray',
        birthDate: DateTime(1984, 3, 13),
        personalYear: 2026,
        alternateNamesLatin: const ['Bappa Roy', 'Bappa Rai'],
        professionalSelectedNameLatin: 'Bappa Rai',
      ),
    );
    final analysis = judgmentEngine.analyze(profile);

    expect(analysis.nameCandidateReviews, hasLength(2));
    expect(
      analysis.nameCandidateReviews.every(
        (value) => value.confidence == AnalysisConfidence.medium,
      ),
      isTrue,
    );
    expect(
      analysis.nameCandidateReviews
          .where((value) => value.selectedForProfessionalReview),
      hasLength(1),
    );
    final selected = analysis.nameCandidateReviews.singleWhere(
      (value) => value.selectedForProfessionalReview,
    );
    expect(selected.candidateNameLatin, 'BAPPA RAI');
    expect(selected.narrativeEn, contains('descriptive only'));
    expect(selected.cautionEn, contains('does not rank'));
    expect(selected.cautionEn, contains('legal-name change'));
    expect(selected.toMap()['rankingScore'], isNull);
    expect(selected.toMap()['automaticRecommendation'], isFalse);
    expect(() => NumerologyAnalysisPolicy.validate(analysis), returnsNormally);
  });

  test('guarded Vedic cross-check stays Low confidence and cannot approve remedies', () {
    final profile = calculationEngine.calculate(
      NumerologyInput(
        fullNameLatin: 'Bappa Ray',
        birthDate: DateTime(1984, 3, 13),
        personalYear: 2026,
      ),
    );
    final analysis = judgmentEngine.analyze(
      profile,
      vedicSnapshot: _vedicSnapshot(),
    );

    expect(analysis.crossSystemFindings, hasLength(3));
    expect(
      analysis.crossSystemFindings.every(
        (value) => value.confidence == AnalysisConfidence.low,
      ),
      isTrue,
    );
    expect(
      analysis.crossSystemFindings
          .any((value) => value.narrativeEn.contains('does not validate')),
      isTrue,
    );
    expect(
      analysis.crossSystemFindings
          .any((value) => value.code.contains('.rahu.limited')),
      isTrue,
    );
    expect(analysis.confidenceSummary.vedicCrossCheckCanRaiseConfidence, isFalse);
    expect(
      analysis.remedyCandidates
          .any((value) => value.kind != AnalysisRemedyKind.behavioral),
      isFalse,
    );
    expect(() => NumerologyAnalysisPolicy.validate(analysis), returnsNormally);
  });

  test('zero vowel subtotal is reviewable and never crashes interpretation', () {
    final profile = calculationEngine.calculate(
      NumerologyInput(
        fullNameLatin: 'Rhythm',
        birthDate: DateTime(1990, 1, 1),
        personalYear: 2026,
      ),
    );
    final analysis = judgmentEngine.analyze(profile);
    final soul = analysis.findings.firstWhere(
      (value) => value.code == 'numerology.pythagorean.soul_urge.0',
    );

    expect(soul.titleEn, contains('Unavailable'));
    expect(soul.narrativeEn, contains('do not invent'));
    expect(() => NumerologyAnalysisPolicy.validate(analysis), returnsNormally);
  });

  test('serialized analysis keeps safety and scientific-status metadata', () {
    final analysis = judgmentEngine.analyze(
      calculationEngine.calculate(
        NumerologyInput(
          fullNameLatin: 'Asha Sen',
          birthDate: DateTime(1992, 7, 4),
          personalYear: 2027,
        ),
      ),
    );
    final output = analysis.toMap();

    expect(output['engineVersion'], '2.1.0');
    expect(output['analysisSchemaVersion'], 'numerology-analysis-v3');
    expect(output['professionalReviewRequired'], isTrue);
    expect(output['scientificStatus'], contains('not scientifically'));
    expect((output['timingWindows'] as List), hasLength(3));
    expect((output['crossSystemFindings'] as List), isEmpty);
    expect((output['nameCandidateReviews'] as List), isEmpty);
    expect(
      ((output['confidenceSummary'] as Map)['predictionConfidence']),
      'low',
    );
    expect(
      (output['warningsEn'] as List).join(' '),
      contains('never changes a name spelling'),
    );
  });
}

KundliAnalysisSnapshot _vedicSnapshot() => KundliAnalysisSnapshot(
      id: 91,
      consultationId: 7,
      calculationOutputId: 12,
      engineId: 'vedic-judgment-engine',
      engineVersion: '32.0.0',
      analysisSchemaVersion: 'kundli-analysis-v32',
      analysis: {
        'gemstoneCandidateReviews': [
          {
            'planet': 'moon',
            'status': 'insufficientEvidence',
            'functionalScore': 1,
            'activeDashaRole': 'none',
            'rationaleEn': 'No governed strengthening approval.',
            'rationaleBn': 'Governed strengthening approval নেই।',
          },
          {
            'planet': 'saturn',
            'status': 'contraindicated',
            'functionalScore': -2,
            'activeDashaRole': 'antardasha',
            'rationaleEn': 'Functional-lordship gate blocks strengthening.',
            'rationaleBn': 'Functional-lordship gate strengthening বন্ধ করেছে।',
          },
        ],
      },
      analysisHash: 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
      createdAt: DateTime.utc(2026, 8, 10),
    );
