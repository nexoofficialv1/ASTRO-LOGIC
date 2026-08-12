import '../models/astrology_settings.dart';
import 'western_governance.dart';
import 'western_native_bridge.dart';

enum WesternBody {
  sun,
  moon,
  mercury,
  venus,
  mars,
  jupiter,
  saturn,
  uranus,
  neptune,
  pluto,
  northNode,
  southNode,
}

enum WesternAspectType {
  conjunction,
  semisextile,
  semisquare,
  sextile,
  quintile,
  square,
  trine,
  sesquiquadrate,
  quincunx,
  opposition,
}

enum WesternAspectMotion { exact, applying, separating }

enum WesternDignityCondition { domicile, exaltation, detriment, fall }

enum WesternAspectPatternType {
  grandTrine,
  tSquare,
  grandCross,
  stellium,
  yod,
  kite,
}

class WesternChartInput {
  const WesternChartInput({
    required this.utc,
    required this.latitude,
    required this.longitude,
    required this.houseSystem,
    required this.nodeMode,
    required this.rulershipProfile,
    required this.aspectProfile,
    required this.includeModernPlanets,
  });

  final DateTime utc;
  final double latitude;
  final double longitude;
  final WesternHouseSystem houseSystem;
  final LunarNodeMode nodeMode;
  final WesternRulershipProfile rulershipProfile;
  final WesternAspectProfile aspectProfile;
  final bool includeModernPlanets;

  Map<String, Object?> toJson() => {
        'utc': utc.toUtc().toIso8601String(),
        'latitude': latitude,
        'longitude': longitude,
        'houseSystem': houseSystem.name,
        'nodeMode': nodeMode.name,
        'rulershipProfile': rulershipProfile.name,
        'aspectProfile': aspectProfile.name,
        'minorAspectEnabled':
            WesternGovernance.minorAspectsEnabled(aspectProfile),
        'includeModernPlanets': includeModernPlanets,
        'zodiacProfile': WesternGovernance.tropicalProfile,
        'houseProfile': WesternGovernance.houseProfile(houseSystem),
        'aspectProfileVersion':
            WesternGovernance.aspectProfileId(aspectProfile),
        'rulershipProfileVersion':
            WesternGovernance.rulershipProfileId(rulershipProfile),
        'modernPlanetProfile': WesternGovernance.modernPlanetProfile,
        'dignityProfile': WesternGovernance.dignityProfile,
      };
}

class WesternChartPoint {
  const WesternChartPoint({
    required this.body,
    required this.longitude,
    required this.eclipticLatitude,
    required this.longitudeSpeedPerDay,
    required this.signIndex,
    required this.house,
  });

  final WesternBody body;
  final double longitude;
  final double eclipticLatitude;
  final double? longitudeSpeedPerDay;
  final int signIndex;
  final int house;

  String get signName => WesternChartEngine.signNames[signIndex];

  Map<String, Object?> toJson() => {
        'body': body.name,
        'tropicalLongitude': longitude,
        'eclipticLatitude': eclipticLatitude,
        'longitudeSpeedPerDay': longitudeSpeedPerDay,
        'signIndex': signIndex,
        'sign': signName,
        'house': house,
        'isModernPlanet': WesternChartEngine.modernBodies.contains(body),
      };
}

class WesternHouseCusp {
  const WesternHouseCusp({required this.house, required this.longitude});

  final int house;
  final double longitude;

  int get signIndex => (longitude / 30.0).floor() % 12;
  String get signName => WesternChartEngine.signNames[signIndex];

  Map<String, Object?> toJson() => {
        'house': house,
        'tropicalLongitude': longitude,
        'signIndex': signIndex,
        'sign': signName,
      };
}

class WesternAspectEvidence {
  const WesternAspectEvidence({
    required this.first,
    required this.second,
    required this.aspect,
    required this.exactAngle,
    required this.orbLimit,
    required this.actualSeparation,
    required this.orb,
    required this.motion,
  });

  final WesternBody first;
  final WesternBody second;
  final WesternAspectType aspect;
  final double exactAngle;
  final double orbLimit;
  final double actualSeparation;
  final double orb;
  final WesternAspectMotion motion;

