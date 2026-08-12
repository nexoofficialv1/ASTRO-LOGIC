import 'dart:math' as math;

/// Governed deterministic arithmetic used by the KP foundation workspace.
///
/// This engine deliberately does not calculate the Krishnamurti ayanamsha or
/// Placidus house cusps. It classifies already-sidereal longitudes into sign,
/// nakshatra, Vimshottari-proportional sub and review-only KP evidence roles.
class KpFoundationEngine {
  const KpFoundationEngine._();

  static const engineVersion = '1.0.0';
  static const ruleVersion = 'kp-foundation-v1';
  static const subdivisionRuleVersion = 'kp-star-sub-v1';
  static const significatorRuleVersion = 'kp-significator-four-level-v1';
  static const rulingPlanetRuleVersion = 'kp-ruling-planets-seven-role-v1';
  static const cuspFrameworkVersion = 'kp-cusp-classification-v1';

  /// Traditional Vimshottari lord sequence used for KP star/sub arithmetic.
  static const List<String> vimshottariSequence = <String>[
    'ketu',
    'venus',
    'sun',
    'moon',
    'mars',
    'rahu',
    'jupiter',
    'saturn',
    'mercury',
  ];

  static const Map<String, int> vimshottariYears = <String, int>{
    'ketu': 7,
    'venus': 20,
    'sun': 6,
    'moon': 10,
    'mars': 7,
    'rahu': 18,
    'jupiter': 16,
    'saturn': 19,
    'mercury': 17,
  };

