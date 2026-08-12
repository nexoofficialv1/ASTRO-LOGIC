import '../models/kundli_analysis.dart';
import '../models/kundli_analysis_snapshot.dart';
import 'numerology_analysis.dart';
import 'numerology_engine.dart';
import 'numerology_vedic_cross_check.dart';

class NumerologyJudgmentEngine {
  const NumerologyJudgmentEngine();

  static const engineId = 'astro-logic-numerology-judgment';
  static const engineVersion = '2.1.0';
  static const analysisSchemaVersion = 'numerology-analysis-v3';
  static const confidencePolicyId = 'numerology-confidence-v1';

  NumerologyAnalysis analyze(
    NumerologyProfile profile, {
    KundliAnalysisSnapshot? vedicSnapshot,
  }) {
    final driverEvidence = _numberEvidence(
      ruleId: 'numerology.interpretation.driver.v2',
      outputPath: r'$.driver.reduced',
      labelEn: 'Driver',
      labelBn: 'ড্রাইভার',
      value: profile.driver,
    );
    final lifePathEvidence = _numberEvidence(
      ruleId: 'numerology.interpretation.life_path.v2',
      outputPath: r'$.lifePath.reduced',
      labelEn: 'Life Path',
      labelBn: 'লাইফ পাথ',
      value: profile.lifePath,
    );
    final pythagoreanEvidence = _numberEvidence(
      ruleId: 'numerology.interpretation.pythagorean_expression.v2',
      outputPath: r'$.pythagorean.expression.reduced',
      labelEn: 'Pythagorean Expression',
      labelBn: 'পাইথাগোরিয়ান এক্সপ্রেশন',
      value: profile.pythagorean.expression,
    );
    final soulUrgeEvidence = _numberEvidence(
      ruleId: 'numerology.interpretation.soul_urge.v1',
      outputPath: r'$.pythagorean.soulUrge.reduced',
      labelEn: 'Soul Urge',
      labelBn: 'সোল আর্জ',
      value: profile.pythagorean.soulUrge!,
    );
    final personalityEvidence = _numberEvidence(
      ruleId: 'numerology.interpretation.personality.v1',
      outputPath: r'$.pythagorean.personality.reduced',
      labelEn: 'Personality',
      labelBn: 'পার্সোনালিটি',
      value: profile.pythagorean.personality!,
    );
    final chaldeanEvidence = _numberEvidence(
      ruleId: 'numerology.interpretation.chaldean_name.v2',
      outputPath: r'$.chaldean.expression.reduced',
      labelEn: 'Chaldean Name',
      labelBn: 'চ্যালডিয়ান নাম',
      value: profile.chaldean.expression,
    );
    final maturityEvidence = _numberEvidence(
      ruleId: 'numerology.interpretation.maturity.v1',
      outputPath: r'$.maturity.reduced',
      labelEn: 'Maturity',
      labelBn: 'ম্যাচিউরিটি',
      value: profile.maturity,
    );

    final findings = <ChartFinding>[
      _meaningFinding(
        code: 'numerology.driver.${profile.driver.reduced}',
        labelEn: 'Driver/Birth number',
        labelBn: 'ড্রাইভার/জন্মসংখ্যা',
        value: profile.driver.reduced,
        area: LifeArea.self,
        evidence: driverEvidence,
      ),
      _meaningFinding(
        code: 'numerology.life_path.${profile.lifePath.reduced}',
        labelEn: 'Life Path number',
        labelBn: 'লাইফ পাথ সংখ্যা',
        value: profile.lifePath.reduced,
        area: LifeArea.overall,
        evidence: lifePathEvidence,
      ),
      _meaningFinding(
        code:
            'numerology.pythagorean.expression.${profile.pythagorean.expression.reduced}',
        labelEn: 'Pythagorean Expression number',
        labelBn: 'পাইথাগোরিয়ান এক্সপ্রেশন সংখ্যা',
        value: profile.pythagorean.expression.reduced,
        area: LifeArea.communication,
        evidence: pythagoreanEvidence,
      ),
      _meaningFinding(
        code:
            'numerology.pythagorean.soul_urge.${profile.pythagorean.soulUrge!.reduced}',
        labelEn: 'Soul Urge number',
        labelBn: 'সোল আর্জ সংখ্যা',
        value: profile.pythagorean.soulUrge!.reduced,
        area: LifeArea.self,
        evidence: soulUrgeEvidence,
      ),
      _meaningFinding(
        code:
            'numerology.pythagorean.personality.${profile.pythagorean.personality!.reduced}',
        labelEn: 'Personality number',
        labelBn: 'পার্সোনালিটি সংখ্যা',
        value: profile.pythagorean.personality!.reduced,
        area: LifeArea.communication,
        evidence: personalityEvidence,
      ),
      _meaningFinding(
        code:
            'numerology.chaldean.name.${profile.chaldean.expression.reduced}',
        labelEn: 'Chaldean Name number',
        labelBn: 'চ্যালডিয়ান নামসংখ্যা',
        value: profile.chaldean.expression.reduced,
        area: LifeArea.communication,
        evidence: chaldeanEvidence,
      ),
      _meaningFinding(
        code: 'numerology.maturity.${profile.maturity.reduced}',
        labelEn: 'Maturity synthesis number',
        labelBn: 'ম্যাচিউরিটি synthesis সংখ্যা',
        value: profile.maturity.reduced,
        area: LifeArea.overall,
        evidence: maturityEvidence,
      ),
      _systemComparisonFinding(
        profile,
        pythagoreanEvidence,
        chaldeanEvidence,
      ),
    ];

    final timingWindows = <AnalysisTimingWindow>[
      for (final cycle in profile.personalYearCycle)
        AnalysisTimingWindow(
          code:
              'numerology.personal_year.${cycle.year}.${cycle.value.reduced}',
          area: LifeArea.overall,
          start: DateTime.utc(cycle.year),
          end: DateTime.utc(cycle.year + 1),
          polarity: AnalysisPolarity.mixed,
          confidence: AnalysisConfidence.low,
          narrativeEn:
              '${cycle.year == profile.personalYearTarget ? 'Target' : cycle.year < profile.personalYearTarget ? 'Previous' : 'Next'} calendar-year planning context: traditional Personal Year ${cycle.value.reduced} theme — ${_meaning(cycle.value.reduced).yearFocusEn}. Use this only as a planning/reflection prompt, not an event prediction.',
          narrativeBn:
              '${cycle.year == profile.personalYearTarget ? 'Target' : cycle.year < profile.personalYearTarget ? 'Previous' : 'Next'} calendar-year planning context: প্রচলিত পার্সোনাল ইয়ার ${cycle.value.reduced}-এর বিষয় — ${_meaning(cycle.value.reduced).yearFocusBn}। এটিকে শুধু পরিকল্পনা/আত্মপর্যালোচনার সংকেত হিসেবে ব্যবহার করুন, ঘটনা ঘটার ভবিষ্যদ্বাণী হিসেবে নয়।',
          evidence: [
            _numberEvidence(
              ruleId: 'numerology.interpretation.personal_year.calendar_v2',
              outputPath:
                  r'$.personalYearCycle[?(@.year==' + cycle.year.toString() + r')].value.reduced',
              labelEn: 'Personal Year ${cycle.year}',
              labelBn: '${cycle.year} পার্সোনাল ইয়ার',
              value: cycle.value,
            ),
          ],
        ),
    ];

    final personalYearMeaning = _meaning(profile.personalYear.reduced);
    final targetEvidence = _numberEvidence(
      ruleId: 'numerology.interpretation.personal_year.calendar_v2',
      outputPath: r'$.personalYear.reduced',
      labelEn: 'Personal Year ${profile.personalYearTarget}',
      labelBn: '${profile.personalYearTarget} পার্সোনাল ইয়ার',
      value: profile.personalYear,
    );
    final remedies = <AnalysisRemedyCandidate>[
      AnalysisRemedyCandidate(
        code:
            'numerology.remedy.personal_year.${profile.personalYear.reduced}.behavioral',
        kind: AnalysisRemedyKind.behavioral,
        targetPlanet: null,
        actionEn: personalYearMeaning.actionEn,
        actionBn: personalYearMeaning.actionBn,
        rationaleEn:
            'This optional low-risk planning exercise matches the traditional Personal Year ${profile.personalYear.reduced} theme.',
        rationaleBn:
            'এই ঐচ্ছিক কম-ঝুঁকির পরিকল্পনা অনুশীলনটি প্রচলিত পার্সোনাল ইয়ার ${profile.personalYear.reduced}-এর বিষয়ের সঙ্গে সামঞ্জস্যপূর্ণ।',
        cautionEn:
            'Numerology v2.1 permits only behavioural reflection candidates. This is not medical, legal, financial, relationship, gemstone, mantra, ritual or guaranteed-outcome advice.',
        cautionBn:
            'Numerology v2.1 শুধু behavioural reflection candidate অনুমোদন করে। এটি চিকিৎসা, আইন, অর্থ, সম্পর্ক, রত্ন, মন্ত্র, আচার বা নিশ্চিত ফলের পরামর্শ নয়।',
        evidence: [targetEvidence],
      ),
    ];

    final nameCandidateReviews = <NumerologyNameCandidateReview>[
      for (final comparison in profile.nameCandidateComparisons)
        _buildNameCandidateReview(comparison),
    ];

    final crossSystemFindings = vedicSnapshot == null
        ? const <ChartFinding>[]
        : const NumerologyVedicCrossCheckEngine().build(
            profile,
            vedicSnapshot,
          );

    return NumerologyAnalysis(
      engineId: engineId,
      engineVersion: engineVersion,
      analysisSchemaVersion: analysisSchemaVersion,
      findings: List.unmodifiable(findings),
      nameCandidateReviews: List.unmodifiable(nameCandidateReviews),
      crossSystemFindings: List.unmodifiable(crossSystemFindings),
      timingWindows: List.unmodifiable(timingWindows),
      remedyCandidates: List.unmodifiable(remedies),
      confidenceSummary: const NumerologyConfidenceSummary(
        policyId: confidencePolicyId,
        predictionConfidence: AnalysisConfidence.low,
        arithmeticDeterministic: true,
        vedicCrossCheckCanRaiseConfidence: false,
        rationaleEn:
            'Arithmetic is deterministic under the frozen rule profile, but symbolic interpretation remains Low-confidence traditional guidance. A Vedic cross-check is contextual only and cannot upgrade Numerology prediction confidence.',
        rationaleBn:
            'Frozen rule profile অনুযায়ী arithmetic deterministic, কিন্তু প্রতীকী ব্যাখ্যা Low-confidence প্রচলিত guidance হিসেবেই থাকে। Vedic cross-check শুধু contextual; এটি Numerology prediction confidence বাড়াতে পারে না।',
      ),
      warningsEn: [
        'Numerology is a traditional belief system and is not scientifically validated.',
        'Every symbolic interpretation and behavioural remedy candidate requires professional review.',
        'No guaranteed event, health, legal, financial or relationship outcome is generated.',
        'The engine never changes a name spelling or recommends a legal-name change automatically.',
        'Alternate-name comparison is arithmetic review only: candidates are never ranked as best/lucky and core-number overlap is not a favourability score.',
        if (profile.nameCandidateComparisons.isNotEmpty && profile.professionalSelectedNameLatin == null)
          'No alternate spelling was explicitly selected for professional discussion; the engine will not choose one automatically.',
        if (profile.professionalSelectedNameLatin != null)
          'The stored professional focus ${profile.professionalSelectedNameLatin} records an explicit human choice for discussion only; it is not an engine endorsement or legal-name-change advice.',
        'Numerology v2.1 never generates gemstone, mantra, charity or ritual prescriptions.',
        'A Vedic cross-check, when present, is a caution context only and never raises Numerology confidence or approves a gemstone.',
        if (vedicSnapshot == null)
          'No immutable Vedic judgment snapshot was supplied, so cross-system review is unavailable rather than inferred.',
      ],
      warningsBn: [
        'সংখ্যাতত্ত্ব একটি প্রচলিত বিশ্বাসভিত্তিক পদ্ধতি; এটি বৈজ্ঞানিকভাবে প্রমাণিত নয়।',
        'প্রতিটি প্রতীকী ব্যাখ্যা ও behavioural remedy candidate পেশাদারভাবে যাচাই করতে হবে।',
        'কোনো ঘটনা, স্বাস্থ্য, আইন, অর্থ বা সম্পর্কের নিশ্চিত ফল তৈরি করা হয় না।',
        'ইঞ্জিন নিজে নামের বানান বদলায় না বা সরকারি নাম পরিবর্তনের নির্দেশ দেয় না।',
        'Alternate-name comparison কেবল arithmetic review: কোনো candidate-কে best/lucky হিসেবে rank করা হয় না এবং core-number overlap-কে শুভতার score ধরা হয় না।',
        if (profile.nameCandidateComparisons.isNotEmpty && profile.professionalSelectedNameLatin == null)
          'Professional discussion-এর জন্য কোনো alternate spelling স্পষ্টভাবে নির্বাচন করা হয়নি; engine নিজে কোনোটি বেছে নেবে না।',
        if (profile.professionalSelectedNameLatin != null)
          'সংরক্ষিত professional focus ${profile.professionalSelectedNameLatin} শুধু আলোচনার জন্য মানুষের স্পষ্ট নির্বাচন; এটি engine endorsement বা সরকারি নাম পরিবর্তনের পরামর্শ নয়।',
        'Numerology v2.1 কখনও gemstone, mantra, charity বা ritual prescription তৈরি করে না।',
        'Vedic cross-check থাকলেও সেটি শুধু caution context; এটি Numerology confidence বাড়ায় না বা gemstone approve করে না।',
        if (vedicSnapshot == null)
          'কোনো immutable Vedic judgment snapshot দেওয়া হয়নি, তাই cross-system review অনুমান না করে unavailable রাখা হয়েছে।',
      ],
      professionalReviewRequired: true,
    );
  }

