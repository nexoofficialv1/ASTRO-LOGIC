# Kundli Judgment Engine

## Purpose

The judgment layer turns a verified calculation-output snapshot into a
structured professional draft. It does not invent planetary data and does not
publish an unreviewed conclusion.

## Output contract

`kundli-analysis-v32` preserves the earlier third-level Dasha, 12-house Navamsha, D10 career interpretation and seven-planet Shadbala families and carries Ashtakavarga foundation v3 with seven unreduced BAV tables, the unreduced 337-point SAV, a separate audited Trikona/Ekadhipatya reduction profile, and post-Shodhana Pinda calculations. It contains:

- supportive, challenging or mixed findings by life area;
- strengths and weaknesses expressed as evidence-backed findings;
- past/future timing windows with start, end and confidence;
- nine reusable Dasha-lord activation profiles with score, polarity, life
  areas, bilingual summary and evidence;
- 729 chart-specific Pratyantardasha interpretation records with exact UTC
  boundaries, MD/AD/PD scores, governed weighted synthesis, trigger relation,
  priority life areas, bilingual narrative and evidence;
- 12 Navamsha house interpretation records with D9 sign/lord, lord house and
  dignity, occupants, enabled full-sign aspectors, transparent component scores,
  contradiction flag, bilingual narrative and evidence;
- 12 Dashamsa career-domain house interpretation records plus one D1-tenth-lord × D10-tenth-house career synthesis, each capped at Medium confidence with contradiction preservation and node-neutral occupancy;
- seven Shadbala foundation records with Uccha, Saptavargaja, Ojhayugma,
  Kendradi and Drekkana Sthana components, exact Dig Bala, Paksha Bala, Ayana Bala, pre-war Kala subtotal and complete Kala Bala when Yuddha evidence permits, governed Cheshta Bala when supported by the calculation contract, fixed Naisargika Bala, exact-longitude Drik Bala with per-aspector Sphuta-Drishti angle/raw/weighted contribution audit trail,
  seven-varga contribution audit trail, motion-state/method evidence, evidence-gated sixfold total/Rupa conversion, BPHS 27.32-33 required total, ratio, surplus/deficit and threshold status;
- one `ashtakavarga-foundation-v3` profile containing seven unreduced BAV tables, contributor-level positive marks, the 337-point unreduced SAV, whole-sign house mapping and BPHS-72 comparative bands, a separate audited Trikona/Ekadhipatya reduction profile, and `ashtakavarga-pinda-v1` with per-sign Rashi multipliers, per-planet Graha multipliers, contribution audits and Rashi/Graha/Shodhya totals for all seven BAVs;
- gemstone, mantra, charity, ritual or behavioural remedy candidates;
- Bengali and English titles, narratives, rationales and cautions;
- rule ids and exact calculation-output paths for every conclusion;
- bilingual warnings and an unremovable professional-review requirement.

## Governance rules

- Every finding, timing window and remedy candidate requires chart evidence.
- High confidence requires at least two independent rule ids.
- Approximate/unknown birth time cannot produce high-confidence timing.
- Timing is a possibility window, never a guaranteed event date.
- Analysis snapshots are bound to one immutable calculation output by SHA-256.
- Database triggers reject analysis snapshot updates and deletions.
- Finalized consultations cannot accept a new analysis snapshot.

## Enabled rule family: Vimshottari timing v1

`vedic-chart-v4/v5` derives the starting Mahadasha from the Moon's exact sidereal
Nakshatra at birth. Ashwini begins with Ketu, after which the fixed cycle is
Venus, Sun, Moon, Mars, Rahu, Jupiter, Saturn and Mercury. Their nominal years
are respectively 7, 20, 6, 10, 7, 18, 16, 19 and 17, totalling 120 years.

The elapsed fraction of the birth Nakshatra determines the elapsed portion of
the first Mahadasha. Every Mahadasha is then divided into nine Antardashas in
the same cyclic order; an Antardasha duration is
`Mahadasha years × Antardasha-lord years / 120`. Calendar conversion uses the
explicit versioned policy `siderealSolarYear = 365.25636 days`. Output retains
all UTC boundaries, the birth balance, rule version and year policy.

The activation profile does not call a planet intrinsically good or bad.
For a classical Dasha lord it combines whole-sign placement, D1 dignity, D9
dignity and ascendant-specific functional ownership. Rahu and Ketu combine
their whole-sign placement with the functional role and D1/D9 dignity of their
sign dispositor. Mahadasha and Antardasha scores pointing in opposite
directions force a `Mixed` result regardless of arithmetic.

Every Antardasha is also divided recursively into nine Pratyantardashas using
the same proportional rule. The complete 120-year calendar therefore contains
729 Pratyantardashas. The ninth child is locked to its parent endpoint to avoid
accumulated rounding drift, and every lord, sequence and adjacent UTC boundary
is validated before `vedic-chart-v4/v5` is accepted.

Every timing window is medium confidence and evidence-backed. It is a broad
activation tendency, not a guaranteed event. The dashboard applies the same
audited lord profile to the Pratyantardasha lord, then synthesizes all three
levels with Mahadasha ×3, Antardasha ×2 and Pratyantardasha ×1 so the broad
period retains greater weight. If any non-zero lord scores oppose each other,
the combined result remains `Mixed` rather than being hidden by arithmetic.