  bool get isMinor => WesternChartEngine.minorAspects.contains(aspect);

  Map<String, Object?> toJson() => {
        'first': first.name,
        'second': second.name,
        'aspect': aspect.name,
        'minor': isMinor,
        'exactAngle': exactAngle,
        'orbLimit': orbLimit,
        'actualSeparation': actualSeparation,
        'orb': orb,
        'motion': motion.name,
      };
}

class WesternDignityEvidence {
  const WesternDignityEvidence({
    required this.body,
    required this.signIndex,
    required this.conditions,
  });

  final WesternBody body;
  final int signIndex;
  final List<WesternDignityCondition> conditions;

  String get signName => WesternChartEngine.signNames[signIndex];

  Map<String, Object?> toJson() => {
        'body': body.name,
        'signIndex': signIndex,
        'sign': signName,
        'conditions': conditions.map((condition) => condition.name).toList(),
        'numericScoreGenerated': false,
        'profile': WesternGovernance.dignityProfile,
        'modernRulerInjected': false,
      };
}

class WesternRulershipEvidence {
  const WesternRulershipEvidence({
    required this.signIndex,
    required this.ruler,
    required this.profile,
  });

  final int signIndex;
  final String ruler;
  final WesternRulershipProfile profile;

  String get signName => WesternChartEngine.signNames[signIndex];

  Map<String, Object?> toJson() => {
        'signIndex': signIndex,
        'sign': signName,
        'ruler': ruler,
        'profile': profile.name,
        'profileVersion': WesternGovernance.rulershipProfileId(profile),
        'affectsTraditionalDignityScore': false,
      };
}

class WesternAspectPatternEvidence {
  const WesternAspectPatternEvidence({
    required this.type,
    required this.planets,
    required this.componentAspects,
    required this.roles,
  });

  final WesternAspectPatternType type;
  final List<WesternBody> planets;
  final List<WesternAspectEvidence> componentAspects;
  final Map<String, String> roles;

  Map<String, Object?> toJson() => {
        'type': type.name,
        'planets': planets.map((body) => body.name).toList(growable: false),
        'roles': roles,
        'componentAspects': componentAspects
            .map((aspect) => aspect.toJson())
            .toList(growable: false),
        'patternEngineVersion': WesternGovernance.patternProfile,
        'automaticLifeEventPrediction': false,
      };
}

class WesternNatalChart {
  const WesternNatalChart({
    required this.nativeLibraryVersion,
    required this.input,
    required this.ascendantLongitude,
    required this.mcLongitude,
    required this.cusps,
    required this.points,
    required this.aspects,
    required this.patterns,
    required this.dignities,
    required this.rulerships,
  });

  final String nativeLibraryVersion;
  final WesternChartInput input;
  final double ascendantLongitude;
  final double mcLongitude;
  final List<WesternHouseCusp> cusps;
  final List<WesternChartPoint> points;
  final List<WesternAspectEvidence> aspects;
  final List<WesternAspectPatternEvidence> patterns;
  final List<WesternDignityEvidence> dignities;
  final List<WesternRulershipEvidence> rulerships;

