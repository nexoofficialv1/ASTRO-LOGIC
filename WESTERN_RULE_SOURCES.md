# WESTERN_RULE_SOURCES.md

## Scope enabled in v082 — Western Modern Planets & Aspect Pattern Expansion v1

This file is provenance for deterministic ASTRO LOGIC Western rule profiles. Astrology-source citations document the convention being encoded; they are not scientific validation of astrological interpretation. Astronomical positions are kept separate from interpretive rule governance.

### Astronomical implementation and independent fixtures

- Pinned implementation: Astronomy Engine `v2.1.19` (MIT):
  - https://github.com/cosinekitty/astronomy
  - The upstream API includes Uranus, Neptune and Pluto and documents geocentric vectors/positions. Upstream states its planetary calculations are tested against NOVAS, JPL Horizons and other ephemeris sources.
- Authoritative external ephemeris path: NASA/JPL Horizons API:
  - https://ssd-api.jpl.nasa.gov/doc/horizons.html
  - https://ssd.jpl.nasa.gov/api.html
- ASTRO LOGIC native policy: `AL_BODY_URANUS=7`, `AL_BODY_NEPTUNE=8`, `AL_BODY_PLUTO=9` map directly to Astronomy Engine bodies. Legacy codes 0–6 are unchanged. No approximate outer-planet longitude formula or silent fallback is allowed.
- Independent v082 spot fixture: `native/tests/western_modern_reference_fixtures.json`. It records rounded public tropical ephemeris values for 2026-08-12T17:19:00Z and uses a deliberately loose 0.02° tolerance because the independent listing is rounded. It is a regression cross-check, not a substitute for JPL-grade ephemeris certification.

### Rulership profiles

Profiles:
- `western-rulership-traditional-v1`
- `western-rulership-modern-v1`

Astrodienst's ruler introduction explicitly distinguishes the old rulers from the modern outer-planet assignments:
- https://www.astro.com/astrology/in_ruler_e.htm

Governed mappings retained by ASTRO LOGIC:
- Traditional: Scorpio = Mars; Aquarius = Saturn; Pisces = Jupiter.
- Modern: Scorpio = Pluto; Aquarius = Uranus; Pisces = Neptune.

The modern selector changes sign-ruler evidence only. It does **not** mutate `western-essential-dignity-major-v1`. Domicile/exaltation/detriment/fall evidence remains the v081 seven-traditional-planet profile. This separation is intentional because modern dignity schemes are not uniform, and v082 does not silently manufacture a new dignity table.

### Aspect profiles

Major profile remains `western-major-aspect-orb-v1`:
- conjunction 0° / 8° orb
- sextile 60° / 4° orb
- square 90° / 6° orb
- trine 120° / 6° orb
- opposition 180° / 8° orb

Optional minor profile: `western-major-minor-aspect-orb-v1`. Exact-angle provenance:
- Astrodienst aspect introduction: semisextile 30°, semisquare 45°, sesquisquare/sesquiquadrate 135°:
  - https://www.astro.com/astrology/in_aspect_e.htm
- Astrodienst Quintile: 72°:
  - https://www.astro.com/astrowiki/en/Quintile
- Astrodienst Quincunx: 150°:
  - https://www.astro.com/astrowiki/en/Quincunx

Frozen ASTRO LOGIC v1 minor orbs:
- semisextile 2°
- semisquare 2°
- quintile 2°
- sesquiquadrate 2°
- quincunx 3°

These orb widths are **versioned operational policy**, not a claim of a universal historical or modern standard. Minor aspects are off under the default `majorOnly` profile and can only appear when `majorAndMinor` is explicitly selected. Lunar nodes remain outside the planetary aspect matrix.

### Aspect-pattern synthesis profile

Profile: `western-aspect-pattern-v1`. A pattern is emitted only if every required component aspect is already present under the selected governed orb profile. Each result retains component planets, exact aspect type, actual separation, orb, orb limit and applying/separating evidence. Different/overlapping pattern types are preserved rather than majority-resolved. No automatic event prediction is attached.

