import 'package:astro_logic/src/models/kundli_analysis.dart';
import 'package:astro_logic/src/vedic/vedic_remedy_recommendation_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const engine = VedicRemedyRecommendationEngine();

  const evidenceA = ChartEvidence(
    ruleId: 'vedic.house_lord.finance.v1',
    outputPath: r'$.planets.jupiter',
    kind: EvidenceKind.lordship,
    descriptionEn: 'Finance lordship challenge.',
    descriptionBn: 'অর্থক্ষেত্রে অধিপতি-সংক্রান্ত চ্যালেঞ্জ।',
  );
  const evidenceB = ChartEvidence(
    ruleId: 'vedic.ashtakavarga.finance.v1',
    outputPath: r'$.ashtakavarga.sarvashtakavarga[1]',
    kind: EvidenceKind.ashtakavarga,
    descriptionEn: 'Independent finance support is below the enabled band.',
    descriptionBn: 'স্বাধীন অষ্টকবর্গ সমর্থন সক্রিয় band-এর নিচে।',
  );

  test('requires two independent challenging rules before drafting a remedy', () {
    final oneRule = engine.build(const [
      ChartFinding(
        code: 'finance.one',
        area: LifeArea.finance,
        polarity: AnalysisPolarity.challenging,
        confidence: AnalysisConfidence.medium,
        titleEn: 'Finance challenge',
        titleBn: 'অর্থনৈতিক চ্যালেঞ্জ',
        narrativeEn: 'Review finances.',
        narrativeBn: 'অর্থনীতি পর্যালোচনা করুন।',
        evidence: [evidenceA],
      ),
    ]);
    expect(oneRule, isEmpty);

    final twoRules = engine.build(const [
      ChartFinding(
        code: 'finance.one',
        area: LifeArea.finance,
        polarity: AnalysisPolarity.challenging,
        confidence: AnalysisConfidence.medium,
        titleEn: 'Finance challenge',
        titleBn: 'অর্থনৈতিক চ্যালেঞ্জ',
        narrativeEn: 'Review finances.',
        narrativeBn: 'অর্থনীতি পর্যালোচনা করুন।',
        evidence: [evidenceA],
      ),
      ChartFinding(
        code: 'finance.two',
        area: LifeArea.finance,
        polarity: AnalysisPolarity.challenging,
        confidence: AnalysisConfidence.medium,
        titleEn: 'Second finance challenge',
        titleBn: 'দ্বিতীয় অর্থনৈতিক চ্যালেঞ্জ',
        narrativeEn: 'Independent review signal.',
        narrativeBn: 'স্বাধীন review signal।',
        evidence: [evidenceB],
      ),
    ]);

    expect(twoRules, hasLength(1));
    expect(twoRules.single.kind, AnalysisRemedyKind.behavioral);
    expect(twoRules.single.targetPlanet, isNull);
    expect(twoRules.single.actionEn, contains('budget'));
    expect(twoRules.single.cautionEn, contains('not investment advice'));
    expect(twoRules.single.evidence.map((e) => e.ruleId).toSet(), hasLength(2));
  });

  test('does not automate longevity/death-type remedies', () {
    final result = engine.build(const [
      ChartFinding(
        code: 'longevity.one',
        area: LifeArea.longevity,
        polarity: AnalysisPolarity.challenging,
        confidence: AnalysisConfidence.medium,
        titleEn: 'Longevity review A',
        titleBn: 'আয়ু review A',
        narrativeEn: 'Review only.',
        narrativeBn: 'শুধু review।',
        evidence: [evidenceA],
      ),
      ChartFinding(
        code: 'longevity.two',
        area: LifeArea.longevity,
        polarity: AnalysisPolarity.challenging,
        confidence: AnalysisConfidence.medium,
        titleEn: 'Longevity review B',
        titleBn: 'আয়ু review B',
        narrativeEn: 'Review only.',
        narrativeBn: 'শুধু review।',
        evidence: [evidenceB],
      ),
    ]);
    expect(result, isEmpty);
  });

  test('supportive and mixed findings never trigger v1 remedy drafting', () {
    final result = engine.build(const [
      ChartFinding(
        code: 'finance.supportive',
        area: LifeArea.finance,
        polarity: AnalysisPolarity.supportive,
        confidence: AnalysisConfidence.medium,
        titleEn: 'Supportive',
        titleBn: 'সহায়ক',
        narrativeEn: 'Supportive.',
        narrativeBn: 'সহায়ক।',
        evidence: [evidenceA],
      ),
      ChartFinding(
        code: 'finance.mixed',
        area: LifeArea.finance,
        polarity: AnalysisPolarity.mixed,
        confidence: AnalysisConfidence.medium,
        titleEn: 'Mixed',
        titleBn: 'মিশ্র',
        narrativeEn: 'Mixed.',
        narrativeBn: 'মিশ্র।',
        evidence: [evidenceB],
      ),
    ]);
    expect(result, isEmpty);
  });
}