  static const List<String> signNames = <String>[
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

  static const List<String> signLords = <String>[
    'mars',
    'venus',
    'mercury',
    'moon',
    'sun',
    'mercury',
    'venus',
    'mars',
    'jupiter',
    'saturn',
    'saturn',
    'jupiter',
  ];

  static const List<String> nakshatraNames = <String>[
    'Ashwini',
    'Bharani',
    'Krittika',
    'Rohini',
    'Mrigashira',
    'Ardra',
    'Punarvasu',
    'Pushya',
    'Ashlesha',
    'Magha',
    'Purva Phalguni',
    'Uttara Phalguni',
    'Hasta',
    'Chitra',
    'Swati',
    'Vishakha',
    'Anuradha',
    'Jyeshtha',
    'Mula',
    'Purva Ashadha',
    'Uttara Ashadha',
    'Shravana',
    'Dhanishta',
    'Shatabhisha',
    'Purva Bhadrapada',
    'Uttara Bhadrapada',
    'Revati',
  ];

  // Exact KP arithmetic is performed in micro-arcseconds. One nakshatra is
  // 13°20' = 48,000 arcseconds. Each sub therefore has an exact integer span
  // because 48,000 / 120 = 400 arcseconds per Vimshottari year.
  static const int _microArcSecondsPerDegree = 3600000000;
  static const int _zodiacMicroArcSeconds = 1296000000000;
  static const int _nakshatraMicroArcSeconds = 48000000000;
  static const int _subUnitMicroArcSeconds = 400000000;

  static KpPointClassification classify(double siderealLongitude) {
    if (!siderealLongitude.isFinite) {
      throw ArgumentError.value(siderealLongitude, 'siderealLongitude');
    }
    final normalized = _normalize(siderealLongitude);
    final micro = _longitudeToMicroArcSeconds(normalized);
    final nakshatraIndex = math.min(26, micro ~/ _nakshatraMicroArcSeconds);
    final nakStart = nakshatraIndex * _nakshatraMicroArcSeconds;
    final elapsed = micro - nakStart;
    final starLord = vimshottariSequence[nakshatraIndex % 9];
    final starSequenceIndex = vimshottariSequence.indexOf(starLord);

    var cumulative = 0;
    String? subLord;
    int? subIndexWithinStar;
    int subStart = 0;
    int subEnd = 0;
    for (var index = 0; index < 9; index++) {
      final lord = vimshottariSequence[(starSequenceIndex + index) % 9];
      final span = _subUnitMicroArcSeconds * vimshottariYears[lord]!;
      final next = cumulative + span;
      // Every interval is [start, end), except the final one which includes
      // the exact rounded end boundary before normalization to the next star.
      if (elapsed < next || index == 8) {
        subLord = lord;
        subIndexWithinStar = index;
        subStart = cumulative;
        subEnd = next;
        break;
      }
      cumulative = next;
    }

    final signIndex = math.min(11, (normalized / 30.0).floor());
    return KpPointClassification(
      siderealLongitude: normalized,
      signIndex: signIndex,
      sign: signNames[signIndex],
      signLord: signLords[signIndex],
      nakshatraIndex: nakshatraIndex,
      nakshatra: nakshatraNames[nakshatraIndex],
      starLord: starLord,
      subLord: subLord!,
      subIndexWithinStar: subIndexWithinStar!,
      starStartLongitude: _microToDegrees(nakStart),
      starEndLongitude: _microToDegrees(nakStart + _nakshatraMicroArcSeconds),
      subStartLongitude: _microToDegrees(nakStart + subStart),
      subEndLongitude: _microToDegrees(nakStart + subEnd),
    );
  }

  static List<KpCuspClassification> classifyCusps(
    List<double> siderealCuspLongitudes,
  ) {
    if (siderealCuspLongitudes.length != 12) {
      throw ArgumentError.value(
        siderealCuspLongitudes.length,
        'siderealCuspLongitudes',
        'KP cusp framework requires exactly 12 already-sidereal cusps',
      );
    }
    return List<KpCuspClassification>.generate(
      12,
      (index) => KpCuspClassification(
        house: index + 1,
        point: classify(siderealCuspLongitudes[index]),
      ),
      growable: false,
    );
  }

  static KpRulingPlanetPanel rulingPlanets({
    required double ascendantSiderealLongitude,
    required double moonSiderealLongitude,
    required int weekday,
  }) {
    if (weekday < DateTime.monday || weekday > DateTime.sunday) {
      throw ArgumentError.value(weekday, 'weekday');
    }
    final asc = classify(ascendantSiderealLongitude);
    final moon = classify(moonSiderealLongitude);
    final dayLord = _weekdayLords[weekday]!;

    final roles = <KpRulingPlanetRole>[
      KpRulingPlanetRole(
        rank: 1,
        role: 'ascendantSubLord',
        planet: asc.subLord,
      ),
      KpRulingPlanetRole(
        rank: 2,
        role: 'ascendantStarLord',
        planet: asc.starLord,
      ),
      KpRulingPlanetRole(
        rank: 3,
        role: 'moonStarLord',
        planet: moon.starLord,
      ),
      KpRulingPlanetRole(
        rank: 4,
        role: 'ascendantSignLord',
        planet: asc.signLord,
      ),
      KpRulingPlanetRole(
        rank: 5,
        role: 'moonSignLord',
        planet: moon.signLord,
      ),
      KpRulingPlanetRole(
        rank: 6,
        role: 'moonSubLord',
        planet: moon.subLord,
      ),
      KpRulingPlanetRole(
        rank: 7,
        role: 'dayLord',
        planet: dayLord,
      ),
    ];

    final seen = <String>{};
    final uniquePlanets = <String>[];
    for (final role in roles) {
      if (seen.add(role.planet)) uniquePlanets.add(role.planet);
    }
    return KpRulingPlanetPanel(
      ruleVersion: rulingPlanetRuleVersion,
      roles: List.unmodifiable(roles),
      uniquePlanets: List.unmodifiable(uniquePlanets),
    );
  }

  /// Four-level house-significator evidence collector.
  ///
  /// It does not decide whether a promised event will occur. It keeps the
  /// common KP hierarchy explicit so a practitioner can review each house link.
  static KpSignificatorProfile buildSignificator({
    required String planet,
    required int occupiedHouse,
    required Iterable<int> ownedHouses,
    required String starLord,
    required int starLordOccupiedHouse,
    required Iterable<int> starLordOwnedHouses,
  }) {
    final normalizedPlanet = _requirePlanet(planet, 'planet');
    final normalizedStarLord = _requirePlanet(starLord, 'starLord');
    final level1 = _validatedHouses(<int>[starLordOccupiedHouse]);
    final level2 = _validatedHouses(<int>[occupiedHouse]);
    final level3 = _validatedHouses(starLordOwnedHouses);
    final level4 = _validatedHouses(ownedHouses);
    return KpSignificatorProfile(
      ruleVersion: significatorRuleVersion,
      planet: normalizedPlanet,
      starLord: normalizedStarLord,
      levels: <KpSignificatorLevel>[
        KpSignificatorLevel(
          level: 1,
          source: 'starLordOccupancy',
          houses: level1,
        ),
        KpSignificatorLevel(
          level: 2,
          source: 'planetOccupancy',
          houses: level2,
        ),
        KpSignificatorLevel(
          level: 3,
          source: 'starLordOwnership',
          houses: level3,
        ),
        KpSignificatorLevel(
          level: 4,
          source: 'planetOwnership',
          houses: level4,
        ),
      ],
    );
  }

  static List<int> _validatedHouses(Iterable<int> values) {
    final result = <int>[];
    for (final value in values) {
      if (value < 1 || value > 12) {
        throw ArgumentError.value(value, 'house', 'House must be 1..12');
      }
      if (!result.contains(value)) result.add(value);
    }
    return List.unmodifiable(result);
  }

  static String _requirePlanet(String value, String name) {
    final normalized = value.trim().toLowerCase();
    if (!vimshottariSequence.contains(normalized)) {
      throw ArgumentError.value(value, name, 'Unknown KP/Vimshottari lord');
    }
    return normalized;
  }

  static int _longitudeToMicroArcSeconds(double normalizedDegrees) {
    var value = (normalizedDegrees * _microArcSecondsPerDegree).round();
    if (value >= _zodiacMicroArcSeconds) value = 0;
    return value;
  }

  static double _microToDegrees(int microArcSeconds) =>
      microArcSeconds / _microArcSecondsPerDegree;

  static double _normalize(double value) {
    final normalized = value % 360.0;
    return normalized < 0 ? normalized + 360.0 : normalized;
  }

  static const Map<int, String> _weekdayLords = <int, String>{
    DateTime.monday: 'moon',
    DateTime.tuesday: 'mars',
    DateTime.wednesday: 'mercury',
    DateTime.thursday: 'jupiter',
    DateTime.friday: 'venus',
    DateTime.saturday: 'saturn',
    DateTime.sunday: 'sun',
  };
}

class KpPointClassification {
  const KpPointClassification({
    required this.siderealLongitude,
    required this.signIndex,
    required this.sign,
    required this.signLord,
    required this.nakshatraIndex,
    required this.nakshatra,
    required this.starLord,
    required this.subLord,
    required this.subIndexWithinStar,
    required this.starStartLongitude,
    required this.starEndLongitude,
    required this.subStartLongitude,
    required this.subEndLongitude,
  });

