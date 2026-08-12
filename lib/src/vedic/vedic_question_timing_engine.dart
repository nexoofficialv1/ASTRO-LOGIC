import '../models/consultation.dart';
import '../models/kundli_analysis.dart';
import '../models/vedic_question_timing.dart';
import '../models/vedic_timing_synthesis.dart';
import '../models/vedic_transit_analysis.dart';
import 'vedic_ashtakavarga_kaksha_engine.dart';

/// Question-specific timing review built only from already-governed layers.
///
/// v3 does not promise events. It narrows the consultation topic to a small,
/// versioned set of whole-sign houses, measures whether the active MD/AD/PD
/// lords actually activate those areas, and only treats a transit as topical
/// when that transiting planet occupies one of the target houses from Lagna.
class VedicQuestionTimingEngine {
  const VedicQuestionTimingEngine();

  String get engineId => 'astro-logic-vedic-question-timing';

  String get engineVersion => '3.0.0';

  String get schemaVersion => 'vedic-question-timing-v3';

  VedicQuestionTiming analyze({
    required VedicQuestionTopic topic,
    required KundliAnalysis kundliAnalysis,
    required VedicTimingSynthesis timingSynthesis,
    required VedicTransitAnalysis transitAnalysis,
  }) {
    _validateInputs(
      kundliAnalysis: kundliAnalysis,
      timingSynthesis: timingSynthesis,
      transitAnalysis: transitAnalysis,
    );

    final profile = _profiles[topic]!;
    final natalFindings = _targetNatalFindings(
      kundliAnalysis.findings,
      profile.targetHouses,
    );
    final natalPolarity = _aggregatePolarities(
      natalFindings.map((finding) => finding.polarity),
    );

    final dasha = _topicDasha(
      timingSynthesis.activeDasha,
      kundliAnalysis.dashaActivationProfiles,
      profile.targetLifeAreas,
    );

    final transit = _topicTransit(
      transitAnalysis,
      profile.targetHouses,
    );
    final ashtakavarga = _topicAshtakavarga(
      kundliAnalysis.ashtakavargaProfile,
      transitAnalysis,
      profile.targetHouses,
    );
    final comparison = _compare(
      natal: natalPolarity,
      dasha: dasha.polarity,
      transit: transit.polarity,
      ashtakavarga: ashtakavarga.polarity,
      hasDashaActivation: dasha.hasTopicActivation,
      hasDirectionalTransit: transit.hasDirectionalSignal,
      hasDirectionalAshtakavarga: ashtakavarga.hasDirectionalSignal,
    );

    final targetHouses = profile.targetHouses.join(', ');
    final targetAreas = profile.targetLifeAreas
        .map((area) => area.name)
        .join(', ');
    final targetedTransitEn = transit.planets.isEmpty
        ? 'No enabled directional transit planet is occupying a target house from Lagna on this date.'
        : 'Topical transit planets in target houses: ${transit.planets.join(', ')}.';
    final targetedTransitBn = transit.planets.isEmpty
        ? 'এই তারিখে কোনো enabled directional transit planet লগ্ন থেকে target house-এ নেই।'
        : 'Target house-এ topical transit planet: ${transit.planets.join(', ')}।';
    final dashaEn = dasha.hasTopicActivation
        ? 'The active MD/AD/PD chain contributes a topic-weighted score of ${dasha.score} (${dasha.polarity.name}).'
        : 'The active MD/AD/PD chain does not repeat an enabled life-area trigger for this topic.';
    final dashaBn = dasha.hasTopicActivation
        ? 'সক্রিয় MD/AD/PD chain-এর topic-weighted score ${dasha.score} (${dasha.polarity.name})।'
        : 'সক্রিয় MD/AD/PD chain-এ এই topic-এর enabled life-area trigger পুনরাবৃত্ত হয়নি।';
    final ashtakavargaEn = ashtakavarga.checks.isEmpty
        ? 'No governed Ashtakavarga transit check is available in a target house on this date.'
        : 'Ashtakavarga reviewed ${ashtakavarga.checks.length} target-house transit(s) with BAV, SAV and Kaksha refinement; aggregate direction is ${ashtakavarga.polarity.name}.';
    final ashtakavargaBn = ashtakavarga.checks.isEmpty
        ? 'এই তারিখে target house-এ governed Ashtakavarga transit check পাওয়া যায়নি।'
        : 'Ashtakavarga ${ashtakavarga.checks.length}টি target-house transit BAV, SAV ও Kaksha refinement দিয়ে review করেছে; aggregate direction ${ashtakavarga.polarity.name}।';

    return VedicQuestionTiming(
      asOfUtc: timingSynthesis.asOfUtc,
      engineId: engineId,
      engineVersion: engineVersion,
      schemaVersion: schemaVersion,
      topic: topic,
      targetHouses: List.unmodifiable(profile.targetHouses),
      targetLifeAreas: List.unmodifiable(profile.targetLifeAreas),
      natalPolarity: natalPolarity,
      dashaPolarity: dasha.polarity,
      transitPolarity: transit.polarity,
      polarity: comparison.polarity,
      confidence: comparison.confidence,
      confirmationCode: comparison.code,
      dashaTopicScore: dasha.score,
      targetedTransitPlanets: List.unmodifiable(transit.planets),
      ashtakavargaPolarity: ashtakavarga.polarity,
      hasDirectionalAshtakavarga: ashtakavarga.hasDirectionalSignal,
      ashtakavargaTransitPlanets:
          List.unmodifiable(ashtakavarga.directionalPlanets),
      ashtakavargaTransitChecks: List.unmodifiable(ashtakavarga.checks),
      titleEn: '${profile.titleEn} timing review — ${comparison.titleEn}',
      titleBn: '${profile.titleBn} timing review — ${comparison.titleBn}',
      narrativeEn:
          '${profile.titleEn} uses governed whole-sign target houses $targetHouses and life areas $targetAreas. The natal target-house baseline is ${natalPolarity.name}. $dashaEn $targetedTransitEn $ashtakavargaEn ${comparison.explanationEn} This identifies a review window only; it is not a promise that the requested event will occur.',
      narrativeBn:
          '${profile.titleBn}-এর জন্য governed whole-sign target house $targetHouses এবং life area $targetAreas ব্যবহার হয়েছে। Natal target-house baseline ${natalPolarity.name}। $dashaBn $targetedTransitBn $ashtakavargaBn ${comparison.explanationBn} এটি শুধু review window শনাক্ত করে; চাওয়া ঘটনাটি ঘটবেই—এমন প্রতিশ্রুতি নয়।',
      evidence: [
        ChartEvidence(
          ruleId: 'vedic.question_timing.${topic.name}.house_profile.v1',
          outputPath: r'$.ascendant.signIndex',
          kind: EvidenceKind.lordship,
          descriptionEn:
              '${profile.titleEn} is reviewed through versioned whole-sign houses $targetHouses.',
          descriptionBn:
              '${profile.titleBn} versioned whole-sign $targetHouses নম্বর ভাব দিয়ে review করা হয়েছে।',
        ),
        for (final finding in natalFindings) ...finding.evidence,
        ...dasha.evidence,
        ...transit.evidence,
        ...ashtakavarga.evidence,
      ],
      warningsEn: const [
        'Question-specific timing v3 is a convergence model, not an exact-event prediction engine.',
        'Ashtakavarga transit confirmation uses unreduced planet-specific BAV plus raw SAV context and now applies the governed Kaksha micro-zone as a refinement gate; stored Trikona/Ekadhipatya reduction and Pinda profiles are still not used for timing, and broader exact-degree trigger families remain separate work.',
        'High confidence remains intentionally disabled until additional governed timing families such as divisional timing and exact-degree triggers are implemented.',
        'A transit is topical here only when the same planet has an enabled directional Moon-gochara finding and occupies a versioned target house from Lagna.',
        'Source-bounded Rahu transit polarity from transit v3 may participate; Ketu remains excluded and Mixed transit findings remain non-directional.',
        'Do not use this output alone for medical, legal, financial, mortality or other high-stakes decisions.',
      ],
      warningsBn: const [
        'Question-specific timing v3 একটি convergence model; এটি exact-event prediction engine নয়।',
        'Unreduced planet-specific BAV ও raw SAV context-এর সঙ্গে এখন governed Kaksha micro-zone refinement ব্যবহার হয়; সংরক্ষিত Trikona/Ekadhipatya reduction ও Pinda profile এখনো timing-এ ব্যবহার করা হয় না, এবং broader exact-degree trigger আলাদা pending work।',
        'Divisional timing ও exact-degree trigger-এর মতো অতিরিক্ত governed timing family যোগ না হওয়া পর্যন্ত High confidence ইচ্ছাকৃতভাবে disabled।',
        'এখানে transit তখনই topical ধরা হয় যখন একই planet-এর enabled directional Moon-gochara finding থাকে এবং সেটি লগ্ন থেকে versioned target house-এ অবস্থান করে।',
        'Transit v3-এর source-bounded Rahu polarity অংশ নিতে পারে; Ketu excluded থাকে এবং Mixed transit finding non-directional থাকে।',
        'চিকিৎসা, আইন, অর্থ, মৃত্যু বা অন্য high-stakes সিদ্ধান্তে শুধু এই output ব্যবহার করা যাবে না।',
      ],
      professionalReviewRequired: true,
    );
  }

