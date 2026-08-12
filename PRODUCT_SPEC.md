# ASTRO LOGIC — Product Specification v0.1

## Product goal

Provide a professional astrologer with one offline workspace for client records,
verified calculations, consultation notes, remedies and branded reports.

## Professional workflow

1. Create or find a client.
2. Capture birth data with place coordinates, timezone and source/confidence.
3. Generate calculation snapshots so later rule or setting changes do not silently
   alter an old consultation.
4. Open a consultation question and select one or more astrology systems.
5. Review evidence: chart factors, houses, lords, dashas, transits and rules.
6. Draft interpretation and remedies.
7. Resolve conflicts and mark each conclusion Approved, Edited or Rejected.
8. Preview and export the signed report.

## Core modules

| Module | Initial capability |
| --- | --- |
| Clients | Profile, birth records, consultations, attachments and search |
| Vedic | D1–D60 registry, Panchanga, Vimshottari, transits, strength and yoga rules |
| KP | Cusps, star/sub/sub-sub lords, significators, ruling planets and horary |

**KP Native/Horary status:** governed classic Krishnamurti ayanamsha reconstruction, native Placidus twelve-cusp generation, full planet/cusp Star/Sub classification, deterministic house occupancy/ownership, four-level significator synthesis, ruling-planet review, DBA timing, Transit/RP confirmation and immutable consultation snapshots are implemented. KP Horary Foundation v1 adds a separate 1–249 question-number workflow using query-moment planets and no natal birth inputs. Source-bounded automatic cusp review remains limited to Marriage and Children; broader Horary event catalogs and Horary timing remain gated.
| Western | Tropical natal chart v1, Placidus/Whole Sign/Equal houses, major aspects and traditional dignity evidence; outer planets/transits/synastry remain later governed expansions |
| Numerology | Chaldean and Pythagorean profiles, cycles and name comparison |
| Vastu | Property profile, compass/floor-plan annotations, findings and remedies |
| Palmistry | Hand images, manual line/mount annotations and reviewed observations |
| Reports | Bengali/English structured consultation reports with offline PDF/DOCX export/share; bilingual combined-layout export remains a later presentation option |
| Gemstone Remedies | Planet-linked stone/substitute, weight, metal, wearing method, evidence, cautions and astrologer decision |
| Kundli Judgment | Evidence-backed strengths, weaknesses, life-area findings, timing windows and remedy candidates |
| Practice | Appointments, fees, receipts, follow-ups and service catalogue |
| Settings | Ayanamsha, house system, chart style, language, backup and branding |

## Calculation integrity

- Store time internally as UTC plus the entered local time and timezone offset.
- Preserve latitude, longitude, altitude (optional) and place label.
- Record birth-time confidence: Exact, Recorded, Approximate or Unknown.
- Every calculation stores engine version, settings profile and input hash.
- Ayanamsha and house system are explicit; never inferred silently.
- Rounding is presentation-only; rules use unrounded values.
- Rule results retain evidence and rule version.
- Contradictory rules remain visible until the astrologer resolves them.
- Dasha timing stores reusable nine-lord activation profiles; the timeline
  shows each Pratyantardasha's own score, weighted three-level synthesis and
  repeated life-area focus without converting it into an event guarantee.

## Offline data and security

- Local encrypted database; no analytics or external tracking.
- PIN/biometric application lock where supported.
- Encrypted portable backup/restore with integrity checking, read-only pre-restore planning and governed non-empty-workspace merge with deterministic ID remapping, immutable source-identity preservation and transactional rollback.
- Attachments stored locally with checksums.
- Immutable audit events for critical edits and report approval.
- Configurable auto-lock and local export controls.

## Language rules

- Every interface string has stable English and Bengali keys.
- Client-entered content is not auto-translated or overwritten.
- Astrology terms may show a preferred term plus the alternate term in brackets.
- Reports may be English, Bengali or bilingual independently of UI language.

## Safety and professional boundaries

- No guaranteed outcomes or deterministic claims about death, disease, crime,
  pregnancy, investment returns or legal results.