  static NumerologyNameCandidateReview _buildNameCandidateReview(
    NameCandidateComparison comparison,
  ) {
    final pyth = comparison.pythagoreanDelta;
    final chaldean = comparison.chaldeanDelta;
    final pythCore = comparison.candidatePythagoreanCoreOverlaps.isEmpty
        ? 'none'
        : comparison.candidatePythagoreanCoreOverlaps.join(', ');
    final chaldeanCore = comparison.candidateChaldeanCoreOverlaps.isEmpty
        ? 'none'
        : comparison.candidateChaldeanCoreOverlaps.join(', ');
    final selectedLabel = comparison.selectedForProfessionalReview
        ? ' Explicit professional discussion focus is recorded.'
        : '';
    final selectedLabelBn = comparison.selectedForProfessionalReview
        ? ' Professional discussion-এর জন্য স্পষ্ট human focus সংরক্ষিত আছে।'
        : '';
    return NumerologyNameCandidateReview(
      code: 'numerology.name_candidate.${comparison.index + 1}',
      candidateNameLatin: comparison.candidateName,
      comparisonStatus: comparison.status.name,
      selectedForProfessionalReview:
          comparison.selectedForProfessionalReview,
      confidence: AnalysisConfidence.medium,
      pythagoreanBaselineReduced: pyth.baselineReduced,
      pythagoreanCandidateReduced: pyth.candidateReduced,
      pythagoreanCompoundDelta: pyth.compoundDelta,
      chaldeanBaselineReduced: chaldean.baselineReduced,
      chaldeanCandidateReduced: chaldean.candidateReduced,
      chaldeanCompoundDelta: chaldean.compoundDelta,
      flags: comparison.flags,
      narrativeEn:
          '${comparison.candidateName}: Pythagorean ${pyth.baselineCompound}→${pyth.candidateCompound} (reduced ${pyth.baselineReduced}→${pyth.candidateReduced}, Δ ${_signed(pyth.compoundDelta)}); Chaldean ${chaldean.baselineCompound}→${chaldean.candidateCompound} (reduced ${chaldean.baselineReduced}→${chaldean.candidateReduced}, Δ ${_signed(chaldean.compoundDelta)}). Candidate arithmetic overlaps: Pythagorean [$pythCore], Chaldean [$chaldeanCore]. These overlaps are descriptive only and are not a favourable/unfavourable score.$selectedLabel',
      narrativeBn:
          '${comparison.candidateName}: Pythagorean ${pyth.baselineCompound}→${pyth.candidateCompound} (reduced ${pyth.baselineReduced}→${pyth.candidateReduced}, Δ ${_signed(pyth.compoundDelta)}); Chaldean ${chaldean.baselineCompound}→${chaldean.candidateCompound} (reduced ${chaldean.baselineReduced}→${chaldean.candidateReduced}, Δ ${_signed(chaldean.compoundDelta)})। Candidate arithmetic overlap: Pythagorean [$pythCore], Chaldean [$chaldeanCore]। এই overlap শুধু বর্ণনামূলক; এটি শুভ/অশুভ score নয়।$selectedLabelBn',
      cautionEn:
          'Comparison status ${comparison.status.name} is arithmetic only. ASTRO LOGIC does not rank this spelling, call it lucky/best, predict outcomes from it, or recommend a legal-name change. A professional must explicitly choose any spelling used for further discussion.',
      cautionBn:
          'Comparison status ${comparison.status.name} শুধু arithmetic। ASTRO LOGIC এই spelling-কে rank করে না, lucky/best বলে না, এর থেকে নিশ্চিত ফল ভবিষ্যদ্বাণী করে না বা সরকারি নাম বদলের পরামর্শ দেয় না। পরবর্তী আলোচনায় কোনো spelling ব্যবহার করলে পেশাদারকে স্পষ্টভাবে সেটি নির্বাচন করতে হবে।',
      evidence: [
        ChartEvidence(
          ruleId: 'numerology.name.candidate_compare.pythagorean.v1',
          outputPath:
              r'$.nameCandidateComparisons[' + comparison.index.toString() + r'].pythagoreanDelta',
          kind: EvidenceKind.strength,
          descriptionEn:
              'Baseline ${comparison.baselineName} versus ${comparison.candidateName}: Pythagorean compound ${pyth.baselineCompound}→${pyth.candidateCompound}, reduced ${pyth.baselineReduced}→${pyth.candidateReduced}.',
          descriptionBn:
              'Baseline ${comparison.baselineName} বনাম ${comparison.candidateName}: Pythagorean compound ${pyth.baselineCompound}→${pyth.candidateCompound}, reduced ${pyth.baselineReduced}→${pyth.candidateReduced}।',
        ),
        ChartEvidence(
          ruleId: 'numerology.name.candidate_compare.chaldean.v1',
          outputPath:
              r'$.nameCandidateComparisons[' + comparison.index.toString() + r'].chaldeanDelta',
          kind: EvidenceKind.strength,
          descriptionEn:
              'Baseline ${comparison.baselineName} versus ${comparison.candidateName}: Chaldean compound ${chaldean.baselineCompound}→${chaldean.candidateCompound}, reduced ${chaldean.baselineReduced}→${chaldean.candidateReduced}.',
          descriptionBn:
              'Baseline ${comparison.baselineName} বনাম ${comparison.candidateName}: Chaldean compound ${chaldean.baselineCompound}→${chaldean.candidateCompound}, reduced ${chaldean.baselineReduced}→${chaldean.candidateReduced}।',
        ),
      ],
    );
  }