  VedicQuestionTopic? topicForConsultationCategory(
    ConsultationCategory category,
  ) {
    return switch (category) {
      ConsultationCategory.career => VedicQuestionTopic.career,
      ConsultationCategory.business => VedicQuestionTopic.business,
      ConsultationCategory.marriage => VedicQuestionTopic.marriage,
      ConsultationCategory.finance => VedicQuestionTopic.finance,
      ConsultationCategory.education => VedicQuestionTopic.education,
      ConsultationCategory.property => VedicQuestionTopic.property,
      ConsultationCategory.children => VedicQuestionTopic.children,
      ConsultationCategory.travelRelocation =>
        VedicQuestionTopic.travelRelocation,
      ConsultationCategory.general || ConsultationCategory.health => null,
    };
  }

  List<ChartFinding> _targetNatalFindings(
    List<ChartFinding> findings,
    List<int> targetHouses,
  ) {
    final byHouse = <int, ChartFinding>{};
    for (final finding in findings) {
      for (final house in targetHouses) {
        if (finding.code == 'vedic.life_area.house_$house.synthesis') {
          byHouse[house] = finding;
        }
      }
    }
    if (byHouse.length != targetHouses.length) {
      final missing = targetHouses.where((house) => !byHouse.containsKey(house));
      throw StateError(
        'Question timing requires detailed house synthesis for houses '
        '${missing.join(', ')}',
      );
    }
    return [for (final house in targetHouses) byHouse[house]!];
  }

