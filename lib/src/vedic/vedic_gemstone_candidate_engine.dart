import '../models/calculation_output_snapshot.dart';
import '../models/kundli_analysis.dart';

/// Conservative strengthening-gemstone review.
///
/// This engine never approves a gemstone. It decides only whether a classical
/// planet's strengthening gemstone is eligible for professional review,
/// contraindicated by the enabled functional-lordship policy, or unsupported
/// by enough verified evidence. Rahu/Ketu gemstones are deliberately outside
/// v1 because the current Shadbala contract covers only the seven classical
/// planets and node-strengthening doctrines vary materially across lineages.
class VedicGemstoneCandidateEngine {
  const VedicGemstoneCandidateEngine();

  static const String ruleVersion = 'vedic-gemstone-candidate-v1';
  static const String mappingProfile = 'astro-logic-navaratna-mapping-v1';

  List<GemstoneCandidateReview> build(
    CalculationOutputSnapshot output, {
    required List<ShadbalaPlanetProfile> shadbalaProfiles,
    required List<AnalysisTimingWindow> timingWindows,
  }) {
    if (!_supportedSchemas.contains(output.outputSchemaVersion)) {
      throw ArgumentError(
        'Gemstone candidate review requires vedic-chart-v1 through vedic-chart-v10 output',
      );
    }
    final ascendant = _requiredMap(output.output['ascendant'], 'ascendant');
    final ascendantSign =
        _requiredSignIndex(ascendant['signIndex'], 'ascendant.signIndex');
    final planets = _requiredPlanets(output.output['planets']);
    for (final planet in _classicalPlanets) {
      if (!planets.containsKey(planet)) {
        throw StateError('Gemstone review is missing $planet');
      }
    }
    final shadbalaByPlanet = <String, ShadbalaPlanetProfile>{
      for (final profile in shadbalaProfiles) profile.planet: profile,
    };
    final activeWindow = _activeDashaWindow(timingWindows, output.createdAt);

    return [
      for (final planet in _classicalPlanets)
        _review(
          planet,
          ascendantSign,
          planets,
          shadbalaByPlanet[planet],
          activeWindow,
        ),
    ];
  }