Life-area focus comes from the occupied whole-sign house plus houses owned by a
classical lord. Rahu/Ketu use their occupied house plus houses owned by the
sign dispositor. Areas repeated at two or more Dasha levels are shown first;
otherwise the Pratyantardasha lord's areas are shown. Selected-date transit
confirmation is handled by the separate timing-synthesis engine; exact-event
claims remain disabled and consultation-question-specific timing is handled by
the separate governed review engine.

### Pratyantardasha detailed interpretation profile v1

For every one of the 729 calendar periods, the interpretation layer reuses the
same nine audited chart-specific Dasha-lord profiles instead of assigning a
fixed good/bad meaning to a planet combination. Mahadasha supplies the broad
activation field, Antardasha modifies that field, and Pratyantardasha supplies
the narrowest immediate activation/trigger layer. The existing governed
`Mahadasha ×3 + Antardasha ×2 + Pratyantardasha ×1` score is retained.

The engine records whether the Pratyantardasha lord reinforces the prevailing
MD/AD score, runs counter to it, or contributes no additional directional
trigger. Opposite non-zero lord signals force `Mixed`; a Mixed interpretation is
low confidence, while a clean supportive or challenging activation is medium
confidence. Life areas repeated across at least two levels receive priority;
when no area repeats, the Pratyantardasha lord's own activated areas are used.
Every record preserves the exact calendar boundary and one auditable Dasha
evidence path.

This family narrows chart activation only. It does not hard-code 729 event
promises and does not infer that a specific marriage, job, health, finance,
property or other event will occur. Question-specific house triggers and
selected-date transit confirmation remain separate required layers.

## Enabled rule family: Classical Moon-gochara transit v2

The standalone `VedicTransitEngine` calculates an explicitly selected UTC
transit epoch with the same audited offline ephemeris provider and the natal
chart's ayanamsha/node policy. It derives all nine sidereal transit positions,
retrograde state and whole-sign distance from both natal Lagna and natal Moon.

Version 2 adds a source-bounded directional matrix for the seven classical
planets using Brihat Samhita Chapter 104. The engine converts the classical
house-by-house passages into review direction only, not literal event promises.
The governed houses are:

| Planet | Supportive from natal Moon | Challenging from natal Moon | Mixed / special |
| --- | --- | --- | --- |
| Sun | 3, 6, 10, 11 | 1, 2, 4, 5, 7, 8, 9 | 12 |
| Moon | 1, 3, 6, 7, 10, 11 | 2, 5, 8, 9, 12 | 4 |
| Mars | 3, 6, 10, 11 | 1, 2, 4, 5, 7, 8, 9, 12 | — |
| Mercury | 2, 4, 6, 8, 10, 11 | 1, 5, 7, 9, 12 | 3 |
| Jupiter | 2, 5, 7, 9, 11 | 1, 3, 4, 6, 8, 10, 12 | — |
| Venus | 1, 2, 3, 4, 5, 8, 9, 11 | 6, 7, 10 | 12 |
| Saturn | 3, 6, 11 | 4, 5, 7, 8, 9 | 10 = mixed passage; 12, 1, 2 = Sade Sati review |

The universal 11th-house supportive rule is preserved. Houses whose translated
passages are mixed, limited or unsuitable for a simple binary classification
remain Mixed. Saturn in the 12th, 1st or 2nd from the natal Moon is identified
as rising, middle or setting Sade Sati respectively, but remains Mixed rather
than being converted into an automatic harmful-outcome rule.

Every transit finding carries a `transit` evidence record and bilingual
caution. Active Vimshottari Dasha, natal-chart promise and other enabled rule
families must confirm any consultation conclusion; Brihat Samhita Chapter 104
itself conditions transit results by Dasha context. Rahu/Ketu positions and
house distances are calculated and exposed, but node transit-result polarity
remains disabled pending a separately governed source profile. Exact-degree
triggers and question-specific event timing guarantees are outside transit-engine v2. Ashtakavarga confirmation is applied later by Question-specific Timing v3, not by the standalone Moon-gochara engine.


## Enabled rule family: Lagna and Lagna lord v1

The first deterministic family consumes fields present in the backward-
compatible `vedic-chart-v1` through current `vedic-chart-v10` outputs:

- sidereal Lagna sign;
- classical sign lord (Mars rules Scorpio; Saturn rules Aquarius);
- Lagna-lord whole-sign house;
- exalted, own-sign, debilitated or neutral dignity.

The transparent first-pass score is:

| Evidence | Score |
| --- | ---: |
| Exalted | +2 |
| Own sign | +1 |
| Neutral dignity | 0 |
| Debilitated | -2 |
| Kendra/Trikona house (1, 4, 5, 7, 9, 10) | +1 |
| Dusthana house (6, 8, 12) | -1 |
| Other house | 0 |

A score of +2 or more is Supportive, -2 or less is Challenging, and the middle
range is Mixed. High confidence is used only when house and dignity are two
independent rules pointing in the same direction. Every result displays both
rule ids and exact chart-output paths.

The earlier negative-score-to-gemstone shortcut is no longer enabled. A weak or
challenging Lagna-lord finding by itself is insufficient to create any gemstone
recommendation. Gemstone selection is delegated to the separate governed Gemstone Candidate & Contraindication Engine v1. It publishes review status only and never auto-approves wearing details.

No timing window is produced by this family.

## Enabled rule family: Integrated twelve-life-area synthesis v1

