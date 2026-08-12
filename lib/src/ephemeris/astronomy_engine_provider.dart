import 'ephemeris_engine_policy.dart';
import 'ephemeris_provider.dart';

/// Boundary for the MIT-licensed Astronomy Engine native implementation.
/// Android and Windows bindings will implement this contract offline.
abstract interface class AstronomyEngineNativeBridge {
  String get libraryVersion;

  Future<void> initialize();

  Future<EphemerisFrame> calculate(EphemerisRequest request);
}

class AstronomyEngineEphemerisProvider implements EphemerisProvider {
  AstronomyEngineEphemerisProvider({
    required AstronomyEngineNativeBridge bridge,
    EphemerisEnginePolicy? enginePolicy,
  })  : _bridge = bridge,
        _enginePolicy =
            enginePolicy ?? EphemerisEnginePolicy.configuredBuild();

  final AstronomyEngineNativeBridge _bridge;
  final EphemerisEnginePolicy _enginePolicy;
  Future<void>? _initialization;

  @override
  String get engineId => 'astronomy-engine-mit';

  @override
  String get engineVersion => _bridge.libraryVersion;

  @override
  Future<EphemerisFrame> calculate(EphemerisRequest request) async {
    _enginePolicy.requireRuntimeConfiguration();
    _validateRequest(request);
    await (_initialization ??= _bridge.initialize());
    return _bridge.calculate(request);
  }

  void _validateRequest(EphemerisRequest request) {
    if (!request.utcDateTime.isUtc) {
      throw ArgumentError.value(
        request.utcDateTime,
        'utcDateTime',
        'Must be explicitly converted to UTC',
      );
    }
    if (!request.latitude.isFinite ||
        request.latitude < -90.0 ||
        request.latitude > 90.0) {
      throw ArgumentError.value(request.latitude, 'latitude');
    }
    if (!request.longitude.isFinite ||
        request.longitude < -180.0 ||
        request.longitude > 180.0) {
      throw ArgumentError.value(request.longitude, 'longitude');
    }
  }
}
