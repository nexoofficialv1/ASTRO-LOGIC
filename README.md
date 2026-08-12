# ASTRO LOGIC

Professional offline astrology workspace for Android and Windows.

## v0.78.0+82 — Western Modern Planets & Aspect Pattern Expansion v1

Western v2 adds native Uranus, Neptune and Pluto through the same pinned MIT Astronomy Engine geocentric pipeline, with no fabricated longitude formula. Traditional and Modern rulership profiles are explicit and independently stored; selecting Modern changes sign-ruler evidence only, while the v081 seven-planet essential-dignity profile remains authoritative. Major-only aspects remain the default; an explicit Major+Minor profile adds Semisextile, Semisquare, Quintile, Sesquiquadrate and Quincunx under a versioned operational orb policy. Grand Trine, T-Square, Grand Cross, strict conjunction-clique Stellium, Yod and Kite are deterministic evidence objects with their component aspects/orbs retained. Native wrapper ABI is `al-abi-9`, SQLite remains schema 12, and Western calculation inputs/outputs continue through the immutable SHA-256 snapshot pipeline. No automatic real-world prediction or cross-system confidence uplift is generated. See `WESTERN_RULE_SOURCES.md` and `V082_WESTERN_MODERN_ASPECT_PATTERNS_STATUS.md`.

## v0.77.0+81 — Western Astrology Foundation v1

Western Astrology is now an available governed module. v081 casts tropical natal charts for the seven traditional planets plus the selected lunar nodes, supports explicit Placidus / Whole Sign / Equal houses, calculates five major aspects using a versioned orb profile, records applying/separating evidence, and publishes domicile/exaltation/detriment/fall evidence without numeric dignity scoring. Western consultation inputs/outputs use the existing immutable SHA-256 snapshot pipeline. Native wrapper ABI is `al-abi-8`; polar Placidus geometry is rejected while Whole Sign/Equal remain available when selected explicitly. No automatic event prediction or cross-system confidence uplift is generated. See `WESTERN_RULE_SOURCES.md` and `V081_WESTERN_FOUNDATION_STATUS.md`.

## v0.76.0+80 — KP Horary Timing & Ruling-Planet Confirmation v1

KP now includes a separate 1–249 Horary workflow plus query-time Ruling-Planet corroboration for the governed Marriage/Children Promise profiles. The selected number deterministically maps to a governed sidereal Ascendant segment; planets use the actual query moment/location, natal birth inputs are excluded, and Placidus cusps bind to the selected Ascendant within a strict tolerance. The RP layer preserves partial and detrimental contradictions, caps confidence at Moderate, and does not reuse natal DBA, scan future transits or produce an exact event date. Horary inputs/outputs remain immutable schema-v12 snapshots with backup/merge integrity coverage. See `KP_RULE_SOURCES.md`, `V079_KP_HORARY_FOUNDATION_STATUS.md` and `V080_KP_HORARY_RP_CONFIRMATION_STATUS.md`.

## v0.74.0+78 — KP Transit & Ruling-Planet Timing Confirmation v1

KP now keeps a third, independent timing layer above chart promise and DBA selection. At the reference moment, Dasha/Bhukti/Antara and Sun/Moon transit Star-Lords are checked against the natal fruitful event significators, while standard Ruling-Planet overlap is retained as separate confirmation evidence. Contradictions are preserved, Day-Lord/Sub-Lord RP roles are audit-only in this v1 profile, and confidence is capped at Moderate. KP chart output is `astro-logic-kp-native` 1.3.0 / `kp-native-chart-v4`; SQLite remains v11. See `KP_RULE_SOURCES.md` and `V078_KP_TRANSIT_RP_CONFIRMATION_STATUS.md`.

## v0.71.0+75 — KP Native Chart Casting v1