  Map<String, Object?> toJson() => {
        'engineId': WesternChartEngine.engineId,
        'engineVersion': WesternChartEngine.engineVersion,
        'outputSchemaVersion': WesternChartEngine.outputSchemaVersion,
        'nativeLibraryVersion': nativeLibraryVersion,
        'input': input.toJson(),
        'governance': {
          'profileVersion': WesternGovernance.profileVersion,
          'zodiacProfile': WesternGovernance.tropicalProfile,
          'houseSystem': input.houseSystem.name,
          'houseProfile': WesternGovernance.houseProfile(input.houseSystem),
          'rulershipProfile': input.rulershipProfile.name,
          'rulershipProfileVersion':
              WesternGovernance.rulershipProfileId(input.rulershipProfile),
          'aspectProfile': input.aspectProfile.name,
          'aspectProfileVersion':
              WesternGovernance.aspectProfileId(input.aspectProfile),
          'minorAspectEnabled':
              WesternGovernance.minorAspectsEnabled(input.aspectProfile),
          'modernPlanetProfile': WesternGovernance.modernPlanetProfile,
          'modernPlanetsEnabled': input.includeModernPlanets,
          'aspectPatternEngineVersion': WesternGovernance.patternProfile,
          'dignityProfile': WesternGovernance.dignityProfile,
          'traditionalDignityAuthoritative': true,
          'modernRulersInjectedIntoTraditionalDignity': false,
          'automaticEventPrediction': false,
          'automaticEventTiming': false,
          'automaticRealWorldPrediction': false,
          'crossSystemConfidenceUplift': false,
        },
        'ascendant': {
          'tropicalLongitude': ascendantLongitude,
          'sign': WesternChartEngine
              .signNames[(ascendantLongitude / 30).floor() % 12],
        },
        'mc': {
          'tropicalLongitude': mcLongitude,
          'sign':
              WesternChartEngine.signNames[(mcLongitude / 30).floor() % 12],
        },
        'cusps': cusps.map((value) => value.toJson()).toList(growable: false),
        'points': points.map((value) => value.toJson()).toList(growable: false),
        'aspects':
            aspects.map((value) => value.toJson()).toList(growable: false),
        'aspectPatterns':
            patterns.map((value) => value.toJson()).toList(growable: false),
        'rulerships':
            rulerships.map((value) => value.toJson()).toList(growable: false),
        'dignities':
            dignities.map((value) => value.toJson()).toList(growable: false),
        'disclosures': const [
          'Tropical longitudes are astronomical chart coordinates; astrological interpretation remains practitioner-review material.',
          'Uranus, Neptune and Pluto use the same native geocentric Astronomy Engine pipeline as the traditional planets; no fabricated or approximate longitude formula is used.',
          'Traditional essential dignity remains restricted to the seven traditional planets. Modern rulership selection changes sign-ruler evidence only and is not silently injected into domicile/exaltation/detriment/fall scoring.',
          'Minor aspects are disabled in the major-only profile and use a versioned ASTRO LOGIC operational orb profile when enabled.',
          'Aspect patterns are emitted only when all required component aspects satisfy the configured governed orb profile. Overlapping or contradictory patterns are preserved.',
          'No automatic real-world prediction or cross-system confidence uplift is generated.',
        ],
      };
}

class WesternChartEngine {
  const WesternChartEngine(this.bridge);

  static const engineId = 'astro-logic-western-native';
  static const engineVersion = '1.1.0';
  static const outputSchemaVersion = 'western-natal-chart-v2';
  static const inputSchemaVersion = 'western-input-schema-v2';

