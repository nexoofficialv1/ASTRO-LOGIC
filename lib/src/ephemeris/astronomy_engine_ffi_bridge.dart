import 'dart:ffi';
import 'dart:io';

import '../models/astrology_settings.dart';
import 'astronomy_engine_provider.dart';
import 'ephemeris_provider.dart';

final class _NativePosition extends Struct {
  @Int32()
  external int status;

  @Double()
  external double tropicalLongitude;

  @Double()
  external double eclipticLatitude;

  @Double()
  external double longitudeSpeedPerDay;
}

final class _NativeFrameSupplement extends Struct {
  @Int32()
  external int status;

  @Double()
  external double lahiriAyanamsha;

  @Double()
  external double tropicalAscendant;

  @Double()
  external double trueNodeLongitude;

  @Double()
  external double trueNodeSpeedPerDay;

  @Double()
  external double meanNodeLongitude;

  @Double()
  external double meanNodeSpeedPerDay;

  @Double()
  external double sunHourAngleHours;

  @Int32()
  external int tribhagaStatus;

  @Int32()
  external int tribhagaIsDay;

  @Int32()
  external int tribhagaThird;

  @Double()
  external double tribhagaPeriodStartOffsetDays;

  @Double()
  external double tribhagaPeriodEndOffsetDays;

  @Int32()
  external int astrologicalDayStatus;

  @Double()
  external double astrologicalDayStartOffsetDays;

  @Int32()
  external int solarIngressStatus;

  @Double()
  external double varshaIngressOffsetDays;

  @Double()
  external double varshaDayStartOffsetDays;

  @Double()
  external double masaIngressOffsetDays;

  @Double()
  external double masaDayStartOffsetDays;
}

typedef _PositionNative = _NativePosition Function(
  Int32,
  Int32,
  Int32,
  Int32,
  Int32,
  Int32,
  Double,
);
typedef _PositionDart = _NativePosition Function(
  int,
  int,
  int,
  int,
  int,
  int,
  double,
);
typedef _SupplementNative = _NativeFrameSupplement Function(
  Int32,
  Int32,
  Int32,
  Int32,
  Int32,
  Double,
  Double,
  Double,
);
typedef _SupplementDart = _NativeFrameSupplement Function(
  int,
  int,
  int,
  int,
  int,
  double,
  double,
  double,
);

class AstronomyEngineFfiBridge implements AstronomyEngineNativeBridge {
  AstronomyEngineFfiBridge._(DynamicLibrary library)
      : _position = library.lookupFunction<_PositionNative, _PositionDart>(
          'al_geocentric_position',
        ),
        _supplement =
            library.lookupFunction<_SupplementNative, _SupplementDart>(
          'al_calculate_frame_supplement',
        );

  factory AstronomyEngineFfiBridge.open() {
    if (Platform.isAndroid) {
      return AstronomyEngineFfiBridge._(
        DynamicLibrary.open('libastro_logic_astronomy.so'),
      );
    }
    if (Platform.isWindows) {
      return AstronomyEngineFfiBridge._(
        DynamicLibrary.open('astro_logic_astronomy.dll'),
      );
    }
    throw UnsupportedError('Only Android and Windows are supported');
  }

  final _PositionDart _position;
  final _SupplementDart _supplement;

  @override
  String get libraryVersion => 'astronomy-engine-c-2.1.19/al-abi-9';

  @override
  Future<void> initialize() async {}

  @override
  Future<EphemerisFrame> calculate(EphemerisRequest request) async {
    if (request.ayanamsha != Ayanamsha.lahiri) {
      throw UnsupportedError(
        'Only the verified Lahiri/Chitrapaksha ayanamsha is enabled',
      );
    }
    final utc = request.utcDateTime;
    final supplement = _supplement(
      utc.year,
      utc.month,
      utc.day,
      utc.hour,
      utc.minute,
      utc.second + utc.millisecond / 1000.0,
      request.latitude,
      request.longitude,
    );
    _requireSuccess(supplement.status, 'frame supplement');

    final positions = <CelestialBody, EphemerisPosition>{};
    for (final entry in _nativeBodyCodes.entries) {
      final value = _position(
        entry.value,
        utc.year,
        utc.month,
        utc.day,
        utc.hour,
        utc.minute,
        utc.second + utc.millisecond / 1000.0,
      );
      _requireSuccess(value.status, entry.key.name);
      positions[entry.key] = EphemerisPosition(
        tropicalLongitude: value.tropicalLongitude,
        eclipticLatitude: value.eclipticLatitude,
        longitudeSpeed: value.longitudeSpeedPerDay,
      );
    }
    final useTrueNode = request.lunarNodeMode == LunarNodeMode.trueNode;
    positions[CelestialBody.rahu] = EphemerisPosition(
      tropicalLongitude: useTrueNode
          ? supplement.trueNodeLongitude
          : supplement.meanNodeLongitude,
      eclipticLatitude: 0.0,
      longitudeSpeed: useTrueNode
          ? supplement.trueNodeSpeedPerDay
          : supplement.meanNodeSpeedPerDay,
    );
    final tribhagaAvailable = supplement.tribhagaStatus == 0;
    final astrologicalDayAvailable = supplement.astrologicalDayStatus == 0;
    final solarIngressAvailable = supplement.solarIngressStatus == 0;
    return EphemerisFrame(
      positions: positions,
      tropicalAscendant: supplement.tropicalAscendant,
      ayanamshaDegrees: supplement.lahiriAyanamsha,
      sunHourAngleHours: supplement.sunHourAngleHours,
      tribhagaIsDay:
          tribhagaAvailable ? supplement.tribhagaIsDay == 1 : null,
      tribhagaThird:
          tribhagaAvailable ? supplement.tribhagaThird : null,
      tribhagaPeriodStartOffsetDays: tribhagaAvailable
          ? supplement.tribhagaPeriodStartOffsetDays
          : null,
      tribhagaPeriodEndOffsetDays: tribhagaAvailable
          ? supplement.tribhagaPeriodEndOffsetDays
          : null,
      astrologicalDayStartOffsetDays: astrologicalDayAvailable
          ? supplement.astrologicalDayStartOffsetDays
          : null,
      varshaIngressOffsetDays: solarIngressAvailable
          ? supplement.varshaIngressOffsetDays
          : null,
      varshaDayStartOffsetDays: solarIngressAvailable
          ? supplement.varshaDayStartOffsetDays
          : null,
      masaIngressOffsetDays: solarIngressAvailable
          ? supplement.masaIngressOffsetDays
          : null,
      masaDayStartOffsetDays: solarIngressAvailable
          ? supplement.masaDayStartOffsetDays
          : null,
    );
  }

  void _requireSuccess(int status, String operation) {
    if (status != 0) {
      throw StateError('Astronomy Engine $operation failed with status $status');
    }
  }

  static const _nativeBodyCodes = <CelestialBody, int>{
    CelestialBody.sun: 0,
    CelestialBody.moon: 1,
    CelestialBody.mars: 2,
    CelestialBody.mercury: 3,
    CelestialBody.jupiter: 4,
    CelestialBody.venus: 5,
    CelestialBody.saturn: 6,
  };
}