After the individual Lagna, house, occupancy and aspect records are created,
the engine emits one integrated professional draft for every whole-sign house.
Each draft keeps the following components visible and independently auditable:

- house sign and classical lord;
- house lord's occupied house and dignity;
- ascendant-specific functional ownership score;
- every listed occupant, with classical dignity/functional score where defined;
- every enabled Parashari full-sign aspector and its functional score.

The transparent net score adds the existing versioned dignity, placement and
functional-role components. Rahu/Ketu occupancy remains a review point rather
than receiving an invented classical dignity or functional score. No hidden
weighting is applied.

If at least one positive and one negative component are both present, the
result is always `Mixed`, regardless of the arithmetic total. This preserves
contradictory evidence for the astrologer. High confidence is allowed only when
there is no contradiction, the absolute score is at least three, and at least
three distinct evidence rules are present; all other integrated drafts use
medium confidence.

Every narrative states that Navamsha, exact aspect strength, full Shadbala, Dasha
and transit are not included. Therefore this family does not claim that a
specific event happened or will happen on a date, and produces no timing window.

## Enabled rule family: Panch Mahapurusha formation v1

The D1 formation detector covers five named yogas:

| Planet | Yoga | Required dignity |
| --- | --- | --- |
| Mars | Ruchaka | own sign or exalted |
| Mercury | Bhadra | own sign or exalted |
| Jupiter | Hamsa | own sign or exalted |
| Venus | Malavya | own sign or exalted |
| Saturn | Shasha | own sign or exalted |

The qualifying planet must simultaneously occupy whole-sign house 1, 4, 7 or
10 from Lagna. Kendra placement and dignity are retained as separate evidence.
Combustion, retrograde state, planetary-war proximity and Rahu/Ketu same-sign
contact change the result to a mixed strength-review draft; they do not silently
erase the structural formation. Full Shadbala, D9 agreement, broader affliction and
Dasha activation remain unavailable, so no guaranteed result is generated.

## Enabled rule family: Kuja-dosha Lagna review screen v1

The screen deliberately distinguishes two profiles:

- core Lagna profile: Mars in house 1, 4, 7, 8 or 12;
- extended variant: Mars in the 2nd house.

The finding is always `Mixed` and medium confidence because this is a screening
flag rather than a marriage verdict. Own/exalted Mars and an enabled Jupiter
conjunction/full-sign aspect are shown as possible mitigation evidence, never
as automatic cancellation. Moon/Venus reference counts, D9, the complete
seventh-house condition, partner comparison and disputed regional cancellation
rules remain outside v1. The screen must not be used alone to infer divorce,
harm or death of a spouse.

## Enabled rule family: BPHS Gajakesari profile v1

The applied profile follows the full Chapter 36 formation rather than labelling
Jupiter-Moon angularity alone as completed Gajakesari Yoga. It requires:

1. Jupiter in whole-sign Kendra 1/4/7/10 from Lagna or the Moon;
2. conjunction or enabled full-sign aspect from Mercury or Venus;
3. Jupiter not debilitated, combust or in a natural-enemy sign.

Mercury and Venus are the enabled unconditional benefic-support profile. Lunar
benefic status is not silently assumed because waxing/waning strength is not
part of the current judgment input. If angular geometry exists but another
qualifier fails, the engine emits a `Mixed`, medium-confidence candidate and
lists every failed qualifier. A complete v1 formation receives high confidence
because geometry, benefic support and Jupiter condition are independent rules.
Neither state guarantees wealth, rank or a timed event.

## Enabled rule family: Raja and Dhana formations v1

The first Raja Yoga rule requires the Lagna lord and fifth lord to conjoin in
whole-sign house 1, 4, 5, 7, 9 or 10. Conjunction and Kendra/Trikona placement
are separate evidence records.

The first Dhana Yoga rule implements the general Chapter 41 affluence formula:
the fifth lord occupies its own fifth house and the eleventh lord occupies its
own eleventh house. Each lord placement is independently evidenced.

For both formations, enabled debilitation or combustion of a participant
changes the result to `Mixed`/medium confidence instead of erasing the
formation. D9/D10, full Shadbala, liabilities and broader contradictory rules remain
incomplete. The new Dasha family may show whether a participant's period is
active, but it does not promise office, authority, status or wealth.

## Enabled rule family: D1-D9 dignity agreement v1

For each of the seven classical planets, the engine compares broad sign dignity
in D1 and D9. The two signs and dignity classifications remain independent
evidence. Opposing positive/negative dignity is always `Mixed`. Agreement in
the same non-neutral direction may receive high confidence; one-sided or
neutral evidence remains medium confidence.

