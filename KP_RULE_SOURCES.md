# KP Rule Sources and Governance

## Scope enabled in v075

ASTRO LOGIC now implements a governed native KP chart profile in addition to the v074 deterministic Star/Sub foundation.

### Ayanamsha profile

`kp-krishnamurti-classic-j1900-newcomb-v1` freezes the classic Krishnamurti Reader-1 reconstruction at J1900 with ayanamsha 22.363889° and Newcomb/Kinoshita precession. The original KP Reader gives limited precision and a zero-year description rather than one uniquely reproducible modern high-precision algorithm, so ASTRO LOGIC keeps this as a visible versioned profile instead of calling it the only possible KP ayanamsha.

The implementation is independent native C. Swiss Ephemeris 2.10.03 output is retained only as an external numeric development oracle; no Swiss source/library is included, linked or executed by the product.

### Placidus profile

`kp-placidus-time-division-native-v1` solves Placidus intermediate cusps from local sidereal time, obliquity, latitude and the semidiurnal-arc time-division conditions. Tropical cusps are generated first, then the governed KP ayanamsha is subtracted for sidereal cusp longitudes. If Placidus geometry is unavailable in polar regions the calculation fails; ASTRO LOGIC does not silently substitute Porphyry.

### Star/Sub and evidence rules

The v074 contracts remain unchanged: `kp-star-sub-v1`, `kp-cusp-classification-v1`, `kp-significator-four-level-v1` and `kp-ruling-planets-seven-role-v1`. Star/Sub arithmetic uses the nine Vimshottari lords in 120-year proportions across each 13°20′ nakshatra. Significators and ruling planets remain evidence for practitioner review, not automatic event guarantees.

### Current exclusions

Horary question-number casting, event-promise judgment, advanced significator synthesis, Dasha/transit timing fusion and automatic yes/no event claims are not part of v075. Cross-system agreement with Vedic or Numerology cannot raise KP confidence automatically.

## Primary/reference material used for governance

- K.S. Krishnamurti Reader tradition for the classical KP ayanamsha/star-sub lineage.
- Newcomb/Kinoshita precession coefficients as independently implemented in the governed profile.
- Swiss Ephemeris documentation/source used only to understand historical mode definitions and to generate numeric external fixtures during development; it is not a product dependency.
- Existing public KP teaching references retained for Star/Sub, significator and ruling-planet conventions.

## Scope enabled in v076 — Advanced Significator & Event Judgment v1

`kp-house-significator-synthesis-v1` derives house occupancy from the native Placidus cusp sequence and house ownership from the sign falling on each cusp. The frozen four-level significator order remains: (1) house occupied by the planet's star lord, (2) house occupied by the planet, (3) houses owned by the star lord, and (4) houses owned by the planet. Rahu/Ketu have no sign ownership in this profile.

`kp-cusp-sublord-promise-review-v1` is deliberately narrower than the full consultation-category list. v076 enables automatic cusp-sub-lord review only where the retained source profile is explicit:

- Marriage: primary cusp 7; conductive houses 2, 7, 11; detrimental houses 1, 6, 10.
- Children: primary cusp 5; conductive houses 2, 5, 11; v076 derives detrimental houses 1, 4, 10 as the twelfth houses from the conductive group.

The state machine is conservative: conductive-only evidence -> `promise`; detrimental-only evidence -> `denial`; mixed or absent evidence -> `insufficientEvidence`. These labels describe the selected KP rule profile only. They do not claim empirical certainty, do not time an event, and cannot be strengthened by Vedic or Numerology agreement.

The primary retained teaching reference is the existing KP Astrology / AstroSage Chapter 2 material for house ownership, four-level significators, house grouping, detrimental houses and cusp-sub-lord promise review, plus its Four Step Theory example for the 2/5/11 children profile. Other consultation categories remain unsupported until a versioned source profile and fixtures are added.


