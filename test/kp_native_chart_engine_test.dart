import 'package:flutter_test/flutter_test.dart';

import 'package:astro_logic/src/kp/kp_governance.dart';
import 'package:astro_logic/src/kp/kp_native_chart_engine.dart';
import 'package:astro_logic/src/models/astrology_settings.dart';

void main() {
  test('native KP chart classifies all nine points and twelve cusps', () async {
    final engine = KpNativeChartEngine(_FakeBridge());
    final chart = await engine.cast(
      KpNativeChartInput(
        utc: DateTime.utc(1984, 3, 12, 18, 42),
        latitude: 23.22,
        longitude: 88.37,
        nodeMode: LunarNodeMode.trueNode,
      ),
    );

    expect(chart.planets, hasLength(9));
    expect(chart.cusps, hasLength(12));
    expect(chart.krishnamurtiAyanamsha, closeTo(23.5395078118, 1e-9));
    expect(chart.ascendant.siderealLongitude, closeTo(236.2935247756, 1e-8));
    expect(chart.rulingPlanets.roles, hasLength(7));
    expect(chart.toJson()['outputSchemaVersion'], 'kp-native-chart-v4');
    expect(chart.houseEvidence.planets, hasLength(9));
    expect(chart.houseEvidence.planet('rahu').ownedHouses, isEmpty);
  });

  test('governance keeps historical ayanamsha ambiguity visible', () {
    expect(KpGovernance.exactChartCastingEnabled, isTrue);
    expect(
      KpGovernance.ayanamshaProfile,
      'kp-krishnamurti-classic-j1900-newcomb-v1',
    );
    expect(KpGovernance.houseProfile, contains('placidus'));
    expect(KpGovernance.englishDisclosure, contains('not perfectly unique'));
  });

  test('native chart validates governed date range', () async {
    final engine = KpNativeChartEngine(_FakeBridge());
    expect(
      () => engine.cast(
        KpNativeChartInput(
          utc: DateTime.utc(2200),
          latitude: 23.22,
          longitude: 88.37,
          nodeMode: LunarNodeMode.trueNode,
        ),
      ),
      throwsA(isA<RangeError>()),
    );
  });
}

class _FakeBridge implements KpNativeBridge {
  @override
  String get libraryVersion => 'fake/al-abi-9';

  @override
  Future<KpNativeFrameData> calculateFrame({
    required DateTime utc,
    required double latitude,
    required double longitude,
  }) async {
    const ayan = 23.5395078118;
    const tropical = <double>[
      259.8330325874,
      291.1655758930,
      325.2763352979,
      359.4110296494,
      29.8853701715,
      56.0324989937,
      79.8330325874,
      111.1655758930,
      145.2763352979,
      179.4110296494,
      209.8853701715,
      236.0324989937,
    ];
    return KpNativeFrameData(
      krishnamurtiAyanamsha: ayan,
      tropicalAscendant: tropical.first,
      tropicalMc: tropical[9],
      siderealAscendant: _normal(tropical.first - ayan),
      siderealMc: _normal(tropical[9] - ayan),
      trueNodeTropical: 70.1004066,
      meanNodeTropical: 70.7318634,
      tropicalCusps: tropical,
      siderealCusps:
          tropical.map((value) => _normal(value - ayan)).toList(),
    );
  }

  @override
  Future<KpNativePositionData> calculatePosition({
    required KpNativeBody body,
    required DateTime utc,
  }) async {
    final values = <KpNativeBody, double>{
      KpNativeBody.sun: 352.3838892,
      KpNativeBody.moon: 107.7246106,
      KpNativeBody.mars: 235.2511681,
      KpNativeBody.mercury: 356.2318337,
      KpNativeBody.jupiter: 279.5631474,
      KpNativeBody.venus: 327.8467585,
      KpNativeBody.saturn: 226.1324506,
    };
    return KpNativePositionData(
      tropicalLongitude: values[body]!,
      eclipticLatitude: 0,
      longitudeSpeedPerDay: 1,
    );
  }

  static double _normal(double value) {
    final result = value % 360;
    return result < 0 ? result + 360 : result;
  }
}
