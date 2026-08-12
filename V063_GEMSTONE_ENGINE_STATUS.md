# ASTRO LOGIC v063 — Gemstone Candidate & Contraindication Engine v1

Version: `v0.59.0+63`
Vedic judgment: `32.0.0`
Analysis schema: `kundli-analysis-v32`
Calculation schema: `vedic-chart-v10` (unchanged)
SQLite schema: `v8` (unchanged)
Professional Report Engine: `1.2.0`

## Completed in v063

- Added `vedic-gemstone-candidate-v1` as a separate conservative strengthening-screen module.
- Publishes seven classical-planet records with `eligible`, `contraindicated`, or `insufficientEvidence`.
- Combines ascendant-specific functional lordship, D1/D9 dignity, complete Shadbala ratio, combustion, Yuddha role, same-sign node contact, and Mahadasha/Antardasha active at the immutable calculation timestamp.
- Hard v1 contraindication: functional score <= -2.
- Eligible gate: functional score >= 2 + complete Shadbala below required + active MD/AD relevance + no node contact + no unresolved Yuddha evidence.
- Shadbala already sufficient, missing Shadbala, inactive Dasha, node contact, or unresolved war blocks eligibility and remains review-visible.
- Operational gemstone labels are versioned under `astro-logic-navaratna-mapping-v1`; no BPHS-universal-gemstone claim is made.
- No automated substitute gemstone, weight, metal, finger, wearing day, ritual or guaranteed outcome. Rahu/Ketu gemstone automation remains outside v1.
- Professional Report Engine 1.2.0 renders automated gemstone review states together with behavioural remedies and practitioner-reviewed records.

## Validation boundary

This container does not include Flutter/Dart SDK, so Flutter analyzer/tests/build are not claimed here. Source-only import, delimiter and repository readiness audits are run before packaging.

## Next locked task

**Numerology Finalization v1** — complete governed name/number interpretation, year-cycle synthesis, Vedic cross-check gates, remedy safety, report integration and final regression coverage without allowing Numerology-alone gemstone approval.