  _TopicDasha _topicDasha(
    VedicActiveDashaChain active,
    List<DashaActivationProfile> profiles,
    List<LifeArea> targetAreas,
  ) {
    final byLord = <String, DashaActivationProfile>{
      for (final profile in profiles) profile.lord: profile,
    };
    final levels = <(String, int, String)>[
      (active.mahadashaLord, 3, 'mahadasha'),
      (active.antardashaLord, 2, 'antardasha'),
      (active.pratyantardashaLord, 1, 'pratyantardasha'),
    ];
    var score = 0;
    var positive = false;
    var negative = false;
    var activations = 0;
    final evidence = <ChartEvidence>[];

    for (final (lord, weight, level) in levels) {
      final profile = byLord[lord];
      if (profile == null) {
        throw StateError('Missing Dasha activation profile for $lord');
      }
      final matchedAreas = profile.lifeAreas
          .where(targetAreas.contains)
          .toList(growable: false);
      if (matchedAreas.isEmpty) continue;
      activations += 1;
      final contribution = profile.score * weight;
      score += contribution;
      positive = positive || contribution > 0;
      negative = negative || contribution < 0;
      evidence.add(
        ChartEvidence(
          ruleId: 'vedic.question_timing.dasha.$level.$lord.v1',
          outputPath: 'analysis.dashaActivationProfiles.$lord',
          kind: EvidenceKind.dasha,
          descriptionEn:
              '$lord $level activates ${matchedAreas.map((area) => area.name).join(', ')} with score ${profile.score} × weight $weight = $contribution.',
          descriptionBn:
              '$lord $level ${matchedAreas.map((area) => area.name).join(', ')} সক্রিয় করছে; score ${profile.score} × weight $weight = $contribution।',
        ),
      );
    }

    final hasTopicActivation = activations > 0;
    final polarity = !hasTopicActivation || (positive && negative)
        ? AnalysisPolarity.mixed
        : score > 0
            ? AnalysisPolarity.supportive
            : score < 0
                ? AnalysisPolarity.challenging
                : AnalysisPolarity.mixed;
    return _TopicDasha(
      score: score,
      polarity: polarity,
      hasTopicActivation: hasTopicActivation,
      evidence: evidence,
    );
  }