- Medical, legal and financial sections include domain-appropriate disclaimers.
- Gemstone and ritual suggestions display contraindication/verification notes.
- Gemstone recommendations require verified chart output, visible evidence and
  explicit astrologer approval; the app never promises medical or guaranteed
  outcomes.
- Palmistry image assistance never replaces the astrologer's marked observation.

## Delivery milestones

1. App shell, bilingual navigation, theme and module registry. **Completed**
2. Client and primary birth-data offline persistence. **Completed**
3. Multiple birth records, client editing and calculation settings profile. **Completed**
4. Audit history and immutable calculation input snapshots. **Completed**
5. Consultation records and engine-versioned calculation output contract. **Completed**
6. Consultation detail/review workflow and calculation orchestration. **Completed**
7. Ephemeris provider contract, licence gate and Vedic derivation core. **Completed**
8. Permissively licensed offline astronomical provider and external-reference
   accuracy tests. Swiss exclusion, MIT Astronomy Engine selection, pinned C
   source, native ABI, seven-body JPL fixture, Android/Windows Dart FFI,
   Lahiri/Chitrapaksha, true/mean Rahu and Ascendant frame **Completed**;
   Android/Windows native packaging integration contract **Completed**;
   generated Flutter runners and additional ayanamsha methods remain pending.
9. KP and Western engines with evidence explorer.
10. Numerology, Vastu and Palmistry workspaces.
    Numerology calculation foundation (Driver, Life Path, Personal Year,
    Pythagorean and Chaldean name profiles), bilingual interpretation,
    dual-system comparison, Personal Year window and safe behavioural-remedy
    policy, responsive workspace, immutable persistence, client/birth-record
    prefill, consultation version history, Numerology v2 confidence/cycle review,
    guarded Vedic cross-check, governed name-candidate comparison and Professional Report rendering **Completed**.
    Candidate comparison is descriptive only: no automatic ranking, lucky-name guarantee or legal-name-change recommendation.
11. Consultation composer, Professional Consultation Report Engine v1 and Professional Report Export Engine v3 **Completed** for immutable bilingual structured report generation/preview, offline PDF/DOCX export/share, practitioner approval/sign-off, signed-report QR generation and offline local verification with tamper detection.
12. Encrypted backup/restore **Completed v1** with Argon2id + AES-256-GCM, canonical SHA-256 manifests, immutable-record revalidation, read-only pre-restore preview/conflict planning, empty-workspace transactional restore and Governed Backup Merge/Migration Adapter v1 for non-empty workspaces. Governed merge never overwrites existing rows: canonical equivalents are reused, resolvable primary-key collisions are deterministically remapped, hash-bound source IDs are preserved in schema-v10 integrity columns, semantic immutable-identity conflicts block the transaction, imported audit provenance is retained, and schema-v11 durable import batches/mappings produce operator-verifiable merge receipts. Cross-platform Flutter runtime/build validation remains pending until the final build checkpoint.
13. Gemstone remedy workspace and bilingual report section. Data model,
    validation, persistence, audit foundation and consultation Add/Edit UI
    **Completed**; practitioner-entered reviewed records can render in Professional Report v1. Evidence-gated behavioural Remedy Recommendation v1 is also **Completed**; Gemstone Candidate & Contraindication v1 is completed; automatic wearing approval remains prohibited.