KP now has governed native Android/Windows chart casting. The native ABI computes the versioned classic Krishnamurti Reader-1 ayanamsha reconstruction, exact Placidus twelve-cusp frame (with polar rejection rather than silent fallback), and full planet/cusp Star/Sub classification. Consultation-linked KP outputs are stored through the existing immutable calculation snapshot pipeline.

The selected ayanamsha remains visibly versioned because historical KP definitions are not perfectly unique. Swiss Ephemeris is used only as a development-time numeric fixture oracle; no Swiss code/library is bundled or linked. See `KP_RULE_SOURCES.md` and `V075_KP_NATIVE_CHART_STATUS.md`.

## Locked product decisions

- Users: professional astrologers only
- Platforms: Android and Windows Desktop
- Languages: Bengali and English
- Connectivity: fully offline
- Systems: Vedic/Parashari, KP, Western, Numerology, Vastu, Palmistry
- Output: astrologer-reviewed consultation reports
- Distribution: proprietary commercial software
- Astronomical base: MIT-licensed Astronomy Engine; Swiss Ephemeris excluded


### Vedic Remedy Recommendation Engine v1

- Requires at least two distinct challenging chart-rule evidence records in the same actionable life area before drafting any remedy.
- v1 automates only bilingual behavioural risk-management guidance; it does not claim that the action changes planetary effects.
- Longevity/death automation is excluded, and health/finance/career/property/relationship/children guidance carries explicit qualified-professional safeguards.
- The old negative-Lagna-lord gemstone shortcut is removed. Gemstone Candidate & Contraindication v1 now publishes review-only status for seven classical planets; mantra, charity and ritual remain gated.
- Professional Report Engine 1.2.0 renders automated behavioural remedy drafts, structured gemstone eligibility/contraindication review, and practitioner-reviewed gemstone records.

### Advanced Rahu/Ketu Analysis v1

- Source-bounded natal Rahu/Ketu whole-sign house review from Phaladeepika VIII.25-34.
- Explicit sign-dispositor and same-sign association context; no invented Rahu/Ketu dignity, exaltation/debilitation or node aspects.
- Node-Dasha association review from Phaladeepika XX.39, 52-53 with conflict preservation and Medium confidence ceiling.
- Transit v3 adds Rahu Moon-relative directional review from Phaladeepika XXVI.24; Ketu transit direction remains gated.
- Medical, mortality, legal, financial and relationship-event conclusions are prohibited from node evidence alone.

## Architecture

The product is divided into three independent layers:

1. **Calculation Core** — deterministic astronomical and numerological results.
2. **Interpretation Workspace** — rule-backed suggestions with visible evidence.
3. **Astrologer Approval** — edits, approves and signs the final report.

No interpretation or remedy is published without astrologer approval.

## Android APK build

The private GitHub repository workflow generates the standard Android runner,
connects the reviewed native C astronomical core through Gradle/CMake, runs
analysis/tests and builds a test release APK:

```text
.github/workflows/android-apk.yml
```

For a new repository and first push from Android/Termux, follow
`TERMUX_GITHUB_APK_BUILD_BN.md`.

The workflow-generated APK uses Flutter's test release signing. A protected
production keystore and a separate signed release workflow are required before
commercial distribution or Play Store upload.


### KP Horary RP confirmation v1

Supported Marriage/Children Horary snapshots now include a separate query-time Ruling-Planet corroboration layer. It compares the standard judgment-moment RP subset with the Horary event-house significator matrix, preserves detrimental contradictions, and caps confidence at Moderate. Natal DBA/birth data and exact future-date claims are explicitly excluded. See `V080_KP_HORARY_RP_CONFIRMATION_STATUS.md`.

## Current milestone: v0.78.0+82

### Signed Report Verification & QR Engine v1

- Signed reports carry a minimal hash-only QR payload (`astro-logic-signed-report-verification-v1`); client name, birth data and narratives are excluded.
- Dashboard and signed-report preview expose an offline verifier with explicit verified / no-local-record / mismatch / invalid outcomes.
- Full verified status requires matching immutable local report and approval records plus successful report, approval and signed-hash recomputation.
- A standalone structurally valid QR does not establish practitioner identity and is not a certificate-backed digital signature.
- Signed PDF renders the QR; signed DOCX embeds an offline-generated PNG QR. No online QR service is used.