  _TopicTransit _topicTransit(
    VedicTransitAnalysis analysis,
    List<int> targetHouses,
  ) {
    final positionByPlanet = <String, VedicTransitPosition>{
      for (final position in analysis.positions) position.body: position,
    };
    final directional = <VedicTransitFinding>[];
    for (final finding in analysis.findings) {
      if (finding.polarity == AnalysisPolarity.mixed) continue;
      final position = positionByPlanet[finding.planet];
      if (position == null) continue;
      if (targetHouses.contains(position.houseFromAscendant)) {
        directional.add(finding);
      }
    }
    return _TopicTransit(
      polarity: _aggregatePolarities(
        directional.map((finding) => finding.polarity),
      ),
      hasDirectionalSignal: directional.isNotEmpty,
      planets: directional.map((finding) => finding.planet).toList(),
      evidence: [for (final finding in directional) ...finding.evidence],
    );
  }

  _TopicAshtakavarga _topicAshtakavarga(
    AshtakavargaAnalysisProfile? profile,
    VedicTransitAnalysis analysis,
    List<int> targetHouses,
  ) {
    if (profile == null) {
      return const _TopicAshtakavarga(
        polarity: AnalysisPolarity.mixed,
        hasDirectionalSignal: false,
        directionalPlanets: [],
        checks: [],
        evidence: [],
      );
    }
    if (profile.ruleVersion != 'ashtakavarga-foundation-v1' &&
        profile.ruleVersion != 'ashtakavarga-foundation-v2' &&
        profile.ruleVersion != 'ashtakavarga-foundation-v3') {
      throw StateError('Question timing requires a supported Ashtakavarga foundation');
    }

    final bavByPlanet = <String, BhinnashtakavargaPlanetProfile>{
      for (final value in profile.bhinnashtakavarga) value.planet: value,
    };
    final savBySign = <int, SarvashtakavargaSignProfile>{
      for (final value in profile.sarvashtakavarga) value.signIndex: value,
    };
    const classical = <String>{
      'sun', 'moon', 'mars', 'mercury', 'jupiter', 'venus', 'saturn',
    };

    final checks = <VedicAshtakavargaTransitCheck>[];
    for (final position in analysis.positions) {
      if (!classical.contains(position.body) ||
          !targetHouses.contains(position.houseFromAscendant)) {
        continue;
      }
      final bav = bavByPlanet[position.body];
      final sav = savBySign[position.signIndex];
      if (bav == null || sav == null || bav.signs.length != 12) {
        throw StateError(
          'Ashtakavarga transit confirmation requires complete BAV/SAV data for ${position.body}',
        );
      }
      final bavSign = bav.signs.firstWhere(
        (value) => value.signIndex == position.signIndex,
        orElse: () => throw StateError(
          'Missing ${position.body} BAV sign ${position.signIndex}',
        ),
      );
      final bavPolarity = _bavTransitPolarity(bavSign.positiveMarks);
      final wholeSign = bavPolarity != AnalysisPolarity.mixed &&
              sav.polarity != AnalysisPolarity.mixed &&
              bavPolarity == sav.polarity
          ? bavPolarity
          : AnalysisPolarity.mixed;
      final kaksha = const VedicAshtakavargaKakshaEngine().review(
        transitingPlanet: position.body,
        signIndex: position.signIndex,
        degreeInSign: position.degreeInSign,
        bavSign: bavSign,
      );
      final combined = wholeSign != AnalysisPolarity.mixed &&
              wholeSign == kaksha.polarity
          ? wholeSign
          : AnalysisPolarity.mixed;
      final evidence = <ChartEvidence>[
        ChartEvidence(
          ruleId: 'vedic.ashtakavarga.transit.bav_5_4_3.v1',
          outputPath:
              'analysis.ashtakavargaProfile.bhinnashtakavarga.${position.body}.sign.${position.signIndex}',
          kind: EvidenceKind.ashtakavarga,
          descriptionEn:
              '${position.body} transits sign ${position.signIndex} / house ${position.houseFromAscendant} with ${bavSign.positiveMarks} unreduced positive marks in its own BAV; v1 treats 5-8 as supportive, 4 as mixed and 0-3 as challenging.',
          descriptionBn:
              '${position.body} sign ${position.signIndex} / house ${position.houseFromAscendant}-এ transit করছে; নিজস্ব unreduced BAV-এ ${bavSign.positiveMarks} positive mark। v1-এ 5-8 supportive, 4 mixed এবং 0-3 challenging।',
        ),
        ChartEvidence(
          ruleId: 'vedic.ashtakavarga.transit.sav_context.v1',
          outputPath:
              'analysis.ashtakavargaProfile.sarvashtakavarga.sign.${position.signIndex}',
          kind: EvidenceKind.ashtakavarga,
          descriptionEn:
              'The same transit sign has ${sav.positiveMarks} SAV positive marks (${sav.band}); BAV and SAV must first agree directionally; v3 then requires the active Kaksha micro-zone to agree before the Ashtakavarga family becomes directional.',
          descriptionBn:
              'একই transit sign-এ SAV positive mark ${sav.positiveMarks} (${sav.band}); v3-এ প্রথমে BAV ও SAV একই দিকে থাকতে হবে; তারপর active Kaksha micro-zone-ও একই দিকে হলে Ashtakavarga family directional হবে।',
        ),
      ];
      checks.add(
        VedicAshtakavargaTransitCheck(
          planet: position.body,
          signIndex: position.signIndex,
          houseFromAscendant: position.houseFromAscendant,
          bavPositiveMarks: bavSign.positiveMarks,
          savPositiveMarks: sav.positiveMarks,
          bavPolarity: bavPolarity,
          savPolarity: sav.polarity,
          wholeSignPolarity: wholeSign,
          kaksha: kaksha,
          polarity: combined,
          evidence: List.unmodifiable(<ChartEvidence>[
            ...evidence,
            ...kaksha.evidence,
          ]),
        ),
      );
    }

    final directional = checks
        .where((value) => value.polarity != AnalysisPolarity.mixed)
        .toList(growable: false);
    return _TopicAshtakavarga(
      polarity: _aggregatePolarities(directional.map((value) => value.polarity)),
      hasDirectionalSignal: directional.isNotEmpty,
      directionalPlanets:
          directional.map((value) => value.planet).toList(growable: false),
      checks: List.unmodifiable(checks),
      evidence: [for (final value in checks) ...value.evidence],
    );
  }

