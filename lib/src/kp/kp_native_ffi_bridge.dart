import 'dart:ffi';
import 'dart:io';

import 'kp_native_chart_engine.dart';

final class _KpNativePosition extends Struct {
  @Int32()
  external int status;
  @Double()
  external double tropicalLongitude;
  @Double()
  external double eclipticLatitude;
  @Double()
  external double longitudeSpeedPerDay;
}

final class _KpNativeFrame extends Struct {
  @Int32()
  external int status;
  @Int32()
  external int placidusStatus;
  @Double()
  external double krishnamurtiAyanamsha;
  @Double()
  external double tropicalAscendant;
  @Double()
  external double tropicalMc;
  @Double()
  external double siderealAscendant;
  @Double()
  external double siderealMc;
  @Double()
  external double trueNodeTropical;
  @Double()
  external double meanNodeTropical;

  @Array(12)
  external Array<Double> tropicalCusps;

  @Array(12)
  external Array<Double> siderealCusps;
}

typedef _PositionNative = _KpNativePosition Function(
  Int32,
  Int32,
  Int32,
  Int32,
  Int32,
  Int32,
  Double,
);
typedef _PositionDart = _KpNativePosition Function(
  int,
  int,
  int,
  int,
  int,
  int,
  double,
);
typedef _FrameNative = _KpNativeFrame Function(
  Int32,
  Int32,
  Int32,
  Int32,
  Int32,
  Double,
  Double,
  Double,
);
typedef _FrameDart = _KpNativeFrame Function(
  int,
  int,
  int,
  int,
  int,
  double,
  double,
  double,
);

class KpNativeFfiBridge implements KpNativeBridge {
  KpNativeFfiBridge._(DynamicLibrary library)
      : _position = library.lookupFunction<_PositionNative, _PositionDart>(
          'al_geocentric_position',
        ),
        _frame = library.lookupFunction<_FrameNative, _FrameDart>(
          'al_calculate_kp_frame',
        );

  factory KpNativeFfiBridge.open() {
    if (Platform.isAndroid) {
      return KpNativeFfiBridge._(
        DynamicLibrary.open('libastro_logic_astronomy.so'),
      );
    }
    if (Platform.isWindows) {
      return KpNativeFfiBridge._(
        DynamicLibrary.open('astro_logic_astronomy.dll'),
      );
    }
    throw UnsupportedError('Only Android and Windows are supported');
  }

  final _PositionDart _position;
  final _FrameDart _frame;

  @override
  String get libraryVersion => 'astronomy-engine-c-2.1.19/al-abi-9';

  @override
  Future<KpNativeFrameData> calculateFrame({
    required DateTime utc,
    required double latitude,
    required double longitude,
  }) async {
    final value = _frame(
      utc.year,
      utc.month,
      utc.day,
      utc.hour,
      utc.minute,
      utc.second + utc.millisecond / 1000.0,
      latitude,
      longitude,
    );
    _requireSuccess(value.status, 'KP native frame');
    _requireSuccess(value.placidusStatus, 'KP Placidus cusps');
    return KpNativeFrameData(
      krishnamurtiAyanamsha: value.krishnamurtiAyanamsha,
      tropicalAscendant: value.tropicalAscendant,
      tropicalMc: value.tropicalMc,
      siderealAscendant: value.siderealAscendant,
      siderealMc: value.siderealMc,
      trueNodeTropical: value.trueNodeTropical,
      meanNodeTropical: value.meanNodeTropical,
      tropicalCusps: List<double>.generate(
        12,
        (index) => value.tropicalCusps[index],
        growable: false,
      ),
      siderealCusps: List<double>.generate(
        12,
        (index) => value.siderealCusps[index],
        growable: false,
      ),
    );
  }

  @override
  Future<KpNativePositionData> calculatePosition({
    required KpNativeBody body,
    required DateTime utc,
  }) async {
    final value = _position(
      _bodyCodes[body]!,
      utc.year,
      utc.month,
      utc.day,
      utc.hour,
      utc.minute,
      utc.second + utc.millisecond / 1000.0,
    );
    _requireSuccess(value.status, body.name);
    return KpNativePositionData(
      tropicalLongitude: value.tropicalLongitude,
      eclipticLatitude: value.eclipticLatitude,
      longitudeSpeedPerDay: value.longitudeSpeedPerDay,
    );
  }

  void _requireSuccess(int status, String operation) {
    if (status != 0) {
      throw StateError('Astronomy Engine $operation failed with status $status');
    }
  }

  static const _bodyCodes = <KpNativeBody, int>{
    KpNativeBody.sun: 0,
    KpNativeBody.moon: 1,
    KpNativeBody.mars: 2,
    KpNativeBody.mercury: 3,
    KpNativeBody.jupiter: 4,
    KpNativeBody.venus: 5,
    KpNativeBody.saturn: 6,
  };
}
