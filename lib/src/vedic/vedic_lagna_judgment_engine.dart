import '../models/calculation_output_snapshot.dart';
import '../models/kundli_analysis.dart';
import '../services/kundli_judgment_engine.dart';
import 'pratyantardasha_interpretation_engine.dart';
import 'vedic_navamsa_interpretation_engine.dart';
import 'vedic_dashamsa_interpretation_engine.dart';
import 'vedic_ashtakavarga_engine.dart';
import 'vedic_shadbala_engine.dart';
import 'vedic_advanced_yoga_dosha_engine.dart';
import 'vedic_rahu_ketu_engine.dart';
import 'vedic_remedy_recommendation_engine.dart';
import 'vedic_gemstone_candidate_engine.dart';

part 'vedic_lagna_judgment_timing_yoga.dart';
part 'vedic_lagna_judgment_house_rules.dart';
part 'vedic_lagna_judgment_support.dart';

/// Versioned Vedic judgment families backed by verified chart fields.
class VedicLagnaJudgmentEngine implements KundliJudgmentEngine {
  const VedicLagnaJudgmentEngine();

  @override
  String get engineId => 'astro-logic-vedic-lagna-judgment';

  @override
  String get engineVersion => '32.0.0';

  @override
  String get analysisSchemaVersion => 'kundli-analysis-v32';

