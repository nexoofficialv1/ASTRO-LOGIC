import '../models/calculation_output_snapshot.dart';
import '../models/kundli_analysis.dart';

/// Conservative, auditable Dashamsa (D10) career-structure synthesis.
///
/// Calculation of D10 itself is produced upstream by the Vedic derivation
/// engine using the BPHS odd-sign/self and even-sign/ninth-sign mapping.
/// This layer reads the explicit D10 chart as a career-domain varga, preserves
/// Rahu/Ketu occupancy as review-only, and never converts D10 structure into a
/// guaranteed profession, promotion or event date.
class VedicDashamsaInterpretationEngine {
  const VedicDashamsaInterpretationEngine();

  String get engineId => 'astro-logic-vedic-dashamsa-interpretation';
  String get engineVersion => '1.0.0';
  String get schemaVersion => 'dashamsa-career-interpretation-v1';

  DashamsaInterpretationResult build(
    CalculationOutputSnapshot calculationOutput,
  ) {
    if (calculationOutput.outputSchemaVersion != 'vedic-chart-v10') {
      throw ArgumentError(
        'Dashamsa career interpretation requires vedic-chart-v10 output',
      );
    }

    final output = calculationOutput.output;
    final d1Ascendant = _requiredSignIndex(
      _requiredMap(output['ascendant'], r'$.ascendant')['signIndex'],
      r'$.ascendant.signIndex',
    );
    final d10 = _requiredD10Chart(output);
    final d10Ascendant = _requiredSignIndex(
      _requiredMap(
        d10['ascendant'],
        r'$.divisionalCharts.d10.ascendant',
      )['signIndex'],
      r'$.divisionalCharts.d10.ascendant.signIndex',
    );

    final rawD10Planets = _requiredList(
      d10['planets'],
      r'$.divisionalCharts.d10.planets',
    );
    final rawNatalPlanets = _requiredList(output['planets'], r'$.planets');

    final perPlanetD10Signs = <String, int>{};
    final d1Signs = <String, int>{};
    for (var index = 0; index < rawNatalPlanets.length; index += 1) {
      final planet = _requiredMap(rawNatalPlanets[index], r'$.planets[$index]');
      final body = _requiredBody(planet['body'], r'$.planets[$index].body');
      d1Signs[body] = _requiredSignIndex(
        planet['signIndex'],
        r'$.planets[$index].signIndex',
      );
      perPlanetD10Signs[body] = _requiredSignIndex(
        planet['dashamsaSignIndex'],
        r'$.planets[$index].dashamsaSignIndex',
      );
    }

    final d10Signs = <String, int>{};
    for (var index = 0; index < rawD10Planets.length; index += 1) {
      final planet = _requiredMap(
        rawD10Planets[index],
        r'$.divisionalCharts.d10.planets[$index]',
      );
      final body = _requiredBody(
        planet['body'],
        r'$.divisionalCharts.d10.planets[$index].body',
      );
      final sign = _requiredSignIndex(
        planet['signIndex'],
        r'$.divisionalCharts.d10.planets[$index].signIndex',
      );
      if (d10Signs.containsKey(body)) {
        throw StateError('Duplicate D10 body $body');
      }
      if (perPlanetD10Signs[body] != sign) {
        throw StateError(
          'D10 chart and per-planet Dashamsa field disagree for $body',
        );
      }
      d10Signs[body] = sign;
    }

    for (final body in _allBodies) {
      if (!d10Signs.containsKey(body) || !d1Signs.containsKey(body)) {
        throw StateError('Explicit D10/D1 chart is missing $body');
      }
    }

    final houses = <DashamsaHouseInterpretation>[];
    for (var house = 1; house <= 12; house += 1) {
      final signIndex = (d10Ascendant + house - 1) % 12;
      final houseLord = _signLords[signIndex]!;
      final lordSign = d10Signs[houseLord]!;
      final lordHouse = _houseOf(d10Ascendant, lordSign);
      final dignity = _dignity(houseLord, lordSign);
      final lordPlacementScore = _placementScore(lordHouse);
      final lordDignityScore = _dignityScore(dignity);

      final occupants = <String>[
        for (final entry in d10Signs.entries)
          if (_houseOf(d10Ascendant, entry.value) == house) entry.key,
      ]..sort(_bodySort);

      final aspectors = <String>[];
      for (final entry in _aspectRules.entries) {
        final sourceHouse = _houseOf(d10Ascendant, d10Signs[entry.key]!);
        if (entry.value.any((rule) {
          final target = ((sourceHouse + rule - 2) % 12) + 1;
          return target == house;
        })) {
          aspectors.add(entry.key);
        }
      }
      aspectors.sort(_bodySort);

      final componentScores = <int>[
        lordPlacementScore,
        lordDignityScore,
      ];
      var occupantScore = 0;
      for (final planet in occupants) {
        if (!_classicalBodies.contains(planet) || planet == houseLord) continue;
        final contribution = _directionalUnit(
          _functionalRoleScore(d10Ascendant, planet),
        );
        occupantScore += contribution;
        componentScores.add(contribution);
      }
      var aspectScore = 0;
      for (final planet in aspectors) {
        final contribution = _directionalUnit(
          _functionalRoleScore(d10Ascendant, planet),
        );
        aspectScore += contribution;
        componentScores.add(contribution);
      }

      final netScore = lordPlacementScore +
          lordDignityScore +
          occupantScore +
          aspectScore;
      final directionalSigns = <int>{
        for (final value in componentScores)
          if (value != 0) value.sign,
      };
      final contradictory = directionalSigns.length > 1;
      final polarity = contradictory
          ? AnalysisPolarity.mixed
          : netScore >= 2
              ? AnalysisPolarity.supportive
              : netScore <= -2
                  ? AnalysisPolarity.challenging
                  : AnalysisPolarity.mixed;
      final directionalComponents =
          componentScores.where((value) => value != 0).length;
      final confidence = polarity != AnalysisPolarity.mixed &&
              directionalComponents >= 2
          ? AnalysisConfidence.medium
          : AnalysisConfidence.low;
      final careerRelevance = _careerFocusHouses.contains(house);

      final evidence = <ChartEvidence>[
        ChartEvidence(
          ruleId: 'vedic.dashamsa.house_frame.v1',
          outputPath: r'$.divisionalCharts.d10.ascendant.signIndex',
          kind: EvidenceKind.divisional,
          descriptionEn:
              'D10 ascendant is ${_signNamesEn[d10Ascendant]}; Dashamsa house $house therefore falls in ${_signNamesEn[signIndex]}.',
          descriptionBn:
              'D10 লগ্ন ${_signNamesBn[d10Ascendant]}; তাই দশাংশের $house নম্বর ভাব ${_signNamesBn[signIndex]} রাশিতে পড়েছে।',
        ),
        ChartEvidence(
          ruleId: 'vedic.dashamsa.house_lord.condition.v1.$houseLord',
          outputPath:
              r'$.divisionalCharts.d10.planets[?(@.body=="' + houseLord + r'")].signIndex',
          kind: EvidenceKind.lordship,
          descriptionEn:
              '${_planetNamesEn[houseLord]} rules D10 house $house and occupies D10 house $lordHouse in ${_signNamesEn[lordSign]} with ${_dignityEn[dignity]} dignity.',
          descriptionBn:
              '${_planetNamesBn[houseLord]} D10-এর $house নম্বর ভাবের অধিপতি এবং D10-এর $lordHouse নম্বর ভাবে ${_signNamesBn[lordSign]} রাশিতে ${_dignityBn[dignity]} মর্যাদায় রয়েছে।',
        ),
        for (final occupant in occupants)
          ChartEvidence(
            ruleId: _classicalBodies.contains(occupant)
                ? 'vedic.dashamsa.house_occupancy.classical.v1.$occupant'
                : 'vedic.dashamsa.house_occupancy.node_review.v1.$occupant',
            outputPath:
                r'$.divisionalCharts.d10.planets[?(@.body=="' + occupant + r'")].signIndex',
            kind: EvidenceKind.divisional,
            descriptionEn: _classicalBodies.contains(occupant)
                ? '${_displayPlanetNameEn(occupant)} occupies D10 house $house; its D10-ascendant functional ownership is used only as a directional career-structure component.'
                : '${_displayPlanetNameEn(occupant)} occupies D10 house $house; node occupancy is visible but contributes no invented dignity, aspect or directional score.',
            descriptionBn: _classicalBodies.contains(occupant)
                ? '${_displayPlanetNameBn(occupant)} D10-এর $house নম্বর ভাবে রয়েছে; D10-লগ্নভিত্তিক কার্যকর অধিপত্য শুধু career-structure directional component হিসেবে ব্যবহৃত হয়েছে।'
                : '${_displayPlanetNameBn(occupant)} D10-এর $house নম্বর ভাবে রয়েছে; node occupancy দৃশ্যমান, কিন্তু কোনো কল্পিত মর্যাদা, দৃষ্টি বা directional score যোগ করা হয়নি।',
          ),
        for (final aspector in aspectors)
          ChartEvidence(
            ruleId: 'vedic.dashamsa.full_sign_aspect.v1.$aspector.house_$house',
            outputPath:
                r'$.divisionalCharts.d10.planets[?(@.body=="' + aspector + r'")].signIndex',
            kind: EvidenceKind.aspect,
            descriptionEn:
                '${_displayPlanetNameEn(aspector)} casts an enabled Parashari full-sign aspect on D10 house $house.',
            descriptionBn:
                '${_displayPlanetNameBn(aspector)} D10-এর $house নম্বর ভাবে সক্রিয় পরাশরী পূর্ণ রাশিদৃষ্টি দিচ্ছে।',
          ),
      ];

      final domainEn = _houseCareerDomainEn[house]!;
      final domainBn = _houseCareerDomainBn[house]!;
      final occupantsEn = occupants.isEmpty
          ? 'No planet occupies this D10 house.'
          : 'Occupants: ${occupants.map(_displayPlanetNameEn).join(', ')}.';
      final occupantsBn = occupants.isEmpty
          ? 'এই D10 ভাবে কোনো গ্রহ নেই।'
          : 'ভাবস্থিত: ${occupants.map(_displayPlanetNameBn).join(', ')}।';
      final aspectsEn = aspectors.isEmpty
          ? 'No enabled classical full-sign aspect reaches this D10 house.'
          : 'Full-sign aspects: ${aspectors.map(_displayPlanetNameEn).join(', ')}.';
      final aspectsBn = aspectors.isEmpty
          ? 'এই D10 ভাবে সক্রিয় ধ্রুপদি পূর্ণ রাশিদৃষ্টি নেই।'
          : 'পূর্ণ রাশিদৃষ্টি: ${aspectors.map(_displayPlanetNameBn).join(', ')}।';
      final contradictionEn = contradictory
          ? ' Supportive and challenging components coexist, so the result is preserved as Mixed.'
          : '';
      final contradictionBn = contradictory
          ? ' সহায়ক ও চ্যালেঞ্জিং component একসঙ্গে থাকায় ফল Mixed রাখা হয়েছে।'
          : '';

      houses.add(
        DashamsaHouseInterpretation(
          code: 'vedic.divisional.d10.house_$house.synthesis',
          ruleVersion: schemaVersion,
          houseNumber: house,
          signIndex: signIndex,
          houseLord: houseLord,
          lordHouse: lordHouse,
          lordDignity: dignity.name,
          occupants: List.unmodifiable(occupants),
          aspectors: List.unmodifiable(aspectors),
          lordPlacementScore: lordPlacementScore,
          lordDignityScore: lordDignityScore,
          occupantScore: occupantScore,
          aspectScore: aspectScore,
          netScore: netScore,
          polarity: polarity,
          confidence: confidence,
          contradictorySignals: contradictory,
          careerRelevance: careerRelevance,
          titleEn: 'D10 house $house ($domainEn): ${_polarityEn[polarity]}',
          titleBn: 'D10 $house নম্বর ভাব ($domainBn): ${_polarityBn[polarity]}',
          narrativeEn:
              'Dashamsa house $house is ${_signNamesEn[signIndex]}, ruled by ${_planetNamesEn[houseLord]}; in this career-domain profile it is reviewed for $domainEn. Its lord is in D10 house $lordHouse with ${_dignityEn[dignity]} dignity. $occupantsEn $aspectsEn Transparent scores are lord placement=$lordPlacementScore, lord dignity=$lordDignityScore, other classical occupants=$occupantScore and full-sign aspects=$aspectScore; net=$netScore.$contradictionEn This is D10 structural evidence only and must be read with the D1 career promise and timing layers.',
          narrativeBn:
              'দশাংশের $house নম্বর ভাব ${_signNamesBn[signIndex]} রাশিতে, অধিপতি ${_planetNamesBn[houseLord]}; career-domain profile-এ এটি $domainBn-এর জন্য review করা হয়। ভাবপতি D10-এর $lordHouse নম্বর ভাবে ${_dignityBn[dignity]} মর্যাদায় রয়েছে। $occupantsBn $aspectsBn স্বচ্ছ score: ভাবপতির অবস্থান=$lordPlacementScore, ভাবপতির মর্যাদা=$lordDignityScore, অন্য ধ্রুপদি ভাবস্থিত গ্রহ=$occupantScore এবং পূর্ণ রাশিদৃষ্টি=$aspectScore; net=$netScore।$contradictionBn এটি শুধু D10 structural evidence; D1 career promise ও timing layer-এর সঙ্গে মিলিয়ে পড়তে হবে।',
          evidence: List.unmodifiable(evidence),
        ),
      );
    }

    final synthesis = _buildCareerSynthesis(
      d1Ascendant: d1Ascendant,
      d10Ascendant: d10Ascendant,
      d10Signs: d10Signs,
      houses: houses,
    );

    return DashamsaInterpretationResult(
      houses: List.unmodifiable(houses),
      careerSynthesis: synthesis,
    );
  }