  AnalysisPolarity _bavTransitPolarity(int positiveMarks) {
    if (positiveMarks < 0 || positiveMarks > 8) {
      throw StateError('BAV transit positive marks must be between 0 and 8');
    }
    if (positiveMarks >= 5) return AnalysisPolarity.supportive;
    if (positiveMarks == 4) return AnalysisPolarity.mixed;
    return AnalysisPolarity.challenging;
  }

  _QuestionComparison _compare({
    required AnalysisPolarity natal,
    required AnalysisPolarity dasha,
    required AnalysisPolarity transit,
    required AnalysisPolarity ashtakavarga,
    required bool hasDashaActivation,
    required bool hasDirectionalTransit,
    required bool hasDirectionalAshtakavarga,
  }) {
    if (!hasDashaActivation) {
      return const _QuestionComparison(
        code: 'insufficient_dasha_topic_activation',
        polarity: AnalysisPolarity.mixed,
        confidence: AnalysisConfidence.low,
        titleEn: 'insufficient Dasha topic activation',
        titleBn: 'দশায় topic activation অপর্যাপ্ত',
        explanationEn:
            'The active Dasha chain does not activate the enabled topic areas strongly enough to open a directional question-specific window.',
        explanationBn:
            'সক্রিয় দশা chain enabled topic area যথেষ্টভাবে activate করছে না; তাই directional question-specific window খোলা হচ্ছে না।',
      );
    }

    if (hasDirectionalAshtakavarga && ashtakavarga == AnalysisPolarity.mixed) {
      return const _QuestionComparison(
        code: 'ashtakavarga_internal_directional_conflict',
        polarity: AnalysisPolarity.mixed,
        confidence: AnalysisConfidence.low,
        titleEn: 'Ashtakavarga transit conflict',
        titleBn: 'অষ্টকবর্গ transit conflict',
        explanationEn:
            'Multiple target-house Ashtakavarga transit checks point in opposite directions, so the timing result remains Mixed.',
        explanationBn:
            'একাধিক target-house Ashtakavarga transit check বিপরীত দিকে ইঙ্গিত করছে, তাই timing result Mixed থাকে।',
      );
    }

    final timingSignals = <AnalysisPolarity>[
      if (hasDirectionalTransit && transit != AnalysisPolarity.mixed) transit,
      if (hasDirectionalAshtakavarga && ashtakavarga != AnalysisPolarity.mixed)
        ashtakavarga,
    ];
    if (timingSignals.isEmpty) {
      return _QuestionComparison(
        code: 'dasha_topic_review_without_transit_confirmation',
        polarity: dasha,
        confidence: AnalysisConfidence.low,
        titleEn: 'Dasha-led review; transit unconfirmed',
        titleBn: 'দশা-নির্ভর review; গোচর confirmation নেই',
        explanationEn:
            'The Dasha chain activates this topic, but neither enabled Moon-gochara nor governed Ashtakavarga supplies a directional target-house transit confirmation. Natal polarity remains ${natal.name}.',
        explanationBn:
            'দশা chain এই topic activate করছে, কিন্তু enabled Moon-gochara বা governed Ashtakavarga—কোনোটিই directional target-house transit confirmation দিচ্ছে না। Natal polarity ${natal.name}।',
      );
    }
    if (timingSignals.toSet().length > 1) {
      return const _QuestionComparison(
        code: 'moon_gochara_ashtakavarga_conflict',
        polarity: AnalysisPolarity.mixed,
        confidence: AnalysisConfidence.low,
        titleEn: 'Moon-gochara × Ashtakavarga conflict',
        titleBn: 'Moon-gochara × অষ্টকবর্গ conflict',
        explanationEn:
            'The enabled Moon-gochara and Ashtakavarga transit families point in opposite directions, so neither is allowed to override the other.',
        explanationBn:
            'Enabled Moon-gochara ও Ashtakavarga transit family বিপরীত দিকে ইঙ্গিত করছে, তাই কোনো একটি অন্যটিকে override করতে পারে না।',
      );
    }

    final timingDirection = timingSignals.first;
    if (dasha == timingDirection && dasha != AnalysisPolarity.mixed) {
      if (natal != AnalysisPolarity.mixed && natal != dasha) {
        return const _QuestionComparison(
          code: 'timing_layers_agree_natal_conflicts',
          polarity: AnalysisPolarity.mixed,
          confidence: AnalysisConfidence.low,
          titleEn: 'timing agreement with natal conflict',
          titleBn: 'timing মিলেছে, natal conflict আছে',
          explanationEn:
              'Dasha and the enabled transit confirmation family agree, but the natal target-house baseline points the other way. The engine preserves the conflict as Mixed.',
          explanationBn:
              'দশা ও enabled transit confirmation family একমত, কিন্তু natal target-house baseline বিপরীত। তাই engine ফল Mixed রেখেছে।',
        );
      }
      final code = hasDirectionalTransit && hasDirectionalAshtakavarga
          ? (dasha == AnalysisPolarity.supportive
              ? 'supportive_topic_convergence_moon_gochara_ashtakavarga'
              : 'challenging_topic_convergence_moon_gochara_ashtakavarga')
          : hasDirectionalAshtakavarga
              ? (dasha == AnalysisPolarity.supportive
                  ? 'supportive_topic_convergence_ashtakavarga'
                  : 'challenging_topic_convergence_ashtakavarga')
              : (dasha == AnalysisPolarity.supportive
                  ? 'supportive_topic_convergence'
                  : 'challenging_topic_convergence');
      return _QuestionComparison(
        code: code,
        polarity: dasha,
        confidence: AnalysisConfidence.medium,
        titleEn: dasha == AnalysisPolarity.supportive
            ? 'supportive topic convergence'
            : 'challenging topic convergence',
        titleBn: dasha == AnalysisPolarity.supportive
            ? 'topic-এ সহায়ক convergence'
            : 'topic-এ চ্যালেঞ্জিং convergence',
        explanationEn:
            'The active Dasha direction and the enabled target-house timing confirmation agree. The natal baseline is not explicitly opposite, so this receives Medium review confidence; High remains disabled.',
        explanationBn:
            'সক্রিয় দশার দিক ও enabled target-house timing confirmation একই দিকে। Natal baseline স্পষ্টভাবে বিপরীত নয়, তাই Medium review confidence দেওয়া হয়েছে; High এখনো disabled।',
      );
    }

    return const _QuestionComparison(
      code: 'dasha_transit_topic_conflict',
      polarity: AnalysisPolarity.mixed,
      confidence: AnalysisConfidence.low,
      titleEn: 'Dasha × transit-family conflict',
      titleBn: 'দশা × transit-family conflict',
      explanationEn:
          'The active Dasha and the enabled target-house transit confirmation do not point in the same direction, so the question-specific result remains Mixed.',
      explanationBn:
          'সক্রিয় দশা ও enabled target-house transit confirmation একই দিকে নয়; তাই question-specific ফল Mixed রাখা হয়েছে।',
    );
  }