14. Complete Kundli Judgment, Timing and Remedy Recommendation Engine.
    Immutable bilingual analysis schema, evidence/confidence policy, timing
    safeguards, engine adapter, persistence foundation, consultation Run action,
    Lagna/Lagna-lord, twelve-house, functional ownership, occupancy, full-sign
    aspects, combustion/retrograde, permanent natural friendship,
    degree-specific Moolatrikona, conjunction, multi-aspect synthesis,
    temporary/compound friendship and planetary-war proximity review rule
    families, integrated twelve-life-area synthesis with visible contradictory
    evidence, transparent score and bilingual detailed narratives, Panch
    Mahapurusha formation review and conservative Kuja-dosha Lagna screening,
    full-profile Gajakesari qualification, initial Lagna/fifth-lord Raja Yoga
    and fifth/eleventh-own-house Dhana Yoga formations, explicit D9 output and
    seven-planet D1-D9 dignity agreement, twelve-house D9 house/lord/full-sign-
    aspect synthesis, exact-Moon Vimshottari Mahadasha,
    Antardasha and 729-period Pratyantardasha calendar, bilingual
    Current/Past/Future timeline, medium-confidence activation windows, plus
    occupancy, classical full-aspect, combustion/retrograde conditions and
    evidence/review UI **Completed**. Standalone selected-date transit
    calculation, all nine sidereal transit positions, Moon/Lagna house distance,
    and a source-bounded Brihat Samhita Chapter 104 Moon-gochara direction matrix
    for Sun, Moon, Mars, Mercury, Jupiter, Venus and Saturn, with Sade-Sati
    detection kept non-automatic and Rahu/Ketu directional results disabled,
    **Completed**. Selected-date Dasha × transit confirmation using the active
    MD/AD/PD chain, governed 3:2:1 weighting, convergence/conflict handling and
    bilingual evidence **Completed**. A separate 729-period chart-specific
    Pratyantardasha interpretation family with broad-theme/modifier/immediate-
    trigger roles, repeated-life-area prioritization, bilingual narratives and
    immutable snapshot persistence **Completed**. Question-specific selected-date
    timing for career/employment, business/partnership, marriage, finance,
    education, property, children and travel/relocation now combines governed
    target-house natal condition, active MD/AD/PD topic activation and topical
    transit convergence, with conflicts preserved as Mixed and High confidence
    disabled **Completed**. Full Conflict & Confidence Engine v2 now resolves
    topic-specific D1 target-house structure, D1-D9 target-lord agreement,
    active topic Dasha, topical Moon-gochara transit and Ashtakavarga transit as
    four governed evidence groups across five visible layers; correlated D1/D9
    evidence cannot inflate confidence, all Ashtakavarga checks collapse to one
    group, any explicit conflict remains Mixed/Low, three/four-group convergence
    is capped at Medium, and High confidence remains disabled **Completed**. D9 House/Lord/Aspect Interpretation
    Engine v1 now validates explicit Navamsha chart structure and records all 12
    D9 houses with lord placement/dignity, classical occupancy, enabled full-sign
    aspects, node-neutral review, transparent scores and conflict preservation
    **Completed**. Advanced Yoga & Dosha Engine v1 now adds bounded Raja-Yoga conjunction subsets, explicit BPHS Chapter 41 verses 2-8 Dhana formations, Harsha/Sarala/Vimala Vipareeta profiles, Phaladeepika Neecha-bhanga review conditions, multi-reference Kuja review and contradiction-preserving synthesis **Completed**. Partial aspect strength, later divisional charts beyond D10, broader Yoga/Dosha catalogs beyond this v1 subset, Ashtakavarga Pinda-derived timing extensions, deeper D9/Shadbala conflict-confidence integration, governed Ketu transit polarity beyond the v1 source profile, exact-degree transit triggers, broader event timing and Gemstone Candidate & Contraindication v1 is completed; mantra/charity/ritual source families, broader lineage profiles and wearing-protocol automation remain pending.


## Advanced Yoga & Dosha Engine v1

The governed `advanced-yoga-dosha-v1` family is implemented in a separate engine file to avoid further growth of the legacy Lagna judgment class. It includes the ninth/tenth-lord Raja-Yoga conjunction where the enabled auspicious-Bhava condition is met, a same-sign-conjunction subset of selected Kendra/Kona relationships, the exact enabled BPHS Chapter 41 verses 2-8 Dhana formulas, Harsha/Sarala/Vimala structural Vipareeta profiles, and bounded Neecha-bhanga conditions. Any out-of-profile ninth/tenth conjunction is retained only as a candidate rather than promoted to a completed yoga.