  DashamsaCareerSynthesis _buildCareerSynthesis({
    required int d1Ascendant,
    required int d10Ascendant,
    required Map<String, int> d10Signs,
    required List<DashamsaHouseInterpretation> houses,
  }) {
    final d1TenthSign = (d1Ascendant + 9) % 12;
    final d1TenthLord = _signLords[d1TenthSign]!;
    final d1LordD10Sign = d10Signs[d1TenthLord]!;
    final d1LordD10House = _houseOf(d10Ascendant, d1LordD10Sign);
    final d1LordDignity = _dignity(d1TenthLord, d1LordD10Sign);
    final d1LordScore =
        _placementScore(d1LordD10House) + _dignityScore(d1LordDignity);

    final tenth = houses[9];
    final d10TenthScore = tenth.netScore;
    final d1Direction = _directionalUnit(d1LordScore);
    final d10Direction = _directionalUnit(d10TenthScore);
    final contradictory =
        d1Direction != 0 && d10Direction != 0 && d1Direction != d10Direction;

    AnalysisPolarity polarity;
    AnalysisConfidence confidence;
    if (contradictory || d1Direction == 0 || d10Direction == 0) {
      polarity = AnalysisPolarity.mixed;
      confidence = AnalysisConfidence.low;
    } else if (d1Direction > 0 && d10Direction > 0) {
      polarity = AnalysisPolarity.supportive;
      confidence = AnalysisConfidence.medium;
    } else {
      polarity = AnalysisPolarity.challenging;
      confidence = AnalysisConfidence.medium;
    }

    final evidence = <ChartEvidence>[
      ChartEvidence(
        ruleId: 'vedic.dashamsa.d1_tenth_lord_in_d10.v1.$d1TenthLord',
        outputPath:
            r'$.divisionalCharts.d10.planets[?(@.body=="' + d1TenthLord + r'")].signIndex',
        kind: EvidenceKind.divisional,
        descriptionEn:
            '${_planetNamesEn[d1TenthLord]} is the D1 tenth lord and occupies D10 house $d1LordD10House in ${_signNamesEn[d1LordD10Sign]} with ${_dignityEn[d1LordDignity]} dignity; structural score=$d1LordScore.',
        descriptionBn:
            '${_planetNamesBn[d1TenthLord]} D1-এর দশম ভাবপতি এবং D10-এর $d1LordD10House নম্বর ভাবে ${_signNamesBn[d1LordD10Sign]} রাশিতে ${_dignityBn[d1LordDignity]} মর্যাদায় রয়েছে; structural score=$d1LordScore।',
      ),
      ...tenth.evidence,
    ];

    final conflictEn = contradictory
        ? 'The D1 tenth-lord signal and the D10 tenth-house signal oppose each other, so the career structure remains Mixed.'
        : d1Direction == 0 || d10Direction == 0
            ? 'One structural family is non-directional, so the engine withholds a directional career conclusion.'
            : 'The D1 tenth-lord signal and D10 tenth-house signal reinforce the same direction.';
    final conflictBn = contradictory
        ? 'D1-এর দশম ভাবপতির signal ও D10-এর দশম ভাবের signal বিপরীত, তাই career structure Mixed রাখা হয়েছে।'
        : d1Direction == 0 || d10Direction == 0
            ? 'একটি structural family directional নয়, তাই engine directional career conclusion দেয়নি।'
            : 'D1-এর দশম ভাবপতি ও D10-এর দশম ভাব একই directional signal সমর্থন করছে।';

    return DashamsaCareerSynthesis(
      code: 'vedic.divisional.d10.career_synthesis',
      ruleVersion: schemaVersion,
      d1TenthLord: d1TenthLord,
      d1TenthLordD10House: d1LordD10House,
      d1TenthLordD10Dignity: d1LordDignity.name,
      d10TenthLord: tenth.houseLord,
      d10TenthLordHouse: tenth.lordHouse,
      d10TenthLordDignity: tenth.lordDignity,
      d10TenthOccupants: tenth.occupants,
      d10TenthAspectors: tenth.aspectors,
      d1LordScore: d1LordScore,
      d10TenthScore: d10TenthScore,
      netScore: d1LordScore + d10TenthScore,
      polarity: polarity,
      confidence: confidence,
      contradictorySignals: contradictory,
      titleEn: 'D1 × D10 career structure: ${_polarityEn[polarity]}',
      titleBn: 'D1 × D10 কর্মজীবন কাঠামো: ${_polarityBn[polarity]}',
      narrativeEn:
          'The D1 tenth lord ${_planetNamesEn[d1TenthLord]} is reviewed inside D10 together with the D10 tenth house and its lord ${_planetNamesEn[tenth.houseLord]}. D1-tenth-lord score=$d1LordScore; D10-tenth-house score=$d10TenthScore. $conflictEn This is a structural career cross-check only; profession choice, promotion, income or timing still require D1, Dasha, transit and other governed evidence.',
      narrativeBn:
          'D1-এর দশম ভাবপতি ${_planetNamesBn[d1TenthLord]}-কে D10-এর ভিতরে এবং D10-এর দশম ভাব ও তার অধিপতি ${_planetNamesBn[tenth.houseLord]}-এর সঙ্গে মিলিয়ে দেখা হয়েছে। D1 দশম-ভাবপতি score=$d1LordScore; D10 দশম-ভাব score=$d10TenthScore। $conflictBn এটি শুধু structural career cross-check; পেশা নির্বাচন, পদোন্নতি, আয় বা timing-এর জন্য D1, দশা, transit ও অন্য governed evidence দরকার।',
      evidence: List.unmodifiable(evidence),
    );
  }