The planet is labelled Vargottama when its D1 and D9 signs are identical. This
is a structural flag, not an automatic favourable result: a same-sign
debilitated placement remains challenging. The dignity-agreement family itself still does not infer D9 houses or aspects;
those are handled by the separate D9 House/Lord/Aspect Interpretation v1 family.
Foundation v10 provides governed Sthana, Dig, Nathonnata, Paksha, Tribhaga, Varsha, Masa, Dina, Hora, Ayana, Cheshta, Naisargika and Drik Bala for current `vedic-chart-v9`/`v10` output when their required solar-event context is available, plus Yuddha correction when the latitude contract is sufficient. When all six strength families are complete, the engine publishes the sixfold total in Virupas/Rupas and the BPHS 27.32-33 required-strength ratio/status. Legacy or incomplete evidence keeps the aggregate unavailable rather than approximated; legacy v1-v4 outputs without persisted daily speed still leave Mars-Saturn Cheshta unavailable.
Current `vedic-chart-v10` retains the v9 fields and persists `metadata.sunHourAngleHours` from the offline Astronomy Engine Sun hour-angle function and, where rise/set search succeeds, `tribhagaIsDay`, `tribhagaThird`, `tribhagaPeriodStartUtc` and `tribhagaPeriodEndUtc`. Nathonnata Bala v1 applies BPHS 27.9 to that apparent solar-time evidence: the angular time distance from apparent midnight (Sun hour angle 12h) is converted to ghatis; Moon/Mars/Saturn receive twice Nata, Sun/Jupiter/Venus receive the 60-virupa complement, and Mercury is fixed at 60. Legacy v1-v5 outputs leave Nathonnata unavailable rather than approximating apparent time from civil clock time.


## Enabled rule family: D9 House/Lord/Aspect Interpretation v1

For `vedic-chart-v2` and later, the engine requires the explicit Navamsha chart
with D9 ascendant and all nine body signs. The explicit D9 body sign must agree
with the per-planet `navamsaSignIndex`; disagreement is rejected before
interpretation. Legacy `vedic-chart-v1` snapshots remain readable but do not
receive D9 house synthesis.

For each of the twelve D9 whole-sign houses the profile records the sign,
classical sign lord, the lord's occupied D9 house and broad D9 dignity. It then
adds visible occupancy and the same enabled Parashari full-sign aspect geometry
used elsewhere: universal seventh aspects plus Mars fourth/eighth, Jupiter
fifth/ninth and Saturn third/tenth. Rahu/Ketu occupancy is shown but contributes
no invented dignity or directional score, and node aspects remain disabled.

The transparent net score is built from four visible component families: D9
house-lord placement, D9 house-lord dignity, other classical occupants'
D9-ascendant functional direction and enabled classical aspectors' functional
direction. The house lord is not double-counted as an occupant. If positive and
negative non-zero components coexist, the result is forced to `Mixed` regardless
of arithmetic. Directional results are capped at Medium confidence and Mixed
results remain Low. This is a Navamsha structural review layer; it does not
replace the natal D1 house promise and does not guarantee an event.

## Enabled rule family: Twelve houses and functional ownership v1

For every whole-sign house, the engine now records:

- the house sign and classical sign lord;
- the house lord's occupied whole-sign house;
- the lord's exalted, own-sign, debilitated or neutral dignity;
- the lord's ascendant-specific ownership tendency;
- a bilingual Supportive, Challenging or Mixed first-pass finding.

House-condition scoring reuses the reviewed dignity and placement table above.
Occupants, aspects, combustion and planetary friendship appear in separate
findings and are not folded into that house score; the Shadbala foundation and divisional
agreement remain unavailable.

Functional ownership is deliberately transparent and provisional:

| Owned house | Score |
| --- | ---: |
| 1 | +2 |
| 2 | 0 |
| 3 | -1 |
| 4 | +1 |
| 5 | +2 |
| 6 | -2 |
| 7 | 0 |
| 8 | -2 |
| 9 | +2 |
| 10 | +1 |
| 11 | -1 |
| 12 | -1 |

Owning both a Kendra (4, 7 or 10) and a Trikona (5 or 9) adds one transparent
Yoga-karaka flag point. Totals of +2 or more are labelled Supportive, -2 or
less Challenging, and the middle range Mixed. The UI calls these functional
*tendencies*, because full Parashari exceptions, associations and yoga
cancellation are not implemented yet.

## Enabled rule family: Occupancy, aspects and planet conditions v1

The engine emits one occupancy record for every house. An empty house is
explicitly described as not automatically weak. Occupied-house polarity uses
the already visible provisional functional-ownership scores; it never replaces
the house-lord condition.

Full Parashari sign aspects are enabled as follows:

| Planet | Full aspects counted from its occupied sign |
| --- | --- |
| All seven classical planets | 7th |
| Mars | 4th and 8th additionally |
| Jupiter | 5th and 9th additionally |
| Saturn | 3rd and 10th additionally |

Rahu/Ketu aspects are excluded because classical/practitioner traditions differ.
The current output describes the target house and resident planets. It also
groups two or more unique full-sign aspectors by target house and synthesizes
their transparent functional tendencies. Partial aspect strength remains out of
scope.

## Enabled rule family: Friendship, Moolatrikona and conjunctions v1

For each classical planet, the engine records its permanent natural relationship
toward the lord of its occupied sign: own, friend, neutral or enemy. For
non-own placements it also derives the temporary relationship from the
dispositor's relative sign: 2nd, 3rd, 4th, 10th, 11th and 12th are temporary
friends; all other positions are temporary enemies. Natural and temporary
relationships are combined into great friend, friend, neutral, enemy or great
enemy.

Degree-specific Moolatrikona intervals use half-open boundaries `[start, end)`:

| Planet | Sign | Interval |
| --- | --- | ---: |
| Sun | Leo | 0°–20° |
| Moon | Taurus | 3°–30° |
| Mars | Aries | 0°–12° |
| Mercury | Virgo | 15°–20° |
| Jupiter | Sagittarius | 0°–10° |
| Venus | Libra | 0°–15° |
| Saturn | Aquarius | 0°–20° |