  AnalysisPolarity _aggregatePolarities(Iterable<AnalysisPolarity> values) {
    var supportive = 0;
    var challenging = 0;
    for (final value in values) {
      if (value == AnalysisPolarity.supportive) supportive += 1;
      if (value == AnalysisPolarity.challenging) challenging += 1;
    }
    if (supportive > 0 && challenging == 0) {
      return AnalysisPolarity.supportive;
    }
    if (challenging > 0 && supportive == 0) {
      return AnalysisPolarity.challenging;
    }
    return AnalysisPolarity.mixed;
  }

  void _validateInputs({
    required KundliAnalysis kundliAnalysis,
    required VedicTimingSynthesis timingSynthesis,
    required VedicTransitAnalysis transitAnalysis,
  }) {
    if (!timingSynthesis.asOfUtc.isUtc ||
        !transitAnalysis.asOfUtc.isUtc ||
        timingSynthesis.asOfUtc != transitAnalysis.asOfUtc) {
      throw ArgumentError(
        'Question timing requires timing synthesis and transit analysis for the same explicit UTC instant',
      );
    }
    if (!timingSynthesis.schemaVersion.startsWith('vedic-timing-synthesis-v')) {
      throw ArgumentError.value(
        timingSynthesis.schemaVersion,
        'timingSynthesis.schemaVersion',
      );
    }
    if (!transitAnalysis.schemaVersion.startsWith('vedic-transit-analysis-v')) {
      throw ArgumentError.value(
        transitAnalysis.schemaVersion,
        'transitAnalysis.schemaVersion',
      );
    }
    if (kundliAnalysis.dashaActivationProfiles.isEmpty) {
      throw StateError('Question timing requires Dasha activation profiles');
    }
  }

