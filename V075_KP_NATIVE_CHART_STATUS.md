# ASTRO LOGIC v075 — KP Native Chart Casting v1

- App: `0.71.0+75`
- SQLite schema: `v11` (unchanged)
- Native wrapper: `astronomy-engine-c-2.1.19/al-abi-7`
- KP native engine: `astro-logic-kp-native` `1.0.0`
- Output schema: `kp-native-chart-v1`
- KP input snapshot: `kp-input-schema-v1`
- Ayanamsha profile: `kp-krishnamurti-classic-j1900-newcomb-v1`
- House profile: `kp-placidus-time-division-native-v1`
- Validated date range: 1840–2100

## Completed

1. Independent native classic Krishnamurti Reader-1 reconstruction using J1900 reference and Newcomb/Kinoshita precession.
2. Independent native Placidus 12-cusp solver with explicit polar failure and no silent Porphyry fallback.
3. Native ABI v7 fixed KP frame containing ayanamsha, Asc/MC, true/mean node and tropical/sidereal cusp arrays.
4. Full Sun through Saturn + Rahu/Ketu and 12-cusp Star/Sub classification using the frozen v074 arithmetic engine.
5. Ruling-planet review panel generated from native Ascendant and Moon.
6. KP workspace native casting plus retained manual Star/Sub/cusp cross-check tools.
7. Consultation-linked immutable KP input snapshot and hash-protected generic calculation output snapshot.
8. Native C reference fixture verification and polar rejection test.
9. External fixture file documents numeric reference provenance without adding Swiss Ephemeris as a runtime/source dependency.

## Safety/governance

The classic KP ayanamsha profile is explicitly versioned because historical source definitions are not uniquely specified at modern sub-arcsecond precision. Native Placidus failure is never hidden by switching house systems. v075 does not automate event guarantees, horary yes/no answers, advanced KP promise judgment or timing synthesis.

## Runtime limitation of this packaging environment

The native C verification is compiled and executed here. Flutter/Dart SDK is not installed, so no `flutter analyze`, `flutter test`, Android APK or Windows runtime-build success is claimed in this milestone package.

## Next locked task

**v076 — KP Advanced Significator & Event Judgment v1**: derive planet occupancy/ownership from native cusps, build cusp sub-lord event-house evidence, governed promise/denial/insufficient-evidence states and practitioner-reviewed KP event judgment without automatic certainty.