  static String _signed(int value) => value > 0 ? '+$value' : '$value';

  static ChartFinding _meaningFinding({
    required String code,
    required String labelEn,
    required String labelBn,
    required int value,
    required LifeArea area,
    required ChartEvidence evidence,
  }) {
    final meaning = _meaning(value);
    return ChartFinding(
      code: code,
      area: area,
      polarity: AnalysisPolarity.mixed,
      confidence: AnalysisConfidence.low,
      titleEn: '$labelEn: $value — ${meaning.titleEn}',
      titleBn: '$labelBn: $value — ${meaning.titleBn}',
      narrativeEn:
          'Traditional strengths: ${meaning.strengthEn}. Review tendency: ${meaning.challengeEn}. This is a symbolic profile, not a fixed personality or guaranteed outcome.',
      narrativeBn:
          'প্রচলিত শক্তি: ${meaning.strengthBn}। পর্যালোচনার প্রবণতা: ${meaning.challengeBn}। এটি প্রতীকী প্রোফাইল—স্থির ব্যক্তিত্ব বা নিশ্চিত ফল নয়।',
      evidence: [evidence],
    );
  }

  static ChartFinding _systemComparisonFinding(
    NumerologyProfile profile,
    ChartEvidence pythagoreanEvidence,
    ChartEvidence chaldeanEvidence,
  ) {
    final pythagorean = profile.pythagorean.expression.reduced;
    final chaldean = profile.chaldean.expression.reduced;
    final same = pythagorean == chaldean;
    return ChartFinding(
      code: 'numerology.name.dual_system_comparison',
      area: LifeArea.communication,
      polarity: AnalysisPolarity.mixed,
      confidence: AnalysisConfidence.medium,
      titleEn: 'Dual-system name comparison',
      titleBn: 'দুই-পদ্ধতির নামসংখ্যা তুলনা',
      narrativeEn: same
          ? 'Pythagorean and Chaldean profiles both reduce to $pythagorean. This arithmetic agreement does not, by itself, justify a favourable judgment or a name change.'
          : 'Pythagorean reduces to $pythagorean and Chaldean to $chaldean. Different mappings commonly produce different totals; this is not automatically a conflict and does not justify changing the spelling.',
      narrativeBn: same
          ? 'পাইথাগোরিয়ান ও চ্যালডিয়ান উভয় ফল $pythagorean। শুধু এই গাণিতিক মিল শুভ সিদ্ধান্ত বা নাম পরিবর্তনের যথেষ্ট কারণ নয়।'
          : 'পাইথাগোরিয়ান ফল $pythagorean এবং চ্যালডিয়ান ফল $chaldean। আলাদা mapping-এ আলাদা সংখ্যা হওয়া স্বাভাবিক; এটি নিজে থেকে সংঘাত নয় এবং বানান বদলের কারণও নয়।',
      evidence: [pythagoreanEvidence, chaldeanEvidence],
    );
  }