### Encrypted Backup & Restore v1

- Password-protected `.albackup` export covers clients, birth records, consultations, governed settings, audit history, immutable calculations/analyses, Numerology, professional reports and practitioner approvals.
- Argon2id derives the encryption key from the user password; AES-256-GCM provides confidentiality plus authenticated tamper detection, and plaintext envelope metadata is bound as AES-GCM AAD. The password is never stored or recoverable by ASTRO LOGIC.
- Per-table and overall SHA-256 manifests are sealed inside the encrypted payload. Immutable domain hashes and SQLite foreign keys are revalidated both before backup and during restore.
- Exact restore still requires an empty workspace. Non-empty workspaces use the separate governed merge path, which never overwrites local rows, reuses canonical equivalents, remaps resolvable ID collisions, preserves immutable source identities and records a durable schema-v11 import ledger.
- Settings provides create/share and native file-pick restore actions; all processing remains offline.


### Vedic Remedy Recommendation Engine v1

- Requires at least two distinct challenging chart-rule evidence records in the same actionable life area before drafting any remedy.
- v1 automates only bilingual behavioural risk-management guidance; it does not claim that the action changes planetary effects.
- Longevity/death automation is excluded, and health/finance/career/property/relationship/children guidance carries explicit qualified-professional safeguards.
- The old negative-Lagna-lord gemstone shortcut is removed. Gemstone Candidate & Contraindication v1 now publishes review-only status for seven classical planets; mantra, charity and ritual remain gated.
- Professional Report Engine 1.2.0 renders automated behavioural remedy drafts, structured gemstone eligibility/contraindication review, and practitioner-reviewed gemstone records.

### Advanced Rahu/Ketu Analysis v1

- Source-bounded natal Rahu/Ketu whole-sign review with explicit dispositor and same-sign association evidence.
- Rahu node-Dasha association logic preserves positive/negative carrier conflicts as Mixed; Ketu does not inherit Rahu-only XX.39.
- Transit v3 enables Rahu Moon-relative direction from the governed Phaladeepika profile; Ketu transit direction remains unavailable in v1.
- Node dignity/exaltation/debilitation and node aspects remain gated rather than inferred.

### Advanced Yoga & Dosha Engine v1

- Separate maintainable `vedic_advanced_yoga_dosha_engine.dart` rather than expanding the legacy Lagna engine further.
- Source-bounded Raja Yoga, BPHS Chapter 41 Dhana formulas, Harsha/Sarala/Vimala Vipareeta profiles, Neecha-bhanga review conditions and multi-reference Kuja review.
- Weakening/cancellation/mitigation evidence stays explicit; structural formations never become guaranteed status, wealth, marriage or harm predictions.
- Cross-yoga synthesis preserves contradictions and remains capped at Medium confidence.

### Build-readiness checkpoint v1

- Android and Windows now have governed generated-runner bootstrap scripts and separate GitHub Actions build gates.
- Both CI jobs pin Flutter 3.44.7, run source audit → package resolution → analyzer → Flutter tests before platform build, and preserve the resolved dependency lock/graph as artifacts.
- `tool/static_build_readiness_audit.py` provides a source-only gate and writes `BUILD_READINESS_AUDIT.json`; it does not pretend that Flutter compilation ran when the SDK is unavailable.
- Dashboard scope is explicit: KP and Western v2 are available; Vastu, Palmistry and Practice remain Coming Soon. Vedic/Reports/Gemstone routes enter the implemented client/consultation workflow.
- See `BUILD_READINESS.md` for remaining release blockers and maintainability watchlist.