  final double siderealLongitude;
  final int signIndex;
  final String sign;
  final String signLord;
  final int nakshatraIndex;
  final String nakshatra;
  final String starLord;
  final String subLord;
  final int subIndexWithinStar;
  final double starStartLongitude;
  final double starEndLongitude;
  final double subStartLongitude;
  final double subEndLongitude;

  Map<String, Object?> toJson() => <String, Object?>{
        'ruleVersion': KpFoundationEngine.subdivisionRuleVersion,
        'siderealLongitude': siderealLongitude,
        'signIndex': signIndex,
        'sign': sign,
        'signLord': signLord,
        'nakshatraIndex': nakshatraIndex,
        'nakshatra': nakshatra,
        'starLord': starLord,
        'subLord': subLord,
        'subIndexWithinStar': subIndexWithinStar,
        'starStartLongitude': starStartLongitude,
        'starEndLongitude': starEndLongitude,
        'subStartLongitude': subStartLongitude,
        'subEndLongitude': subEndLongitude,
      };
}

class KpCuspClassification {
  const KpCuspClassification({required this.house, required this.point});

  final int house;
  final KpPointClassification point;

  Map<String, Object?> toJson() => <String, Object?>{
        'house': house,
        'point': point.toJson(),
      };
}

class KpRulingPlanetRole {
  const KpRulingPlanetRole({
    required this.rank,
    required this.role,
    required this.planet,
  });

  final int rank;
  final String role;
  final String planet;
}

class KpRulingPlanetPanel {
  const KpRulingPlanetPanel({
    required this.ruleVersion,
    required this.roles,
    required this.uniquePlanets,
  });

  final String ruleVersion;
  final List<KpRulingPlanetRole> roles;
  final List<String> uniquePlanets;
}

class KpSignificatorLevel {
  const KpSignificatorLevel({
    required this.level,
    required this.source,
    required this.houses,
  });

  final int level;
  final String source;
  final List<int> houses;
}

class KpSignificatorProfile {
  const KpSignificatorProfile({
    required this.ruleVersion,
    required this.planet,
    required this.starLord,
    required this.levels,
  });

  final String ruleVersion;
  final String planet;
  final String starLord;
  final List<KpSignificatorLevel> levels;

  List<int> get combinedHouses {
    final values = <int>[];
    for (final level in levels) {
      for (final house in level.houses) {
        if (!values.contains(house)) values.add(house);
      }
    }
    return List.unmodifiable(values);
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'ruleVersion': ruleVersion,
        'planet': planet,
        'starLord': starLord,
        'levels': levels
            .map((level) => <String, Object?>{
                  'level': level.level,
                  'source': level.source,
                  'houses': level.houses,
                })
            .toList(growable: false),
        'combinedHouses': combinedHouses,
      };
}