  @override
  Future<KundliAnalysis> analyze(
    CalculationOutputSnapshot calculationOutput,
  ) async {
    if (calculationOutput.outputSchemaVersion != 'vedic-chart-v1' &&
        calculationOutput.outputSchemaVersion != 'vedic-chart-v2' &&
        calculationOutput.outputSchemaVersion != 'vedic-chart-v3' &&
        calculationOutput.outputSchemaVersion != 'vedic-chart-v4' &&
        calculationOutput.outputSchemaVersion != 'vedic-chart-v5' &&
        calculationOutput.outputSchemaVersion != 'vedic-chart-v6' &&
        calculationOutput.outputSchemaVersion != 'vedic-chart-v7' &&
        calculationOutput.outputSchemaVersion != 'vedic-chart-v8' &&
        calculationOutput.outputSchemaVersion != 'vedic-chart-v9' &&
        calculationOutput.outputSchemaVersion != 'vedic-chart-v10') {
      throw ArgumentError(
        'Vedic Lagna judgment requires vedic-chart-v1 through vedic-chart-v10 output',
      );
    }
    final ascendant = _requiredMap(
      calculationOutput.output['ascendant'],
      'ascendant',
    );
    final ascendantSign = _requiredSignIndex(
      ascendant['signIndex'],
      'ascendant.signIndex',
    );
    final planets = _requiredPlanets(calculationOutput.output['planets']);
    for (final body in _planetNamesEn.keys) {
      if (!planets.containsKey(body)) {
        throw StateError('Vedic output is missing required planet $body');
      }
    }
    final lagnaLord = _signLords[ascendantSign];
    if (lagnaLord == null) throw StateError('Lagna lord is unavailable');
    final lord = planets[lagnaLord];
    if (lord == null) {
      throw StateError('Vedic output is missing Lagna lord $lagnaLord');
    }

    final house = ((lord.signIndex - ascendantSign + 12) % 12) + 1;
    final dignity = _dignity(lagnaLord, lord.signIndex);
    final dignityScore = _dignityScore(dignity);
    final houseScore = _placementScore(house);
    final score = dignityScore + houseScore;
    final sameDirection = dignityScore != 0 &&
        houseScore != 0 &&
        dignityScore.sign == houseScore.sign;
    final polarity = _polarity(score);
    final confidence = sameDirection
        ? AnalysisConfidence.high
        : AnalysisConfidence.medium;
    final ascendantNameEn = _signNamesEn[ascendantSign];
    final ascendantNameBn = _signNamesBn[ascendantSign];
    final lordNameEn = _planetNamesEn[lagnaLord]!;
    final lordNameBn = _planetNamesBn[lagnaLord]!;
    final lordSignEn = _signNamesEn[lord.signIndex];
    final lordSignBn = _signNamesBn[lord.signIndex];
    final dignityEn = _dignityEn[dignity]!;
    final dignityBn = _dignityBn[dignity]!;

    final ascendantEvidence = ChartEvidence(
      ruleId: 'vedic.lagna.sign.v1',
      outputPath: r'$.ascendant.signIndex',
      kind: EvidenceKind.placement,
      descriptionEn: 'The sidereal ascendant is $ascendantNameEn.',
      descriptionBn: 'নিরয়ণ লগ্ন $ascendantNameBn।',
    );
    final houseEvidence = ChartEvidence(
      ruleId: 'vedic.lagna_lord.house.v1',
      outputPath: r'$.planets[?(@.body=="' + lagnaLord + r'")].signIndex',
      kind: EvidenceKind.lordship,
      descriptionEn: '$lordNameEn, the ascendant lord, occupies whole-sign house $house.',
      descriptionBn: 'লগ্নেশ $lordNameBn হোল-সাইন পদ্ধতিতে $house নম্বর ভাবে অবস্থান করছে।',
    );
    final dignityEvidence = ChartEvidence(
      ruleId: 'vedic.lagna_lord.dignity.v1',
      outputPath: r'$.planets[?(@.body=="' + lagnaLord + r'")].signIndex',
      kind: EvidenceKind.strength,
      descriptionEn: '$lordNameEn is in $lordSignEn with $dignityEn dignity.',
      descriptionBn: '$lordNameBn $lordSignBn রাশিতে $dignityBn মর্যাদায় রয়েছে।',
    );

    final findings = <ChartFinding>[
      ChartFinding(
        code: 'vedic.lagna.identity.$ascendantSign',
        area: LifeArea.self,
        polarity: AnalysisPolarity.mixed,
        confidence: AnalysisConfidence.medium,
        titleEn: '$ascendantNameEn ascendant',
        titleBn: '$ascendantNameBn লগ্ন',
        narrativeEn:
            'This establishes the whole-sign house frame. It is descriptive and is not, by itself, a favourable or unfavourable judgment.',
        narrativeBn:
            'এটি হোল-সাইন ভাব কাঠামো নির্ধারণ করে। শুধু লগ্নরাশি নিজে থেকে শুভ বা অশুভ সিদ্ধান্ত নয়।',
        evidence: [ascendantEvidence],
      ),
      ChartFinding(
        code: 'vedic.lagna_lord.condition.$lagnaLord',
        area: LifeArea.self,
        polarity: polarity,
        confidence: confidence,
        titleEn: 'Ascendant-lord condition: ${_polarityEn[polarity]}',
        titleBn: 'লগ্নেশের অবস্থা: ${_polarityBn[polarity]}',
        narrativeEn:
            '$lordNameEn is in house $house, in $lordSignEn, with $dignityEn dignity. The combined first-pass score is $score. This indicates a ${_polarityEn[polarity]!.toLowerCase()} tendency for vitality, self-direction and resilience; aspects, combustion, Navamsha agreement and dasha must be reviewed before final judgment.',
        narrativeBn:
            '$lordNameBn $house নম্বর ভাবে, $lordSignBn রাশিতে, $dignityBn মর্যাদায় রয়েছে। প্রথম ধাপের সম্মিলিত স্কোর $score। এটি প্রাণশক্তি, আত্মনির্দেশ ও সহনশীলতায় ${_polarityBn[polarity]} প্রবণতা নির্দেশ করে; চূড়ান্ত সিদ্ধান্তের আগে দৃষ্টি, অস্তাঙ্গতা, নবাংশের সমর্থন ও দশা যাচাই আবশ্যক।',
        evidence: [houseEvidence, dignityEvidence],
      ),
    ];
    final advancedYogaDosha =
        const VedicAdvancedYogaDoshaEngine().build(calculationOutput);
    final rahuKetuFindings =
        const VedicRahuKetuEngine().build(calculationOutput);
    findings
      ..addAll(_buildPanchMahapurushaFindings(ascendantSign, planets))
      ..addAll(_buildGajakesariFindings(ascendantSign, planets))
      ..addAll(_buildRajaDhanaYogaFindings(ascendantSign, planets))
      ..addAll(_buildD1D9AgreementFindings(planets))
      ..addAll(_buildKujaDoshaReview(ascendantSign, planets))
      ..addAll(advancedYogaDosha)
      ..addAll(rahuKetuFindings)
      ..addAll(_buildDetailedHouseSynthesis(ascendantSign, planets))
      ..addAll(_buildHouseFindings(ascendantSign, planets))
      ..addAll(_buildOccupancyFindings(ascendantSign, planets))
      ..addAll(_buildAspectFindings(ascendantSign, planets))
      ..addAll(_buildAspectSynthesisFindings(ascendantSign, planets))
      ..addAll(_buildConjunctionFindings(ascendantSign, planets))
      ..addAll(_buildPlanetConditionFindings(planets))
      ..addAll(_buildFriendshipFindings(planets))
      ..addAll(_buildCompoundFriendshipFindings(planets))
      ..addAll(_buildMoolatrikonaFindings(planets))
      ..addAll(_buildPlanetaryWarFindings(ascendantSign, planets))
      ..addAll(_buildFunctionalRoleFindings(ascendantSign));

    final yogaDoshaSynthesis =
        const VedicAdvancedYogaDoshaEngine().synthesize(findings);
    if (yogaDoshaSynthesis != null) {
      findings.add(yogaDoshaSynthesis);
    }

    final timingWindows = _buildVimshottariTimingWindows(
      ascendantSign,
      planets,
      calculationOutput.output['vimshottari'],
      required: calculationOutput.outputSchemaVersion == 'vedic-chart-v3' ||
          calculationOutput.outputSchemaVersion == 'vedic-chart-v4' ||
          calculationOutput.outputSchemaVersion == 'vedic-chart-v5' ||
              calculationOutput.outputSchemaVersion == 'vedic-chart-v6' ||
              calculationOutput.outputSchemaVersion == 'vedic-chart-v7' ||
              (calculationOutput.outputSchemaVersion == 'vedic-chart-v8' ||
              (calculationOutput.outputSchemaVersion == 'vedic-chart-v9' ||
              calculationOutput.outputSchemaVersion == 'vedic-chart-v10')),
      requirePratyantardasha:
          calculationOutput.outputSchemaVersion == 'vedic-chart-v4' ||
              calculationOutput.outputSchemaVersion == 'vedic-chart-v5' ||
              calculationOutput.outputSchemaVersion == 'vedic-chart-v6' ||
              calculationOutput.outputSchemaVersion == 'vedic-chart-v7' ||
              (calculationOutput.outputSchemaVersion == 'vedic-chart-v8' ||
              (calculationOutput.outputSchemaVersion == 'vedic-chart-v9' ||
              calculationOutput.outputSchemaVersion == 'vedic-chart-v10')),
    );
    final dashaActivationProfiles = _buildDashaActivationProfiles(
      ascendantSign,
      planets,
    );
    final pratyantardashaInterpretations =
        (calculationOutput.outputSchemaVersion == 'vedic-chart-v4' ||
                calculationOutput.outputSchemaVersion == 'vedic-chart-v5' ||
                calculationOutput.outputSchemaVersion == 'vedic-chart-v6' ||
                calculationOutput.outputSchemaVersion == 'vedic-chart-v7' ||
                (calculationOutput.outputSchemaVersion == 'vedic-chart-v8' ||
              (calculationOutput.outputSchemaVersion == 'vedic-chart-v9' ||
              calculationOutput.outputSchemaVersion == 'vedic-chart-v10')))
            ? PratyantardashaInterpretationEngine.build(
                rawVimshottari: calculationOutput.output['vimshottari'],
                profiles: dashaActivationProfiles,
              )
            : const <PratyantardashaInterpretation>[];
    final navamsaHouseInterpretations =
        calculationOutput.outputSchemaVersion == 'vedic-chart-v1'
            ? const <NavamsaHouseInterpretation>[]
            : const VedicNavamsaInterpretationEngine().build(calculationOutput);
    findings.addAll(
      navamsaHouseInterpretations.map(
        (value) => ChartFinding(
          code: value.code,
          area: LifeArea.overall,
          polarity: value.polarity,
          confidence: value.confidence,
          titleEn: value.titleEn,
          titleBn: value.titleBn,
          narrativeEn: value.narrativeEn,
          narrativeBn: value.narrativeBn,
          evidence: value.evidence,
        ),
      ),
    );
    final dashamsaResult = calculationOutput.outputSchemaVersion == 'vedic-chart-v10'
        ? const VedicDashamsaInterpretationEngine().build(calculationOutput)
        : null;
    final dashamsaHouseInterpretations =
        dashamsaResult?.houses ?? const <DashamsaHouseInterpretation>[];
    final dashamsaCareerSynthesis = dashamsaResult?.careerSynthesis;
    findings.addAll(
      dashamsaHouseInterpretations.map(
        (value) => ChartFinding(
          code: value.code,
          area: LifeArea.career,
          polarity: value.polarity,
          confidence: value.confidence,
          titleEn: value.titleEn,
          titleBn: value.titleBn,
          narrativeEn: value.narrativeEn,
          narrativeBn: value.narrativeBn,
          evidence: value.evidence,
        ),
      ),
    );
    if (dashamsaCareerSynthesis != null) {
      findings.add(
        ChartFinding(
          code: dashamsaCareerSynthesis.code,
          area: LifeArea.career,
          polarity: dashamsaCareerSynthesis.polarity,
          confidence: dashamsaCareerSynthesis.confidence,
          titleEn: dashamsaCareerSynthesis.titleEn,
          titleBn: dashamsaCareerSynthesis.titleBn,
          narrativeEn: dashamsaCareerSynthesis.narrativeEn,
          narrativeBn: dashamsaCareerSynthesis.narrativeBn,
          evidence: dashamsaCareerSynthesis.evidence,
        ),
      );
    }
    final shadbalaProfiles = const VedicShadbalaEngine().build(calculationOutput);
    findings.addAll(
      shadbalaProfiles.map(
        (value) => ChartFinding(
          code: value.code,
          area: LifeArea.overall,
          polarity: AnalysisPolarity.mixed,
          confidence: AnalysisConfidence.medium,
          titleEn: '${_planetNamesEn[value.planet]} Shadbala strength',
          titleBn: '${_planetNamesBn[value.planet]} ষড়বল শক্তি',
          narrativeEn: value.narrativeEn,
          narrativeBn: value.narrativeBn,
          evidence: value.evidence,
        ),
      ),
    );
    final ashtakavargaProfile =
        const VedicAshtakavargaEngine().build(calculationOutput);
    findings.addAll(
      ashtakavargaProfile.sarvashtakavarga.map(
        (value) => ChartFinding(
          code: 'vedic.ashtakavarga.house_${value.houseNumber}',
          area: _houseLifeAreas[value.houseNumber - 1],
          polarity: value.polarity,
          confidence: value.confidence,
          titleEn:
              'Ashtakavarga house ${value.houseNumber}: ${value.positiveMarks} positive marks',
          titleBn:
              'অষ্টকবর্গ ভাব ${value.houseNumber}: ${value.positiveMarks} positive mark',
          narrativeEn: value.narrativeEn,
          narrativeBn: value.narrativeBn,
          evidence: value.evidence,
        ),
      ),
    );

    final remedies =
        const VedicRemedyRecommendationEngine().build(findings);
    final gemstoneCandidateReviews = const VedicGemstoneCandidateEngine().build(
      calculationOutput,
      shadbalaProfiles: shadbalaProfiles,
      timingWindows: timingWindows,
    );

    return KundliAnalysis(
      findings: findings,
      timingWindows: timingWindows,
      dashaActivationProfiles: dashaActivationProfiles,
      pratyantardashaInterpretations: pratyantardashaInterpretations,
      navamsaHouseInterpretations: navamsaHouseInterpretations,
      dashamsaHouseInterpretations: dashamsaHouseInterpretations,
      dashamsaCareerSynthesis: dashamsaCareerSynthesis,
      shadbalaProfiles: shadbalaProfiles,
      ashtakavargaProfile: ashtakavargaProfile,
      gemstoneCandidateReviews: gemstoneCandidateReviews,
      remedyCandidates: remedies,
      warningsEn: [
        'Professional astrologer review is mandatory before using this draft.',
        'House occupancy, Parashari full sign aspects, same-sign conjunctions, multi-aspect synthesis and planetary-war proximity review are included. Shadbala foundation v10 publishes governed Sthana, Dig, Nathonnata, Paksha, Tribhaga, Varsha, Masa, Dina, Hora, Ayana, Yuddha, Cheshta, Naisargika and exact-longitude Drik Bala, plus the sixfold total and BPHS 27.32-33 required-strength ratio when all six families are complete. Current vedic-chart-v10 retains the v9 geocentric ecliptic latitude so an isolated same-sign <=1 degree Mars-through-Saturn war can use a versioned northern-latitude victor for the BPHS 27.20 numeric correction. Multi-war clusters, latitude ties, missing solar context and legacy outputs remain gated rather than guessed. The threshold is a strength-sufficiency measure only and is not converted into automatic beneficence or guaranteed events.',
        'Ashtakavarga foundation v3 preserves the seven unreduced planetary BAV tables and 337-point SAV, and carries the audited Trikona-then-Ekadhipatya reduction profile plus post-Shodhana Rashi/Graha/Shodhya Pinda for all seven BAVs. The persisted term is positive mark because classical Bindu/Rekha notation differs across editions. Raw SAV bands remain attached only to the unreduced aggregate; reduced values are a later calculation stage and are not compared with BPHS 72 raw-SAV bands. Question Timing v3 uses the governed unreduced BAV/SAV confirmation profile refined by the active Kaksha micro-zone; reduced/Pinda timing use remains separate work.',
        'Permanent, temporary and compound friendship to the sign dispositor are shown as separate, versioned findings.',
        'Planetary-war proximity remains a professional-review finding. On current vedic-chart-v10 outputs, the Shadbala module may identify a computational victor from persisted geocentric ecliptic latitude solely for the numeric Yuddha correction; this is not converted into a deterministic life-event conclusion.',
        'Panch Mahapurusha formation and Kuja-dosha Lagna screening are visible review profiles; they are not guaranteed life-event or marriage outcomes.',
        'Gajakesari, Raja and Dhana findings record only the enabled D1 formation profile; divisional agreement and complete strength remain incomplete, while the separate Dasha calendar shows activation tendency without promising the yoga result.',
        'D1-D9 dignity agreement, Vargottama and twelve D9 house/lord/full-sign-aspect synthesis records are included for D9-capable outputs; exact Sphuta-Drishti strength, evidence-gated complete Kala and the full six-component Shadbala aggregate/required-strength evaluation are now available, while D10 career calculation plus twelve house/lord/full-sign-aspect records and a D1-tenth-lord × D10-tenth-house structural synthesis are included on vedic-chart-v10 outputs.',
        'Kuja-dosha traditions and cancellation rules differ. The app records the selected profile and possible mitigating evidence without declaring automatic cancellation.',
        'Retrograde motion is shown as an intensified/review condition, never automatically as good or bad.',
        'Combustion uses versioned traditional angular thresholds and indicates possible reduced independent expression, not destruction of a planet.',
        if (timingWindows.isNotEmpty)
          'Vimshottari Mahadasha-Antardasha timing plus 729 chart-specific Pratyantardasha interpretations are included as review-grade activation tendencies. Each interpretation preserves the governed 3:2:1 hierarchy and identifies repeated life areas; it is not a guaranteed event date. Selected-date Dasha × transit confirmation is produced only by the separate timing-synthesis engine.'
        else
          'No event timing is generated because this legacy calculation output has no verified Vimshottari calendar.',
        'Gemstone Candidate v1 is a strengthening-versus-contraindication screen for the seven classical planets. Eligible means professional review only; it never auto-approves a gemstone, weight, metal, finger or wearing ritual. Rahu/Ketu gemstone automation remains outside v1.',
        'Astrological interpretations are possibilities, not guaranteed outcomes.',
      ],
      warningsBn: [
        'এই খসড়া ব্যবহারের আগে পেশাদার জ্যোতিষীর পর্যালোচনা বাধ্যতামূলক।',
        'ভাবস্থিত গ্রহ, পরাশরী পূর্ণ রাশিদৃষ্টি, একই-রাশির সংযোগ, বহু-দৃষ্টির সম্মিলিত বিচার ও গ্রহযুদ্ধের নৈকট্য পর্যালোচনা অন্তর্ভুক্ত। ষড়বল foundation v10-এ governed স্থানবল, দিকবল, নতোন্নত বল, পক্ষবল, ত্রিভাগ বল, বর্ষবল, মাসবল, দিনবল, হোরাবল, অয়নবল, যুদ্ধবল, চেষ্টাবল, নৈসর্গিক বল ও exact-longitude দৃকবল আছে; সব ছয়টি family complete হলে full total এবং BPHS 27.32-33 required-strength ratio-ও প্রকাশ হয়। current vedic-chart-v10 retains geocentric ecliptic latitude সংরক্ষণ করে, তাই একই রাশিতে <=1°-এর isolated মঙ্গল-থেকে-শনি গ্রহযুদ্ধে BPHS 27.20 numeric correction-এর জন্য versioned northern-latitude victor ব্যবহার করা যায়। multi-war, latitude tie, missing solar context ও legacy output অনুমান করা হয় না। এই threshold শুধু strength sufficiency; এটিকে স্বয়ংক্রিয় শুভতা বা নিশ্চিত ঘটনার ফল করা হয় না।',
        'অষ্টকবর্গ foundation v3-এ সূর্য থেকে শনি ও লগ্ন—এই আট reference ব্যবহার করে সাতটি unreduced planetary BAV table, 337-point SAV, audited Trikona→Ekadhipatya reduction এবং reduction-পরবর্তী সাত গ্রহের Rashi/Graha/Shodhya Pinda রাখা হয়। বিভিন্ন classical edition-এ Bindu/Rekha notation উল্টো হওয়ায় persisted term positive mark রাখা হয়েছে। raw SAV comparative band নিশ্চিত ঘটনা নয়; Pinda-ও এই পর্যায়ে timing guarantee নয়।',
        'রাশিপতির সঙ্গে স্থায়ী, তৎকালিক ও পঞ্চধা মৈত্রী আলাদা versioned ফল হিসেবে দেখানো হয়।',
        'গ্রহযুদ্ধের নৈকট্য পেশাদার যাচাইয়ের জন্য দেখানো হয়। current vedic-chart-v10-এ persisted geocentric ecliptic latitude থেকে Shadbala module কেবল numeric যুদ্ধবল correction-এর জন্য computational victor নির্ধারণ করতে পারে; এটিকে নিশ্চিত জীবনঘটনার সিদ্ধান্তে রূপান্তর করা হয় না।',
        'পঞ্চ মহাপুরুষ যোগের গঠন ও কুজদোষের লগ্ন-স্ক্রিন দৃশ্যমান পর্যালোচনা প্রোফাইল; এগুলি নিশ্চিত জীবনঘটনা বা বিবাহের ফল নয়।',
        'গজকেশরী, রাজ ও ধনযোগের ফল শুধু সক্রিয় D1 গঠন-প্রোফাইল নথিভুক্ত করে; বিভাগীয় সমর্থন ও পূর্ণ বল অসম্পূর্ণ, আর আলাদা দশা calendar যোগের ফল নিশ্চিত না করে শুধু সক্রিয়তার প্রবণতা দেখায়।',
        'সাতটি ধ্রুপদি গ্রহের D1-D9 মর্যাদা-মিল, বর্গোত্তম এবং D9-capable output-এ ১২টি D9 ভাব/অধিপতি/পূর্ণ-রাশিদৃষ্টি synthesis অন্তর্ভুক্ত; Shadbala-র exact Sphuta-Drishti strength, evidence থাকলে পূর্ণ Kala এবং পূর্ণ ছয়-অংশের ষড়বল aggregate/required-strength evaluation এখন অন্তর্ভুক্ত; vedic-chart-v10 output-এ D10 career calculation, ১২টি ভাব/অধিপতি/পূর্ণ-রাশিদৃষ্টি record এবং D1-এর দশম ভাবপতি × D10-এর দশম ভাব structural synthesis অন্তর্ভুক্ত।',
        'কুজদোষ ও তার খণ্ডনের নিয়মে প্রথাভেদ আছে। অ্যাপ নির্বাচিত প্রোফাইল ও সম্ভাব্য প্রশমন-প্রমাণ দেখায়, নিজে থেকে সম্পূর্ণ খণ্ডন ঘোষণা করে না।',
        'বক্রী গতিকে তীব্রতা/পর্যালোচনার অবস্থা হিসেবে দেখানো হয়; নিজে থেকেই শুভ বা অশুভ বলা হয় না।',
        'অস্তাঙ্গতা versioned প্রচলিত কৌণিক সীমা ব্যবহার করে এবং গ্রহের স্বাধীন প্রকাশ কমার সম্ভাবনা বোঝায়—গ্রহ নষ্ট হয়ে যায় না।',
        if (timingWindows.isNotEmpty)
          'বিমশোত্তরী মহাদশা-অন্তর্দশার সময়কালসহ ৭২৯টি chart-specific প্রত্যন্তরদশা interpretation review-grade সক্রিয়তার প্রবণতা হিসেবে অন্তর্ভুক্ত। প্রতিটি interpretation governed ৩:২:১ hierarchy বজায় রেখে পুনরাবৃত্ত life area দেখায়; এটি নিশ্চিত ঘটনার তারিখ নয়। Selected-date দশা × গোচর confirmation শুধু আলাদা timing-synthesis engine তৈরি করে।'
        else
          'এই পুরোনো calculation output-এ যাচাইকৃত বিমশোত্তরী calendar নেই, তাই কোনো ঘটনার সময়কাল তৈরি করা হয়নি।',
        'Gemstone Candidate v1 সাতটি ধ্রুপদি গ্রহের strengthening-versus-contraindication screen। Eligible মানে শুধু professional review; কোনো gemstone, ওজন, ধাতু, আঙুল বা wearing ritual auto-approve হয় না। Rahu/Ketu gemstone automation v1-এর বাইরে।',
        'জ্যোতিষীয় ব্যাখ্যা সম্ভাবনা মাত্র, নিশ্চিত ফল নয়।',
      ],
      professionalReviewRequired: true,
    );
  }

}