- Bilingual application shell and professional module registry
- Offline Professional Report Export Engine v3 for immutable PDF/DOCX generation, platform sharing, signed-report QR and practitioner approval-bound offline verification
- Encrypted `.albackup` backup/restore v1 with Argon2id + AES-256-GCM, SHA-256 manifests, hash revalidation, exact empty-workspace restore and governed non-empty merge
- Read-only Backup Restore Preview & Conflict/Migration Planner v1 with source app/schema metadata, manifest/snapshot verification, same-ID equivalent/conflict counts, zero-mutation preview and governed merge eligibility
- Persistent offline SQLite database for Android and Windows
- Client registration, search and list
- Controlled birth date and time pickers
- Birth-place coordinates, UTC offset and time-confidence validation
- Transactional save of client and birth record
- Client detail and edit workflow
- Multiple editable birth records per client
- Persistent governed calculation defaults
- Non-destructive database migration from schema v1 to v2
- Transactional audit events for governed changes
- Immutable calculation input snapshots protected by database triggers
- Canonical settings/input JSON and SHA-256 integrity hash
- Non-destructive database migration from schema v2 to v3
- Professional consultation creation and categorisation
- Per-consultation birth record and astrology-system selection
- Draft, reviewed and finalized workflow model
- Versioned immutable calculation-output contract without placeholder results
- Non-destructive database migration from schema v3 to v4
- Consultation detail and edit workspace
- Idempotent calculation-input preparation
- Engine orchestration contract with selected-system validation
- Governed Draft to Reviewed to Finalized transitions
- Verified output required before review or finalization
- Finalized consultation edit/output lock
- Vendor-neutral offline ephemeris provider contract
- Swiss Ephemeris code, licence gate and commercial dependency removed
- MIT Astronomy Engine selected as the offline astronomical base
- Injectable Android/Windows Astronomy Engine bridge boundary
- Native initialization-once and coordinate/UTC validation
- Pinned Astronomy Engine C source v2.1.19 with archive/per-file checksums
- Stable shared-library C ABI and cross-platform CMake target
- NASA/JPL Horizons DE441 seven-body accuracy fixture (0.01° tolerance)
- Consultation-linked governed gemstone-remedy records
- Primary/substitute stone, ratti/carat, metal, finger, day and instructions
- Verified-output/evidence requirement before astrologer approval
- Finalized-consultation lock and transactional remedy audit history
- Consultation detail remedy list with finalized-state lock display
- Bengali/English gemstone remedy Add/Edit form
- Permanent natural friendship to the sign dispositor and degree-specific Moolatrikona flags
- Same-sign conjunction evidence and multi-aspect functional conflict synthesis
- Temporary and five-fold compound relationship toward the sign dispositor
- Five classical-planet war-proximity review; current v9 may identify a latitude-based computational victor only for the governed numeric Yuddha correction, while review findings remain non-deterministic
- Offline Numerology profile v3 with audited Driver, Life Path, Maturity and three-year Personal Year context
- Pythagorean and Chaldean name totals plus governed alternate-spelling arithmetic comparison with immutable spelling evidence
- Bilingual Numerology strengths/challenges, guarded Vedic context, Personal Year planning windows and no-ranking name-candidate review
- Twelve detailed Vedic life-area judgments combining house lord, dignity,
  functional ownership, occupants and enabled Parashari full-sign aspects
- Visible supportive/challenging evidence, contradiction preservation,
  transparent net scores and conservative confidence labels
- Dedicated bilingual detailed-judgment UI after Kundli calculation
- Vimshottari Mahadasha-Antardasha calendar and medium-confidence activation
  windows; exact-event promises remain disabled while transit timing is a separate review-only layer
- Panch Mahapurusha D1 formation review for Ruchaka, Bhadra, Hamsa, Malavya
  and Shasha, with separate Kendra/dignity evidence
- Conservative Kuja-dosha Lagna screen with the disputed second-house rule
  clearly separated, possible mitigation visible and no automatic cancellation