  GemstoneCandidateReview _review(
    String planet,
    int ascendantSign,
    Map<String, _Planet> planets,
    ShadbalaPlanetProfile? shadbala,
    AnalysisTimingWindow? activeWindow,
  ) {
    final position = planets[planet]!;
    final role = _functionalRole(ascendantSign, planet);
    final d1 = _dignity(planet, position.signIndex);
    final d9 = _dignity(planet, position.navamsaSignIndex);
    final combust = planet == 'sun'
        ? false
        : _angularSeparation(
              position.siderealLongitude,
              planets['sun']!.siderealLongitude,
            ) <=
            _combustionThreshold(planet, position.retrograde);
    final nodeContacts = <String>[
      for (final node in const ['rahu', 'ketu'])
        if (planets[node]?.signIndex == position.signIndex) node,
    ];
    final warRole = shadbala?.yuddhaRole ?? 'unavailable';
    final dasha = _dashaContext(activeWindow, planet);

    final evidence = <ChartEvidence>[
      ChartEvidence(
        ruleId: '$ruleVersion.functional.$planet',
        outputPath: r'$.ascendant.signIndex',
        kind: EvidenceKind.lordship,
        descriptionEn:
            '${_planetNamesEn[planet]} owns houses ${role.ownedHouses.join(', ')} for this ascendant; the governed functional score is ${role.score}${role.yogaKaraka ? ' with Yoga-karaka support' : ''}.',
        descriptionBn:
            'এই লগ্নে ${_planetNamesBn[planet]} ${role.ownedHouses.join(', ')} নম্বর ভাবের অধিপতি; governed functional score ${role.score}${role.yogaKaraka ? ' এবং Yoga-karaka support আছে' : ''}।',
      ),
      ChartEvidence(
        ruleId: '$ruleVersion.d1_d9.$planet',
        outputPath:
            r'$.planets[?(@.body=="' + planet + r'")].navamsaSignIndex',
        kind: EvidenceKind.divisional,
        descriptionEn:
            '${_planetNamesEn[planet]} dignity: D1=${_dignityEn[d1]}, D9=${_dignityEn[d9]}.',
        descriptionBn:
            '${_planetNamesBn[planet]} মর্যাদা: D1=${_dignityBn[d1]}, D9=${_dignityBn[d9]}।',
      ),
      if (shadbala != null)
        ChartEvidence(
          ruleId: '$ruleVersion.shadbala.$planet',
          outputPath: r'$.shadbalaProfiles[?(@.planet=="' + planet + r'")]',
          kind: EvidenceKind.strength,
          descriptionEn: shadbala.aggregateAvailable
              ? '${_planetNamesEn[planet]} Shadbala ratio is ${_fmt(shadbala.requiredStrengthRatio)}; threshold status=${shadbala.thresholdStatus}.'
              : '${_planetNamesEn[planet]} complete sixfold Shadbala aggregate is unavailable.',
          descriptionBn: shadbala.aggregateAvailable
              ? '${_planetNamesBn[planet]}-এর ষড়বল ratio ${_fmt(shadbala.requiredStrengthRatio)}; threshold status=${shadbala.thresholdStatus}।'
              : '${_planetNamesBn[planet]}-এর পূর্ণ ছয়-অংশের ষড়বল aggregate unavailable।',
        ),
      ChartEvidence(
        ruleId: '$ruleVersion.condition.$planet',
        outputPath:
            r'$.planets[?(@.body=="' + planet + r'")].siderealLongitude',
        kind: EvidenceKind.strength,
        descriptionEn:
            '${_planetNamesEn[planet]} condition review: combust=$combust; planetaryWarRole=$warRole; nodeContacts=${nodeContacts.isEmpty ? 'none' : nodeContacts.join(',')}.',
        descriptionBn:
            '${_planetNamesBn[planet]} condition review: combust=$combust; planetaryWarRole=$warRole; nodeContacts=${nodeContacts.isEmpty ? 'none' : nodeContacts.join(',')}।',
      ),
      if (activeWindow != null)
        ChartEvidence(
          ruleId: '$ruleVersion.dasha.$planet',
          outputPath: r'$.vimshottari',
          kind: EvidenceKind.dasha,
          descriptionEn:
              'At analysis time ${activeWindow.start.toUtc().toIso8601String()}..${activeWindow.end.toUtc().toIso8601String()}, ${_planetNamesEn[planet]} Dasha role is ${dasha.role}; window polarity=${activeWindow.polarity.name}.',
          descriptionBn:
              'Analysis-time ${activeWindow.start.toUtc().toIso8601String()}..${activeWindow.end.toUtc().toIso8601String()} সময়ে ${_planetNamesBn[planet]}-এর Dasha role ${dasha.role}; window polarity=${activeWindow.polarity.name}।',
        ),
    ];

    final contraindicationsEn = <String>[];
    final contraindicationsBn = <String>[];
    final supportsEn = <String>[];
    final supportsBn = <String>[];

    if (role.score <= -2) {
      contraindicationsEn.add(
        'Functional lordship is challenging in the enabled ascendant-specific strengthening policy (score ${role.score}).',
      );
      contraindicationsBn.add(
        'সক্রিয় লগ্নভিত্তিক strengthening policy-তে functional lordship challenging (score ${role.score})।',
      );
    } else if (role.score >= 2) {
      supportsEn.add(
        'Functional lordship is supportive (score ${role.score}${role.yogaKaraka ? ', Yoga-karaka' : ''}).',
      );
      supportsBn.add(
        'Functional lordship supportive (score ${role.score}${role.yogaKaraka ? ', Yoga-karaka' : ''})।',
      );
    }

    if (shadbala == null || !shadbala.aggregateAvailable) {
      contraindicationsEn.add('Complete governed Shadbala is unavailable.');
      contraindicationsBn.add('পূর্ণ governed Shadbala unavailable।');
    } else if (shadbala.thresholdStatus == 'belowRequired') {
      supportsEn.add(
        'Complete Shadbala is below the governed BPHS required-strength threshold (ratio ${_fmt(shadbala.requiredStrengthRatio)}).',
      );
      supportsBn.add(
        'পূর্ণ ষড়বল governed BPHS required-strength threshold-এর নিচে (ratio ${_fmt(shadbala.requiredStrengthRatio)})।',
      );
    } else {
      contraindicationsEn.add(
        'Complete Shadbala already meets the governed required-strength threshold; v1 finds no verified strengthening deficit.',
      );
      contraindicationsBn.add(
        'পূর্ণ ষড়বল governed required-strength threshold পূরণ করে; v1-এ verified strengthening deficit পাওয়া যায়নি।',
      );
    }

    if (d1 == _Dignity.debilitated || d9 == _Dignity.debilitated) {
      supportsEn.add('D1/D9 includes debilitation, adding a weakness-review signal.');
      supportsBn.add('D1/D9-এ নীচ মর্যাদা আছে, যা weakness-review signal যোগ করে।');
    }
    if (combust) {
      supportsEn.add('Combustion adds a reduced-independent-expression review flag.');
      supportsBn.add('অস্তাঙ্গতা reduced-independent-expression review flag যোগ করে।');
    }
    if (warRole == 'loser') {
      supportsEn.add('The Shadbala Yuddha profile records this planet as the computational loser.');
      supportsBn.add('Shadbala Yuddha profile-এ এই গ্রহ computational loser হিসেবে নথিভুক্ত।');
    }
    if (warRole == 'ambiguousMultiplePartners' ||
        warRole == 'latitudeTie' ||
        warRole == 'preWarStrengthUnavailable') {
      contraindicationsEn.add('Planetary-war evidence is unresolved ($warRole).');
      contraindicationsBn.add('গ্রহযুদ্ধের evidence unresolved ($warRole)।');
    }
    if (nodeContacts.isNotEmpty) {
      contraindicationsEn.add(
        'Same-sign ${nodeContacts.map((e) => e.toUpperCase()).join('/')} contact is an unresolved expression modifier; v1 does not auto-strengthen through it.',
      );
      contraindicationsBn.add(
        'একই রাশিতে ${nodeContacts.map((e) => e.toUpperCase()).join('/')} contact unresolved expression modifier; v1 এটিকে অতিক্রম করে auto-strengthen করে না।',
      );
    }
    if (activeWindow == null) {
      contraindicationsEn.add('No verified active Mahadasha/Antardasha window exists at analysis time.');
      contraindicationsBn.add('Analysis time-এ verified active Mahadasha/Antardasha window নেই।');
    } else if (!dasha.active) {
      contraindicationsEn.add(
        '${_planetNamesEn[planet]} is not the active Mahadasha or Antardasha lord at analysis time.',
      );
      contraindicationsBn.add(
        'Analysis time-এ ${_planetNamesBn[planet]} সক্রিয় Mahadasha বা Antardasha lord নয়।',
      );
    } else {
      supportsEn.add(
        '${_planetNamesEn[planet]} is active as ${dasha.role}; this supplies timing relevance, not outcome certainty.',
      );
      supportsBn.add(
        '${_planetNamesBn[planet]} ${dasha.role} হিসেবে সক্রিয়; এটি timing relevance দেয়, নিশ্চিত ফল নয়।',
      );
    }

    late final GemstoneCandidateStatus status;
    if (role.score <= -2) {
      status = GemstoneCandidateStatus.contraindicated;
    } else {
      final shadbalaDeficit = shadbala != null &&
          shadbala.aggregateAvailable &&
          shadbala.thresholdStatus == 'belowRequired';
      final unresolvedWar = warRole == 'ambiguousMultiplePartners' ||
          warRole == 'latitudeTie' ||
          warRole == 'preWarStrengthUnavailable';
      if (role.score >= 2 &&
          shadbalaDeficit &&
          dasha.active &&
          nodeContacts.isEmpty &&
          !unresolvedWar) {
        status = GemstoneCandidateStatus.eligible;
      } else {
        status = GemstoneCandidateStatus.insufficientEvidence;
      }
    }

    final gem = _gemstones[planet]!;
    final rationaleEn = switch (status) {
      GemstoneCandidateStatus.eligible =>
        '${gem.primary} is eligible only as a professional strengthening-gemstone review candidate for ${_planetNamesEn[planet]}. ${supportsEn.join(' ')}',
      GemstoneCandidateStatus.contraindicated =>
        '${gem.primary} is contraindicated for automatic strengthening in v1 because ${contraindicationsEn.join(' ')}',
      GemstoneCandidateStatus.insufficientEvidence =>
        'Evidence is insufficient to show ${gem.primary} as a strengthening candidate in v1. ${contraindicationsEn.join(' ')}${supportsEn.isEmpty ? '' : ' Supporting context: ${supportsEn.join(' ')}'}',
    };
    final rationaleBn = switch (status) {
      GemstoneCandidateStatus.eligible =>
        '${_planetNamesBn[planet]}-এর strengthening-gemstone professional review candidate হিসেবে শুধু ${gem.primaryBn} eligible। ${supportsBn.join(' ')}',
      GemstoneCandidateStatus.contraindicated =>
        'v1-এ automatic strengthening-এর জন্য ${gem.primaryBn} contraindicated, কারণ ${contraindicationsBn.join(' ')}',
      GemstoneCandidateStatus.insufficientEvidence =>
        'v1-এ ${gem.primaryBn}-কে strengthening candidate দেখানোর evidence যথেষ্ট নয়। ${contraindicationsBn.join(' ')}${supportsBn.isEmpty ? '' : ' Supporting context: ${supportsBn.join(' ')}'}',
    };

    return GemstoneCandidateReview(
      code: 'vedic.gemstone.$planet.v1',
      ruleVersion: ruleVersion,
      mappingProfile: mappingProfile,
      planet: planet,
      primaryGemstone: gem.primary,
      primaryGemstoneBn: gem.primaryBn,
      status: status,
      functionalOwnedHouses: role.ownedHouses,
      functionalScore: role.score,
      yogaKaraka: role.yogaKaraka,
      shadbalaAvailable: shadbala?.aggregateAvailable ?? false,
      requiredStrengthRatio: shadbala?.requiredStrengthRatio,
      shadbalaThresholdStatus: shadbala?.thresholdStatus ?? 'unavailable',
      d1Dignity: _dignityEn[d1]!,
      d9Dignity: _dignityEn[d9]!,
      combust: combust,
      planetaryWarRole: warRole,
      nodeContacts: nodeContacts,
      activeDashaRole: dasha.role,
      activeDashaPolarity: activeWindow?.polarity,
      rationaleEn: rationaleEn,
      rationaleBn: rationaleBn,
      cautionEn:
          'Candidate status is a strengthening-versus-contraindication screen, not a prescription or approval. A professional astrologer must review the complete chart, current question, wearing suitability and gemstone authenticity before any practitioner-entered record is approved.',
      cautionBn:
          'এই candidate status strengthening-versus-contraindication screen; prescription বা approval নয়। কোনো practitioner-entered record approve করার আগে পেশাদার জ্যোতিষীকে পূর্ণ chart, বর্তমান প্রশ্ন, wearing suitability ও gemstone authenticity যাচাই করতে হবে।',
      evidence: evidence,
    );
  }