  Map<String, Object?> _requiredD10Chart(Map<String, Object?> output) {
    final charts = _requiredMap(output['divisionalCharts'], r'$.divisionalCharts');
    final d10 = _requiredMap(charts['d10'], r'$.divisionalCharts.d10');
    final division = d10['division'];
    if (division is! num || division.toInt() != 10) {
      throw StateError('Explicit divisional chart is not D10');
    }
    if (d10['calculationProfile'] !=
        'bphs-dashamsa-odd-self-even-ninth-v1') {
      throw StateError('Unsupported D10 calculation profile');
    }
    return d10;
  }

  static int _houseOf(int ascendantSign, int planetSign) =>
      ((planetSign - ascendantSign + 12) % 12) + 1;

  static int _placementScore(int house) => _supportiveHouses.contains(house)
      ? 1
      : _challengingHouses.contains(house)
          ? -1
          : 0;

  static int _functionalRoleScore(int ascendantSign, String planet) {
    if (!_classicalBodies.contains(planet)) return 0;
    var score = 0;
    final ownedHouses = <int>[];
    for (var sign = 0; sign < 12; sign += 1) {
      if (_signLords[sign] != planet) continue;
      final house = ((sign - ascendantSign + 12) % 12) + 1;
      ownedHouses.add(house);
      score += _ownershipScores[house]!;
    }
    final yogaKaraka = ownedHouses.any(_kendraForYoga.contains) &&
        ownedHouses.any(_trikonaForYoga.contains);
    if (yogaKaraka) score += 1;
    return score;
  }