- Dedicated bilingual Yoga/Dosha review group; no marriage-harm prediction from
  a standalone dosha screen
- BPHS-profile Gajakesari judgment with angular geometry, enabled benefic
  support, dignity, combustion and enemy-sign qualifiers shown independently
- Geometry-only Gajakesari candidates are not mislabeled as completed yogas
- Initial Raja Yoga for Lagna/fifth-lord conjunction in Kendra/Trikona
- Initial Dhana Yoga for fifth/eleventh lords occupying their own houses
- Participant strength review and no guaranteed office, status or wealth claim
- Explicit D9/Navamsha chart output for ascendant and all planets
- Explicit BPHS-profile D10/Dashamsa chart output for ascendant and all planets (3° parts; odd signs from self, even signs from the ninth)
- Seven-planet D1-D9 dignity agreement with Vargottama and contradiction review
- Twelve D9 house/lord/full-sign-aspect synthesis records with explicit Navamsha ascendant, classical functional review, node-neutral occupancy and conflict preservation
- Twelve D10 career-domain house/lord/full-sign-aspect synthesis records plus a conservative D1 tenth-lord × D10 tenth-house structural career cross-check; nodes remain occupancy-only and no career event is guaranteed
- Shadbala foundation v10 for all seven classical planets with transparent Uccha, Saptavargaja, Ojhayugma, Kendradi and Drekkana Sthana Bala, exact BPHS-27.7 Dig Bala, governed Nathonnata/Paksha/Tribhaga/Varsha/Masa/Dina/Hora/Ayana temporal-strength components, governed Cheshta Bala, fixed Naisargika Bala, exact-longitude Drik Bala and an evidence-gated sixfold aggregate
- Ashtakavarga foundation v3 with seven unreduced BAV tables, fixed 48/49/39/54/56/52/39 checksums and raw 337-point SAV, audited Trikona then occupancy-sensitive Ekadhipatya reductions, and post-Shodhana Rashi/Graha/Shodhya Pinda for all seven classical planets; raw, reduced and Pinda stages remain explicitly separate
- `vedic-chart-v10` retains the v9 temporal/latitude evidence and adds explicit Dashamsa fields plus an audited D10 chart; Hora still uses twelve seasonal daylight horas plus twelve seasonal night horas rather than fixed civil-clock hours
- Seven-varga D1/D2/D3/D7/D9/D12/D30 audit trail with versioned Rasi-based temporary-friendship policy; Drik persists each received Sphuta-Drishti contribution and signed BPHS-27.19 weighting; current v9/v10 can complete Kala as Nathonnata + Paksha + Tribhaga + Varsha + Masa + Dina + Hora + Ayana + Yuddha and, when every strength family is present, publish total Virupas/Rupas plus the BPHS 27.32-33 required-strength ratio/status
- Navamsha/sign-longitude consistency validation and backward-compatible v1
  judgment support
- Exact-Moon Vimshottari birth balance, nine Mahadashas and 81 Antardashas
- Complete 729-period Pratyantardasha calendar with parent-boundary validation
- Lazy bilingual Current/Past/Future Dasha timeline and active three-lord chain
- Selected-date Dasha × transit confirmation with active MD/AD/PD chain, governed 3:2:1 weighting, convergence/conflict state and bilingual evidence
- Nine chart-specific Dasha-lord profiles with evidence-backed scores and
  occupied/owned-house life areas
