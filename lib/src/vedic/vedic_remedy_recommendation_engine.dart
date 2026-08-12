import '../models/kundli_analysis.dart';

/// Conservative, evidence-gated remedy drafting.
///
/// v1 intentionally automates only behavioural safeguards. Planetary mantra,
/// charity, ritual and gemstone prescriptions remain separate governed rule
/// families until their source profile and contraindication policy are enabled.
class VedicRemedyRecommendationEngine {
  const VedicRemedyRecommendationEngine();

  static const String ruleVersion = 'vedic-remedy-recommendation-v1';

  List<AnalysisRemedyCandidate> build(List<ChartFinding> findings) {
    final byArea = <LifeArea, List<ChartFinding>>{};
    for (final finding in findings) {
      if (finding.polarity != AnalysisPolarity.challenging) continue;
      if (!_actionableAreas.contains(finding.area)) continue;
      byArea.putIfAbsent(finding.area, () => <ChartFinding>[]).add(finding);
    }

    final output = <AnalysisRemedyCandidate>[];
    for (final entry in byArea.entries) {
      final independent = <String, ChartEvidence>{};
      for (final finding in entry.value) {
        for (final evidence in finding.evidence) {
          independent.putIfAbsent(evidence.ruleId, () => evidence);
        }
      }
      if (independent.length < 2) continue;

      final copy = _copy[entry.key];
      if (copy == null) continue;
      final evidence = independent.values.take(4).toList(growable: false);
      output.add(
        AnalysisRemedyCandidate(
          code: 'vedic.remedy.behavioral.${entry.key.name}.v1',
          kind: AnalysisRemedyKind.behavioral,
          targetPlanet: null,
          actionEn: copy.actionEn,
          actionBn: copy.actionBn,
          rationaleEn:
              'At least two independent chart rules show a challenging tendency in ${copy.areaEn}. This is a practical risk-management suggestion, not a promise that the action will change an astrological result.',
          rationaleBn:
              '${copy.areaBn} ক্ষেত্রে অন্তত দুটি স্বাধীন chart rule চ্যালেঞ্জিং প্রবণতা দেখাচ্ছে। এটি বাস্তবসম্মত risk-management পরামর্শ; এই কাজ করলে জ্যোতিষীয় ফল নিশ্চিতভাবে বদলাবে—এমন দাবি নয়।',
          cautionEn: copy.cautionEn,
          cautionBn: copy.cautionBn,
          evidence: evidence,
        ),
      );
    }
    return List.unmodifiable(output);
  }

  static const Set<LifeArea> _actionableAreas = {
    LifeArea.self,
    LifeArea.family,
    LifeArea.communication,
    LifeArea.siblings,
    LifeArea.career,
    LifeArea.finance,
    LifeArea.marriage,
    LifeArea.health,
    LifeArea.obstacles,
    LifeArea.expenses,
    LifeArea.education,
    LifeArea.property,
    LifeArea.children,
    LifeArea.spirituality,
  };