  static const signNames = <String>[
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

  static const modernBodies = <WesternBody>{
    WesternBody.uranus,
    WesternBody.neptune,
    WesternBody.pluto,
  };

  static const minorAspects = <WesternAspectType>{
    WesternAspectType.semisextile,
    WesternAspectType.semisquare,
    WesternAspectType.quintile,
    WesternAspectType.sesquiquadrate,
    WesternAspectType.quincunx,
  };

  static const aspectAngles = <WesternAspectType, double>{
    WesternAspectType.conjunction: 0.0,
    WesternAspectType.semisextile: 30.0,
    WesternAspectType.semisquare: 45.0,
    WesternAspectType.sextile: 60.0,
    WesternAspectType.quintile: 72.0,
    WesternAspectType.square: 90.0,
    WesternAspectType.trine: 120.0,
    WesternAspectType.sesquiquadrate: 135.0,
    WesternAspectType.quincunx: 150.0,
    WesternAspectType.opposition: 180.0,
  };

  static const majorAspectOrbs = <WesternAspectType, double>{
    WesternAspectType.conjunction: 8.0,
    WesternAspectType.sextile: 4.0,
    WesternAspectType.square: 6.0,
    WesternAspectType.trine: 6.0,
    WesternAspectType.opposition: 8.0,
  };

  static const minorAspectOrbs = <WesternAspectType, double>{
    WesternAspectType.semisextile: 2.0,
    WesternAspectType.semisquare: 2.0,
    WesternAspectType.quintile: 2.0,
    WesternAspectType.sesquiquadrate: 2.0,
    WesternAspectType.quincunx: 3.0,
  };

  final WesternNativeBridge bridge;

  Future<WesternNatalChart> cast(WesternChartInput input) async {
    final utc = input.utc.toUtc();
    _validate(input, utc);

    final frame = await bridge.calculateFrame(
      utc: utc,
      latitude: input.latitude,
      longitude: input.longitude,
    );
    final cusps = _buildCusps(input.houseSystem, frame);

    final nativeBodies = input.includeModernPlanets
        ? _nativeBodyMap
        : Map<WesternBody, WesternNativeBody>.fromEntries(
            _nativeBodyMap.entries.where(
              (entry) => !modernBodies.contains(entry.key),
            ),
          );
    final rawPoints = <WesternBody, WesternNativePositionData>{};
    for (final entry in nativeBodies.entries) {
      rawPoints[entry.key] =
          await bridge.calculatePosition(body: entry.value, utc: utc);
    }

    final nodeLongitude = input.nodeMode == LunarNodeMode.trueNode
        ? frame.trueNodeTropical
        : frame.meanNodeTropical;

    final points = <WesternChartPoint>[];
    for (final body in nativeBodies.keys) {
      final raw = rawPoints[body]!;
      final longitude = _normalize(raw.tropicalLongitude);
      points.add(
        WesternChartPoint(
          body: body,
          longitude: longitude,
          eclipticLatitude: raw.eclipticLatitude,
          longitudeSpeedPerDay: raw.longitudeSpeedPerDay,
          signIndex: (longitude / 30.0).floor() % 12,
          house: houseForLongitude(longitude, cusps),
        ),
      );
    }

    final north = _normalize(nodeLongitude);
    final south = _normalize(nodeLongitude + 180.0);
    points.add(
      WesternChartPoint(
        body: WesternBody.northNode,
        longitude: north,
        eclipticLatitude: 0,
        longitudeSpeedPerDay: null,
        signIndex: (north / 30.0).floor() % 12,
        house: houseForLongitude(north, cusps),
      ),
    );
    points.add(
      WesternChartPoint(
        body: WesternBody.southNode,
        longitude: south,
        eclipticLatitude: 0,
        longitudeSpeedPerDay: null,
        signIndex: (south / 30.0).floor() % 12,
        house: houseForLongitude(south, cusps),
      ),
    );

    final aspectPoints = points
        .where(
          (point) =>
              point.body != WesternBody.northNode &&
              point.body != WesternBody.southNode,
        )
        .toList(growable: false);
    final aspects = _buildAspects(aspectPoints, input.aspectProfile);
    final traditional = points
        .where((point) => _traditionalBodies.contains(point.body))
        .toList(growable: false);

    return WesternNatalChart(
      nativeLibraryVersion: bridge.libraryVersion,
      input: input,
      ascendantLongitude: _normalize(frame.tropicalAscendant),
      mcLongitude: _normalize(frame.tropicalMc),
      cusps: List.unmodifiable(cusps),
      points: List.unmodifiable(points),
      aspects: List.unmodifiable(aspects),
      patterns: List.unmodifiable(
        _buildPatterns(
          aspectPoints,
          aspects,
          input.aspectProfile,
        ),
      ),
      dignities: List.unmodifiable(_buildDignities(traditional)),
      rulerships: List.unmodifiable(_buildRulerships(input.rulershipProfile)),
    );
  }

  static int houseForLongitude(
    double longitude,
    List<WesternHouseCusp> cusps,
  ) {
    if (cusps.length != 12) {
      throw ArgumentError('Exactly 12 house cusps are required');
    }
    final target = _normalize(longitude);
    for (var i = 0; i < 12; i++) {
      final start = _normalize(cusps[i].longitude);
      final end = _normalize(cusps[(i + 1) % 12].longitude);
      if (_isInForwardArc(target, start, end)) return i + 1;
    }
    throw StateError('Longitude could not be assigned to a Western house');
  }

  List<WesternHouseCusp> _buildCusps(
    WesternHouseSystem system,
    WesternNativeFrameData frame,
  ) {
    final asc = _normalize(frame.tropicalAscendant);
    final values = switch (system) {
      WesternHouseSystem.placidus => frame.placidusAvailable
          ? frame.tropicalCusps
          : throw StateError(
              'Placidus houses are unavailable for this latitude; no fallback house system was substituted.',
            ),
      WesternHouseSystem.wholeSign => List<double>.generate(
          12,
          (index) => _normalize((asc / 30.0).floor() * 30.0 + index * 30.0),
          growable: false,
        ),
      WesternHouseSystem.equal => List<double>.generate(
          12,
          (index) => _normalize(asc + index * 30.0),
          growable: false,
        ),
    };
    if (values.length != 12) {
      throw StateError('Western house engine did not return 12 cusps');
    }
    return List<WesternHouseCusp>.generate(
      12,
      (index) => WesternHouseCusp(
        house: index + 1,
        longitude: _normalize(values[index]),
      ),
      growable: false,
    );
  }

  List<WesternAspectEvidence> _buildAspects(
    List<WesternChartPoint> points,
    WesternAspectProfile profile,
  ) {
    final enabled = <WesternAspectType, double>{...majorAspectOrbs};
    if (WesternGovernance.minorAspectsEnabled(profile)) {
      enabled.addAll(minorAspectOrbs);
    }
    final result = <WesternAspectEvidence>[];
    for (var i = 0; i < points.length; i++) {
      for (var j = i + 1; j < points.length; j++) {
        final first = points[i];
        final second = points[j];
        final separation = _angularSeparation(first.longitude, second.longitude);
        WesternAspectType? best;
        var bestOrb = double.infinity;
        var bestLimit = 0.0;
        for (final entry in enabled.entries) {
          final exact = aspectAngles[entry.key]!;
          final orb = (separation - exact).abs();
          if (orb <= entry.value && orb < bestOrb) {
            best = entry.key;
            bestOrb = orb;
            bestLimit = entry.value;
          }
        }
        if (best == null) continue;
        final exactAngle = aspectAngles[best]!;
        result.add(
          WesternAspectEvidence(
            first: first.body,
            second: second.body,
            aspect: best,
            exactAngle: exactAngle,
            orbLimit: bestLimit,
            actualSeparation: separation,
            orb: bestOrb,
            motion: _aspectMotion(first, second, exactAngle, bestOrb),
          ),
        );
      }
    }
    result.sort((a, b) {
      final byOrb = a.orb.compareTo(b.orb);
      if (byOrb != 0) return byOrb;
      final byFirst = a.first.index.compareTo(b.first.index);
      return byFirst != 0 ? byFirst : a.second.index.compareTo(b.second.index);
    });
    return result;
  }

  WesternAspectMotion _aspectMotion(
    WesternChartPoint first,
    WesternChartPoint second,
    double exactAngle,
    double currentOrb,
  ) {
    if (currentOrb <= 0.000001) return WesternAspectMotion.exact;
    final firstSpeed = first.longitudeSpeedPerDay;
    final secondSpeed = second.longitudeSpeedPerDay;
    if (firstSpeed == null || secondSpeed == null) {
      return WesternAspectMotion.separating;
    }
    const sampleDays = 1.0 / 24.0;
    final futureSeparation = _angularSeparation(
      _normalize(first.longitude + firstSpeed * sampleDays),
      _normalize(second.longitude + secondSpeed * sampleDays),
    );
    final futureOrb = (futureSeparation - exactAngle).abs();
    if ((futureOrb - currentOrb).abs() <= 0.0000001) {
      return WesternAspectMotion.exact;
    }
    return futureOrb < currentOrb
        ? WesternAspectMotion.applying
        : WesternAspectMotion.separating;
  }

  List<WesternAspectPatternEvidence> _buildPatterns(
    List<WesternChartPoint> points,
    List<WesternAspectEvidence> aspects,
    WesternAspectProfile profile,
  ) {
    final byPair = <String, WesternAspectEvidence>{};
    for (final aspect in aspects) {
      byPair[_pairKey(aspect.first, aspect.second)] = aspect;
    }
    WesternAspectEvidence? get(
      WesternBody a,
      WesternBody b,
      WesternAspectType type,
    ) {
      final value = byPair[_pairKey(a, b)];
      return value?.aspect == type ? value : null;
    }

    final result = <WesternAspectPatternEvidence>[];
    final seen = <String>{};

    void addPattern(
      WesternAspectPatternType type,
      List<WesternBody> bodies,
      List<WesternAspectEvidence> components,
      Map<String, String> roles,
    ) {
      final ordered = [...bodies]..sort((a, b) => a.index.compareTo(b.index));
      final key = '${type.name}:${ordered.map((body) => body.name).join(',')}';
      if (!seen.add(key)) return;
      final sortedComponents = [...components]
        ..sort((a, b) => a.orb.compareTo(b.orb));
      result.add(
        WesternAspectPatternEvidence(
          type: type,
          planets: List.unmodifiable(ordered),
          componentAspects: List.unmodifiable(sortedComponents),
          roles: Map.unmodifiable(roles),
        ),
      );
    }

    for (final combo in _combinations(points.map((p) => p.body).toList(), 3)) {
      final a = combo[0], b = combo[1], c = combo[2];
      final abTrine = get(a, b, WesternAspectType.trine);
      final acTrine = get(a, c, WesternAspectType.trine);
      final bcTrine = get(b, c, WesternAspectType.trine);
      if (abTrine != null && acTrine != null && bcTrine != null) {
        addPattern(
          WesternAspectPatternType.grandTrine,
          combo,
          [abTrine, acTrine, bcTrine],
          const {},
        );
      }

      for (final apex in combo) {
        final base = combo.where((body) => body != apex).toList(growable: false);
        final opposition = get(base[0], base[1], WesternAspectType.opposition);
        final square1 = get(apex, base[0], WesternAspectType.square);
        final square2 = get(apex, base[1], WesternAspectType.square);
        if (opposition != null && square1 != null && square2 != null) {
          addPattern(
            WesternAspectPatternType.tSquare,
            combo,
            [opposition, square1, square2],
            {
              apex.name: 'apex',
              base[0].name: 'oppositionBase',
              base[1].name: 'oppositionBase',
            },
          );
        }
      }

      if (WesternGovernance.minorAspectsEnabled(profile)) {
        for (final apex in combo) {
          final base = combo.where((body) => body != apex).toList(growable: false);
          final sextile = get(base[0], base[1], WesternAspectType.sextile);
          final q1 = get(apex, base[0], WesternAspectType.quincunx);
          final q2 = get(apex, base[1], WesternAspectType.quincunx);
          if (sextile != null && q1 != null && q2 != null) {
            addPattern(
              WesternAspectPatternType.yod,
              combo,
              [sextile, q1, q2],
              {
                apex.name: 'apex',
                base[0].name: 'sextileBase',
                base[1].name: 'sextileBase',
              },
            );
          }
        }
      }
    }

    for (final combo in _combinations(points.map((p) => p.body).toList(), 4)) {
      final pairAspects = <WesternAspectEvidence>[];
      for (final pair in _combinations(combo, 2)) {
        final value = byPair[_pairKey(pair[0], pair[1])];
        if (value != null) pairAspects.add(value);
      }
      final oppositions = pairAspects
          .where((a) => a.aspect == WesternAspectType.opposition)
          .toList(growable: false);
      final squares = pairAspects
          .where((a) => a.aspect == WesternAspectType.square)
          .toList(growable: false);
      if (oppositions.length == 2 && squares.length == 4) {
        final degrees = <WesternBody, int>{for (final body in combo) body: 0};
        for (final opposition in oppositions) {
          degrees[opposition.first] = degrees[opposition.first]! + 1;
          degrees[opposition.second] = degrees[opposition.second]! + 1;
        }
        final validOppositionPairing = degrees.values.every((count) => count == 1);
        if (validOppositionPairing) {
          addPattern(
            WesternAspectPatternType.grandCross,
            combo,
            [...oppositions, ...squares],
            const {},
          );
        }
      }

      for (final trineSet in _combinations(combo, 3)) {
        final tail = combo.firstWhere((body) => !trineSet.contains(body));
        final t1 = get(trineSet[0], trineSet[1], WesternAspectType.trine);
        final t2 = get(trineSet[0], trineSet[2], WesternAspectType.trine);
        final t3 = get(trineSet[1], trineSet[2], WesternAspectType.trine);
        if (t1 == null || t2 == null || t3 == null) continue;
        for (final opposedVertex in trineSet) {
          final other = trineSet
              .where((body) => body != opposedVertex)
              .toList(growable: false);
          final opposition =
              get(tail, opposedVertex, WesternAspectType.opposition);
          final s1 = get(tail, other[0], WesternAspectType.sextile);
          final s2 = get(tail, other[1], WesternAspectType.sextile);
          if (opposition != null && s1 != null && s2 != null) {
            addPattern(
              WesternAspectPatternType.kite,
              combo,
              [t1, t2, t3, opposition, s1, s2],
              {
                tail.name: 'tail',
                opposedVertex.name: 'opposedGrandTrineVertex',
                other[0].name: 'grandTrineVertex',
                other[1].name: 'grandTrineVertex',
              },
            );
          }
        }
      }
    }

    final bodies = points.map((p) => p.body).toList(growable: false);
    for (var size = 3; size <= bodies.length; size++) {
      for (final combo in _combinations(bodies, size)) {
        final conjunctions = <WesternAspectEvidence>[];
        var clique = true;
        for (final pair in _combinations(combo, 2)) {
          final conjunction =
              get(pair[0], pair[1], WesternAspectType.conjunction);
          if (conjunction == null) {
            clique = false;
            break;
          }
          conjunctions.add(conjunction);
        }
        if (!clique) continue;
        final extendable = bodies.any((candidate) {
          if (combo.contains(candidate)) return false;
          return combo.every(
            (member) =>
                get(candidate, member, WesternAspectType.conjunction) != null,
          );
        });
        if (!extendable) {
          addPattern(
            WesternAspectPatternType.stellium,
            combo,
            conjunctions,
            const {},
          );
        }
      }
    }

    result.sort((a, b) {
      final byType = a.type.index.compareTo(b.type.index);
      if (byType != 0) return byType;
      return a.planets.length.compareTo(b.planets.length);
    });
    return result;
  }

  List<WesternDignityEvidence> _buildDignities(
    List<WesternChartPoint> points,
  ) =>
      points.map((point) {
        final conditions = <WesternDignityCondition>[];
        final signs = _dignitySigns[point.body];
        if (signs != null) {
          if (signs.domicile.contains(point.signIndex)) {
            conditions.add(WesternDignityCondition.domicile);
          }
          if (signs.exaltation.contains(point.signIndex)) {
            conditions.add(WesternDignityCondition.exaltation);
          }
          if (signs.detriment.contains(point.signIndex)) {
            conditions.add(WesternDignityCondition.detriment);
          }
          if (signs.fall.contains(point.signIndex)) {
            conditions.add(WesternDignityCondition.fall);
          }
        }
        return WesternDignityEvidence(
          body: point.body,
          signIndex: point.signIndex,
          conditions: List.unmodifiable(conditions),
        );
      }).toList(growable: false);

  List<WesternRulershipEvidence> _buildRulerships(
    WesternRulershipProfile profile,
  ) =>
      List<WesternRulershipEvidence>.generate(
        12,
        (signIndex) => WesternRulershipEvidence(
          signIndex: signIndex,
          ruler: WesternGovernance.rulerNameForSign(signIndex, profile),
          profile: profile,
        ),
        growable: false,
      );

  void _validate(WesternChartInput input, DateTime utc) {
    if (!input.latitude.isFinite || input.latitude < -90 || input.latitude > 90) {
      throw ArgumentError('Valid latitude is required');
    }
    if (!input.longitude.isFinite ||
        input.longitude < -180 ||
        input.longitude > 180) {
      throw ArgumentError('Valid longitude is required');
    }
    if (utc.year < WesternGovernance.validatedStartYear ||
        utc.year > WesternGovernance.validatedEndYear) {
      throw RangeError(
        'Western v2 is validated only for '
        '${WesternGovernance.validatedStartYear}–${WesternGovernance.validatedEndYear}',
      );
    }
  }

  static bool _isInForwardArc(double target, double start, double end) {
    final span = _normalize(end - start);
    final offset = _normalize(target - start);
    if (span == 0) return false;
    return offset < span || offset == 0;
  }

  static double _angularSeparation(double first, double second) {
    final diff = (_normalize(first) - _normalize(second)).abs();
    return diff > 180.0 ? 360.0 - diff : diff;
  }

  static double _normalize(double value) {
    final result = value % 360.0;
    return result < 0 ? result + 360.0 : result;
  }

  static String _pairKey(WesternBody first, WesternBody second) {
    final a = first.index <= second.index ? first : second;
    final b = first.index <= second.index ? second : first;
    return '${a.name}:${b.name}';
  }

  static List<List<T>> _combinations<T>(List<T> values, int size) {
    final result = <List<T>>[];
    void visit(int start, List<T> current) {
      if (current.length == size) {
        result.add(List<T>.unmodifiable(current));
        return;
      }
      final remaining = size - current.length;
      for (var i = start; i <= values.length - remaining; i++) {
        current.add(values[i]);
        visit(i + 1, current);
        current.removeLast();
      }
    }

    if (size > 0 && size <= values.length) visit(0, <T>[]);
    return result;
  }

  static const _traditionalBodies = <WesternBody>{
    WesternBody.sun,
    WesternBody.moon,
    WesternBody.mercury,
    WesternBody.venus,
    WesternBody.mars,
    WesternBody.jupiter,
    WesternBody.saturn,
  };

  static const _nativeBodyMap = <WesternBody, WesternNativeBody>{
    WesternBody.sun: WesternNativeBody.sun,
    WesternBody.moon: WesternNativeBody.moon,
    WesternBody.mercury: WesternNativeBody.mercury,
    WesternBody.venus: WesternNativeBody.venus,
    WesternBody.mars: WesternNativeBody.mars,
    WesternBody.jupiter: WesternNativeBody.jupiter,
    WesternBody.saturn: WesternNativeBody.saturn,
    WesternBody.uranus: WesternNativeBody.uranus,
    WesternBody.neptune: WesternNativeBody.neptune,
    WesternBody.pluto: WesternNativeBody.pluto,
  };

  static const _dignitySigns = <WesternBody, _WesternDignitySigns>{
    WesternBody.sun: _WesternDignitySigns(
      domicile: [4],
      exaltation: [0],
      detriment: [10],
      fall: [6],
    ),
    WesternBody.moon: _WesternDignitySigns(
      domicile: [3],
      exaltation: [1],
      detriment: [9],
      fall: [7],
    ),
    WesternBody.mercury: _WesternDignitySigns(
      domicile: [2, 5],
      exaltation: [5],
      detriment: [8, 11],
      fall: [11],
    ),
    WesternBody.venus: _WesternDignitySigns(
      domicile: [1, 6],
      exaltation: [11],
      detriment: [0, 7],
      fall: [5],
    ),
    WesternBody.mars: _WesternDignitySigns(
      domicile: [0, 7],
      exaltation: [9],
      detriment: [1, 6],
      fall: [3],
    ),
    WesternBody.jupiter: _WesternDignitySigns(
      domicile: [8, 11],
      exaltation: [3],
      detriment: [2, 5],
      fall: [9],
    ),
    WesternBody.saturn: _WesternDignitySigns(
      domicile: [9, 10],
      exaltation: [6],
      detriment: [3, 4],
      fall: [0],
    ),
  };
}

class _WesternDignitySigns {
  const _WesternDignitySigns({
    required this.domicile,
    required this.exaltation,
    required this.detriment,
    required this.fall,
  });

  final List<int> domicile;
  final List<int> exaltation;
  final List<int> detriment;
  final List<int> fall;
}