- 729 chart-specific Pratyantardasha detailed interpretations with MD broad-theme, AD modifier and PD immediate-trigger roles, governed 3:2:1 synthesis, repeated-life-area focus and bilingual review text in the Dasha timeline
- Standalone offline Vedic transit-analysis engine for a selected UTC date
- All nine sidereal transit positions with Lagna/Moon whole-sign distances
- Brihat Samhita Ch. 104 source-bounded Moon-gochara matrix for Sun, Moon, Mars, Mercury, Jupiter, Venus and Saturn
- Supportive/Challenging/Mixed directional review; ambiguous houses and Sade Sati remain non-automatic; Rahu transit now uses a separate Phaladeepika XXVI.24 profile while Ketu transit remains gated
- Question-specific Timing Engine v3 for career/employment, business/partnership, marriage, finance, education, property, children and travel/relocation, including governed target-house Ashtakavarga BAV+SAV confirmation refined by the active 3°45′ Kaksha
- Topic timing combines versioned target-house condition, active MD/AD/PD topic activation and only target-house directional transit signals; disagreements remain Mixed/low confidence
- Consultation categories now include Business and Travel / Relocation for direct routing into the governed timing-topic profile
- Full Conflict & Confidence Engine v2 across D1 target-house structure, D1-D9 target-lord agreement, active topic Dasha, topical Moon-gochara transit and governed Ashtakavarga transit confirmation
- D1 and D1-D9 are treated as one structural group, while all Ashtakavarga transit checks count as one Ashtakavarga group; explicit structural, internal-Ashtakavarga or cross-group contradictions remain Mixed/Low instead of being majority-voted away
- Three or four governed directional groups can produce Medium confidence; two-group convergence remains Low, and High confidence is still disabled because Moon-gochara and Ashtakavarga share selected-date transit-position evidence
- Dasha activation scoring from whole-sign placement, D1/D9 dignity,
  functional ownership and Rahu/Ketu sign dispositors
- Bilingual timing-window review with contradictory periods preserved as Mixed
- Safe behavioural remedy review with automatic-name-change and gemstone gates
- Professional Consultation Report Engine v1 with a governed 13-section bilingual report contract, curated executive summary, D1/D9/D10/Shadbala/Ashtakavarga/Dasha sections, explicit unavailable-state handling for non-persisted selected-date timing, optional immutable Numerology inclusion, practitioner-entered gemstone/remedy records, source manifest and SHA-256 report snapshot
- Professional Report Export Engine v2: offline A4 PDF + OOXML DOCX, source/approval hash verification, immutable practitioner sign-off, signed-report verification hash, deterministic signed/unsigned filenames and platform share flow; Bengali PDF uses a compatible device system font and never bundles font binaries
- Consultation report preview UI with immutable version history plus offline PDF/DOCX export and platform sharing; every export re-verifies the source report hash and carries the source hash in document metadata
- Responsive Android/Windows Numerology consultation workspace from dashboard
- Controlled date/year inputs, bilingual results, formulas, evidence and warnings
- Database schema v11 with immutable hash-bound snapshots/approvals, governed merge source-identity preservation and durable import batch/mapping provenance
- Consultation client/birth-date prefill, save action and version history
- Controlled planet, weight-unit and decision selectors
- Inline approval-output/evidence and weight validation
- Bilingual Kundli judgment output contract
- Supportive/challenging/mixed life-area findings and timing windows
- Evidence-backed remedy candidates with mandatory cautions
- High-confidence multi-rule requirement and imprecise-time timing guard
- Immutable calculation-bound judgment snapshots with SHA-256 integrity
- Database schema v11 and transactional analysis/Numerology/report/approval/import audit plus durable merge-batch history
- Pure Dart Vedic derivation engine for D1, D9, Nakshatra, Pada and Panchanga
- Fixed-evidence derivation tests without fabricated astronomical positions
- Third-party notice and release licence-check policy
- Android/Windows Dart FFI bridge for the stable native ABI
- Spica-anchored Lahiri/Chitrapaksha ayanamsha (Lahiri-only verified path)
- True and mean Rahu with Ketu derived exactly opposite
- Tropical and sidereal ascendant with committed frame regression fixture
- Production Vedic engine composition point guarded by build configuration
- Android Gradle/CMake packaging integration contract
- Windows CMake build-and-install integration for the FFI DLL
- Reusable native calculation and exported-symbol verification script
- Consultation-level Run Kundli Analysis workflow
- Immutable calculation-to-judgment orchestration and version history
- First Vedic rule family: Lagna identity and whole-sign Lagna-lord house
- Lagna-lord exaltation, own-sign, debilitation and neutral dignity scoring
- All twelve whole-sign houses with house sign, lord, placement and dignity
- House-wise supportive, challenging or mixed first-pass condition
- Ascendant-specific ownership scores for all seven classical planets
- Explicit Yoga-karaka flag for simultaneous Kendra/Trikona ownership
- Separate Lagna, twelve-house and functional-role review sections
- Twelve explicit house-occupancy records including empty-house safeguards
- Parashari full sign aspects: universal seventh and classical special aspects
- Rahu/Ketu aspect exclusion because traditions differ
- Versioned direct/retrograde combustion thresholds and angular evidence
- Retrograde review flags without automatic good/bad classification
- Separate occupancy, aspect and planet-condition review sections
- Evidence paths, bilingual findings, confidence and review-only remedies UI
- Exact event timing remains disabled; selected-date Dasha × transit and question-specific target-house convergence are review-only until additional governed timing families are added
- Android runner is reproducibly generated and native-linked in GitHub Actions
- Android uses the mobile SQLite factory; Windows/Linux tests retain FFI SQLite
- Private-repository Termux bootstrap and APK artifact workflow
- Vedic Remedy Recommendation Engine v1 now generates evidence-gated behavioural remedy drafts only after two independent challenging rules converge. Gemstone Candidate & Contraindication v1 now publishes review-only status for the seven classical planets; mantra/charity/ritual rule families remain pending, while practitioner-reviewed gemstone records continue to require explicit approval. Professional report PDF/DOCX export is available from immutable saved report snapshots.
- Broader partial-aspect interpretation outside Shadbala, later divisional charts beyond D9, Ashtakavarga Pinda-derived timing extensions, deeper D9/Shadbala conflict-confidence integration, Ketu transit polarity, broader exact-degree transit triggers and broader event-family timing remain pending