Rule provenance and deterministic definitions:
- **Grand Trine** — three planets connected by three trines. Astrodienst: https://www.astro.com/astrowiki/en/Grand_Trine
- **T-Square** — one opposition with a third planet square to both ends. Astrodienst: https://www.astro.com/astrowiki/en/T-Square
- **Grand Cross** — two oppositions and four squares among four planets. Astrodienst: https://www.astro.com/astrowiki/en/Grand_Cross
- **Stellium** — Astrodienst describes a conjunction of more than two planets, noting some astrologers require more than three: https://www.astro.com/astrowiki/en/Stellium . Because the threshold/conjunction span varies by school, ASTRO LOGIC v1 uses a conservative operationalization: at least three planets forming a complete conjunction clique under the configured conjunction orb, and only the maximal clique is emitted. This deliberately avoids loose same-sign grouping.
- **Yod** — one apex linked by two 150° quincunxes to a 60° sextile base. Astrodienst: https://www.astro.com/astrowiki/en/Yod . Yod is disabled when minor aspects are disabled.
- **Kite** — a Grand Trine plus a fourth planet opposite one trine vertex and sextile the other two. Astrodienst's Grand Trine page gives this exact construction; Skyscript independently states the same geometry: https://www.astro.com/astrowiki/en/Grand_Trine and https://www.skyscript.co.uk/aspects2.html

Loose angular resemblance is insufficient. ASTRO LOGIC does not infer missing component aspects, widen pattern-specific orbs, or create a life-event conclusion from a pattern.

### Output governance

`western-natal-chart-v2` records at minimum the tropical zodiac profile, selected house system/profile, rulership profile/version, aspect profile/version, minor-aspect enabled state, modern-planet profile/enabled state, pattern-engine version and unchanged traditional dignity profile. Governance explicitly stores `crossSystemConfidenceUplift=false` and `automaticRealWorldPrediction=false`.

---

## Scope enabled in v081 — Western Astrology Foundation v1

ASTRO LOGIC treats Western astrology as an independent practitioner-review system. Western evidence must not be counted as independent confirmation of Vedic, KP, Numerology or any other system merely because two systems use the same astronomical birth data.

### Astronomical frame

- Zodiac profile: `western-tropical-zodiac-v1`.
- Planetary longitudes: tropical geocentric longitudes from the existing MIT-licensed Astronomy Engine native core.
- House systems enabled in v081:
  - `western-placidus-native-v1`
  - `western-whole-sign-v1`
  - `western-equal-ascendant-v1`
- Placidus geometry reuses ASTRO LOGIC's independently implemented native time-division solver. It does **not** link or bundle Swiss Ephemeris.
- Unsupported polar Placidus geometry is rejected rather than silently replaced by another house system.
- Astrodienst's public house-system documentation is retained as a development reference for the time-oriented Placidus definition and its polar limitation:
  - https://www.astro.com/swisseph/sweph_ht_f.htm
  - https://www.astro.com/swisseph/swisseph.htm

### Equal and Whole Sign profiles

- Equal: tropical Ascendant is cusp 1; all twelve cusps are exactly 30° apart.
- Whole Sign: the sign containing the tropical Ascendant becomes house 1; the sign boundary is the house cusp and all houses are exactly one sign wide.
- These are deterministic chart-construction profiles. ASTRO LOGIC does not auto-switch among them after a chart is saved.

### Major aspects v1

Profile: `western-major-aspect-orb-v1`.

Included exact angles:

- Conjunction: 0°
- Sextile: 60°
- Square: 90°
- Trine: 120°
- Opposition: 180°

Frozen operating orbs:

- Conjunction: 8°
- Sextile: 4°
- Square: 6°
- Trine: 6°
- Opposition: 8°

The angles are the classical/Ptolemaic major aspect family. **Orb width is not presented as a universal traditional standard.** The above values are an ASTRO LOGIC versioned operational profile and must remain visible in the output. Applying/separating status is derived from the native longitude-speed direction using a short deterministic forward comparison.

Lunar nodes are shown as chart points but are excluded from the v1 planetary aspect matrix to avoid silently adopting a disputed node-aspect convention.

### Essential dignity evidence v1

Profile: `western-essential-dignity-major-v1`.

Historical references retained for rule provenance:

- William Lilly, *Christian Astrology*, especially the table of essential dignities (public-domain index / transcription):
  - https://en.wikisource.org/wiki/Christian_Astrology
- Ptolemy, *Tetrabiblos*, Book I (public-domain transcription):
  - https://penelope.uchicago.edu/Thayer/E/Roman/Texts/Ptolemy/Tetrabiblos/1B*.html

v081 automates only the major sign conditions for the seven traditional planets:

- domicile
- exaltation
- detriment
- fall

Triplicity, bounds/terms and faces/decans are deliberately not automated in v081. No numeric dignity score is generated. Uranus, Neptune and Pluto are not assigned modern sign rulerships in this foundation profile.

### Safety / interpretation policy

- The chart output is evidence for astrologer review, not a scientific claim.
- No automatic real-world prediction is generated in v081.
- No cross-system confidence uplift is allowed.
- Mixed dignity/debility conditions are preserved rather than resolved by a majority score.
- The exact house system, orb profile and dignity scope are stored in the immutable calculation output.