Every pair sharing a sign receives a conjunction record with circular angular
separation. Its provisional polarity uses functional ownership only when both
bodies are classical planets.

## Enabled rule family: Planetary-war proximity review v1

Mars, Mercury, Jupiter, Venus and Saturn are checked pairwise. A circular
longitude separation of 1° or less creates a mixed review finding. Sun, Moon,
Rahu and Ketu do not enter this profile. The finding never declares a victor:
verified celestial latitude/declination, apparent brightness and disc evidence
are not available in `vedic-chart-v1`. This prevents longitude alone from being
presented as a settled classical result.

Combustion uses the versioned profile recorded in
`ASTROLOGY_RULE_SOURCES.md`: Moon 12°, Mars 17° direct/8° retrograde, Mercury
14°/12°, Jupiter 11°, Venus 10°/8°, and Saturn 16°. Circular angular distance
from the Sun is calculated from verified sidereal longitudes. A match creates a
medium-confidence review flag and never treats a planet as destroyed.

Verified negative longitude speed creates a separate retrograde finding for
Mars, Mercury, Jupiter, Venus or Saturn. Its polarity is always Mixed because
retrograde motion is not automatically favourable or unfavourable.

## Dasha × transit confirmation profile v1

`VedicTimingSynthesisEngine` compares two outputs that remain independently
auditable: the active Vimshottari MD/AD/PD chain and the selected-date transit
analysis. It does not introduce a universal event rule or claim that agreement
proves an event. The active Dasha side reuses the governed 3:2:1 weighting
(Mahadasha ×3, Antardasha ×2, Pratyantardasha ×1). Opposite non-zero Dasha-lord
signals remain Mixed. The transit side aggregates only explicitly directional
findings from enabled transit profiles; Mixed findings are non-directional.

The v1 comparison states are:

- supportive Dasha + supportive directional transit → supportive convergence,
  medium confidence;
- challenging Dasha + challenging directional transit → challenging convergence,
  medium confidence;
- opposite directional layers → Mixed conflict, medium confidence;
- any Mixed/non-directional layer → Mixed, low confidence.

Absence of a supportive transit is never converted into an adverse signal.
Question-specific house triggers, divisional timing, exact-degree
triggers and Ketu transit polarity remains outside this base synthesis layer; source-bounded Rahu transit v3 may participate as a directional finding. Ashtakavarga timing is consumed by Question-specific Timing v3 rather than retrofitted into this two-layer base synthesis. A modern
source-bounded methodology cross-check is recorded in
`ASTROLOGY_RULE_SOURCES.md`; the implementation deliberately avoids presenting
Dasha-plus-transit agreement as a classical universal guarantee.

## Question-specific timing profile v3

`VedicQuestionTimingEngine` narrows the already-governed natal, Dasha and
transit layers to the consultation topic and, in v3, adds unreduced Ashtakavarga transit confirmation refined by the active Kaksha micro-zone. It does not add a literal classical
event promise. Each topic uses a versioned whole-sign target-house set:

- Career / employment: 10, 6, 11.
- Business / partnership: 10, 7, 11, 2.
- Marriage / partnership: 7, 2, 11.
- Finance / gains: 2, 11.
- Education / higher learning: 5, 9.

For each classical planet physically occupying a target house on the selected date, v3 reads that planet's unreduced BAV positive-mark count in the transit sign and the same sign's SAV band. The whole-sign profile uses BAV 5-8 = supportive, 4 = Mixed and 0-3 = challenging. It then divides the sign into eight 3°45′ half-open Kaksha zones in the fixed Saturn→Jupiter→Mars→Sun→Venus→Mercury→Moon→Lagna order and checks whether the active Kaksha lord contributed a positive mark in the same BAV sign. A directional Ashtakavarga timing signal is emitted only when BAV, SAV and Kaksha agree; disagreement remains Mixed. Ashtakavarga cannot replace missing Dasha topic activation, and conflict with Moon-gochara is preserved as Mixed/Low. Rahu/Ketu remain excluded.
- Property / home assets: 4, 2, 11.
- Children / progeny: 5, 2, 11.
- Travel / relocation: 12, 4; this is intentionally a conservative
  foreign-stay/home-axis profile rather than a universal journey rule.

The natal layer requires the existing detailed synthesis record for every target
house. The Dasha layer applies the existing MD ×3, AD ×2, PD ×1 hierarchy, but
a lord contributes only if its governed activation life areas overlap the
selected topic. The transit layer accepts only an already-directional
Moon-gochara finding whose same transiting planet is physically in one of the
topic's target houses from Lagna. Mixed transit findings and Ketu are
non-directional.

The v3 result is Medium confidence only when the governed timing families converge and
the natal target-house baseline is not explicitly opposite. Natal conflict,
Dasha/transit disagreement, missing topical transit or missing Dasha topic
activation are preserved as Mixed/Low or Dasha-led Low review states. High
confidence is disabled until further governed timing families are implemented.
General and Health consultations are not automatically routed into this engine;
medical event timing is outside scope.

## Full conflict and confidence profile v2

`VedicConflictConfidenceEngine` v2 is a topic-specific governance layer above the
question-timing output. It does not add a new astrological event rule. It keeps
five visible evidence layers while counting at most four governed evidence
groups:

1. **Structure** — the detailed D1 target-house baseline plus D1-D9 dignity
   agreement for the unique lords of those target houses. These are correlated
   chart-structure signals and therefore never count as two confirmations.
2. **Dasha** — the already-governed topic-weighted active MD/AD/PD direction.
3. **Moon-gochara transit** — only the already-enabled directional topical
   transit occupying a governed target house.
4. **Ashtakavarga transit** — the question-timing-v3 aggregate derived from
   planet-specific unreduced BAV plus the same transit sign's SAV context. Every
   qualifying planet/check remains visible, but the entire family counts as one
   group so repeated planets cannot inflate confidence.

The target-house lords are derived deterministically from the natal sidereal
Ascendant and whole-sign target houses. The engine requires `vedic-chart-v2` or
later so the D1-D9 findings are available and verifies that the natal polarity
inside the question-timing record still matches the immutable Kundli findings.
For `vedic-question-timing-v3`, it also verifies that the Ashtakavarga
directional flag, directional planet list and aggregate polarity exactly match
the supplied per-transit checks.

Resolution policy:

- D1 target-house direction opposite to the relevant D1-D9 agreement is an
  explicit structural conflict → `Mixed`, Low confidence. Dasha/transit-family
  agreement cannot override it.
- Opposing directional Ashtakavarga checks create an explicit internal family
  conflict → `Mixed`, Low confidence. Multiple checks are never majority-voted.
- Opposite directions among Structure/Dasha/Moon-gochara/Ashtakavarga groups →
  `Mixed`, Low confidence; majority voting is disabled.
- Four governed groups directional and in the same direction → that direction,
  Medium confidence. High stays disabled because the two transit families share
  selected-date positional evidence.
- Any three governed groups directional and in the same direction, with the
  fourth unavailable/non-directional → that direction, Medium confidence.
- Two governed groups in the same direction → that direction, Low confidence.
- One or zero directional groups → no combined directional verdict; `Mixed`,
  Low confidence.

The output contract is `vedic-conflict-confidence-v2`. It records every visible
layer, its evidence group, source codes, evidence, target-house lords,
structural polarity, resolution code, directional-group counts, conflict flag,
bilingual narratives and mandatory professional-review warnings.

## Enabled rule family: Shadbala foundation v10

`VedicShadbalaEngine` publishes a quantitative strength foundation for Sun,
Moon, Mars, Mercury, Jupiter, Venus and Saturn only. It calculates Uccha Bala
from distance to the versioned deep-debilitation point; Saptavargaja Bala from
D1, D2, D3, D7, D9, D12 and D30; Ojhayugma Bala from Rasi/Navamsha parity;
Kendradi Bala from the app's governed whole-sign house frame; and Drekkana Bala
from the BPHS 27.6 male-first/female-second/hermaphrodite-third decanate rule. These five values are summed as the
published Sthana Bala. Dig Bala is calculated from exact sidereal planetary and Ascendant longitudes using the BPHS 27.7 zero-strength directional points, folding angular distance to at most 180° and dividing by 3 for a 0–60 virupa result. Paksha Bala follows BPHS 27.10-11: the Sun-Moon separation is folded to at most 180°, divided by 3 for the benefic group (Moon/Mercury/Jupiter/Venus), with the 60-complement assigned to Sun/Mars/Saturn. Ayana Bala follows BPHS 27.15-17 from tropical longitude using the 45/33/12 khanda interpolation and planet-group north/south rule. Fixed Naisargika Bala is stored separately.

The Saptavargaja relation scale is Moolatrikona 45, own 30, great friend 20,
friend 15, neutral 10, enemy 4 and great enemy 2 virupas. Version 3 retains the earlier rule that resolves
Tatkalika Maitri from natal Rasi positions for all seven varga contributions.
That choice is explicit because source traditions differ on whether temporary
friendship should instead be recalculated inside each derived varga.

Cheshta foundation v1 is part of this contract. BPHS 27.18 is applied directly for the luminaries: Sun Cheshta equals its computed Ayana Bala and Moon Cheshta equals its computed Paksha Bala. For Mars, Mercury, Jupiter, Venus and Saturn, current `vedic-chart-v9`/`v10` output persists exact ephemeris daily longitude speed. The versioned `bphsMotionStateSpeedProfileV1` compares absolute speed with a governed nominal mean daily motion and uses one-day sign-entry projection to distinguish the eight BPHS motion labels where applicable: Vakra 60, Anuvakra 30, Vikala 15, Manda 30, Mandatara 15, Sama 7.5, Chara 45 and Atichara 30 virupas. The profile is explicitly an operational speed-state mapping; it is **not** described as the separate BPHS 27.24-25 mean/true-longitude Cheshta-kendra calculation, because the required mean longitude/apogee inputs are not yet part of the audited chart contract. Legacy `vedic-chart-v1` through `v4` snapshots therefore leave Mars-Saturn Cheshta unavailable rather than inferring it from a retrograde boolean.

Drik Bala v1 uses exact sidereal longitude differences and the versioned `bphsSphutaDrishtiDrikV1` profile. The common Chapter-26 six-range Sphuta-Drishti curve is applied to all aspectors, with special Mars/Jupiter/Saturn curves preserving their classical full-strength aspect peaks. Because published translations disagree on Jupiter's 240°–270° branch, v1 records an explicit continuity-preserving corrected branch (60 virupas at 240°, declining to 15 at 270°) rather than silently mixing variants. For BPHS 27.19 weighting, Sun/Mars/Saturn are malefic, Venus/Jupiter benefic, Moon follows waxing/waning phase, and Mercury's quarter term follows a governed same-sign association rule; the entire measured Mercury and Jupiter aspect is then super-added as required by the selected local translation profile. Rahu/Ketu neither aspect nor receive Shadbala Drik contributions. Drik may be negative and is never clamped to zero.