Participant weakening (debilitation, combustion and same-sign node contact) is separate review metadata and does not silently cancel a formation. Neecha-bhanga preserves the original D1 debilitation and remains Mixed; it never automatically makes a planet strong/benefic. The multi-reference Kuja screen checks Mars from Lagna, Moon and Venus, keeps the second-house extension separately labelled, and shows D1/D9/Jupiter mitigation evidence without automatic cancellation. Cross-Yoga/Dosha synthesis preserves contradictions, does not use majority voting, cannot by itself predict marriage harm or guaranteed status/wealth, and is capped at Medium confidence.

## Professional Consultation Report Engine v1

Report generation is a derived-document layer, not a new astrology judgment engine. It consumes the latest immutable Kundli and/or Numerology snapshots for the consultation and preserves source ids, schema versions and SHA-256 hashes in a source manifest. The governed `professional-consultation-report-v1` contract contains exactly thirteen sections: client/profile, executive summary, D1, D9, D10, Yoga/Dosha, Shadbala, Ashtakavarga, Dasha/Pratyantardasha, selected-date Transit/Question Timing status, Numerology, Remedy/Gemstone record, and professional notes/warnings. Missing evidence is represented as `Unavailable` instead of being inferred.

The executive summary is curated from persisted findings with the consultation category prioritised; it does not create a new astrological polarity. Current report v1 can display a current Pratyantardasha from the immutable 729-period calendar at the report `asOfUtc` instant. Selected-date Transit/Question Timing/Conflict engines are intentionally shown as unavailable in the report until their own immutable snapshot chain exists. Professional Report Export Engine v3 can render any saved report snapshot to offline PDF or DOCX after re-verifying its report SHA-256 and, when present, its immutable practitioner approval binding. Export files are derived artifacts and are not new astrology judgments.


## Professional Report Export Engine v3

Export consumes only a saved immutable professional report snapshot. Before generation it recomputes the report SHA-256 from stored report JSON, source manifest and report engine identity; a mismatch is rejected. If the snapshot has an immutable practitioner approval, export also recomputes the approval SHA-256 and the report+approval `signedReportHash`; mismatched identity, report linkage or approval metadata is rejected. Approved exports use the signed-report hash prefix and `_signed` filename marker, while unsigned exports retain the original source-report filename contract. The source report hash plus approval/signed hashes are included in visible/metadata content for traceability.

Approval v1 is an in-app practitioner electronic sign-off, not a certificate-backed PKI/digital signature. One immutable approval is allowed per report snapshot. Practitioner name and designation are required, credential/reference is optional, and an explicit note is mandatory for `approvedWithReservations`. Existing report-snapshot UPDATE/DELETE triggers plus new approval UPDATE/DELETE triggers make post-sign mutation impossible at the report/approval record level; changing the professional opinion requires a new report snapshot.

PDF output is A4 multi-page and fully offline. Bengali or other non-ASCII selected text requires a compatible system Unicode/Bengali font; the app searches governed Android/Windows/Linux/macOS system-font locations and refuses to create a broken-glyph PDF if none is available. No font binary is distributed with ASTRO LOGIC. DOCX is generated as minimal OOXML with Unicode text and no embedded fonts. The current UI exports the active Bengali/English locale, stores files under the app documents `ASTRO_LOGIC/exports` folder and opens the platform share sheet. Export files are derived artifacts; no SQLite migration or mutation of report snapshots occurs.

Signed reports additionally carry `astro-logic-signed-report-verification-v1`. The QR payload intentionally excludes client/birth/narrative data and carries only ids plus report/approval/signed hashes and contract identity. The Dashboard exposes an offline verifier, and signed-report preview can open the same verifier pre-filled. Only a payload that recomputes and matches the local immutable report+approval records is labelled verified; a standalone structurally valid payload without a local record is explicitly not treated as proof of authenticity. Signed PDF renders the QR directly and signed DOCX embeds an offline-generated PNG QR. No online verification service or camera-scanner dependency is required in v1.

## Shadbala foundation v10

