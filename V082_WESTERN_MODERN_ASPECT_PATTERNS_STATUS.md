# v082 — Western Modern Planets & Aspect Pattern Expansion v1

App version: `0.78.0+82`  
SQLite schema: `12` (unchanged)  
Native ABI: `al-abi-9`  
Western engine: `1.1.0`  
Input/output: `western-input-schema-v2` / `western-natal-chart-v2`

## Implemented scope

- Uranus, Neptune and Pluto are calculated natively by the pinned MIT Astronomy Engine path; no approximate ASTRO LOGIC longitude formula is used. Legacy native body codes 0–6 remain unchanged and outer planets are appended as 7–9.
- Explicit governed rulership profiles are available: Traditional keeps Mars/Saturn/Jupiter for Scorpio/Aquarius/Pisces; Modern uses Pluto/Uranus/Neptune. The existing seven-planet traditional essential-dignity engine remains authoritative and independent of the selector.
- Major-only remains the default aspect profile. Major+Minor optionally enables Semisextile 30°, Semisquare 45°, Quintile 72°, Sesquiquadrate 135° and Quincunx 150° under a versioned operational orb policy.
- Aspect-pattern evidence supports Grand Trine, T-Square, Grand Cross, conservative complete-conjunction-clique Stellium, Yod and Kite. Every emitted pattern retains its component aspects/orbs. Loose geometry is rejected; overlapping/contradictory pattern types are not silently collapsed.
- Western output metadata binds zodiac, house, rulership, aspect, modern-planet, pattern and traditional-dignity profiles and keeps `crossSystemConfidenceUplift=false` plus `automaticRealWorldPrediction=false`.
- Western workspace includes rulership/aspect selectors, native modern-planet table, aspect table, pattern panel and traditional dignity separation with English/Bengali parity.
- Consultation input/output reuses the existing immutable SHA-256 calculation snapshot pipeline. No DB migration is required; encrypted backup/restore and governed merge/import remain on their existing schema-12 coverage.
- Dashboard Western availability is retained; Vastu, Palmistry and Practice remain Coming Soon, so full commercial scope remains blocked.

## Validation contract

`tool/validate_v082_western_modern.py` is the v082 source/native gate. It checks version/schema/ABI contracts, modern-planet body mapping and independent fixtures, major/minor aspect boundaries, deterministic pattern fixtures, rulership/dignity separation, snapshot hash settings, Dashboard governance, EN/BN localization parity, Dart relative imports/structural balance, native C compile/run, existing KP/Placidus regression and SDK availability disclosure.

Flutter/Dart runtime qualification is deliberately separate. If the local environment has no Flutter/Dart SDK, this milestone does not claim `flutter analyze`, `flutter test`, APK build, Windows Flutter build or device-runtime PASS. `pubspec.lock` must not be fabricated before the final tested dependency-resolution checkpoint.

## Completed validation evidence

- `tool/validate_v082_western_modern.py`: **48/48 required checks PASS**.
- Dart source/test/tool structural + relative-import scan: **183 files PASS**.
- English/Bengali localization key parity: **PASS**.
- Native C compile/run regression: **PASS**, including the existing Sun–Saturn reference suite, KP classic ayanamsha/Placidus fixture, and Uranus/Neptune/Pluto external rounded reference fixture.
- Source-only build-readiness audit: **0 error failures**; one expected warning remains because `pubspec.lock` is intentionally absent until a tested Flutter dependency-resolution checkpoint.
- Protected-module baseline comparison against exact v081: **58 Vedic, KP Horary, Numerology, professional report/signing/QR, encrypted backup/restore and merge-related source files byte-for-byte unchanged**. Shared Western snapshot wiring and native ABI metadata are the only intentional cross-cutting source changes.
- Flutter SDK: **not available locally**. Dart SDK: **not available locally**. Therefore `flutter analyze`, `flutter test`, APK build and Windows Flutter build are **NOT RUN / NOT CLAIMED** for v082.