  static int _directionalUnit(int score) => score > 0
      ? 1
      : score < 0
          ? -1
          : 0;

  static _D10Dignity _dignity(String planet, int signIndex) {
    if (_exaltationSigns[planet] == signIndex) return _D10Dignity.exalted;
    if (_debilitationSigns[planet] == signIndex) {
      return _D10Dignity.debilitated;
    }
    if (_ownSigns[planet]!.contains(signIndex)) return _D10Dignity.ownSign;
    return _D10Dignity.neutral;
  }

  static int _dignityScore(_D10Dignity dignity) => switch (dignity) {
        _D10Dignity.exalted => 2,
        _D10Dignity.ownSign => 1,
        _D10Dignity.debilitated => -2,
        _D10Dignity.neutral => 0,
      };

  static Map<String, Object?> _requiredMap(Object? value, String path) {
    if (value is! Map) throw StateError('Missing or invalid $path');
    return Map<String, Object?>.from(value);
  }

  static List<Object?> _requiredList(Object? value, String path) {
    if (value is! List) throw StateError('Missing or invalid $path');
    return List<Object?>.from(value);
  }

  static String _requiredBody(Object? value, String path) {
    if (value is! String || !_allBodies.contains(value)) {
      throw StateError('Missing or invalid $path');
    }
    return value;
  }