  static AnalysisTimingWindow? _activeDashaWindow(
    List<AnalysisTimingWindow> windows,
    DateTime asOf,
  ) {
    final instant = asOf.toUtc();
    for (final window in windows) {
      if (!instant.isBefore(window.start) && instant.isBefore(window.end)) {
        return window;
      }
    }
    return null;
  }

  static _DashaContext _dashaContext(
    AnalysisTimingWindow? window,
    String planet,
  ) {
    if (window == null) return const _DashaContext(false, 'unavailable');
    final parts = window.code.split('.');
    if (parts.length < 7 ||
        parts[0] != 'vedic' ||
        parts[1] != 'dasha' ||
        parts[2] != 'vimshottari') {
      return const _DashaContext(false, 'unavailable');
    }
    final maha = parts[3];
    final antar = parts[4];
    if (maha == planet && antar == planet) {
      return const _DashaContext(true, 'mahadasha+antardasha');
    }
    if (maha == planet) return const _DashaContext(true, 'mahadasha');
    if (antar == planet) return const _DashaContext(true, 'antardasha');
    return const _DashaContext(false, 'inactive');
  }

  static _FunctionalRole _functionalRole(int ascendantSign, String planet) {
    final ownedHouses = <int>[];
    var score = 0;
    for (var house = 1; house <= 12; house += 1) {
      final sign = (ascendantSign + house - 1) % 12;
      if (_signLords[sign] == planet) {
        ownedHouses.add(house);
        score += _ownershipScores[house]!;
      }
    }
    final yogaKaraka = ownedHouses.any(_kendraForYoga.contains) &&
        ownedHouses.any(_trikonaForYoga.contains);
    if (yogaKaraka) score += 1;
    return _FunctionalRole(ownedHouses, score, yogaKaraka);
  }

