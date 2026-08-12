import 'package:flutter_test/flutter_test.dart';

import 'package:astro_logic/src/models/astrology_settings.dart';
import 'package:astro_logic/src/western/western_chart_engine.dart';
import 'package:astro_logic/src/western/western_governance.dart';
import 'package:astro_logic/src/western/western_native_bridge.dart';

class _FakeWesternBridge implements WesternNativeBridge {
  const _FakeWesternBridge({this.longitudes = defaultLongitudes});

  final Map<WesternNativeBody, double> longitudes;

  @override
  String get libraryVersion => 'fake/al-abi-9';

  static const defaultLongitudes = <WesternNativeBody, double>{
    WesternNativeBody.sun: 5.0,
    WesternNativeBody.moon: 65.0,
    WesternNativeBody.mercury: 155.0,
    WesternNativeBody.venus: 335.0,
    WesternNativeBody.mars: 95.0,
    WesternNativeBody.jupiter: 185.0,
    WesternNativeBody.saturn: 275.0,
    WesternNativeBody.uranus: 65.342,
    WesternNativeBody.neptune: 4.082,
    WesternNativeBody.pluto: 303.906,
  };

  @override
  Future<WesternNativeFrameData> calculateFrame({
    required DateTime utc,
    required double latitude,
    required double longitude,
  }) async => const WesternNativeFrameData(
        tropicalAscendant: 15.0,
        tropicalMc: 285.0,
        trueNodeTropical: 45.0,
        meanNodeTropical: 46.0,
        placidusAvailable: true,
        tropicalCusps: <double>[
          15, 45, 75, 105, 135, 165,
          195, 225, 255, 285, 315, 345,
        ],
      );

  @override
  Future<WesternNativePositionData> calculatePosition({
    required WesternNativeBody body,
    required DateTime utc,
  }) async => WesternNativePositionData(
        tropicalLongitude: longitudes[body]!,
        eclipticLatitude: 0,
        longitudeSpeedPerDay:
            body == WesternNativeBody.saturn ? -0.05 : 1.0,
      );
}

WesternChartInput _input({
  WesternHouseSystem houseSystem = WesternHouseSystem.equal,
  LunarNodeMode nodeMode = LunarNodeMode.trueNode,
  WesternRulershipProfile rulershipProfile = WesternRulershipProfile.traditional,
  WesternAspectProfile aspectProfile = WesternAspectProfile.majorOnly,
  bool includeModernPlanets = true,
}) =>
    WesternChartInput(
      utc: DateTime.utc(1984, 3, 12, 18, 42),
      latitude: 23.22,
      longitude: 88.37,
      houseSystem: houseSystem,
      nodeMode: nodeMode,
      rulershipProfile: rulershipProfile,
      aspectProfile: aspectProfile,
      includeModernPlanets: includeModernPlanets,
    );

