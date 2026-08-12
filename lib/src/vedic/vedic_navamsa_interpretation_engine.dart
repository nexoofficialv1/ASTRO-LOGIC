import '../models/calculation_output_snapshot.dart';
import '../models/kundli_analysis.dart';

/// Conservative, auditable Navamsha (D9) house/lord/aspect synthesis.
///
/// The engine requires the explicit D9 chart introduced by `vedic-chart-v2`.
/// It reuses the documented whole-sign sign-lord frame and enabled Parashari
/// full sign aspects inside D9. Rahu/Ketu occupancy is visible but review-only;
/// node dignity and node aspects are not invented.
class VedicNavamsaInterpretationEngine {
  const VedicNavamsaInterpretationEngine();

  String get engineId => 'astro-logic-vedic-navamsa-interpretation';

  String get engineVersion => '1.0.0';

  String get schemaVersion => 'navamsa-house-interpretation-v1';

  List<NavamsaHouseInterpretation> build(
    CalculationOutputSnapshot calculationOutput,
  ) {
    if (calculationOutput.outputSchemaVersion != 'vedic-chart-v2' &&
        calculationOutput.outputSchemaVersion != 'vedic-chart-v3' &&
        calculationOutput.outputSchemaVersion != 'vedic-chart-v4' &&
        calculationOutput.outputSchemaVersion != 'vedic-chart-v5' &&
        calculationOutput.outputSchemaVersion != 'vedic-chart-v6' &&
        calculationOutput.outputSchemaVersion != 'vedic-chart-v7' &&
        calculationOutput.outputSchemaVersion != 'vedic-chart-v8' &&
        calculationOutput.outputSchemaVersion != 'vedic-chart-v9' &&
        calculationOutput.outputSchemaVersion != 'vedic-chart-v10') {
      throw ArgumentError(
        'Navamsha house interpretation requires vedic-chart-v2 or later',
      );
    }

    final d9 = _requiredD9Chart(calculationOutput.output);
    final ascendantSign = _requiredSignIndex(
      _requiredMap(d9['ascendant'], r'$.divisionalCharts.d9.ascendant')[
          'signIndex'],
      r'$.divisionalCharts.d9.ascendant.signIndex',
    );
    final rawD9Planets = _requiredList(
      d9['planets'],
      r'$.divisionalCharts.d9.planets',
    );
    final rawNatalPlanets = _requiredList(
      calculationOutput.output['planets'],
      r'$.planets',
    );

    final natalD9Signs = <String, int>{};
    for (var index = 0; index < rawNatalPlanets.length; index += 1) {
      final planet = _requiredMap(rawNatalPlanets[index], r'$.planets[$index]');
      final body = _requiredBody(planet['body'], r'$.planets[$index].body');
      final d9Sign = _requiredSignIndex(
        planet['navamsaSignIndex'],
        r'$.planets[$index].navamsaSignIndex',
      );
      natalD9Signs[body] = d9Sign;
    }

    final d9Signs = <String, int>{};
    for (var index = 0; index < rawD9Planets.length; index += 1) {
      final planet = _requiredMap(
        rawD9Planets[index],
        r'$.divisionalCharts.d9.planets[$index]',
      );
      final body = _requiredBody(
        planet['body'],
        r'$.divisionalCharts.d9.planets[$index].body',
      );
      final sign = _requiredSignIndex(
        planet['signIndex'],
        r'$.divisionalCharts.d9.planets[$index].signIndex',
      );
      if (d9Signs.containsKey(body)) {
        throw StateError('Duplicate D9 body $body');
      }
      if (natalD9Signs[body] != sign) {
        throw StateError('D9 chart and per-planet Navamsha field disagree for $body');
      }
      d9Signs[body] = sign;
    }

    for (final body in _allBodies) {
      if (!d9Signs.containsKey(body)) {
        throw StateError('Explicit D9 chart is missing $body');
      }
    }

    final results = <NavamsaHouseInterpretation>[];
    for (var house = 1; house <= 12; house += 1) {
      final signIndex = (ascendantSign + house - 1) % 12;
      final houseLord = _signLords[signIndex]!;
      final lordSign = d9Signs[houseLord]!;
      final lordHouse = _houseOf(ascendantSign, lordSign);
      final dignity = _dignity(houseLord, lordSign);
      final lordPlacementScore = _placementScore(lordHouse);
      final lordDignityScore = _dignityScore(dignity);

      final occupants = <String>[
        for (final entry in d9Signs.entries)
          if (_houseOf(ascendantSign, entry.value) == house) entry.key,
      ]..sort(_bodySort);

      final aspectors = <String>[];
      for (final entry in _aspectRules.entries) {
        final sourceHouse = _houseOf(ascendantSign, d9Signs[entry.key]!);
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
        final contribution = _directionalUnit(_functionalRoleScore(
          ascendantSign,
          planet,
        ));
        occupantScore += contribution;
        componentScores.add(contribution);
      }
      var aspectScore = 0;
      for (final planet in aspectors) {
        final contribution = _directionalUnit(_functionalRoleScore(
          ascendantSign,
          planet,
        ));
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

      final evidence = <ChartEvidence>[
        ChartEvidence(
          ruleId: 'vedic.navamsa.house_frame.v1',
          outputPath: r'$.divisionalCharts.d9.ascendant.signIndex',
          kind: EvidenceKind.divisional,
          descriptionEn:
              'D9 ascendant is ${_signNamesEn[ascendantSign]}; Navamsha house $house therefore falls in ${_signNamesEn[signIndex]}.',
          descriptionBn:
              'D9 লগ্ন ${_signNamesBn[ascendantSign]}; তাই নবাংশের $house নম্বর ভাব ${_signNamesBn[signIndex]} রাশিতে পড়েছে।',
        ),
        ChartEvidence(
          ruleId: 'vedic.navamsa.house_lord.condition.v1.$houseLord',
          outputPath:
              r'$.divisionalCharts.d9.planets[?(@.body=="' + houseLord + r'")].signIndex',
          kind: EvidenceKind.lordship,
          descriptionEn:
              '${_planetNamesEn[houseLord]} rules D9 house $house and occupies D9 house $lordHouse in ${_signNamesEn[lordSign]} with ${_dignityEn[dignity]} dignity.',
          descriptionBn:
              '${_planetNamesBn[houseLord]} D9-এর $house নম্বর ভাবের অধিপতি এবং D9-এর $lordHouse নম্বর ভাবে ${_signNamesBn[lordSign]} রাশিতে ${_dignityBn[dignity]} মর্যাদায় রয়েছে।',
        ),
        for (final occupant in occupants)
          ChartEvidence(
            ruleId: _classicalBodies.contains(occupant)
                ? 'vedic.navamsa.house_occupancy.classical.v1.$occupant'
                : 'vedic.navamsa.house_occupancy.node_review.v1.$occupant',
            outputPath:
                r'$.divisionalCharts.d9.planets[?(@.body=="' + occupant + r'")].signIndex',
            kind: EvidenceKind.divisional,
            descriptionEn: _classicalBodies.contains(occupant)
                ? '${_displayPlanetNameEn(occupant)} occupies D9 house $house; its D9-ascendant functional ownership is used only as a directional review component.'
                : '${_displayPlanetNameEn(occupant)} occupies D9 house $house; node occupancy is visible but contributes no invented dignity or directional score.',
            descriptionBn: _classicalBodies.contains(occupant)
                ? '${_displayPlanetNameBn(occupant)} D9-এর $house নম্বর ভাবে রয়েছে; D9-লগ্নভিত্তিক কার্যকর অধিপত্য শুধু directional review component হিসেবে ব্যবহৃত হয়েছে।'
                : '${_displayPlanetNameBn(occupant)} D9-এর $house নম্বর ভাবে রয়েছে; node occupancy দৃশ্যমান, কিন্তু কোনো কল্পিত মর্যাদা বা directional score যোগ করা হয়নি।',
          ),
        for (final aspector in aspectors)
          ChartEvidence(
            ruleId: 'vedic.navamsa.full_sign_aspect.v1.$aspector.house_$house',
            outputPath:
                r'$.divisionalCharts.d9.planets[?(@.body=="' + aspector + r'")].signIndex',
            kind: EvidenceKind.aspect,
            descriptionEn:
                '${_displayPlanetNameEn(aspector)} casts an enabled Parashari full sign aspect on D9 house $house.',
            descriptionBn:
                '${_displayPlanetNameBn(aspector)} D9-এর $house নম্বর ভাবে সক্রিয় পরাশরী পূর্ণ রাশিদৃষ্টি দিচ্ছে।',
          ),
      ];

      final occupantsEn = occupants.isEmpty
          ? 'No planet occupies this D9 house.'
          : 'Occupants: ${occupants.map(_displayPlanetNameEn).join(', ')}.';
      final occupantsBn = occupants.isEmpty
          ? 'এই D9 ভাবে কোনো গ্রহ নেই।'
          : 'ভাবস্থিত: ${occupants.map(_displayPlanetNameBn).join(', ')}।';
      final aspectsEn = aspectors.isEmpty
          ? 'No enabled classical full sign aspect reaches this D9 house.'
          : 'Full sign aspects: ${aspectors.map(_displayPlanetNameEn).join(', ')}.';
      final aspectsBn = aspectors.isEmpty
          ? 'এই D9 ভাবে সক্রিয় ধ্রুপদি পূর্ণ রাশিদৃষ্টি নেই।'
          : 'পূর্ণ রাশিদৃষ্টি: ${aspectors.map(_displayPlanetNameBn).join(', ')}।';
      final contradictionEn = contradictory
          ? ' Supportive and challenging components coexist, so the result is preserved as Mixed.'
          : '';
      final contradictionBn = contradictory
          ? ' সহায়ক ও চ্যালেঞ্জিং component একসঙ্গে থাকায় ফল Mixed রাখা হয়েছে।'
          : '';

      results.add(
        NavamsaHouseInterpretation(
          code: 'vedic.divisional.d9.house_$house.synthesis',
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
          titleEn:
              'D9 house $house synthesis: ${_polarityEn[polarity]}',
          titleBn:
              'D9 $house নম্বর ভাবের বিচার: ${_polarityBn[polarity]}',
          narrativeEn:
              'Navamsha house $house is ${_signNamesEn[signIndex]}, ruled by ${_planetNamesEn[houseLord]}. Its lord is in D9 house $lordHouse with ${_dignityEn[dignity]} dignity. $occupantsEn $aspectsEn The transparent component scores are lord placement=$lordPlacementScore, lord dignity=$lordDignityScore, other classical occupants=$occupantScore and full-sign aspects=$aspectScore; net=$netScore.$contradictionEn This is a D9 structural review layer, not a replacement for the natal D1 house promise or a guaranteed event prediction.',
          narrativeBn:
              'নবাংশের $house নম্বর ভাব ${_signNamesBn[signIndex]} রাশিতে, অধিপতি ${_planetNamesBn[houseLord]}। ভাবপতি D9-এর $lordHouse নম্বর ভাবে ${_dignityBn[dignity]} মর্যাদায় রয়েছে। $occupantsBn $aspectsBn স্বচ্ছ component score: ভাবপতির অবস্থান=$lordPlacementScore, ভাবপতির মর্যাদা=$lordDignityScore, অন্য ধ্রুপদি ভাবস্থিত গ্রহ=$occupantScore এবং পূর্ণ রাশিদৃষ্টি=$aspectScore; net=$netScore।$contradictionBn এটি D9-এর structural review layer; জন্মছকের D1 ভাবের promise-এর বিকল্প বা নিশ্চিত ঘটনা-ভবিষ্যদ্বাণী নয়।',
          evidence: List.unmodifiable(evidence),
        ),
      );
    }

    return List.unmodifiable(results);
  }

  Map<String, Object?> _requiredD9Chart(Map<String, Object?> output) {
    final charts = _requiredMap(
      output['divisionalCharts'],
      r'$.divisionalCharts',
    );
    final d9 = _requiredMap(charts['d9'], r'$.divisionalCharts.d9');
    final division = d9['division'];
    if (division is! num || division.toInt() != 9) {
      throw StateError('Explicit divisional chart is not D9');
    }
    return d9;
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

  static _D9Dignity _dignity(String planet, int signIndex) {
    if (_exaltationSigns[planet] == signIndex) return _D9Dignity.exalted;
    if (_debilitationSigns[planet] == signIndex) {
      return _D9Dignity.debilitated;
    }
    if (_ownSigns[planet]!.contains(signIndex)) return _D9Dignity.ownSign;
    return _D9Dignity.neutral;
  }

  static int _dignityScore(_D9Dignity dignity) => switch (dignity) {
        _D9Dignity.exalted => 2,
        _D9Dignity.ownSign => 1,
        _D9Dignity.debilitated => -2,
        _D9Dignity.neutral => 0,
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
    'sun',
    'moon',
    'mars',
    'mercury',
    'jupiter',
    'venus',
    'saturn',
    'rahu',
    'ketu',
  ];
  static const _classicalBodies = <String>{
    'sun',
    'moon',
    'mars',
    'mercury',
    'jupiter',
    'venus',
    'saturn',
  };
  static const _supportiveHouses = <int>{1, 4, 5, 7, 9, 10};
  static const _challengingHouses = <int>{6, 8, 12};
  static const _kendraForYoga = <int>{4, 7, 10};
  static const _trikonaForYoga = <int>{5, 9};
  static const _ownershipScores = <int, int>{
    1: 2,
    2: 0,
    3: -1,
    4: 1,
    5: 2,
    6: -2,
    7: 0,
    8: -2,
    9: 2,
    10: 1,
    11: -1,
    12: -1,
  };
  static const _signLords = <int, String>{
    0: 'mars',
    1: 'venus',
    2: 'mercury',
    3: 'moon',
    4: 'sun',
    5: 'mercury',
    6: 'venus',
    7: 'mars',
    8: 'jupiter',
    9: 'saturn',
    10: 'saturn',
    11: 'jupiter',
  };
  static const _exaltationSigns = <String, int>{
    'sun': 0,
    'moon': 1,
    'mars': 9,
    'mercury': 5,
    'jupiter': 3,
    'venus': 11,
    'saturn': 6,
  };
  static const _debilitationSigns = <String, int>{
    'sun': 6,
    'moon': 7,
    'mars': 3,
    'mercury': 11,
    'jupiter': 9,
    'venus': 5,
    'saturn': 0,
  };
  static const _ownSigns = <String, Set<int>>{
    'sun': {4},
    'moon': {3},
    'mars': {0, 7},
    'mercury': {2, 5},
    'jupiter': {8, 11},
    'venus': {1, 6},
    'saturn': {9, 10},
  };
  static const _aspectRules = <String, List<int>>{
    'sun': [7],
    'moon': [7],
    'mercury': [7],
    'venus': [7],
    'mars': [7, 4, 8],
    'jupiter': [7, 5, 9],
    'saturn': [7, 3, 10],
  };
  static const _signNamesEn = <String>[
    'Aries',
    'Taurus',
    'Gemini',
    'Cancer',
    'Leo',
    'Virgo',
    'Libra',
    'Scorpio',
    'Sagittarius',
    'Capricorn',
    'Aquarius',
    'Pisces',
  ];
  static const _signNamesBn = <String>[
    'মেষ',
    'বৃষ',
    'মিথুন',
    'কর্কট',
    'সিংহ',
    'কন্যা',
    'তুলা',
    'বৃশ্চিক',
    'ধনু',
    'মকর',
    'কুম্ভ',
    'মীন',
  ];
  static const _planetNamesEn = <String, String>{
    'sun': 'Sun',
    'moon': 'Moon',
    'mars': 'Mars',
    'mercury': 'Mercury',
    'jupiter': 'Jupiter',
    'venus': 'Venus',
    'saturn': 'Saturn',
  };
  static const _planetNamesBn = <String, String>{
    'sun': 'সূর্য',
    'moon': 'চন্দ্র',
    'mars': 'মঙ্গল',
    'mercury': 'বুধ',
    'jupiter': 'বৃহস্পতি',
    'venus': 'শুক্র',
    'saturn': 'শনি',
  };
  static const _nodeNamesEn = <String, String>{
    'rahu': 'Rahu',
    'ketu': 'Ketu',
  };
  static const _nodeNamesBn = <String, String>{
    'rahu': 'রাহু',
    'ketu': 'কেতু',
  };
  static const _dignityEn = <_D9Dignity, String>{
    _D9Dignity.exalted: 'exalted',
    _D9Dignity.ownSign: 'own-sign',
    _D9Dignity.debilitated: 'debilitated',
    _D9Dignity.neutral: 'neutral',
  };
  static const _dignityBn = <_D9Dignity, String>{
    _D9Dignity.exalted: 'তুঙ্গ',
    _D9Dignity.ownSign: 'স্বক্ষেত্র',
    _D9Dignity.debilitated: 'নীচ',
    _D9Dignity.neutral: 'নিরপেক্ষ',
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

enum _D9Dignity { exalted, ownSign, debilitated, neutral }