  static const _profiles = <VedicQuestionTopic, _QuestionProfile>{
    VedicQuestionTopic.career: _QuestionProfile(
      titleEn: 'Career / employment',
      titleBn: 'পেশা / চাকরি',
      targetHouses: [10, 6, 11],
      targetLifeAreas: [LifeArea.career, LifeArea.obstacles, LifeArea.gains],
    ),
    VedicQuestionTopic.business: _QuestionProfile(
      titleEn: 'Business / partnership',
      titleBn: 'ব্যবসা / অংশীদারিত্ব',
      targetHouses: [10, 7, 11, 2],
      targetLifeAreas: [
        LifeArea.career,
        LifeArea.marriage,
        LifeArea.gains,
        LifeArea.finance,
      ],
    ),
    VedicQuestionTopic.marriage: _QuestionProfile(
      titleEn: 'Marriage / partnership',
      titleBn: 'বিবাহ / অংশীদারিত্ব',
      targetHouses: [7, 2, 11],
      targetLifeAreas: [LifeArea.marriage, LifeArea.family, LifeArea.gains],
    ),
    VedicQuestionTopic.finance: _QuestionProfile(
      titleEn: 'Finance / gains',
      titleBn: 'অর্থ / লাভ',
      targetHouses: [2, 11],
      targetLifeAreas: [LifeArea.finance, LifeArea.family, LifeArea.gains],
    ),
    VedicQuestionTopic.education: _QuestionProfile(
      titleEn: 'Education / higher learning',
      titleBn: 'শিক্ষা / উচ্চশিক্ষা',
      targetHouses: [5, 9],
      targetLifeAreas: [LifeArea.education, LifeArea.fortune],
    ),
    VedicQuestionTopic.property: _QuestionProfile(
      titleEn: 'Property / home assets',
      titleBn: 'সম্পত্তি / গৃহ-সম্পদ',
      targetHouses: [4, 2, 11],
      targetLifeAreas: [
        LifeArea.property,
        LifeArea.family,
        LifeArea.finance,
        LifeArea.gains,
      ],
    ),
    VedicQuestionTopic.children: _QuestionProfile(
      titleEn: 'Children / progeny',
      titleBn: 'সন্তান / প্রজন্ম',
      targetHouses: [5, 2, 11],
      targetLifeAreas: [LifeArea.children, LifeArea.family, LifeArea.gains],
    ),
    VedicQuestionTopic.travelRelocation: _QuestionProfile(
      titleEn: 'Travel / relocation',
      titleBn: 'ভ্রমণ / স্থানান্তর',
      targetHouses: [12, 4],
      targetLifeAreas: [LifeArea.expenses, LifeArea.property, LifeArea.family],
    ),
  };
}