  static _Dignity _dignity(String planet, int sign) {
    if (_exaltationSigns[planet] == sign) return _Dignity.exalted;
    if (_debilitationSigns[planet] == sign) return _Dignity.debilitated;
    if (_ownSigns[planet]!.contains(sign)) return _Dignity.ownSign;
    return _Dignity.neutral;
  }

  static double _combustionThreshold(String planet, bool retrograde) =>
      switch (planet) {
        'moon' => 12.0,
        'mars' => retrograde ? 8.0 : 17.0,
        'mercury' => retrograde ? 12.0 : 14.0,
        'jupiter' => 11.0,
        'venus' => retrograde ? 8.0 : 10.0,
        'saturn' => 16.0,
        _ => throw ArgumentError.value(planet, 'planet'),
      };

  static double _angularSeparation(double first, double second) {
    final direct = (first - second).abs();
    return direct <= 180.0 ? direct : 360.0 - direct;
  }

  static Map<String, _Planet> _requiredPlanets(Object? raw) {
    if (raw is! List) throw StateError('Missing or invalid planets');
    final result = <String, _Planet>{};
    for (var i = 0; i < raw.length; i += 1) {
      final map = _requiredMap(raw[i], 'planets[$i]');
      final body = map['body'];
      if (body is! String || body.trim().isEmpty) {
        throw StateError('Missing planet body at index $i');
      }
      final sign = _requiredSignIndex(map['signIndex'], 'planets[$i].signIndex');
      final longitude =
          _requiredLongitude(map['siderealLongitude'], 'planets[$i].siderealLongitude');
      if ((longitude ~/ 30) != sign) {
        throw StateError('Planet sign and longitude disagree at index $i');
      }
      final calculatedD9 = _navamsaSignIndex(longitude);
      final suppliedD9 = map['navamsaSignIndex'];
      final d9 = suppliedD9 == null
          ? calculatedD9
          : _requiredSignIndex(suppliedD9, 'planets[$i].navamsaSignIndex');
      if (d9 != calculatedD9) {
        throw StateError('Planet Navamsha and longitude disagree at index $i');
      }
      final retrograde = map['retrograde'];
      if (retrograde is! bool) {
        throw StateError('Missing or invalid planets[$i].retrograde');
      }
      result[body] = _Planet(sign, longitude, d9, retrograde);
    }
    return result;
  }

