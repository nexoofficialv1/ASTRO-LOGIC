# Numerology Engine v2 — Frozen calculation and review contract

## Scope and evidence status

`numerology-profile-v3` is a deterministic offline arithmetic contract and
`numerology-analysis-v3` is a separately governed traditional-symbolic review
contract. Numerology is treated by ASTRO LOGIC as a traditional belief system,
not as scientifically validated prediction. Arithmetic reproducibility must not
be confused with predictive validity.

Every serialized calculation and analysis requires professional review. The
prediction-confidence policy is permanently capped at **Low** in v2. A Vedic
cross-check can add caution context but cannot raise that confidence.

## Required input

- exact Latin/English name spelling used for the calculation;
- governed birth date;
- target calendar year.

ASCII letters, spaces, period, hyphen and apostrophe are accepted. Bengali or
other scripts are rejected rather than silently transliterated. The normalized
Latin spelling remains visible in the immutable snapshot.

## Frozen calculation profile

Profile id: `astro-logic-numerology-core-cycle-v2`

### Driver / Birth number

Reduce the calendar day, preserving final Master Numbers `11`, `22`, `33`.

### Life Path v2

ASTRO LOGIC v2 uses a component-reduction convention:

1. reduce birth month separately;
2. reduce birth day separately;
3. reduce birth year separately;
4. preserve `11`, `22`, `33` in those components;
5. add the reduced components;
6. reduce the final sum while preserving `11`, `22`, `33`.

Example: 4 November 2005:

- month `11 -> 11`
- day `4 -> 4`
- year `2005 -> 7`
- `11 + 4 + 7 = 22 -> 22`

The formula is serialized as evidence. A future change to this reduction policy
requires a new profile/schema version.

### Personal Year / calendar-cycle v2

Calendar cycles use a separate frozen policy because published Numerology
schools differ on Master Number handling and on calendar-year versus
birthday-to-birthday timing.

ASTRO LOGIC v2 selects the **calendar-year** profile:

1. birth month is reduced to a single-digit root;
2. birth day is reduced to a single-digit root;
3. target calendar year is reduced to a single-digit Universal Year root;
4. those roots are added;
5. the **final** total may preserve `11`, `22`, `33`.

The engine calculates three visible windows: target year - 1, target year, and
target year + 1. Each window is January 1 inclusive through the following
January 1 exclusive. These windows are reflection/planning contexts only, not
event predictions.

This is an explicit selected school, not a claim that all Numerology schools
agree. `NUMEROLOGY_RULE_SOURCES.md` records the disagreement.

## Name profiles

### Pythagorean mapping v2

| Value | Letters |
| ---: | --- |
| 1 | A J S |
| 2 | B K T |
| 3 | C L U |
| 4 | D M V |
| 5 | E N W |
| 6 | F O X |
| 7 | G P Y |
| 8 | H Q Z |
| 9 | I R |

The profile returns:

- Expression / Name number;
- Soul Urge subtotal from `A/E/I/O/U` only;
- Personality subtotal from the remaining Latin letters.

`Y` remains a consonant under this frozen profile. If a spelling has no selected
vowel, Soul Urge is explicitly `0 / unavailable under the frozen letter policy`;
the engine does not invent a substitute number or silently reclassify `Y`.
Master Numbers `11`, `22`, `33` are preserved.

### Chaldean mapping v2

| Value | Letters |
| ---: | --- |
| 1 | A I J Q Y |
| 2 | B K R |
| 3 | C G L S |
| 4 | D M T |
| 5 | E H N X |
| 6 | U V W |
| 7 | O Z |
| 8 | F P |

No letter is assigned `9`. The engine retains the compound total and reduced
single digit. Chaldean vowel/consonant subtotals are not relabelled as Soul Urge
or Personality in v2.

## Maturity synthesis v1

The Maturity number is calculated from the reduced Life Path plus the reduced
Pythagorean Expression number, with the final Master Number policy preserved.
It is exposed as a symbolic synthesis only; no age-triggered event is generated.