class _QuestionProfile {
  const _QuestionProfile({
    required this.titleEn,
    required this.titleBn,
    required this.targetHouses,
    required this.targetLifeAreas,
  });

  final String titleEn;
  final String titleBn;
  final List<int> targetHouses;
  final List<LifeArea> targetLifeAreas;
}

class _TopicDasha {
  const _TopicDasha({
    required this.score,
    required this.polarity,
    required this.hasTopicActivation,
    required this.evidence,
  });

  final int score;
  final AnalysisPolarity polarity;
  final bool hasTopicActivation;
  final List<ChartEvidence> evidence;
}

class _TopicTransit {
  const _TopicTransit({
    required this.polarity,
    required this.hasDirectionalSignal,
    required this.planets,
    required this.evidence,
  });

  final AnalysisPolarity polarity;
  final bool hasDirectionalSignal;
  final List<String> planets;
  final List<ChartEvidence> evidence;
}

class _TopicAshtakavarga {
  const _TopicAshtakavarga({
    required this.polarity,
    required this.hasDirectionalSignal,
    required this.directionalPlanets,
    required this.checks,
    required this.evidence,
  });

  final AnalysisPolarity polarity;
  final bool hasDirectionalSignal;
  final List<String> directionalPlanets;
  final List<VedicAshtakavargaTransitCheck> checks;
  final List<ChartEvidence> evidence;
}

class _QuestionComparison {
  const _QuestionComparison({
    required this.code,
    required this.polarity,
    required this.confidence,
    required this.titleEn,
    required this.titleBn,
    required this.explanationEn,
    required this.explanationBn,
  });

  final String code;
  final AnalysisPolarity polarity;
  final AnalysisConfidence confidence;
  final String titleEn;
  final String titleBn;
  final String explanationEn;
  final String explanationBn;
}