  static Map<String, Object?> _requiredMap(Object? value, String path) {
    if (value is! Map) throw StateError('Missing or invalid $path');
    return Map<String, Object?>.from(value);
  }

  static int _requiredSignIndex(Object? value, String path) {
    if (value is! num || value.toInt() < 0 || value.toInt() > 11) {
      throw StateError('Missing or invalid $path');
    }
    return value.toInt();
  }

  static double _requiredLongitude(Object? value, String path) {
    if (value is! num ||
        !value.toDouble().isFinite ||
        value.toDouble() < 0 ||
        value.toDouble() >= 360) {
      throw StateError('Missing or invalid $path');
    }
    return value.toDouble();
  }

  static int _navamsaSignIndex(double longitude) =>
      (((longitude * 9.0) / 30.0).floor()) % 12;

  static String _fmt(double? value) =>
      value == null ? 'unavailable' : value.toStringAsFixed(3);

  static const _supportedSchemas = <String>{
    'vedic-chart-v1',
    'vedic-chart-v2',
    'vedic-chart-v3',
    'vedic-chart-v4',
    'vedic-chart-v5',
    'vedic-chart-v6',
    'vedic-chart-v7',
    'vedic-chart-v8',
    'vedic-chart-v9',
    'vedic-chart-v10',
  };
  static const _classicalPlanets = <String>[
    'sun', 'moon', 'mars', 'mercury', 'jupiter', 'venus', 'saturn',
  ];
  static const _signLords = <int, String>{
    0: 'mars', 1: 'venus', 2: 'mercury', 3: 'moon', 4: 'sun',
    5: 'mercury', 6: 'venus', 7: 'mars', 8: 'jupiter', 9: 'saturn',
    10: 'saturn', 11: 'jupiter',
  };
  static const _ownershipScores = <int, int>{
    1: 2, 2: 0, 3: -1, 4: 1, 5: 2, 6: -2,
    7: 0, 8: -2, 9: 2, 10: 1, 11: -1, 12: -1,
  };
  static const _kendraForYoga = {4, 7, 10};
  static const _trikonaForYoga = {5, 9};
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
  static const _planetNamesEn = <String, String>{
    'sun': 'Sun', 'moon': 'Moon', 'mars': 'Mars', 'mercury': 'Mercury',
    'jupiter': 'Jupiter', 'venus': 'Venus', 'saturn': 'Saturn',
  };
  static const _planetNamesBn = <String, String>{
    'sun': 'সূর্য', 'moon': 'চন্দ্র', 'mars': 'মঙ্গল', 'mercury': 'বুধ',
    'jupiter': 'বৃহস্পতি', 'venus': 'শুক্র', 'saturn': 'শনি',
  };
  static const _dignityEn = <_Dignity, String>{
    _Dignity.exalted: 'exalted',
    _Dignity.ownSign: 'own-sign',
    _Dignity.debilitated: 'debilitated',
    _Dignity.neutral: 'neutral',
  };
  static const _dignityBn = <_Dignity, String>{
    _Dignity.exalted: 'উচ্চ',
    _Dignity.ownSign: 'নিজ রাশি',
    _Dignity.debilitated: 'নীচ',
    _Dignity.neutral: 'সম',
  };
  static const _gemstones = <String, _Gem>{
    'sun': _Gem('Ruby', 'রুবি/মাণিক্য'),
    'moon': _Gem('Pearl', 'মুক্তা'),
    'mars': _Gem('Red Coral', 'লাল প্রবাল'),
    'mercury': _Gem('Emerald', 'পান্না'),
    'jupiter': _Gem('Yellow Sapphire', 'পোখরাজ'),
    'venus': _Gem('Diamond', 'হীরা'),
    'saturn': _Gem('Blue Sapphire', 'নীলা'),
  };
}

class _Planet {
  const _Planet(this.signIndex, this.siderealLongitude, this.navamsaSignIndex, this.retrograde);
  final int signIndex;
  final double siderealLongitude;
  final int navamsaSignIndex;
  final bool retrograde;
}

class _FunctionalRole {
  const _FunctionalRole(this.ownedHouses, this.score, this.yogaKaraka);
  final List<int> ownedHouses;
  final int score;
  final bool yogaKaraka;
}

class _DashaContext {
  const _DashaContext(this.active, this.role);
  final bool active;
  final String role;
}

class _Gem {
  const _Gem(this.primary, this.primaryBn);
  final String primary;
  final String primaryBn;
}

enum _Dignity { exalted, ownSign, debilitated, neutral }