void main() {
  test('Western v2 includes native modern planets and explicit metadata', () async {
    final chart = await const WesternChartEngine(_FakeWesternBridge()).cast(
      _input(),
    );
    expect(chart.points.length, 12);
    expect(chart.cusps.length, 12);
    expect(chart.points.any((p) => p.body == WesternBody.uranus), isTrue);
    expect(chart.points.any((p) => p.body == WesternBody.neptune), isTrue);
    expect(chart.points.any((p) => p.body == WesternBody.pluto), isTrue);
    expect(chart.points.firstWhere((p) => p.body == WesternBody.sun).signName, 'Aries');
    expect(chart.points.firstWhere((p) => p.body == WesternBody.northNode).longitude, 45.0);
    final json = chart.toJson();
    expect(json['outputSchemaVersion'], WesternChartEngine.outputSchemaVersion);
    final governance = json['governance']! as Map<String, Object?>;
    expect(governance['crossSystemConfidenceUplift'], isFalse);
    expect(governance['automaticRealWorldPrediction'], isFalse);
  });

  test('legacy traditional seven-planet behavior can be retained explicitly', () async {
    final chart = await const WesternChartEngine(_FakeWesternBridge()).cast(
      _input(includeModernPlanets: false),
    );
    expect(chart.points.length, 9);
    expect(chart.points.any((p) => WesternChartEngine.modernBodies.contains(p.body)), isFalse);
    expect(chart.dignities.length, 7);
  });

  test('traditional and modern rulership profiles remain governed and distinct', () async {
    final traditional = await const WesternChartEngine(_FakeWesternBridge()).cast(
      _input(rulershipProfile: WesternRulershipProfile.traditional),
    );
    final modern = await const WesternChartEngine(_FakeWesternBridge()).cast(
      _input(rulershipProfile: WesternRulershipProfile.modern),
    );
    expect(traditional.rulerships[7].ruler, 'mars');
    expect(traditional.rulerships[10].ruler, 'saturn');
    expect(traditional.rulerships[11].ruler, 'jupiter');
    expect(modern.rulerships[7].ruler, 'pluto');
    expect(modern.rulerships[10].ruler, 'uranus');
    expect(modern.rulerships[11].ruler, 'neptune');
    expect(modern.dignities.length, 7);
    expect(modern.dignities.any((d) => WesternChartEngine.modernBodies.contains(d.body)), isFalse);
  });

  test('traditional dignity evidence preserves multiple conditions', () async {
    final chart = await const WesternChartEngine(_FakeWesternBridge()).cast(
      _input(houseSystem: WesternHouseSystem.wholeSign, nodeMode: LunarNodeMode.meanNode),
    );
    final mercury = chart.dignities.firstWhere((d) => d.body == WesternBody.mercury);
    expect(mercury.signName, 'Virgo');
    expect(mercury.conditions, contains(WesternDignityCondition.domicile));
    expect(mercury.conditions, contains(WesternDignityCondition.exaltation));
  });

  test('nodes stay outside the aspect matrix', () async {
    final chart = await const WesternChartEngine(_FakeWesternBridge()).cast(
      _input(houseSystem: WesternHouseSystem.placidus),
    );
    expect(
      chart.aspects.any(
        (a) =>
            a.first == WesternBody.northNode ||
            a.second == WesternBody.northNode ||
            a.first == WesternBody.southNode ||
            a.second == WesternBody.southNode,
      ),
      isFalse,
    );
  });

  test('minor aspects are opt-in and carry operational orb evidence', () async {
    const positions = <WesternNativeBody, double>{
      WesternNativeBody.sun: 0,
      WesternNativeBody.moon: 30,
      WesternNativeBody.mercury: 80,
      WesternNativeBody.venus: 170,
      WesternNativeBody.mars: 250,
      WesternNativeBody.jupiter: 310,
      WesternNativeBody.saturn: 200,
      WesternNativeBody.uranus: 20,
      WesternNativeBody.neptune: 110,
      WesternNativeBody.pluto: 290,
    };
    final engine = const WesternChartEngine(_FakeWesternBridge(longitudes: positions));
    final majorOnly = await engine.cast(_input(aspectProfile: WesternAspectProfile.majorOnly));
    final expanded = await engine.cast(_input(aspectProfile: WesternAspectProfile.majorAndMinor));
    expect(
      majorOnly.aspects.any(
        (a) =>
            {a.first, a.second}.contains(WesternBody.sun) &&
            {a.first, a.second}.contains(WesternBody.moon) &&
            a.aspect == WesternAspectType.semisextile,
      ),
      isFalse,
    );
    final semisextile = expanded.aspects.firstWhere(
      (a) =>
          {a.first, a.second}.contains(WesternBody.sun) &&
          {a.first, a.second}.contains(WesternBody.moon),
    );
    expect(semisextile.aspect, WesternAspectType.semisextile);
    expect(semisextile.exactAngle, 30.0);
    expect(semisextile.orbLimit, WesternChartEngine.minorAspectOrbs[WesternAspectType.semisextile]);
  });

  test('Grand Trine and Kite require complete component aspect evidence', () async {
    const positions = <WesternNativeBody, double>{
      WesternNativeBody.sun: 0,
      WesternNativeBody.moon: 120,
      WesternNativeBody.mercury: 240,
      WesternNativeBody.venus: 180,
      WesternNativeBody.mars: 13,
      WesternNativeBody.jupiter: 43,
      WesternNativeBody.saturn: 73,
      WesternNativeBody.uranus: 103,
      WesternNativeBody.neptune: 133,
      WesternNativeBody.pluto: 163,
    };
    final chart = await const WesternChartEngine(
      _FakeWesternBridge(longitudes: positions),
    ).cast(_input());
    expect(chart.patterns.any((p) => p.type == WesternAspectPatternType.grandTrine), isTrue);
    expect(chart.patterns.any((p) => p.type == WesternAspectPatternType.kite), isTrue);
    expect(chart.patterns.every((p) => p.componentAspects.isNotEmpty), isTrue);
  });

  test('T-Square and Grand Cross use opposition/square geometry', () async {
    const positions = <WesternNativeBody, double>{
      WesternNativeBody.sun: 0,
      WesternNativeBody.moon: 90,
      WesternNativeBody.mercury: 180,
      WesternNativeBody.venus: 270,
      WesternNativeBody.mars: 14,
      WesternNativeBody.jupiter: 44,
      WesternNativeBody.saturn: 74,
      WesternNativeBody.uranus: 104,
      WesternNativeBody.neptune: 134,
      WesternNativeBody.pluto: 164,
    };
    final chart = await const WesternChartEngine(
      _FakeWesternBridge(longitudes: positions),
    ).cast(_input());
    expect(chart.patterns.any((p) => p.type == WesternAspectPatternType.tSquare), isTrue);
    expect(chart.patterns.any((p) => p.type == WesternAspectPatternType.grandCross), isTrue);
  });

  test('Yod is emitted only under the minor-aspect profile', () async {
    const positions = <WesternNativeBody, double>{
      WesternNativeBody.sun: 0,
      WesternNativeBody.moon: 60,
      WesternNativeBody.mercury: 210,
      WesternNativeBody.venus: 22,
      WesternNativeBody.mars: 82,
      WesternNativeBody.jupiter: 112,
      WesternNativeBody.saturn: 172,
      WesternNativeBody.uranus: 252,
      WesternNativeBody.neptune: 292,
      WesternNativeBody.pluto: 332,
    };
    final engine = const WesternChartEngine(_FakeWesternBridge(longitudes: positions));
    final major = await engine.cast(_input(aspectProfile: WesternAspectProfile.majorOnly));
    final minor = await engine.cast(_input(aspectProfile: WesternAspectProfile.majorAndMinor));
    expect(major.patterns.any((p) => p.type == WesternAspectPatternType.yod), isFalse);
    expect(minor.patterns.any((p) => p.type == WesternAspectPatternType.yod), isTrue);
  });

  test('Stellium uses a strict complete-conjunction clique and preserves evidence', () async {
    const positions = <WesternNativeBody, double>{
      WesternNativeBody.sun: 0,
      WesternNativeBody.moon: 4,
      WesternNativeBody.mercury: 8,
      WesternNativeBody.venus: 50,
      WesternNativeBody.mars: 100,
      WesternNativeBody.jupiter: 150,
      WesternNativeBody.saturn: 200,
      WesternNativeBody.uranus: 250,
      WesternNativeBody.neptune: 300,
      WesternNativeBody.pluto: 340,
    };
    final chart = await const WesternChartEngine(
      _FakeWesternBridge(longitudes: positions),
    ).cast(_input());
    final stellium = chart.patterns.firstWhere(
      (p) => p.type == WesternAspectPatternType.stellium,
    );
    expect(stellium.planets.length, greaterThanOrEqualTo(3));
    expect(
      stellium.componentAspects.every(
        (a) => a.aspect == WesternAspectType.conjunction,
      ),
      isTrue,
    );
  });
}
