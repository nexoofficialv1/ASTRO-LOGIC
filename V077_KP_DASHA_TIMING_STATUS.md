# ASTRO LOGIC v077 — KP Dasha & Timing Synthesis v1

- App: `0.73.0+77`
- SQLite schema: `v11` (unchanged)
- Native ABI: `al-abi-7` (unchanged)
- KP native engine: `astro-logic-kp-native` `1.2.0`
- KP output schema: `kp-native-chart-v3`
- Timing schema: `kp-dasha-timing-v1`
- Timing profile: `kp-vimshottari-dba-house-coverage-v1`

## Completed

1. KP-native Moon longitude seeds the existing governed Vimshottari calendar; no alternate Dasha system is introduced.
2. Mahadasha / Antardasha / Pratyantardasha are exposed as Dasha / Bhukti / Antara in the KP timing layer.
3. Per-lord conductive/detrimental houses and four-level source evidence are persisted once and referenced by the period chain.
4. All post-birth DBA windows are retained. Supportive requires all three lords to touch conductive houses, complete house-group coverage across the chain, and no detrimental hit.
5. Mixed or incomplete relevant DBA periods remain Conflicting rather than being discarded or majority-voted away.
6. Chart Promise/Denial/Insufficient Evidence remains an independent gate. Denial/inconclusive charts keep timing evidence but promote no actionable window.
7. Current DBA and next supportive windows are exposed in the bilingual KP workspace and persisted in supported consultation snapshots.
8. Transit and Ruling-Planet confirmation remain separate and are explicitly marked absent from v077 timing confidence.

## Still gated

- Transit confirmation of DBA windows.
- Ruling-Planet overlap/selection as an independent timing evidence layer.
- KP Horary question-number workflow.
- Broader event-house catalogs beyond Marriage and Children.
- Any automatic health/mortality timing judgment.

## Runtime limitation

Flutter/Dart SDK is unavailable in this packaging environment. Static/source validation and native C verification can run here; `flutter analyze`, `flutter test`, Android APK and Windows Flutter build remain final CI gates.

## Next locked task

**v078 — KP Transit & Ruling-Planet Timing Confirmation v1**: keep DBA selection fixed, then add independent transit/Ruling-Planet confirmation without allowing either layer to silently override chart promise or conflicting DBA evidence.