## Interpretation contract v2

`numerology-analysis-v3` emits bilingual, evidence-backed findings for:

- Driver / Birth;
- Life Path;
- Pythagorean Expression;
- Soul Urge;
- Personality;
- Chaldean Name;
- Maturity synthesis;
- Pythagorean-versus-Chaldean arithmetic comparison.

All symbolic number findings are `Low` confidence. The arithmetic comparison
may remain `Medium` because it merely compares two deterministic totals; it is
not a prediction and does not justify a name change.

## Guarded Vedic cross-check v1

If an immutable Vedic judgment snapshot is already linked to the same
consultation, v2 may display a traditional Indian number-to-planet mapping for
**review context only**:

`1 Sun · 2 Moon · 3 Jupiter · 4 Rahu · 5 Mercury · 6 Venus · 7 Ketu · 8 Saturn · 9 Mars`

The cross-check currently applies only to Driver, Life Path, and Pythagorean
Expression. It may read the already-governed Vedic gemstone-candidate status for
the corresponding classical planet as a caution record. It does **not**:

- validate the Numerology interpretation;
- count as independent Vedic evidence;
- raise Numerology prediction confidence;
- infer Rahu/Ketu strength when no governed node-strengthening review exists;
- approve or recommend a gemstone;
- create event predictions.

The Vedic snapshot id, schema and short integrity hash are retained in evidence
text so the cross-system context is traceable.

## Remedy safety v2

Numerology v2 permits only optional non-planetary **behavioural reflection**
candidates tied to the selected target Personal Year. It prohibits automatic:

- gemstone selection or wearing details;
- mantra, charity or ritual prescriptions;
- legal-name changes;
- medical, legal, financial or relationship directives;
- guaranteed outcomes.

High-stakes decisions must rely on appropriate qualified professionals and
ordinary evidence, not Numerology output.

## Workspace and immutable snapshot

The Android/Windows-responsive workspace shows:

- exact Latin spelling input;
- controlled birth date and target year;
- Driver, Life Path, Maturity, Personal Year, Pythagorean Expression, Soul Urge,
  Personality and Chaldean cards;
- auditable formula/rule evidence;
- bilingual findings;
- Low-confidence policy card;
- optional guarded Vedic cross-check;
- three-year Personal Year context;
- behavioural review and warnings.

When opened from a saved consultation, the birth date is governed by the birth
record and the latest persisted Vedic judgment snapshot for that consultation is
used only if available. Saving writes a new immutable Numerology snapshot bound
by SHA-256 to the input, calculation payload, analysis payload and both engine/
schema versions. SQLite schema remains unchanged because these additions live
inside the versioned JSON snapshot contract.

## Alternate-name candidate comparison v1

Profile id: `astro-logic-name-candidate-comparison-v1`. The exact normalized original Latin spelling remains the baseline. The practitioner may enter up to eight unique alternate Latin spellings. Baseline-equivalent names, normalized duplicates and non-Latin spellings are rejected; automatic transliteration remains disabled.

For every candidate the engine computes the same frozen Pythagorean and Chaldean name profiles and stores compound/reduced deltas, Soul Urge/Personality reduced-change flags, Master-number transition flags, and arithmetic overlap with Driver, Life Path and Maturity. The neutral comparison status is only `noReducedChange`, `oneSystemReducedChange`, or `bothSystemsReducedChange`. No status means favourable or unfavourable.

The engine has no ranking score and never auto-selects a candidate. Core-number overlap is explicitly not a favourability signal. It does not label a spelling best/lucky, promise an outcome, or recommend a legal-name change. One optional candidate can be explicitly marked by the professional as a discussion focus; that human selection is persisted only as context and is never treated as engine endorsement.

Candidate inputs, selection, calculation comparisons and bilingual analysis reviews are part of the immutable snapshot payload and SHA-256 integrity binding.