## Scope enabled in v077 — KP Dasha & Timing Synthesis v1

`kp-vimshottari-dba-house-coverage-v1` reuses ASTRO LOGIC's governed Vimshottari calendar v2, but the calendar is seeded from the KP-native Moon sidereal longitude. The calendar's Mahadasha / Antardasha / Pratyantardasha levels are exposed in this KP layer as Dasha / Bhukti / Antara. No other Dasha system is introduced.

The retained KP teaching reference states that Vimshottari is the Dasha system used in KP and that Dasha, Bhukti and Antara lords are reviewed against the significators of the houses under consideration before event fructification is narrowed further by transit. ASTRO LOGIC therefore freezes a deliberately conservative application policy: each of the three period lords must signify at least one conductive event house, the three-lord union must cover the complete frozen event house-group, and any frozen detrimental-house hit prevents the period from being labelled Supportive. Such mixed periods are preserved as `conflicting`; periods without complete DBA support are `insufficientCoverage`.

The chart-promise state remains a separate gate. A `denial` or `insufficientEvidence` chart does not erase its Dasha evidence, but no timing window is promoted for practitioner action. Transit and Ruling-Planet confirmation are explicitly excluded from v077 and cannot silently raise confidence.

Retained references:

- KP Astrology / AstroSage, Chapter 2 — Fundamental Principles: Vimshottari-only KP timing and Dasha/Bhukti/Antara lords reviewed with relevant-house significators before transit refinement: https://kpastrology.astrosage.com/kp-learning-home/tutorial/chapter-2-fundamental-principles
- KP Astrology / AstroSage, KP System FAQ — KP uses Vimshottari Dasha: https://kpastrology.astrosage.com/kp-learning-home/kp-system-faq
- KP Astrology / AstroSage, Four Step Theory — worked example selecting Dasha/Bhukti/Antara significators for the remaining event houses: https://kpastrology.astrosage.com/kp-learning-home/related-systems/four-step-theory

## Scope enabled in v078 — KP Transit & Ruling-Planet Timing Confirmation v1

`kp-dba-transit-rp-confirmation-v1` is an independent reference-moment confirmation layer. It does **not** modify the v077 chart-promise state or DBA window state.

The retained Chapter 2 reference states that Dasha, Bhukti and Antara lords should transit through the significators of the houses under consideration; for finer timing, Sun and Moon should also transit through the significators. The same source describes Ruling Planets as a method for selecting stronger/common significators. ASTRO LOGIC freezes a deliberately narrow operational interpretation: the KP Star-Lord of each reference-time transit point is checked against the natal event-significator matrix. This exact operational mapping is versioned software policy, not represented as the only possible KP transit technique.

For v1 confidence, the Ruling-Planet overlap subset is Ascendant Star Lord, Ascendant Sign Lord, Moon Star Lord and Moon Sign Lord. The existing expanded Ascendant/Moon Sub-Lord roles remain visible for audit but do not raise confidence. Day Lord also remains audit-only because the current engine uses civil weekday while the retained source notes that KP Day Lord should follow the sunrise-to-sunrise Hindu day; that sunrise-day resolver is not yet implemented in the KP module.

Confirmation states are conservative: a current supportive DBA can become `confirmedForPractitionerReview` only when all three DBA transit Star-Lords are fruitful natal event significators, both Sun and Moon transit Star-Lords are fruitful, at least one standard RP overlaps a fruitful significator, and no required transit Star-Lord is detrimental-only. Detrimental-only transit evidence becomes `contradictory`; incomplete support is retained as `partialConfirmation` or `insufficientConfirmation`. Confidence is capped at Moderate and never produces an exact-event or real-world guarantee.

Retained references:

- KP Astrology / AstroSage, Chapter 2 — Fundamental Principles, lines/sections on Ruling Planets, significator selection and Timing Events: https://kpastrology.astrosage.com/kp-learning-home/tutorial/chapter-2-fundamental-principles
- KP Astrology / AstroSage, KP System FAQ — KP uses Vimshottari and describes the Ruling-Planet methodology: https://kpastrology.astrosage.com/kp-learning-home/kp-system-faq


## Scope enabled in v079 — KP Horary Foundation v1

`kp-horary-249-table-v1` derives the traditional 1–249 Horary number table rather than embedding 249 opaque rows. Each of the 27 nakshatras is split into the nine unequal Vimshottari Sub-Lord spans. The 243 Star/Sub spans are then split wherever one span crosses a 30-degree sign boundary; exactly six such crossings produce 249 sign-contained segments. The implementation asserts continuity from 0° through 360° and reference rows including #1, the Aries/Taurus split at #22/#23, and #249.

The selected number fixes the Horary sidereal Ascendant to the start of its governed segment. Planetary positions are calculated for the actual question UTC/location. The remaining Placidus cusps are generated through a bounded native cusp-1 solver rather than by rotating an unrelated cusp set; the internal technical frame timestamp exists only to solve the house geometry and is explicitly not an event time. Natal client/birth-record inputs are not consumed.

Horary v1 requires one explicit question and stores an immutable `kp-horary-input-v1` → `kp-horary-chart-v1` snapshot. Automatic event review is deliberately limited to the already governed Marriage and Children cusp profiles. General questions retain full chart/house evidence but receive no invented Promise/Denial formula. Automatic Horary timing and real-world guarantees remain disabled.

Retained public references for the 1–249 table and question-number workflow include the Vaastu International KP 1–249 table, JyotishPortal KP Horary table explanation, and public KP Horary descriptions that distinguish the number-selected Ascendant from planets placed at the query moment. These references are used as governance/reference material; the runtime table is generated independently from exact Vimshottari arithmetic.

## Scope enabled in v080 — KP Horary Timing & Ruling-Planet Confirmation v1

`kp-horary-query-rp-overlap-v1` adds a query-moment Ruling-Planet corroboration layer to the supported Horary Marriage and Children Promise workflow. It is intentionally separate from the Natal-KP DBA/transit stack.

The retained KP Astrology / AstroSage Chapter 2 reference defines the judgment-moment Ruling Planets as Ascendant Star Lord, Ascendant Sign Lord, Moon Star Lord, Moon Sign Lord and Day Lord. The same reference says that Ruling Planets common with the relevant house significators are the strongest significators and can be used while fixing event timing. It also notes that Day Lord should follow the sunrise-to-sunrise Hindu day.

ASTRO LOGIC therefore freezes a conservative v1 software policy rather than pretending that the source specifies one exact scoring algorithm:

- confidence uses Ascendant Star Lord, Ascendant Sign Lord, Moon Star Lord and Moon Sign Lord;
- Day Lord is retained for audit only until a governed sunrise-day resolver exists;
- the existing Ascendant/Moon Sub-Lord RP roles remain audit-only;
- a supported Horary chart must already be `promise` before RP corroboration can be promoted;
- full corroboration requires the Promise primary-cusp sub-lord itself to appear among the standard query-time RPs as a fruitful event-house significator;
- any detrimental-only standard RP produces an explicit contradiction state;
- other fruitful/mixed overlaps remain partial evidence;
- confidence is capped at Moderate.

No natal birth data or natal DBA is reused. v080 does not run a future transit scanner, convert Ruling Planets into days/weeks/months, or generate an exact event date.

Retained references:

- KP Astrology / AstroSage, Chapter 2 — Ruling Planets, Selection of Significators and Ruling Planets Method: https://kpastrology.astrosage.com/kp-learning-home/tutorial/chapter-2-fundamental-principles
- KP Astro, How to Cast a Horary Chart — Horary number + date/time/place, planetary significators and ruling planets as review factors: https://kpastroapp.com/learn/how-to-cast-a-horary-chart
