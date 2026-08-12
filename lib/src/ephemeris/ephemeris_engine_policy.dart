enum OfflineEphemerisBackend { unconfigured, astronomyEngine }

class EphemerisEnginePolicy {
  const EphemerisEnginePolicy(this.backend);

  static const _configuredBackend = String.fromEnvironment(
    'ASTRO_LOGIC_EPHEMERIS_BACKEND',
  );

  final OfflineEphemerisBackend backend;

  factory EphemerisEnginePolicy.configuredBuild() => EphemerisEnginePolicy(
        switch (_configuredBackend) {
          'astronomy-engine' => OfflineEphemerisBackend.astronomyEngine,
          _ => OfflineEphemerisBackend.unconfigured,
        },
      );

  bool get isRuntimeConfigured =>
      backend == OfflineEphemerisBackend.astronomyEngine;

  void requireRuntimeConfiguration() {
    if (!isRuntimeConfigured) {
      throw StateError(
        'Offline astronomical calculation is disabled until the audited '
        'Astronomy Engine backend is included in this build.',
      );
    }
  }
}