The Kundli snapshot persists seven `shadbala-foundation-v10` records, one for
Sun through Saturn. Each record exposes Uccha, Saptavargaja, Ojhayugma,
Kendradi and Drekkana virupas, their Sthana Bala sum, exact Dig Bala, governed Paksha Bala and Ayana Bala, both pre-war Kala subtotal and complete Kala Bala when Yuddha evidence permits, governed Cheshta Bala where the input contract supports it, the fixed Naisargika Bala,
exact-longitude Drik Bala with received-aspect contribution audit records, and the seven D1/D2/D3/D7/D9/D12/D30 contributions. Rahu/Ketu are excluded.

Saptavargaja v2 retains the declared Rasi-position-based Tatkalika Maitri profile
when deriving the five-fold relationship to a varga dispositor. Because
traditional implementations differ on whether temporary friendship should be
recomputed inside every derived varga, this policy is versioned and visible.

Dig Bala is enabled from exact sidereal planet/Ascendant longitudes using the BPHS 27.7 zero-strength directions and angular-distance/3 rule. The current Kala foundation combines BPHS 27.9 Nathonnata Bala from observer-specific apparent Sun hour angle, BPHS 27.10-11 Paksha Bala from folded Sun-Moon separation, BPHS 27.12 Tribhaga Bala from the actual sunrise→sunset or sunset→sunrise interval split into three equal parts, BPHS 27.13 Varsha/Masa/Dina/Hora allocations (15/30/45/60 virupas), and BPHS 27.15-17 Ayana Bala from tropical longitude using the 45/33/12 khanda profile. Current `vedic-chart-v10` retains the exact Tribhaga solar-period boundaries and adds a versioned `siderealSolarIngressAstrologicalDayV1` audit profile: Varsha is anchored to the prior sidereal Aries ingress, Masa to the prior ingress into the Sun's current sidereal sign, Dina to the sunrise-to-sunrise astrological weekday, and Hora to one of twelve equal daylight or twelve equal night seasonal horas following the Saturn-Jupiter-Mars-Sun-Venus-Mercury-Moon sequence from the Dina lord. If required rise/set or ingress context cannot be found, the affected component stays unavailable instead of being guessed. Weekday conversion uses the birth record's stored UTC offset; until an IANA zone id is persisted, DST-sensitive historical records carry that explicit limitation. Cheshta foundation v1 follows BPHS 27.18 directly for Sun (Ayana) and Moon (Paksha); Mars through Saturn use the versioned speed-state operational profile from persisted exact daily longitude speed. Drik Bala v1 remains exact-longitude and contribution-audited. Yuddha Bala v1 now uses current-chart geocentric ecliptic latitude to audit isolated same-sign planetary-war pairs among Mars through Saturn. When the pair is unambiguous, the northern-latitude participant receives the BPHS 27.20 pre-war-strength difference and the other loses the same amount; no-war is a computed zero, while multi-war clusters, latitude ties and missing pre-war strength remain unavailable. This can complete Kala Bala on current v9 charts. Foundation v10 then publishes the six-component total as Sthana + Dig + Kala + Cheshta + Naisargika + Drik whenever all six are available, converts the total to Rupas, compares it with the BPHS 27.32-33 planet-specific requirement (Sun 390, Moon 360, Mars 300, Mercury 420, Jupiter 390, Venus 330, Saturn 300 virupas), and stores the ratio plus surplus/deficit. Missing evidence keeps the aggregate unavailable. Meeting the threshold is recorded only as strength sufficiency; it is not an automatic favourable/adverse, event-success or remedy conclusion.


## Ashtakavarga foundation v3

