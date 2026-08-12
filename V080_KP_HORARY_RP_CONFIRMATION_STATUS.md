# ASTRO LOGIC v080 — KP Horary Timing & Ruling-Planet Confirmation v1

## Identity

- App: `0.76.0+80`
- SQLite schema: `12` (unchanged)
- KP Horary engine: `1.1.0`
- Horary input schema: `kp-horary-input-v1` (unchanged)
- Horary output schema: `kp-horary-chart-v2`
- Horary profile: `kp-horary-249-placidus-rp-v2`
- RP confirmation schema: `kp-horary-rp-confirmation-v1`
- RP confirmation profile: `kp-horary-query-rp-overlap-v1`
- Encrypted backup writer: `1.4.0` (unchanged)

## What v080 adds

v080 adds a separate query-time Ruling-Planet corroboration layer to supported KP Horary Marriage and Children questions. It does not reuse natal birth data, natal Vimshottari DBA, a natal chart, or the v077/v078 Natal-KP timing stack.

The base Horary chart remains the v079 1–249 number chart: the selected number fixes the Horary Ascendant, the actual query UTC/location supplies the planetary sky, and native Placidus supplies the remaining cusps. The primary-cusp sub-lord still controls the source-bounded Promise / Denial / Insufficient Evidence review.

## Ruling-Planet profile

The retained KP teaching reference defines the standard Ruling Planets for a judgment moment as Ascendant Star Lord, Ascendant Sign Lord, Moon Star Lord, Moon Sign Lord and Day Lord, and describes common planets between the Ruling Planets and the relevant house significators as stronger/fruitful significators.

ASTRO LOGIC v080 uses the following standard confidence subset:

1. Ascendant Star Lord
2. Ascendant Sign Lord
3. Moon Star Lord
4. Moon Sign Lord

Day Lord remains audit-only because the retained source specifies sunrise-to-sunrise Hindu day, while the current KP engine has not yet implemented a governed sunrise-day resolver. Existing Ascendant/Moon Sub-Lord RP roles also remain audit-only and cannot raise confidence.

## Conservative state machine

The RP layer is eligible only when the existing supported Horary cusp review is `promise`.

- `corroboratedForPractitionerReview`: the Promise primary-cusp sub-lord is itself present among the standard query-time RPs and is a fruitful event-house significator, with no detrimental-only standard RP contradiction.
- `partialCorroboration`: one or more standard RPs are fruitful or mixed event-house significators, but the Promise primary-cusp sub-lord is not independently corroborated as a fruitful standard RP.
- `contradictory`: at least one standard RP is detrimental-only for the frozen event-house profile. The contradiction is retained even if other RPs are favourable.
- `insufficientCorroboration`: the Promise has no sufficient standard RP overlap.
- `notEligible`: the cusp review is Denial or Insufficient Evidence.

Confidence is capped at `moderate` for corroborated, `low` for partial/contradictory, and `none` otherwise.

This is a versioned software interpretation of the retained KP Ruling-Planet/significator conventions. It is not represented as the only legitimate KP timing technique.

## Explicit exclusions

- no natal birth details
- no natal DBA
- no automatic Horary Dasha/Bhukti/Antara timing
- no future transit scan
- no automatic days/weeks/months conversion
- no exact event date
- no real-world guarantee
- no Vedic/Numerology confidence uplift

## Persistence and backup

No new database table is required. `timingConfirmation` is embedded in the immutable `kp_horary_snapshots.output_json` payload and therefore covered by the existing output SHA-256. Encrypted backup/restore/merge engine `1.4.0` recomputes the stored Horary output hash and therefore protects the new v080 evidence without changing schema v12.

## Runtime truthfulness

The current environment has no Flutter/Dart SDK. v080 does not claim `flutter analyze`, `flutter test`, Android APK, Windows Flutter build, or device runtime success. Static source validation and the retained native C regression suite are the available gates here.

## Next locked milestone

`v081 — Western Astrology Foundation v1`: tropical chart contract, governed house-system profile, aspect engine, dignity/evidence model, bilingual professional workspace, immutable snapshot integration, and no cross-system confidence inflation.
