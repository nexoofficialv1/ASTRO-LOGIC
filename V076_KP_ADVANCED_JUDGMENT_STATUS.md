# ASTRO LOGIC v076 — KP Advanced Significator & Event Judgment v1

- App: `0.72.0+76`
- SQLite schema: `v11` (unchanged)
- Native ABI: `al-abi-7` (unchanged)
- KP native engine: `astro-logic-kp-native` `1.1.0`
- KP output schema: `kp-native-chart-v2`
- House evidence: `kp-house-significator-synthesis-v1`
- Event judgment: `kp-cusp-sublord-promise-review-v1` / `kp-event-judgment-v1`

## Completed

1. Deterministic Placidus house occupancy for all nine KP points, including zodiac-wrap intervals.
2. Cusp-sign house ownership with Rahu/Ketu explicitly owning no signs/houses.
3. Full four-level significator matrix retained separately by level and with an auditable combined-house view.
4. Source-bounded Marriage review: 7th cusp sub lord against 2/7/11 and 1/6/10.
5. Source-bounded Children review: 5th cusp sub lord against 2/5/11 and 1/4/10.
6. Conservative Promise / Denial / Insufficient Evidence state machine with bilingual narrative and no real-world guarantee.
7. Consultation snapshots persist judgment only for supported Marriage/Children categories; other categories retain significator evidence without an invented formula.
8. KP workspace shows occupied houses, combined significators and manual event-evidence review.

## Still gated

- KP Dasha/Bhukti/Antara event timing synthesis.
- Transit/Ruling-Planet timing fusion.
- Horary question-number workflow.
- Broader event-house catalogs until source profiles and fixtures are frozen.
- Any health/mortality automatic event judgment.

## Runtime limitation

Flutter/Dart SDK is unavailable in this packaging environment. Static/source validation and native C verification can be run here; `flutter analyze`, `flutter test`, Android APK and Windows Flutter build remain final CI gates.

## Next locked task

**v077 — KP Dasha & Timing Synthesis v1**: reuse governed Vimshottari periods, select only KP house-group significators for supported event topics, preserve Dasha/Bhukti/Antara evidence separately, and keep transit/ruling-planet timing as a later independent layer.
