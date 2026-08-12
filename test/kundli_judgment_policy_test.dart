import 'package:astro_logic/src/models/kundli_analysis.dart';
import 'package:astro_logic/src/services/kundli_judgment_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const placement = ChartEvidence(
    ruleId: 'vedic.placement.v1',
    outputPath: r'$.planets.jupiter',
    kind: EvidenceKind.placement,
    descriptionEn: 'Jupiter placement evidence',
    descriptionBn: 'বৃহস্পতির অবস্থানের প্রমাণ',
  );
  const strength = ChartEvidence(
    ruleId: 'vedic.strength.v1',
    outputPath: r'$.strength.jupiter',
    kind: EvidenceKind.strength,
    descriptionEn: 'Jupiter strength evidence',
    descriptionBn: 'বৃহস্পতির শক্তির প্রমাণ',
  );

  KundliAnalysis fixture({
    AnalysisConfidence timingConfidence = AnalysisConfidence.high,
    List<ChartEvidence> findingEvidence = const [placement, strength],
    bool professionalReviewRequired = true,
  }) =>
      KundliAnalysis(
        findings: [
          ChartFinding(
            code: 'career.support.jupiter',
            area: LifeArea.career,
            polarity: AnalysisPolarity.supportive,
            confidence: AnalysisConfidence.high,
            titleEn: 'Career support',
            titleBn: 'পেশাগত সহায়তা',
            narrativeEn: 'A supportive tendency is present.',
            narrativeBn: 'সহায়ক প্রবণতা রয়েছে।',
            evidence: findingEvidence,
          ),
        ],
        timingWindows: [
          AnalysisTimingWindow(
            code: 'career.window.jupiter',
            area: LifeArea.career,
            start: DateTime.utc(2027),
            end: DateTime.utc(2028),
            polarity: AnalysisPolarity.supportive,
            confidence: timingConfidence,
            narrativeEn: 'A potentially supportive period.',
            narrativeBn: 'সম্ভাব্য সহায়ক সময়কাল।',
            evidence: const [placement, strength],
          ),
        ],
        remedyCandidates: const [
          AnalysisRemedyCandidate(
            code: 'remedy.review.jupiter',
            kind: AnalysisRemedyKind.gemstone,
            targetPlanet: 'jupiter',
            actionEn: 'Review a Jupiter gemstone candidate.',
            actionBn: 'বৃহস্পতির রত্ন প্রার্থী পর্যালোচনা করুন।',
            rationaleEn: 'Candidate only; professional review required.',
            rationaleBn: 'শুধু প্রার্থী; পেশাদার পর্যালোচনা আবশ্যক।',
            cautionEn: 'Check functional lordship and contraindications.',
            cautionBn: 'কার্যকর অধিপতি ও বিরুদ্ধতা যাচাই করুন।',
            evidence: [placement],
          ),
        ],
        warningsEn: const ['Astrological possibility, not a guarantee.'],
        warningsBn: const ['জ্যোতিষীয় সম্ভাবনা, নিশ্চিত ফল নয়।'],
        professionalReviewRequired: professionalReviewRequired,
      );

  test('evidence-backed bilingual analysis passes', () {
    expect(
      () => KundliJudgmentPolicy.validate(
        fixture(),
        preciseBirthTime: true,
      ),
      returnsNormally,
    );
  });

  test('high confidence requires two independent rules', () {
    expect(
      () => KundliJudgmentPolicy.validate(
        fixture(findingEvidence: const [placement]),
        preciseBirthTime: true,
      ),
      throwsStateError,
    );
  });

  test('imprecise birth time blocks high-confidence timing', () {
    expect(
      () => KundliJudgmentPolicy.validate(
        fixture(),
        preciseBirthTime: false,
      ),
      throwsStateError,
    );
    expect(
      () => KundliJudgmentPolicy.validate(
        fixture(timingConfidence: AnalysisConfidence.medium),
        preciseBirthTime: false,
      ),
      returnsNormally,
    );
  });

  test('professional review cannot be disabled', () {
    expect(
      () => KundliJudgmentPolicy.validate(
        fixture(professionalReviewRequired: false),
        preciseBirthTime: true,
      ),
      throwsStateError,
    );
  });

  test('rejects a Dasha profile whose score and polarity disagree', () {
    final analysis = fixture();
    final invalid = KundliAnalysis(
      findings: analysis.findings,
      timingWindows: analysis.timingWindows,
      dashaActivationProfiles: const [
        DashaActivationProfile(
          lord: 'jupiter',
          score: 4,
          polarity: AnalysisPolarity.challenging,
          lifeAreas: [LifeArea.career],
          summaryEn: 'Jupiter activates career.',
          summaryBn: 'বৃহস্পতি পেশাক্ষেত্র সক্রিয় করে।',
          evidence: [placement],
        ),
      ],
      remedyCandidates: analysis.remedyCandidates,
      warningsEn: analysis.warningsEn,
      warningsBn: analysis.warningsBn,
      professionalReviewRequired: true,
    );

    expect(
      () => KundliJudgmentPolicy.validate(
        invalid,
        preciseBirthTime: true,
      ),
      throwsStateError,
    );
  });
}
