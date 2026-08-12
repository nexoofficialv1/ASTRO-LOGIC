# ASTRO LOGIC v079 — KP Horary Foundation v1

## Frozen release identifiers

- App: `0.75.0+79`
- SQLite: schema `v12`
- Horary engine: `astro-logic-kp-horary` `1.0.0`
- Input: `kp-horary-input-v1`
- Output: `kp-horary-chart-v1`
- Number table: `kp-horary-249-table-v1`
- Horary profile: `kp-horary-249-placidus-v1`
- Encrypted backup writer: `1.4.0`

## Completed

- Deterministic 1–249 table generation from exact Vimshottari Star/Sub spans with sign-boundary splitting.
- Number-selected sidereal Ascendant; query-moment/location planetary positions.
- Native Placidus cusp-1 solver with a maximum accepted bind error of 2 arcseconds and no rotated-cusp shortcut.
- Explicit no-natal-data contract.
- Full 12-cusp Star/Sub and house-evidence matrix.
- Optional source-governed Marriage/Children cusp judgment; General remains manual practitioner review.
- Immutable schema-v12 Horary persistence with SHA-256 input/output hashes and audit event.
- Schema-aware encrypted-backup coverage preserving schema 9–11 manifest compatibility.
- Governed audit entity remapping for imported Horary snapshots.

## Safety / scope boundary

The 1–249 number and KP judgments are astrology workflow constructs, not empirical guarantees. v079 does not produce automatic Horary event timing, exact event dates or real-world certainty. The technical cusp-solver timestamp is never exposed as an event time.

## Runtime validation boundary

Flutter/Dart SDK is unavailable in the current environment. Source/static validation and native C regression can be performed, but no Flutter analyzer, Flutter test, Android APK or Windows Flutter build success is claimed.

## Next

`v080 — KP Horary Timing & Ruling-Planet Confirmation v1`: separate query-time RP evidence and source-bounded Horary timing without importing natal DBA assumptions.

## Source/native validation result

- v079 validator: **68/68 PASS**
- Dart source/test/tool files scanned: **174**
- Native packaging/fixture regression: **PASS**
- Release-source preparation gate: **9/9 PASS**
- Static build-readiness blocking errors: **0**
- Expected warning: final tested `pubspec.lock` not yet present