Seven unreduced planetary BAV tables and the unreduced 337-point SAV are persisted with contributor-level positive-mark evidence. The selected received-standard Parashari table profile uses Sun through Saturn plus Lagna as the eight references, excludes Rahu/Ketu, maps raw SAV signs to whole-sign houses, and applies the selected BPHS 72 comparative bands (>30 favourable, 25-30 medium, <25 adverse). The engine deliberately stores `positiveMarks` because Bindu/Rekha notation differs across classical editions. Foundation v3 keeps the separate audit-preserving reduction stage: BPHS-67 Trikona Shodhana followed by BPHS-68 occupancy-sensitive Ekadhipatya Shodhana across the five dual-lord sign pairs, then adds post-Shodhana Pinda calculation. Each reduced BAV produces Rashi Pinda from the fixed twelve Rashi multipliers and Graha Pinda from the reduced marks at the seven classical planetary occupancies with fixed Graha multipliers; their sum is Shodhya/Yoga Pinda. Reduced values, Pinda values and raw SAV bands remain separate. Question-specific timing v3 consumes unreduced BAV/SAV and refines that whole-sign signal with the active 3°45′ Kaksha contributor from the same planetary BAV. Pinda-derived timing remains separate work. High confidence and exact-event guarantees remain disabled.


## D10 Dashamsa Career Interpretation v1

Current `vedic-chart-v10` adds an explicit Parashari Dashamsa (D10) for the Ascendant and all nine displayed planets. Each natal sign is divided into ten 3-degree parts. Odd signs map forward from the natal sign itself; even signs map forward from the ninth sign from the natal sign. The immutable D10 payload carries the calculation profile id `bphs-dashamsa-odd-self-even-ninth-v1`, explicit D10 ascendant and per-body D10 sign.

`dashamsa-career-interpretation-v1` produces twelve D10 house/lord/full-sign-aspect structural records. Rahu/Ketu occupancy is visible but contributes no invented dignity, functional score or node aspect. The career synthesis separately cross-checks the D1 tenth lord inside D10 against the D10 tenth house and its lord. Both structural families must be directional and agree before the synthesis becomes Supportive or Challenging; disagreement or a non-directional family remains Mixed/Low. This layer is career-domain evidence only and does not promise profession, promotion, income or event timing.

## Build-readiness and module-availability governance (v0.77.0+81)

Android and Windows runners remain generated artifacts rather than committed
source. The reviewed bootstrap scripts must regenerate the current Flutter
runner and then apply only the ASTRO LOGIC native FFI packaging contract. CI
pins Flutter 3.44.7 on both platforms and must run the source-readiness audit,
package resolution, analyzer and Flutter test suite before release build.

Dashboard exposure must match implementation state. KP Native Chart v4 is available for governed native casting, deterministic star/sub, Placidus cusps, house occupancy/ownership, four-level significators, source-bounded Marriage/Children cusp-sub-lord judgment, DBA timing and a separate Transit/Ruling-Planet confirmation layer with a Moderate confidence ceiling. KP Horary v2 is available as a separate 1–249 query-moment workflow with immutable schema-v12 snapshots, no natal-birth reuse, and a query-time Ruling-Planet corroboration layer for supported Marriage/Children Promise review. Horary RP confirmation never reuses natal DBA, scans future transits, or generates an exact event date. Western v2 is available with tropical natal casting, explicit Placidus/Whole Sign/Equal house profiles, native Uranus/Neptune/Pluto, explicit Traditional/Modern rulership profiles, governed Major-only or Major+Minor aspect profiles, deterministic aspect-pattern evidence and authoritative traditional seven-planet dignity evidence. Vastu, Palmistry and Practice remain explicit Coming Soon modules until they have real engine/screen/persistence coverage. Vedic, Professional Reports and
Gemstone/Remedy records are available through the governed client/consultation
workflow; no placeholder tile may imply that an unimplemented engine exists.

A source-only audit is not equivalent to a successful Flutter build. Final
release evidence must include the Android and Windows CI results, the committed
tested `pubspec.lock`, dependency graph, analyzer/test/native logs, versioned
platform artifact manifests and SHA-256 sums. The final bundle assembler must
confirm identical version, release tag, source commit, Flutter baseline, lock
SHA-256 and Astronomy Engine backend across both platform builds. A tagged
full-scope release is blocked while any dashboard module remains Coming Soon.
See `RELEASE_GATE.md` for the release contract.


## Advanced Rahu/Ketu analysis v1

