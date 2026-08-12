# ASTRO LOGIC v078 — KP Transit & Ruling-Planet Timing Confirmation v1

- App: `0.74.0+78`
- SQLite schema: `v11` (unchanged)
- Native ABI: `al-abi-7` (unchanged)
- KP native engine: `astro-logic-kp-native` `1.3.0`
- KP output schema: `kp-native-chart-v4`
- DBA timing schema: `kp-dasha-timing-v1` (unchanged)
- Confirmation schema: `kp-transit-rp-confirmation-v1`
- Confirmation profile: `kp-dba-transit-rp-confirmation-v1`

## Completed

1. Chart promise and v077 DBA selection remain immutable base layers; confirmation cannot rewrite either state.
2. At the reference moment, Dasha/Bhukti/Antara plus Sun/Moon KP transit positions are classified and their Star-Lords are checked against the natal event-significator evidence.
3. Fruitful, mixed, detrimental-only and neutral natal significator states are retained independently for every Vimshottari planet.
4. Detrimental-only required transit evidence is preserved as a contradiction; it is never majority-voted away.
5. Reference-moment Ruling Planets are calculated from the same native KP chart. Asc Star/Sign and Moon Star/Sign roles can confirm; expanded Sub-Lord roles are audit-only.
6. Day Lord is audit-only in v1 because the current RP builder uses civil weekday while sunrise-based Hindu-day resolution is not yet implemented.
7. Confirmation state is one of Confirmed-for-review, Partial, Contradictory, Insufficient or Not Eligible.
8. Confidence ceiling is hard-capped: Moderate for fully confirmed review, Low for partial/contradictory, None otherwise. High confidence is unavailable.
9. Supported Marriage/Children consultation snapshots persist `timingConfirmation` beside `eventJudgment` and `eventTiming`.
10. The bilingual KP workspace displays confirmation state, confidence ceiling, RP overlap and D/B/A + Sun/Moon Star-Lord evidence.

## Still gated

- Future-window transit projection/scanning; v078 confirms only the selected reference moment.
- Sunrise-to-sunrise Hindu Day Lord calculation.
- Sukshma-level timing and Lagna minute/hour transit timing.
- KP Horary question-number workflow.
- Broader event-house catalogs beyond Marriage and Children.
- Any automatic health/mortality timing judgment or real-world event guarantee.

## Runtime limitation

Flutter/Dart SDK is unavailable in this packaging environment. Static/source validation and native C verification can run here; `flutter analyze`, `flutter test`, Android APK and Windows Flutter build remain final CI gates.

## Next locked task

**v079 — KP Horary Foundation v1**: governed 1–249 question-number chart input, immutable horary context, native KP chart casting for the query moment/location, question-number ascendant mapping fixtures and practitioner-review evidence without reusing natal birth assumptions.
