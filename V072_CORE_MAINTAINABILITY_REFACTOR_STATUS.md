# ASTRO LOGIC v072 — Core Maintainability Refactor v1

App version: `0.68.0+72`  
SQLite schema: `11` (unchanged)  
Vedic calculation: `vedic-chart-v10` (unchanged)  
Vedic judgment: `32.0.0` / `kundli-analysis-v32` (unchanged)  
Shadbala: `shadbala-foundation-v10` (unchanged)  
Backup engine: `1.3.0` (unchanged)

## Completed

- Vedic Lagna judgment main file reduced from 2921 to 363 lines; timing/yoga, house rules and support data/types moved to same-library part files.
- Shadbala main file reduced from 1842 to 111 lines; profile, Kala/geometry and support logic moved to same-library part files.
- Encrypted Backup Service main file reduced from 2087 to 764 lines; pure merge, envelope/crypto and integrity helpers moved to same-library part files.
- Consultation Detail screen reduced from 1426 to 594 lines; read-only analysis sections/widgets moved to same-library part files.
- No SQLite migration and no calculation/judgment/report/backup/signing contract bump.
- Static `LARGE_DART_FILES` gate now passes.

## Validation boundary

Source/readiness validation only. Flutter/Dart SDK is unavailable in this environment, so analyzer, Flutter tests, APK and Windows build success are not claimed.

## Next locked milestone

**Final Flutter CI & Release Gate Preparation v1** — consolidate release checks, generated-runner gates, dependency lock policy, test matrix and final APK/Windows/GitHub release procedure before opening the KP/Western/Vastu/Palmistry expansion track.