## Previous governed backup milestone — v0.66.0+70

Governed Backup Merge/Migration Adapter v1 can import verified schema-v9/v10 `.albackup` data into a non-empty workspace without overwriting existing local records. Equivalent rows are reused, resolvable primary-key collisions are deterministically remapped, source IDs required by immutable hashes/signed-report QR verification are preserved in schema-v10 integrity columns, and the merge is committed only after foreign-key and governed-hash verification.



## Core maintainability refactor — v0.68.0+72

The largest Vedic, Shadbala, encrypted-backup and consultation-detail files are now split into governed Dart library parts. Public engine/service APIs, private rule names, serialized schemas and integrity/hash contracts are unchanged. The static `LARGE_DART_FILES` release-readiness gate now passes; the remaining source-only warning is the missing `pubspec.lock`, which must be generated and retained at the final Flutter build checkpoint.

## Backup import ledger — v0.67.0+71

Governed non-empty backup merge now records a local schema-v11 batch ledger. Committed batches preserve source manifest/version/schema, inserted/equivalent/remapped counts, immutable per-row source→local mappings with row hashes, all-or-nothing rollback policy and an exportable SHA-256 merge receipt. Failed/interrupted attempts keep diagnostics but no partial imported rows or mapping ledger entries. The operational import ledger is deliberately local-only rather than recursively embedded in portable backups.


## GitHub push-ready v082 checkpoint

For the v082 Android runtime checkpoint, `.github/workflows/android-apk.yml` runs on `main` and manual dispatch. It executes source readiness, the v082 source/native validator, Flutter package resolution, analyzer, tests, native regression, release APK build, governed evidence packaging and artifact upload. Flutter is pinned to `3.44.7`. Windows does not run automatically on `main` at this checkpoint; it remains manual/tag governed. An uncommitted `pubspec.lock` may be generated by CI and preserved as evidence, but it is not treated as the final tested lock until the governed release process accepts it.