  static ChartEvidence _numberEvidence({
    required String ruleId,
    required String outputPath,
    required String labelEn,
    required String labelBn,
    required NumerologyValue value,
  }) =>
      ChartEvidence(
        ruleId: ruleId,
        outputPath: outputPath,
        kind: EvidenceKind.strength,
        descriptionEn:
            '$labelEn compound ${value.compound}, reduced ${value.reduced}${value.masterNumberPreserved ? ', master number preserved' : ''}.',
        descriptionBn:
            '$labelBn যৌগিক সংখ্যা ${value.compound}, হ্রাসকৃত সংখ্যা ${value.reduced}${value.masterNumberPreserved ? ', মাস্টার নম্বর সংরক্ষিত' : ''}।',
      );

  static _NumberMeaning _meaning(int value) =>
      _meanings[value] ?? _meanings[_reduceMaster(value)]!;

  static int _reduceMaster(int value) {
    var current = value;
    while (current > 9) {
      current = current
          .toString()
          .codeUnits
          .fold(0, (sum, digit) => sum + digit - 48);
    }
    return current;
  }

  static const _meanings = <int, _NumberMeaning>{
    0: _NumberMeaning('Unavailable under the frozen letter policy', 'নির্ধারিত letter policy-তে unavailable', 'no symbolic interpretation is produced when the selected vowel/consonant subtotal is zero', 'নির্বাচিত vowel/consonant subtotal শূন্য হলে কোনো প্রতীকী ব্যাখ্যা তৈরি করা হয় না', 'do not invent a substitute number or silently reclassify Y', 'বিকল্প সংখ্যা উদ্ভাবন বা Y-কে নীরবে পুনঃশ্রেণিবদ্ধ করবেন না', 'no cycle theme', 'কোনো cycle theme নয়', 'Keep the exact spelling visible and review the selected letter policy before interpretation.', 'সঠিক spelling দৃশ্যমান রাখুন এবং ব্যাখ্যার আগে নির্বাচিত letter policy যাচাই করুন।'),
    1: _NumberMeaning('Initiative', 'উদ্যোগ', 'independence, direction and starting capacity', 'স্বাধীনতা, দিশা ও শুরু করার ক্ষমতা', 'impatience, isolation or excessive control', 'অধৈর্য, একাকিত্ব বা অতিরিক্ত নিয়ন্ত্রণ', 'new beginnings and clear direction', 'নতুন শুরু ও স্পষ্ট দিশা', 'Write one 90-day priority and complete one measurable first step each week.', 'একটি ৯০ দিনের অগ্রাধিকার লিখুন এবং প্রতি সপ্তাহে একটি পরিমাপযোগ্য প্রথম পদক্ষেপ সম্পন্ন করুন।'),
    2: _NumberMeaning('Cooperation', 'সহযোগিতা', 'diplomacy, sensitivity and partnership', 'কূটনীতি, সংবেদনশীলতা ও অংশীদারিত্ব', 'indecision, dependency or over-sensitivity', 'সিদ্ধান্তহীনতা, নির্ভরতা বা অতিসংবেদনশীলতা', 'patience, partnership and careful development', 'ধৈর্য, অংশীদারিত্ব ও সতর্ক বিকাশ', 'Schedule a weekly relationship check-in and pause before emotionally charged decisions.', 'সাপ্তাহিক সম্পর্ক-পর্যালোচনা রাখুন এবং আবেগপূর্ণ সিদ্ধান্তের আগে বিরতি নিন।'),
    3: _NumberMeaning('Expression', 'প্রকাশ', 'communication, creativity and social warmth', 'যোগাযোগ, সৃজনশীলতা ও সামাজিক উষ্ণতা', 'scattered effort, exaggeration or unfinished work', 'বিক্ষিপ্ত প্রচেষ্টা, অতিরঞ্জন বা অসমাপ্ত কাজ', 'creative expression and communication', 'সৃজনশীল প্রকাশ ও যোগাযোগ', 'Keep a three-times-weekly writing, speaking or creative practice and finish one piece monthly.', 'সপ্তাহে তিনবার লেখা, বলা বা সৃজনশীল অনুশীলন করুন এবং মাসে অন্তত একটি কাজ শেষ করুন।'),
    4: _NumberMeaning('Structure', 'কাঠামো', 'discipline, reliability and practical building', 'শৃঙ্খলা, নির্ভরযোগ্যতা ও বাস্তব নির্মাণ', 'rigidity, overwork or resistance to change', 'অনমনীয়তা, অতিরিক্ত কাজ বা পরিবর্তনে বাধা', 'foundation, systems and steady work', 'ভিত্তি, ব্যবস্থা ও ধারাবাহিক কাজ', 'Use a fixed weekly routine and review budget, workload and unfinished tasks every seven days.', 'নির্দিষ্ট সাপ্তাহিক রুটিন ব্যবহার করুন এবং প্রতি সাত দিনে বাজেট, কাজের চাপ ও অসমাপ্ত কাজ পর্যালোচনা করুন।'),
    5: _NumberMeaning('Change', 'পরিবর্তন', 'adaptability, curiosity and movement', 'অভিযোজন, কৌতূহল ও গতিশীলতা', 'restlessness, excess or risky impulsiveness', 'অস্থিরতা, অতিরিক্ততা বা ঝুঁকিপূর্ণ তাড়াহুড়ো', 'change, experimentation and freedom with limits', 'পরিবর্তন, পরীক্ষা ও সীমাসহ স্বাধীনতা', 'Run one small controlled experiment at a time with written time, money and risk limits.', 'লিখিত সময়, অর্থ ও ঝুঁকির সীমা রেখে একবারে একটি ছোট নিয়ন্ত্রিত পরীক্ষা করুন।'),
    6: _NumberMeaning('Responsibility', 'দায়িত্ব', 'care, service and commitment', 'যত্ন, সেবা ও অঙ্গীকার', 'over-responsibility, interference or perfectionism', 'অতিরিক্ত দায় নেওয়া, হস্তক্ষেপ বা নিখুঁততাবাদ', 'family, duty and balanced care', 'পরিবার, কর্তব্য ও ভারসাম্যপূর্ণ যত্ন', 'Make a weekly responsibility list with one clear boundary and one protected rest period.', 'সাপ্তাহিক দায়িত্বের তালিকায় একটি স্পষ্ট সীমা ও একটি সংরক্ষিত বিশ্রামের সময় রাখুন।'),
    7: _NumberMeaning('Inquiry', 'অনুসন্ধান', 'analysis, study and inner reflection', 'বিশ্লেষণ, অধ্যয়ন ও অন্তর্দর্শন', 'withdrawal, suspicion or analysis paralysis', 'বিচ্ছিন্নতা, সন্দেহ বা অতিবিশ্লেষণে স্থবিরতা', 'study, verification and reflection', 'অধ্যয়ন, যাচাই ও আত্মপর্যালোচনা', 'Keep a study journal and verify one important assumption with evidence before acting.', 'একটি অধ্যয়ন-ডায়েরি রাখুন এবং কাজের আগে একটি গুরুত্বপূর্ণ অনুমান প্রমাণ দিয়ে যাচাই করুন।'),
    8: _NumberMeaning('Stewardship', 'পরিচালনা', 'organization, authority and material accountability', 'সংগঠন, কর্তৃত্ব ও বস্তুগত জবাবদিহি', 'control struggles, status pressure or financial overreach', 'নিয়ন্ত্রণের সংঘাত, মর্যাদার চাপ বা আর্থিক অতিরিক্ত ঝুঁকি', 'resources, accountability and measured ambition', 'সম্পদ, জবাবদিহি ও পরিমিত উচ্চাকাঙ্ক্ষা', 'Review cash flow and obligations monthly; require written limits before any major financial commitment.', 'মাসে একবার নগদ প্রবাহ ও দায় পর্যালোচনা করুন; বড় আর্থিক অঙ্গীকারের আগে লিখিত সীমা নির্ধারণ করুন।'),
    9: _NumberMeaning('Completion', 'সমাপ্তি', 'compassion, perspective and completion', 'সহমর্মিতা, বিস্তৃত দৃষ্টি ও সমাপ্তি', 'over-giving, emotional burden or difficulty releasing', 'অতিরিক্ত দান, আবেগের ভার বা ছাড়তে অসুবিধা', 'completion, release and service', 'সমাপ্তি, ছেড়ে দেওয়া ও সেবা', 'List unfinished commitments, close one each week and avoid replacing them immediately with new obligations.', 'অসমাপ্ত অঙ্গীকার লিখুন, প্রতি সপ্তাহে একটি শেষ করুন এবং সঙ্গে সঙ্গে নতুন দায় দিয়ে সেটি প্রতিস্থাপন করবেন না।'),
    11: _NumberMeaning('Inspired sensitivity', 'প্রেরণাময় সংবেদনশীলতা', 'intuition, inspiration and heightened perception', 'অন্তর্দৃষ্টি, প্রেরণা ও সূক্ষ্ম উপলব্ধি', 'nervous strain, idealization or inconsistent grounding', 'স্নায়বিক চাপ, অতিআদর্শ বা বাস্তব ভিত্তির অভাব', 'inspiration supported by grounding', 'বাস্তব ভিত্তিসহ প্রেরণা', 'Record ideas before acting, protect sleep and test one inspiration through a small practical step.', 'কাজের আগে ভাবনা লিখুন, ঘুম রক্ষা করুন এবং একটি ছোট বাস্তব পদক্ষেপে একটি প্রেরণা পরীক্ষা করুন।'),
    22: _NumberMeaning('Practical vision', 'বাস্তবায়নযোগ্য দৃষ্টি', 'large-scale planning, building and coordination', 'বড় পরিকল্পনা, নির্মাণ ও সমন্বয়', 'overload, unrealistic scale or fear of responsibility', 'অতিরিক্ত চাপ, অবাস্তব পরিসর বা দায়ের ভয়', 'turning vision into staged delivery', 'দৃষ্টিকে ধাপে ধাপে বাস্তব করা', 'Break one large goal into milestones with owner, budget, deadline and monthly review.', 'একটি বড় লক্ষ্যকে দায়িত্বপ্রাপ্ত ব্যক্তি, বাজেট, সময়সীমা ও মাসিক পর্যালোচনাসহ ধাপে ভাগ করুন।'),
    33: _NumberMeaning('Responsible service', 'দায়িত্বশীল সেবা', 'compassionate teaching, care and upliftment', 'সহমর্মী শিক্ষা, যত্ন ও উন্নয়ন', 'self-sacrifice, rescuing or burnout', 'আত্মত্যাগ, অতিরিক্ত উদ্ধারপ্রবণতা বা অবসাদ', 'service balanced with boundaries', 'সীমাসহ সেবা', 'Choose one service commitment, define its boundary and schedule non-negotiable recovery time.', 'একটি সেবামূলক অঙ্গীকার বেছে নিন, তার সীমা নির্ধারণ করুন এবং অপরিবর্তনীয় বিশ্রামের সময় রাখুন।'),
  };
}

class _NumberMeaning {
  const _NumberMeaning(
    this.titleEn,
    this.titleBn,
    this.strengthEn,
    this.strengthBn,
    this.challengeEn,
    this.challengeBn,
    this.yearFocusEn,
    this.yearFocusBn,
    this.actionEn,
    this.actionBn,
  );

  final String titleEn;
  final String titleBn;
  final String strengthEn;
  final String strengthBn;
  final String challengeEn;
  final String challengeBn;
  final String yearFocusEn;
  final String yearFocusBn;
  final String actionEn;
  final String actionBn;
}