`rahu-ketu-analysis-v1` adds source-bounded natal node house themes, explicit sign-dispositor and same-sign-association context, and bounded node-Dasha modifiers. Phaladeepika VIII.25-34 is used for natal house review; XX.39 is applied only to Rahu's explicit associated-planet Dasha direction, while XX.52-53 provide Kendra/Trikona and benefic-sign connection candidates for both nodes. The v1 connection convention is same-sign association only. Rahu/Ketu dignity, exaltation/debilitation and node aspects are not invented. Transit v3 adds Rahu's Moon-relative house sequence from Phaladeepika XXVI.24; Ketu transit direction remains unavailable until a separately governed source profile is enabled. All node conclusions remain professional-review-only and High confidence is disabled.


## Numerology Finalization v2 governance (v0.60.0+64)

- Calculation contract is `numerology-profile-v2` / engine `2.0.0` with a frozen component-reduction Life Path profile, separate calendar-cycle Personal Year profile, Maturity synthesis, visible formulas and three-year cycle context.
- Judgment contract is `numerology-analysis-v2` / engine `2.0.0`; Driver, Life Path, Pythagorean Expression, Soul Urge, Personality, Chaldean Name and Maturity are bilingual evidence-backed findings.
- Numerology prediction confidence remains Low even when arithmetic is deterministic. Published-school disagreements are preserved in the source register rather than hidden behind one universal-accuracy claim.
- Optional Vedic cross-check consumes only an already-persisted Kundli judgment snapshot from the same consultation, is always Low-confidence caution context, cannot count as independent Vedic evidence and cannot approve gemstone use.
- Numerology automatic remedies are limited to non-planetary behavioural reflection candidates. Gemstone, mantra, charity, ritual, name-change and high-stakes directive automation is prohibited.
- No SQLite migration is required; immutable Numerology JSON snapshots retain calculation/analysis engine and schema versions plus SHA-256 integrity binding.

## Numerology Name Candidate Comparison governance (v0.61.0+65)

- Calculation contract is `numerology-profile-v3` / engine `2.1.0`; the frozen v2 core/cycle arithmetic remains unchanged and `astro-logic-name-candidate-comparison-v1` adds alternate-spelling comparison.
- Original normalized Latin spelling is always the baseline. Up to eight unique alternate Latin spellings may be entered; silent transliteration, baseline-equivalent candidates and normalized duplicates are rejected.
- Comparison output is arithmetic only: Pythagorean and Chaldean compound/reduced deltas, Soul Urge/Personality change flags, Master-number transition flags and Driver/Life Path/Maturity numeric overlaps are shown without a favourability score.
- Judgment contract is `numerology-analysis-v3` / engine `2.1.0`; comparison reviews are Medium-confidence only because they describe deterministic arithmetic, not prediction. Overall Numerology prediction confidence remains Low.
- The engine never ranks a candidate, labels a spelling best/lucky, automatically selects a spelling, predicts an outcome from a spelling or recommends a legal-name change.
- One optional professional discussion focus may be explicitly chosen by a human from the entered candidates. That selection is stored as review context only and does not imply endorsement.
- Candidate inputs, explicit selection, calculation comparison and analysis review are SHA-256 bound inside the immutable Numerology snapshot. No SQLite migration is required.



## Current governed backup milestone — v0.68.0+72

Backup Merge Recovery & Import Batch Ledger v1 adds schema-v11 local-only merge provenance. Each merge gets a durable batch status record, immutable source→local ID mapping ledger, row-hash evidence, failure/interruption diagnostics and a SHA-256-bound exportable merge receipt. The batch ledger is not recursively included in portable `.albackup` protected tables. Failed transactions retain no partial imported rows or mappings; committed batches are immutable and duplicate committed manifest import is blocked.

Core Maintainability Refactor, final release-gate preparation, KP Native/Horary through query-time RP corroboration, and Western Astrology Foundation v1 are complete. Vastu, Palmistry and Practice remain pending; later Western expansion will add governed outer planets, modern/traditional rulership separation, additional aspect policy and pattern synthesis.
