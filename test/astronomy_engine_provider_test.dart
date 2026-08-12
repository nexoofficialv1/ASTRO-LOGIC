import 'package:astro_logic/src/ephemeris/astronomy_engine_provider.dart';
import 'package:astro_logic/src/ephemeris/ephemeris_engine_policy.dart';
import 'package:astro_logic/src/ephemeris/ephemeris_provider.dart';
import 'package:astro_logic/src/models/astrology_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final request = EphemerisRequest(
    utcDateTime: _utcFixture,
    latitude: 23.22,
    longitude: 88.37,
    ayanamsha: Ayanamsha.lahiri,
    lunarNodeMode: LunarNodeMode.trueNode,
  );

  test('blocks calculation when audited backend is absent', () async {
    final bridge = _FakeBridge();
    final provider = AstronomyEngineEphemerisProvider(
      bridge: bridge,
      enginePolicy: const EphemerisEnginePolicy(
        OfflineEphemerisBackend.unconfigured,
      ),
    );

    await expectLater(provider.calculate(request), throwsStateError);
    expect(bridge.initializeCount, 0);
    expect(bridge.calculateCount, 0);
  });

  test('initializes once and delegates to the configured offline backend',
      () async {
    final bridge = _FakeBridge();
    final provider = AstronomyEngineEphemerisProvider(
      bridge: bridge,
      enginePolicy: const EphemerisEnginePolicy(
        OfflineEphemerisBackend.astronomyEngine,
      ),
    );

    await provider.calculate(request);
    await provider.calculate(request);

    expect(provider.engineId, 'astronomy-engine-mit');
    expect(bridge.initializeCount, 1);
    expect(bridge.calculateCount, 2);
  });

  test('rejects invalid coordinates before native initialization', () async {
    final bridge = _FakeBridge();
    final provider = AstronomyEngineEphemerisProvider(
      bridge: bridge,
      enginePolicy: const EphemerisEnginePolicy(
        OfflineEphemerisBackend.astronomyEngine,
      ),
    );
    final invalidRequest = EphemerisRequest(
      utcDateTime: _utcFixture,
      latitude: 91,
      longitude: 88.37,
      ayanamsha: Ayanamsha.lahiri,
      lunarNodeMode: LunarNodeMode.trueNode,
    );

    await expectLater(provider.calculate(invalidRequest), throwsArgumentError);
    expect(bridge.initializeCount, 0);
    expect(bridge.calculateCount, 0);
  });
}

final _utcFixture = DateTime.utc(1984, 3, 12, 18, 42);

class _FakeBridge implements AstronomyEngineNativeBridge {
  int initializeCount = 0;
  int calculateCount = 0;

  @override
  String get libraryVersion => 'audited-test-fixture';

  @override
  Future<void> initialize() async {
    initializeCount++;
  }

  @override
  Future<EphemerisFrame> calculate(EphemerisRequest request) async {
    calculateCount++;
    return const EphemerisFrame(
      positions: {},
      tropicalAscendant: 0,
      ayanamshaDegrees: 0,
      sunHourAngleHours: 12.0,
    );
  }
}