  static const Map<LifeArea, _RemedyCopy> _copy = {
    LifeArea.self: _RemedyCopy(
      areaEn: 'self-direction and personal discipline',
      areaBn: 'আত্মনির্দেশ ও ব্যক্তিগত শৃঙ্খলা',
      actionEn:
          'Use a written routine, realistic priorities and regular self-review; make major choices from verified facts rather than from the chart alone.',
      actionBn:
          'লিখিত রুটিন, বাস্তবসম্মত অগ্রাধিকার ও নিয়মিত self-review ব্যবহার করুন; বড় সিদ্ধান্ত শুধু কুণ্ডলীর উপর নয়, যাচাইকৃত তথ্যের ভিত্তিতে নিন।',
      cautionEn:
          'This is behavioural guidance only and does not replace professional medical, legal, financial or psychological support when needed.',
      cautionBn:
          'এটি কেবল behavioural guidance; প্রয়োজন হলে চিকিৎসা, আইন, অর্থ বা মানসিক-স্বাস্থ্য পেশাদারের সহায়তার বিকল্প নয়।',
    ),
    LifeArea.family: _RemedyCopy(
      areaEn: 'family matters',
      areaBn: 'পারিবারিক বিষয়ে',
      actionEn:
          'Prefer calm discussion, written clarity for shared responsibilities and early mediation when repeated conflict appears.',
      actionBn:
          'শান্ত আলোচনা, যৌথ দায়িত্বে লিখিত স্পষ্টতা এবং বারবার বিরোধ হলে দ্রুত mediation-কে অগ্রাধিকার দিন।',
      cautionEn:
          'Do not use astrology to assign blame, guilt or inevitability to any family member.',
      cautionBn:
          'কোনো পরিবারের সদস্যকে দোষ, অপরাধবোধ বা অনিবার্য ফল আরোপ করতে জ্যোতিষ ব্যবহার করবেন না।',
    ),
    LifeArea.communication: _RemedyCopy(
      areaEn: 'communication',
      areaBn: 'যোগাযোগে',
      actionEn:
          'Slow down important communication, confirm facts in writing and review sensitive messages before sending them.',
      actionBn:
          'গুরুত্বপূর্ণ যোগাযোগে তাড়াহুড়ো কমান, তথ্য লিখিতভাবে নিশ্চিত করুন এবং সংবেদনশীল বার্তা পাঠানোর আগে পুনরায় যাচাই করুন।',
      cautionEn:
          'Treat this as a communication-quality safeguard, not as evidence that misunderstandings are destined to occur.',
      cautionBn:
          'এটিকে যোগাযোগের মান রক্ষার safeguard হিসেবে নিন; ভুল বোঝাবুঝি অনিবার্য—এমন প্রমাণ হিসেবে নয়।',
    ),
    LifeArea.siblings: _RemedyCopy(
      areaEn: 'sibling matters',
      areaBn: 'ভাইবোন-সংক্রান্ত বিষয়ে',
      actionEn:
          'Keep expectations explicit, avoid avoidable comparison and document shared financial or property responsibilities.',
      actionBn:
          'প্রত্যাশা স্পষ্ট রাখুন, অপ্রয়োজনীয় তুলনা এড়ান এবং যৌথ অর্থ বা সম্পত্তির দায়িত্ব লিখিতভাবে রাখুন।',
      cautionEn:
          'The chart does not establish another person’s intent or future behaviour.',
      cautionBn:
          'কুণ্ডলী অন্য ব্যক্তির উদ্দেশ্য বা ভবিষ্যৎ আচরণ প্রমাণ করে না।',
    ),
    LifeArea.career: _RemedyCopy(
      areaEn: 'career',
      areaBn: 'পেশাগত ক্ষেত্রে',
      actionEn:
          'Prioritize skill-building, documented goals, measurable work output and a fallback plan before changing jobs or roles.',
      actionBn:
          'চাকরি বা ভূমিকা বদলের আগে skill-building, লিখিত লক্ষ্য, measurable work output এবং fallback plan-কে অগ্রাধিকার দিন।',
      cautionEn:
          'Do not resign, accept an offer or make an irreversible career decision solely from an astrological recommendation.',
      cautionBn:
          'শুধু জ্যোতিষীয় recommendation দেখে চাকরি ছাড়া, offer গ্রহণ বা অপরিবর্তনীয় career decision নেবেন না।',
    ),
    LifeArea.finance: _RemedyCopy(
      areaEn: 'finance',
      areaBn: 'অর্থনৈতিক ক্ষেত্রে',
      actionEn:
          'Use a written budget, emergency reserve, debt-control plan and independent due diligence before investing or lending.',
      actionBn:
          'বিনিয়োগ বা ঋণ দেওয়ার আগে লিখিত budget, emergency reserve, debt-control plan এবং স্বাধীন due diligence ব্যবহার করুন।',
      cautionEn:
          'Astrology is not investment advice; do not trade, borrow or commit capital solely from this signal.',
      cautionBn:
          'জ্যোতিষ বিনিয়োগ-পরামর্শ নয়; শুধু এই সংকেতের ভিত্তিতে trade, ঋণ বা মূলধন commit করবেন না।',
    ),
    LifeArea.marriage: _RemedyCopy(
      areaEn: 'marriage and partnership',
      areaBn: 'বিবাহ ও অংশীদারিত্বে',
      actionEn:
          'Use direct communication, consent, boundary-setting and timely counselling or mediation for persistent conflict.',
      actionBn:
          'স্থায়ী বিরোধে সরাসরি যোগাযোগ, consent, boundary-setting এবং প্রয়োজনে counselling বা mediation ব্যবহার করুন।',
      cautionEn:
          'Do not infer infidelity, abuse, separation or spouse harm from this remedy trigger.',
      cautionBn:
          'এই remedy trigger থেকে পরকীয়া, নির্যাতন, বিচ্ছেদ বা সঙ্গীর ক্ষতি অনুমান করবেন না।',
    ),
    LifeArea.health: _RemedyCopy(
      areaEn: 'health-related matters',
      areaBn: 'স্বাস্থ্য-সংক্রান্ত ক্ষেত্রে',
      actionEn:
          'Maintain sleep, nutrition, activity and routine check-ups; seek qualified medical assessment for symptoms or persistent concerns.',
      actionBn:
          'ঘুম, পুষ্টি, শারীরিক কার্যকলাপ ও নিয়মিত check-up বজায় রাখুন; উপসর্গ বা স্থায়ী উদ্বেগে যোগ্য চিকিৎসকের পরামর্শ নিন।',
      cautionEn:
          'This is not diagnosis or treatment advice, and no medical care should be delayed because of astrology.',
      cautionBn:
          'এটি রোগনির্ণয় বা চিকিৎসা-পরামর্শ নয়; জ্যোতিষের কারণে কোনো চিকিৎসা বিলম্ব করা যাবে না।',
    ),
    LifeArea.obstacles: _RemedyCopy(
      areaEn: 'obstacles and conflict',
      areaBn: 'বাধা ও বিরোধে',
      actionEn:
          'Break difficult tasks into documented steps, keep contingency time and escalate disputes through appropriate formal channels.',
      actionBn:
          'কঠিন কাজকে লিখিত ছোট ধাপে ভাগ করুন, contingency time রাখুন এবং বিরোধ হলে উপযুক্ত formal channel ব্যবহার করুন।',
      cautionEn:
          'Do not treat normal setbacks as proof of a curse, hostile person or supernatural cause.',
      cautionBn:
          'স্বাভাবিক বাধাকে অভিশাপ, শত্রু ব্যক্তি বা অতিপ্রাকৃত কারণের প্রমাণ হিসেবে ধরবেন না।',
    ),
    LifeArea.expenses: _RemedyCopy(
      areaEn: 'expenses',
      areaBn: 'ব্যয়ে',
      actionEn:
          'Track recurring costs, delay non-essential commitments and set a pre-agreed spending ceiling for large purchases.',
      actionBn:
          'নিয়মিত খরচ track করুন, অপ্রয়োজনীয় commitment পিছিয়ে দিন এবং বড় কেনাকাটায় আগেই spending ceiling ঠিক করুন।',
      cautionEn:
          'This is a budgeting safeguard, not a prediction of unavoidable loss.',
      cautionBn:
          'এটি budgeting safeguard; অনিবার্য ক্ষতির ভবিষ্যদ্বাণী নয়।',
    ),
    LifeArea.education: _RemedyCopy(
      areaEn: 'education',
      areaBn: 'শিক্ষাক্ষেত্রে',
      actionEn:
          'Use a fixed study schedule, active practice, spaced revision and measurable weekly targets.',
      actionBn:
          'নির্দিষ্ট study schedule, active practice, spaced revision এবং measurable weekly target ব্যবহার করুন।',
      cautionEn:
          'Academic performance should be assessed from actual learning evidence, not astrology alone.',
      cautionBn:
          'শিক্ষাগত ফল বাস্তব learning evidence দিয়ে বিচার করতে হবে; শুধু জ্যোতিষ দিয়ে নয়।',
    ),
    LifeArea.property: _RemedyCopy(
      areaEn: 'property',
      areaBn: 'সম্পত্তি-সংক্রান্ত ক্ষেত্রে',
      actionEn:
          'Verify title, documents, costs and legal obligations independently before buying, selling, mortgaging or transferring property.',
      actionBn:
          'সম্পত্তি কেনা, বিক্রি, বন্ধক বা হস্তান্তরের আগে title, document, cost এবং legal obligation স্বাধীনভাবে যাচাই করুন।',
      cautionEn:
          'Astrology is not a substitute for legal due diligence or a qualified property inspection.',
      cautionBn:
          'জ্যোতিষ legal due diligence বা qualified property inspection-এর বিকল্প নয়।',
    ),
    LifeArea.children: _RemedyCopy(
      areaEn: 'children-related matters',
      areaBn: 'সন্তান-সংক্রান্ত ক্ষেত্রে',
      actionEn:
          'Use age-appropriate support, open communication and evidence-based educational or health guidance when concerns arise.',
      actionBn:
          'উদ্বেগ হলে বয়স-উপযোগী সহায়তা, খোলামেলা যোগাযোগ এবং evidence-based শিক্ষা বা স্বাস্থ্য নির্দেশনা ব্যবহার করুন।',
      cautionEn:
          'Do not make deterministic fertility, pregnancy, health or future-success claims from this signal.',
      cautionBn:
          'এই সংকেত থেকে fertility, pregnancy, স্বাস্থ্য বা ভবিষ্যৎ সাফল্য নিয়ে deterministic দাবি করবেন না।',
    ),
    LifeArea.spirituality: _RemedyCopy(
      areaEn: 'spiritual practice',
      areaBn: 'আধ্যাত্মিক অনুশীলনে',
      actionEn:
          'Prefer voluntary, non-harmful reflective practice such as prayer, meditation, service or journaling according to personal belief.',
      actionBn:
          'ব্যক্তিগত বিশ্বাস অনুযায়ী স্বেচ্ছামূলক ও ক্ষতিহীন prayer, meditation, service বা journaling-এর মতো reflective practice বেছে নিন।',
      cautionEn:
          'No costly ritual, coercion or claim of guaranteed supernatural effect is implied.',
      cautionBn:
          'কোনো ব্যয়বহুল ritual, জবরদস্তি বা নিশ্চিত অতিপ্রাকৃত ফলের দাবি এখানে করা হয় না।',
    ),
  };
}

class _RemedyCopy {
  const _RemedyCopy({
    required this.areaEn,
    required this.areaBn,
    required this.actionEn,
    required this.actionBn,
    required this.cautionEn,
    required this.cautionBn,
  });

  final String areaEn;
  final String areaBn;
  final String actionEn;
  final String actionBn;
  final String cautionEn;
  final String cautionBn;
}
