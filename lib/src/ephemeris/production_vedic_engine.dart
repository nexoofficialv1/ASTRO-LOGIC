import '../services/calculation_engine_adapter.dart';
import '../vedic/vedic_derivation_engine.dart';
import 'astronomy_engine_ffi_bridge.dart';
import 'astronomy_engine_provider.dart';

/// Opens the packaged native library and composes the production Vedic engine.
///
/// Callers must only use this in Android/Windows builds that include the native
/// library and set ASTRO_LOGIC_EPHEMERIS_BACKEND=astronomy-engine.
CalculationEngineAdapter createProductionVedicEngine() {
  final provider = AstronomyEngineEphemerisProvider(
    bridge: AstronomyEngineFfiBridge.open(),
  );
  return VedicDerivationEngine(provider);
}