Current `vedic-chart-v9`/`v10` records preserve a pre-war Kala subtotal of Nathonnata + Paksha + Tribhaga + Varsha + Masa + Dina + Hora + Ayana and then apply Yuddha separately. An isolated same-sign Mars-through-Saturn pair within 1° uses persisted geocentric ecliptic latitude as the versioned computational-victor criterion; BPHS 27.20 then adds the absolute pre-war sixfold-strength difference to the northern-latitude winner and deducts it from the loser. No-war is a computed 0; latitude ties, multi-war clusters, missing latitude and unavailable pre-war strength leave Yuddha and complete Kala unavailable rather than guessed. Tribhaga and Hora use actual solar-period boundaries; Varsha and Masa use prior sidereal solar ingresses with sunrise-based astrological weekday lords; Dina uses the current sunrise-to-sunrise weekday. The stored birth UTC offset remains the weekday-conversion convention until an IANA zone id is persisted. Legacy outputs omit newer evidence rather than fabricating it.

When Sthana, Dig, complete Kala, Cheshta, Naisargika and Drik are all available, foundation v10 publishes the sixfold total in Virupas and Rupas and evaluates it against the BPHS 27.32-33 required totals: Sun 390, Moon 360, Mars 300, Mercury 420, Jupiter 390, Venus 330 and Saturn 300 virupas. It stores `requiredStrengthRatio = total / required`, signed surplus/deficit and `meetsRequired` or `belowRequired`. If any family is incomplete, the total/ratio/status stay unavailable. The threshold is never converted into benefic/malefic polarity, guaranteed event delivery or automatic remedy advice.


## Enabled rule family: Advanced Yoga & Dosha v1

`advanced-yoga-dosha-v1` is implemented in a separate engine module. It adds a bounded same-sign-conjunction subset for ninth/tenth and selected Kendra/Kona lord Raja-Yoga structures, the exact enabled BPHS Chapter 41 verses 2-8 Dhana formations, Phaladeepika VI.57 Harsha/Sarala/Vimala dusthana-lord profiles, and Phaladeepika VII.27-29 Neecha-bhanga review conditions. The relationship operator in v1 is deliberately limited to the explicitly implemented conjunction/aspect geometry; it does not silently treat exchange or every possible sambandha as equivalent.

Weakening review (debilitation, combustion and same-sign node contact) is operational metadata, not a universal classical cancellation doctrine. Neecha-bhanga remains Mixed and never deletes the natal debilitation or automatically relabels a planet strong/benefic. Multi-reference Kuja review checks Lagna, Moon and Venus, keeps the second-house extension separate, records dignity/D9/Jupiter mitigation evidence, and forbids standalone divorce, injury, abuse, spouse-harm or death predictions. Multi-yoga synthesis preserves contradictory formations rather than majority-voting them away and is capped at Medium confidence.


## Enabled rule family: Vedic Remedy Recommendation v1

`vedic-remedy-recommendation-v1` is a deliberately conservative post-judgment
layer. It groups only challenging findings by actionable life area and requires
at least two distinct evidence rule ids before producing a remedy draft. The
engine does not majority-vote mixed/supportive evidence into a remedy.

v1 automates only behavioural risk-management guidance: planning, documented
communication, budgeting/due diligence, study routines, qualified medical
assessment for symptoms, professional/legal verification for property, and
other practical safeguards appropriate to the life area. These actions are not
claimed to alter planetary effects and are never presented as guaranteed
astrological cures. Longevity/death-type automation is excluded entirely.

Planetary mantra, charity and ritual prescriptions remain disabled in this rule family. Gemstone review is now delegated to `vedic-gemstone-candidate-v1`, which emits only `eligible`, `contraindicated` or `insufficientEvidence` status after combining functional lordship, complete Shadbala sufficiency, D1/D9 dignity, combustion/Yuddha/node-contact conditions and the active Mahadasha/Antardasha context. It never auto-approves a gemstone or wearing protocol. Practitioner-entered gemstone records remain subject to the existing verified-output, evidence and astrologer-approval gate.

## Remaining rule families

1. Partial aspect strength and broader conjunction/aspect conflict synthesis.
2. Later divisional charts beyond D10, beginning with governed D7 and D12 interpretation.
3. Broader Yoga/Dosha catalogs beyond the governed v1 subset and Ashtakavarga Pinda-derived timing extensions.
4. Deeper conflict-confidence integration of the full D9 house family and
   complete Shadbala strength family.
5. Node/degree transit extensions and broader event-family timing.
6. Broader gemstone lineage profiles beyond the completed strengthening/contraindication v1 screen; mantra, charity and ritual source families.

No family is enabled until its required verified chart fields and golden
fixtures exist.


## Enabled rule family: Ashtakavarga foundation v3

The foundation builds seven unreduced Bhinnashtakavarga tables for Sun through Saturn. Each table receives binary positive marks from eight references: Sun, Moon, Mars, Mercury, Jupiter, Venus, Saturn and Lagna. Rahu/Ketu are excluded. The persisted term is `positiveMarks` because classical editions differ on whether the positive `1` is called Rekha/Sthana or modern software calls it Bindu.

