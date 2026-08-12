# Numerology v2 rule-source register

These references document **traditional Numerology conventions**. They are not
scientific validation. ASTRO LOGIC freezes a named operational profile whenever
published schools differ instead of silently treating one convention as
universal.

## Life Path component reduction

World Numerology / Hans Decoz describes reducing the month, day and year
separately, preserving Master Numbers, then adding and reducing the final sum:

- https://www.worldnumerology.com/numerology-life-path/
- https://www.worldnumerology.com/numerology-life-path/life-path-number-11/

Applied rule: `numerology.birth.life_path.component_reduction.v2`.

## Personal Year school selection and disagreement

Felicia Bender explicitly describes a current-calendar-year Personal Year mode
and separately discusses a birthday-to-birthday school, making the school
choice visible rather than universal:

- https://feliciabender.com/monthly-forecast/
- https://feliciabender.com/numerology/master-11-2-personal-year/

World Numerology documents a different Master Number policy for date cycles,
reducing Masters during Personal Year/Month/Day calculation:

- https://www.worldnumerology.com/numerology-master-numbers/

Because these published conventions conflict, ASTRO LOGIC v2 freezes its own
calendar-cycle profile: month/day/universal-year roots are single digits and the
**final** cycle total may preserve `11/22/33`. The formula and profile id are
serialized. This selected profile is not described as the universally correct
Numerology method.

Applied rule: `numerology.cycle.personal_year.calendar_v2`.

## Pythagorean and Chaldean name mappings

- https://numerologist.com/numerology/name-numerology-calculation
- https://suspha.github.io/numerology/

The exact applied letter tables, the `A/E/I/O/U` vowel policy, treatment of `Y`,
and Master Number behavior are frozen in `NUMEROLOGY_ENGINE.md`; external pages
are not runtime dependencies.

## Maturity synthesis

World Numerology describes the Maturity number as the sum of Expression and Life
Path:

- https://www.worldnumerology.com/numerology-articles/numerology-maturity-number.html

ASTRO LOGIC uses this only as a symbolic synthesis. It does not generate an
age-triggered prediction from the source's interpretive claims.

Applied rule: `numerology.core.maturity.life_path_plus_expression.v1`.

## Indian number-to-planet review mapping

A traditional Indian numerology mapping used for the optional guarded Vedic
cross-check is documented in contemporary astrology/numerology material,
including 4→Rahu and 7→Ketu:

- https://timesofindia.indiatimes.com/astrology/numerology-tarot/ruling-numbers-and-their-planets-how-numerology-connects-to-astrology/articleshow/114576206.cms
- https://timesofindia.indiatimes.com/astrology/numerology-tarot/the-power-of-birth-dates-how-to-identify-your-lord-planet/articleshow/108236169.cms

Applied mapping profile:
`traditional-number-planet-correspondence-v1` =
`1 Sun, 2 Moon, 3 Jupiter, 4 Rahu, 5 Mercury, 6 Venus, 7 Ketu, 8 Saturn, 9 Mars`.

This mapping is **not** treated as independent Vedic evidence. Western-derived
Numerology sources sometimes associate 4/7 with Uranus/Neptune instead; ASTRO
LOGIC therefore labels the selected Indian mapping profile explicitly and never
uses it to increase prediction confidence or approve a gemstone.

## Interpretation safety

Single-number symbolic meanings are retained only as traditional review themes:

- https://www.worldnumerology.com/numerology-single-digit-numbers/

The app converts these themes into optional low-risk planning/reflection prompts
only. It does not convert them into promises, medical/legal/financial advice,
compulsory rituals or automatic gemstone prescriptions.

## Alternate-name comparison v1

`astro-logic-name-candidate-comparison-v1` introduces **no new predictive or
remedial source family**. Every practitioner-entered alternate Latin spelling is
recalculated with the same frozen Pythagorean and Chaldean mappings documented
above, then compared arithmetically with the immutable original-name baseline.
Compound/reduced deltas, Soul Urge/Personality changes and core-number overlaps
are descriptive audit fields only. They are not a favourability score, ranking,
"lucky name" test or evidence for a legal-name change.

At most one candidate may be explicitly marked by the practitioner as a
professional discussion focus. That human selection is serialized and
SHA-256-bound with the Numerology snapshot; it is never represented as an
engine recommendation.
