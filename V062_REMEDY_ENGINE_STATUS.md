# ASTRO LOGIC v062 — Remedy Recommendation Engine v1

Version: `v0.58.0+62`
Vedic judgment: `31.0.0`
Analysis schema: `kundli-analysis-v31`
Calculation schema: `vedic-chart-v10` (unchanged)
SQLite schema: `v8` (unchanged)
Professional Report Engine: `1.1.0`

## Completed in v062

- Added `vedic-remedy-recommendation-v1` as a separate Vedic post-judgment module.
- Removed the legacy negative Lagna-lord score → gemstone candidate shortcut.
- A behavioural remedy draft now requires at least two distinct challenging chart-rule evidence ids in the same actionable life area.
- Supportive and Mixed findings never trigger v1 remedy drafting.
- Longevity/death-related remedy automation is excluded.
- Health, finance, career, marriage/partnership, property, children and other high-stakes-adjacent areas carry explicit practical/professional safeguards.
- Mantra, charity, ritual and automated gemstone selection remain disabled pending their own governed source profiles.
- Professional Report Engine 1.1.0 renders persisted automated behavioural remedy candidates together with practitioner-reviewed gemstone records.
- Added dedicated remedy-engine and report regression tests.

## Validation completed in this container

- Static build-readiness audit: 0 errors.
- All local Dart imports resolve.
- No unresolved TODO/FIXME/HACK/XXX markers.
- 121 Dart files scanned by source-only delimiter/structure validation with no structural issue found.
- Known warnings retained: large-file maintainability watchlist and missing `pubspec.lock` until the final Flutter build checkpoint.

This container does not include Flutter/Dart SDK, so this milestone does not claim `flutter analyze`, `flutter test`, APK build or Windows executable build. Those remain final CI gates.

## Next locked task

**Gemstone Candidate & Contraindication Engine v1**

The next engine should decide when a strengthening gemstone is eligible for professional review, when it is contraindicated, and when evidence is insufficient. It must combine functional lordship, governed Shadbala sufficiency, D1/D9 condition, combustion/war/node-contact conflicts and active Dasha context without auto-approval or guaranteed-outcome claims.
