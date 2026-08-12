# ASTRO LOGIC v081 — Western Astrology Foundation v1

Status: **Completed (source/native validation checkpoint)**

## Version / contracts

- App: `0.77.0+81`
- SQLite schema: `12` (unchanged)
- Native astronomy ABI: `al-abi-8`
- Western engine: `astro-logic-western-native` `1.0.0`
- Output schema: `western-natal-chart-v1`
- Input schema: `western-input-schema-v1`
- Governance: `western-foundation-v1`
- Tropical profile: `western-tropical-zodiac-v1`
- Aspect profile: `western-major-aspect-orb-v1`
- Dignity profile: `western-essential-dignity-major-v1`

## Implemented

1. Tropical Sun, Moon, Mercury, Venus, Mars, Jupiter, Saturn plus selected North/South lunar node.
2. Tropical Ascendant and MC.
3. Governed Placidus, Whole Sign and Equal houses.
4. Five major aspects with disclosed versioned orbs and applying/separating evidence.
5. Major traditional essential-dignity/debility evidence: domicile, exaltation, detriment and fall.
6. Standalone bilingual Western workspace.
7. Consultation-linked Western execution using the selected saved birth record.
8. Western-specific immutable input snapshot and existing hash-protected calculation-output snapshot pipeline.
9. No schema bump: the generic immutable snapshot tables already protect Western inputs/outputs and are covered by encrypted backup/merge.
10. Western Dashboard tile promoted from Coming Soon to available.

## Explicitly not included in v081

- Uranus / Neptune / Pluto calculation or modern rulerships.
- Chiron, Lilith or asteroids.
- Minor aspects.
- Triplicity, bounds/terms or faces/decans.
- Aspect patterns / midpoint / progressions / solar returns / transits.
- Automatic Western event prediction.
- Cross-system confidence uplift.

## Validation boundary

- `tool/validate_v081_western_foundation.py`: **62/62 PASS**.
- Dart source/test/tool files scanned: **183**.
- Native C wrapper: compiled with `-Wall -Wextra -Werror` and executed successfully, including the JPL planetary fixtures, KP Placidus fixture, new Western tropical-frame fixture, polar Placidus/core-separation gate and required ABI exports.
- Static build readiness: **0 blocking errors / 1 expected warning** (`pubspec.lock` pending final Flutter CI).
- Release-source preparation: **9/9 PASS**; full-scope commercial tagging remains blocked by Vastu, Palmistry and Practice.

The current container has no Flutter/Dart SDK, so this milestone does not claim `flutter analyze`, `flutter test`, APK build or Windows Flutter build success.

## Next locked milestone

**v082 — Western Modern Planets & Aspect Pattern Expansion v1**: add governed Uranus/Neptune/Pluto native positions, modern-vs-traditional rulership separation, node/aspect policy options, minor-aspect gating and professional aspect-pattern synthesis without changing the v081 traditional dignity evidence.