  static int _requiredSignIndex(Object? value, String path) {
    if (value is! num || value.toInt() < 0 || value.toInt() > 11) {
      throw StateError('Missing or invalid $path');
    }
    return value.toInt();
  }

  static String _displayPlanetNameEn(String planet) =>
      _planetNamesEn[planet] ?? _nodeNamesEn[planet]!;
  static String _displayPlanetNameBn(String planet) =>
      _planetNamesBn[planet] ?? _nodeNamesBn[planet]!;
  static int _bodySort(String a, String b) =>
      _allBodies.indexOf(a).compareTo(_allBodies.indexOf(b));

  static const _allBodies = <String>[
    'sun', 'moon', 'mars', 'mercury', 'jupiter', 'venus', 'saturn', 'rahu', 'ketu',
  ];
  static const _classicalBodies = <String>{
    'sun', 'moon', 'mars', 'mercury', 'jupiter', 'venus', 'saturn',
  };
  static const _careerFocusHouses = <int>{1, 2, 6, 7, 10, 11};
  static const _supportiveHouses = <int>{1, 4, 5, 7, 9, 10, 11};
  static const _challengingHouses = <int>{6, 8, 12};
  static const _kendraForYoga = <int>{4, 7, 10};
  static const _trikonaForYoga = <int>{5, 9};
  static const _ownershipScores = <int, int>{
    1: 2, 2: 0, 3: -1, 4: 1, 5: 2, 6: -2,
    7: 0, 8: -2, 9: 2, 10: 2, 11: -1, 12: -1,
  };
  static const _signLords = <int, String>{
    0: 'mars', 1: 'venus', 2: 'mercury', 3: 'moon', 4: 'sun', 5: 'mercury',
    6: 'venus', 7: 'mars', 8: 'jupiter', 9: 'saturn', 10: 'saturn', 11: 'jupiter',
  };
  static const _exaltationSigns = <String, int>{
    'sun': 0, 'moon': 1, 'mars': 9, 'mercury': 5,
    'jupiter': 3, 'venus': 11, 'saturn': 6,
  };
  static const _debilitationSigns = <String, int>{
    'sun': 6, 'moon': 7, 'mars': 3, 'mercury': 11,
    'jupiter': 9, 'venus': 5, 'saturn': 0,
  };
  static const _ownSigns = <String, Set<int>>{
    'sun': {4}, 'moon': {3}, 'mars': {0, 7}, 'mercury': {2, 5},
    'jupiter': {8, 11}, 'venus': {1, 6}, 'saturn': {9, 10},
  };
  static const _aspectRules = <String, List<int>>{
    'sun': [7], 'moon': [7], 'mercury': [7], 'venus': [7],
    'mars': [7, 4, 8], 'jupiter': [7, 5, 9], 'saturn': [7, 3, 10],
  };
  static const _houseCareerDomainEn = <int, String>{
    1: 'professional identity and operating style',
    2: 'career resources, speech and earnings context',
    3: 'initiative, skills and self-driven effort',
    4: 'professional foundation and inner stability',
    5: 'judgment, creativity and advisory intelligence',
    6: 'service, workload, competition and problem-solving',
    7: 'clients, contracts, partnerships and public dealings',
    8: 'career disruption, confidential work and transformation',
    9: 'professional ethics, mentors and institutional fortune',
    10: 'profession, responsibility, authority and public action',
    11: 'career gains, networks, recognition and fulfilment',
    12: 'foreign/remote work, withdrawal and professional expenditure',
  };
  static const _houseCareerDomainBn = <int, String>{
    1: 'পেশাগত পরিচয় ও কাজের ধরন',
    2: 'পেশাগত সম্পদ, বাকশক্তি ও আয়ের প্রেক্ষিত',
    3: 'উদ্যোগ, দক্ষতা ও নিজস্ব প্রচেষ্টা',
    4: 'পেশাগত ভিত্তি ও অন্তর্গত স্থিতি',
    5: 'বিচারবুদ্ধি, সৃজনশীলতা ও পরামর্শদানের ক্ষমতা',
    6: 'চাকরি/সেবা, কাজের চাপ, প্রতিযোগিতা ও সমস্যা সমাধান',
    7: 'ক্লায়েন্ট, চুক্তি, অংশীদারিত্ব ও জনসম্মুখের লেনদেন',
    8: 'পেশাগত পরিবর্তন, গোপন কাজ ও রূপান্তর',
    9: 'পেশাগত নীতি, মেন্টর ও প্রাতিষ্ঠানিক সহায়তা',
    10: 'পেশা, দায়িত্ব, কর্তৃত্ব ও জনসম্মুখের কর্ম',
    11: 'পেশাগত লাভ, নেটওয়ার্ক, স্বীকৃতি ও অর্জন',
    12: 'বিদেশ/রিমোট কাজ, প্রত্যাহার ও পেশাগত ব্যয়',
  };
  static const _signNamesEn = <String>[
    'Aries','Taurus','Gemini','Cancer','Leo','Virgo','Libra','Scorpio','Sagittarius','Capricorn','Aquarius','Pisces',
  ];
  static const _signNamesBn = <String>[
    'মেষ','বৃষ','মিথুন','কর্কট','সিংহ','কন্যা','তুলা','বৃশ্চিক','ধনু','মকর','কুম্ভ','মীন',
  ];
  static const _planetNamesEn = <String, String>{
    'sun': 'Sun','moon': 'Moon','mars': 'Mars','mercury': 'Mercury','jupiter': 'Jupiter','venus': 'Venus','saturn': 'Saturn',
  };
  static const _planetNamesBn = <String, String>{
    'sun': 'সূর্য','moon': 'চন্দ্র','mars': 'মঙ্গল','mercury': 'বুধ','jupiter': 'বৃহস্পতি','venus': 'শুক্র','saturn': 'শনি',
  };
  static const _nodeNamesEn = <String, String>{'rahu': 'Rahu', 'ketu': 'Ketu'};
  static const _nodeNamesBn = <String, String>{'rahu': 'রাহু', 'ketu': 'কেতু'};
  static const _dignityEn = <_D10Dignity, String>{
    _D10Dignity.exalted: 'exalted',
    _D10Dignity.ownSign: 'own-sign',
    _D10Dignity.debilitated: 'debilitated',
    _D10Dignity.neutral: 'neutral',
  };
  static const _dignityBn = <_D10Dignity, String>{
    _D10Dignity.exalted: 'তুঙ্গ',
    _D10Dignity.ownSign: 'স্বক্ষেত্র',
    _D10Dignity.debilitated: 'নীচ',
    _D10Dignity.neutral: 'নিরপেক্ষ',
  };
  static const _polarityEn = <AnalysisPolarity, String>{
    AnalysisPolarity.supportive: 'Supportive',
    AnalysisPolarity.challenging: 'Challenging',
    AnalysisPolarity.mixed: 'Mixed',
  };
  static const _polarityBn = <AnalysisPolarity, String>{
    AnalysisPolarity.supportive: 'সহায়ক',
    AnalysisPolarity.challenging: 'চ্যালেঞ্জিং',
    AnalysisPolarity.mixed: 'মিশ্র',
  };
}

class DashamsaInterpretationResult {
  const DashamsaInterpretationResult({
    required this.houses,
    required this.careerSynthesis,
  });

  final List<DashamsaHouseInterpretation> houses;
  final DashamsaCareerSynthesis careerSynthesis;
}

enum _D10Dignity { exalted, ownSign, debilitated, neutral }