The engine validates the fixed table totals Sun=48, Moon=49, Mars=39, Mercury=54, Jupiter=56, Venus=52 and Saturn=39, then sums the seven unreduced tables sign-by-sign into a 337-point Sarvashtakavarga. Raw SAV is mapped to whole-sign houses from Lagna. The selected BPHS 72 comparative profile classifies >30 as favourable, 25-30 as medium and <25 as adverse; these are review-grade comparative house-support findings and never guaranteed event outcomes. Foundation v3 separately applies Trikona Shodhana to each BAV, then occupancy-sensitive Ekadhipatya Shodhana to Mars/Mercury/Jupiter/Venus/Saturn sign pairs. Raw, Trikona and final reduced values plus action audits are retained. Reduced values are a later calculation stage and never inherit raw SAV bands. Question-specific Timing v3 continues to consume unreduced BAV and SAV as its governed transit-confirmation family.


## Enabled rule family: D10 Dashamsa career interpretation v1

`vedic-chart-v10` introduces the explicit Dashamsa chart using the BPHS D10 mapping: each Rashi is divided into ten 3-degree parts; odd signs count from themselves, even signs count from the ninth sign from the natal sign. The calculation output stores the profile id `bphs-dashamsa-odd-self-even-ninth-v1`, explicit D10 Ascendant and D10 sign for every displayed body.

`VedicDashamsaInterpretationEngine` (`dashamsa-career-interpretation-v1`) builds twelve whole-sign D10 house records. Each record audits the house sign/lord, lord placement and dignity, classical occupants, enabled Parashari full-sign aspects and transparent component score. Rahu/Ketu are occupancy-only and do not receive invented dignity or aspects. Mixed component directions remain Mixed/Low; v1 never emits High confidence.

The single career synthesis first identifies the D1 tenth lord, then reviews that lord's placement/dignity inside D10 and independently reads the D10 tenth-house structural record. Only agreement between two directional structural families yields a Supportive or Challenging Medium-confidence result. Conflict or missing direction is preserved as Mixed/Low. D10 remains a career-domain structural cross-check and is not used alone to choose a profession, guarantee status/promotion or generate timing.

## Advanced Rahu/Ketu v1

`VedicRahuKetuEngine` (`rahu-ketu-analysis-v1`) keeps natal, Dasha and transit node logic separate. Natal Rahu/Ketu house themes are source-bounded to Phaladeepika VIII.25-34 and are paraphrased rather than converted into guaranteed events. Sign dispositor and explicit same-sign classical associations are recorded, but no Rahu/Ketu dignity, exaltation/debilitation or node aspects are invented. For Dasha review, Phaladeepika XX.39 is applied only to Rahu's explicitly associated classical carrier direction; XX.52-53 add Medium-capped Kendra/Trikona and benefic-sign connection candidates for both nodes. Opposing Rahu carrier directions force Mixed. `VedicTransitEngine` v3 adds Rahu's Moon-relative house sequence from Phaladeepika XXVI.24 while Ketu remains non-directional. Node evidence alone cannot establish medical, mortality, legal, financial or relationship events.


## Numerology name-candidate comparison governance

Numerology `2.1.0` / `numerology-analysis-v3` may consume the calculation
engine's `astro-logic-name-candidate-comparison-v1` records. Each review reports
only deterministic arithmetic differences from the stored original-name
baseline: Pythagorean/Chaldean compound and reduced-number deltas,
Soul-Urge/Personality change flags and arithmetic overlaps with Driver, Life
Path and Maturity. Comparison confidence is capped at Medium because the
arithmetic is deterministic; overall Numerology prediction confidence remains
Low.

The engine does not rank candidates, infer that more core-number overlap is
better, choose a best/lucky spelling, recommend a legal-name change or use a
candidate to approve a gemstone/remedy. An optional practitioner-selected
professional discussion focus is human context only and is integrity-bound in
the immutable Numerology snapshot.

## Enabled rule family: KP Advanced Significator & Event Judgment v1

`kp-house-significator-synthesis-v1` operates only on the governed native KP Placidus chart. Each planet receives an occupied house from the forward cusp interval containing its sidereal longitude. House ownership is taken from the sign lord on each cusp; Rahu/Ketu receive no sign ownership. The existing four-level significator hierarchy is then materialized without changing its order or collapsing levels.

`kp-cusp-sublord-promise-review-v1` is a practitioner-review layer, not an empirical probability engine. v1 enables only two source-bounded profiles: Marriage uses the 7th cusp and conductive houses 2/7/11 with detrimental houses 1/6/10; Children uses the 5th cusp and conductive houses 2/5/11 with detriments derived as 1/4/10. The primary cusp's sub lord is looked up in the chart significator matrix. Conductive-only evidence yields `promise`, detrimental-only evidence yields `denial`, and mixed/no-direction evidence remains `insufficientEvidence`. The latter is intentionally used instead of forcing the source tradition's mixed-period interpretation because KP timing synthesis is not yet enabled.

The engine never returns High confidence, does not guarantee a marriage/childbirth outcome, does not automate health or mortality events, and does not use Vedic/Numerology agreement to raise confidence. Other consultation categories remain judgment-gated until their own source profile and regression fixtures are frozen.
