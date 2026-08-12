import 'dart:ffi';
import 'dart:io';

import 'western_native_bridge.dart';

final class _WesternNativePosition extends Struct {
  @Int32()
  external int status;
  @Double()
  external double tropicalLongitude;
  @Double()
  external double eclipticLatitude;
  @Double()
  external double longitudeSpeedPerDay;
}

final class _WesternNativeFrame extends Struct {
  @Int32()
  external int status;
  @Int32()
  external int placidusStatus;
  @Double()
  external double tropicalAscendant;
  @Double()
  external double tropicalMc;
  @Double()
  external double trueNodeTropical;
  @Double()
  external double meanNodeTropical;
  @Array(12)
  external Array<Double> tropicalCusps;
}

typedef _PositionNative = _WesternNativePosition Function(
  Int32,
  Int32,
  Int32,
  Int32,
  Int32,
  Int32,
  Double,
);
typedef _PositionDart = _WesternNativePosition Function(
  int,
  int,
  int,
  int,
  int,
  int,
  double,
);
typedef _FrameNative = _WesternNativeFrame Function(
  Int32,
  Int32,
  Int32,
  Int32,
  Int32,
  Double,
  Double,
  Double,
);
typedef _FrameDart = _WesternNativeFrame Function(
  int,
  int,
  int,
  int,
  int,
  double,
  double,
  double,
);

class WesternNativeFfiBridge implements WesternNativeBridge {
  WesternNativeFfiBridge._(DynamicLibrary library)
      : _position = library.lookupFunction<_PositionNative, _PositionDart>(
          'al_geocentric_position',
        ),
        _frame = library.lookupFunction<_FrameNative, _FrameDart>(
          'al_calculate_western_frame',
        );

  factory WesternNativeFfiBridge.open() {
    if (Platform.isAndroid) {
      return WesternNativeFfiBridge._(
        DynamicLibrary.open('libastro_logic_astronomy.so'),
      );
    }
    if (Platform.isWindows) {
      return WesternNativeFfiBridge._(
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
  Future<WesternNativeFrameData> calculateFrame({
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
    _requireSuccess(value.status, 'Western native frame');
    final placidusAvailable = value.placidusStatus == 0;
    return WesternNativeFrameData(
      tropicalAscendant: value.tropicalAscendant,
      tropicalMc: value.tropicalMc,
      trueNodeTropical: value.trueNodeTropical,
      meanNodeTropical: value.meanNodeTropical,
      placidusAvailable: placidusAvailable,
      tropicalCusps: placidusAvailable
          ? List<double>.generate(
              12,
              (index) => value.tropicalCusps[index],
              growable: false,
            )
          : const <double>[],
    );
  }

  @override
  Future<WesternNativePositionData> calculatePosition({
    required WesternNativeBody body,
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
    return WesternNativePositionData(
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

  static const _bodyCodes = <WesternNativeBody, int>{
    WesternNativeBody.sun: 0,
    WesternNativeBody.moon: 1,
    WesternNativeBody.mars: 2,
    WesternNativeBody.mercury: 3,
    WesternNativeBody.jupiter: 4,
    WesternNativeBody.venus: 5,
    WesternNativeBody.saturn: 6,
    WesternNativeBody.uranus: 7,
    WesternNativeBody.neptune: 8,
    WesternNativeBody.pluto: 9,
  };
}
