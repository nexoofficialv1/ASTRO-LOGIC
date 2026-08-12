## 0.78.0+82

- Western engine upgraded to `1.1.0` / `western-natal-chart-v2` / `western-input-schema-v2` with native Uranus, Neptune and Pluto positions through the pinned MIT Astronomy Engine core; native wrapper body-code contract advances to `al-abi-9` while legacy body codes 0–6 remain unchanged.
- Added explicit Traditional and Modern rulership profiles. Modern profile maps Scorpio/Pluto, Aquarius/Uranus and Pisces/Neptune, while the existing seven-planet traditional essential-dignity profile remains authoritative and receives no silent outer-planet scoring.
- Added governed optional minor aspects (30°, 45°, 72°, 135°, 150°) behind `western-major-minor-aspect-orb-v1`; major-only remains the default. Orb widths are versioned ASTRO LOGIC operating policy, not claimed as universal doctrine.
- Added deterministic Grand Trine, T-Square, Grand Cross, strict conjunction-clique Stellium, Yod and Kite evidence with component planets/aspects/orbs retained and no automatic life-event prediction.
- Added bilingual Western workspace selectors, modern-planet table, aspect table, pattern panel and rulership evidence. Consultation snapshots reuse the existing immutable SHA-256 calculation snapshot/output pipeline; SQLite remains schema 12 and encrypted backup/merge engine remains 1.4.0.
- Source/native validation adds independent rounded outer-planet ephemeris fixtures, aspect boundary fixtures, pattern fixtures, KP/Placidus regression and release-source preparation gates. No Flutter/Dart runtime PASS, APK build or Windows final build is claimed in this source milestone.

## 0.77.0+81

- Added Western Astrology Foundation v1 with `astro-logic-western-native` 1.0.0 / `western-natal-chart-v1` and Western-specific immutable input schema `western-input-schema-v1`.
- Added tropical Sun, Moon, Mercury, Venus, Mars, Jupiter and Saturn plus selected true/mean North/South lunar-node chart points using the existing MIT Astronomy Engine native core.
- Added explicit Placidus, Whole Sign and Equal house profiles. Native ABI upgraded to `al-abi-8` so polar Placidus failure no longer blocks Whole Sign/Equal tropical Ascendant/MC/node calculation; no house-system fallback is substituted silently.
- Added the five major aspects (conjunction, sextile, square, trine, opposition) with a disclosed versioned orb profile and applying/separating evidence derived from native longitude speeds. Lunar nodes remain outside the v1 aspect matrix.
- Added traditional seven-planet domicile/exaltation/detriment/fall evidence without numeric dignity scoring; triplicity, terms/bounds, faces/decans and modern outer-planet rulerships remain gated.
- Added standalone bilingual Western workspace, Dashboard availability, consultation-linked execution and hash-protected calculation output snapshots. SQLite remains schema 12 and backup engine remains 1.4.0 because existing generic calculation snapshot tables already cover Western inputs/outputs.
- Western evidence remains independent practitioner-review material: no automatic event prediction, timing guarantee or cross-system confidence uplift is generated.

## 0.76.0+80

- Added KP Horary Timing & Ruling-Planet Confirmation v1 with `kp-horary-rp-confirmation-v1` / `kp-horary-query-rp-overlap-v1`.
- Supported Horary Marriage/Children Promise review now preserves a separate query-time RP corroboration state: corroborated, partial, contradictory, insufficient or not eligible.
- Standard confidence subset is Ascendant Star Lord, Ascendant Sign Lord, Moon Star Lord and Moon Sign Lord; Day Lord and expanded Sub-Lord roles remain audit-only.
- Primary-cusp sub-lord fruitful overlap is required for full Horary corroboration; detrimental-only standard RP evidence is never hidden by favourable evidence.
- Confidence remains capped at Moderate. Natal birth data, natal DBA, future transit scanning, exact event dates and real-world guarantees remain excluded.
- KP Horary engine upgraded to `1.1.0` / `kp-horary-chart-v2`; SQLite remains schema 12 and backup engine remains `1.4.0`, with the new evidence protected inside immutable Horary output hashes.

## 0.75.0+79

- Added KP Horary Foundation v1 with exact deterministic `kp-horary-249-table-v1` generation from 27 Vimshottari Star/Sub partitions plus sign-boundary splitting, yielding the governed 1–249 number map without hard-coded rows.
- Added `astro-logic-kp-horary` 1.0.0 / `kp-horary-input-v1` / `kp-horary-chart-v1`. A horary number sets the sidereal Ascendant at the selected segment start; query-moment planets are cast from the actual question UTC/location and natal birth data is not consumed.
- Added a native Placidus cusp binding solver that finds a technical frame whose cusp 1 matches the selected Horary Ascendant within 2 arcseconds. The technical solution timestamp is explicitly not treated as event time.
- Added conservative Horary event evidence: General questions remain practitioner-only, while only the already governed Marriage and Children cusp profiles may produce the existing Promise/Denial/Insufficient-Evidence state. Automatic timing and real-world guarantees remain disabled.
- Added immutable `kp_horary_snapshots` persistence and SQLite schema v12 with SHA-256-bound input/settings/output, no-update/no-delete triggers and audit creation events.
- Upgraded encrypted backup engine to 1.4.0 with a schema-aware protected-table set so schema 9–11 backups remain readable/mergeable while schema 12 includes `kp_horary_snapshots`; imported `kpHorary` audit entity IDs follow governed ID remapping.

## 0.74.0+78

- Added KP Transit & Ruling-Planet Timing Confirmation v1 without changing SQLite schema v11, native ABI v7 or the v077 DBA selection policy.
- Upgraded `astro-logic-kp-native` to `1.3.0` / `kp-native-chart-v4`; supported Marriage/Children consultation snapshots now persist a separate `kp-transit-rp-confirmation-v1` layer beside chart promise and `kp-dasha-timing-v1`.
- Frozen operational transit profile: Dasha/Bhukti/Antara plus Sun/Moon are evaluated by their reference-time KP transit Star-Lord against the natal fruitful/detrimental event-significator evidence. Sub-Lord/Sign-Lord transit is retained in the point data but does not silently add confidence.
- Ruling-Planet overlap uses Ascendant Star Lord, Ascendant Sign Lord, Moon Star Lord and Moon Sign Lord for v1 confidence; expanded Sub-Lord roles and civil-weekday Day Lord remain audit-only because sunrise-based Hindu-day resolution is not yet implemented.
- Added confirmation states `confirmedForPractitionerReview`, `partialConfirmation`, `contradictory`, `insufficientConfirmation` and `notEligible`; DBA state is never rewritten by the confirmation layer.
- Added a hard confidence ceiling: confirmed -> Moderate maximum; partial/contradictory -> Low; insufficient/not-eligible -> None. No exact event date or real-world guarantee is produced.
- Expanded the bilingual KP workspace with transit/RP confirmation state, confidence ceiling, RP overlap and D/B/A + Sun/Moon Star-Lord evidence.

## 0.73.0+77

- Added KP Dasha & Timing Synthesis v1 while preserving SQLite schema v11, native ABI v7 and all existing Vedic/Numerology/report/backup contracts.
- Upgraded `astro-logic-kp-native` to `1.2.0` / `kp-native-chart-v3`; consultation-linked Marriage/Children KP snapshots now persist a separate `kp-dasha-timing-v1` evidence layer beside the existing cusp-sub-lord promise review.
- Reused governed Vimshottari calendar v2 with the KP-native Moon sidereal longitude and explicitly maps Mahadasha/Antardasha/Pratyantardasha to KP Dasha/Bhukti/Antara labels without changing the shared calendar arithmetic.
- Added `kp-vimshottari-dba-house-coverage-v1`: a Supportive window requires every DBA lord to touch at least one frozen conductive house, the combined chain to cover the full event-house group, and no frozen detrimental-house hit. Mixed/incomplete relevant periods remain Conflicting rather than being discarded.
- Chart-promise and timing remain separate gates. Denial or Insufficient Evidence retains all DBA evidence for audit but promotes no actionable supportive timing window.
- The immutable timing output keeps per-lord level evidence, all post-birth DBA windows, current DBA, supportive/conflicting counts and next supportive windows. Transit and Ruling-Planet confirmation flags remain explicitly false for this v1 layer.
- Expanded the bilingual KP workspace with current DBA and next-window review while retaining explicit no-guarantee/no-cross-system-confidence-uplift disclosures.

## 0.72.0+76

- Added KP Advanced Significator & Event Judgment v1 while keeping SQLite schema v11, native ABI v7 and all Vedic/Numerology/report/backup contracts unchanged.
- Upgraded `astro-logic-kp-native` to `1.1.0` / `kp-native-chart-v2` and added deterministic Placidus house occupancy plus cusp-sign house ownership for Sun through Saturn, Rahu and Ketu. Rahu/Ketu retain no sign ownership in the frozen profile.
- Added `kp-house-significator-synthesis-v1`, deriving the existing four-level hierarchy from the native chart: star-lord occupancy, planet occupancy, star-lord ownership and planet ownership.
- Added source-bounded `kp-cusp-sublord-promise-review-v1` with automatic review only for Marriage (7th cusp, 2/7/11; detriments 1/6/10) and Children (5th cusp, 2/5/11; detriments 1/4/10).
- Promise is emitted only for conductive-only cusp-sub-lord evidence, Denial only for detrimental-only evidence, and mixed/neither evidence remains Insufficient Evidence. These are practitioner-review states, not real-world guarantees.
- Consultation-linked KP snapshots persist event judgment only for supported Marriage/Children categories; all other categories retain advanced significators but no invented event formula.
- Expanded the bilingual KP workspace with house occupancy, combined significators and manual Marriage/Children cusp-sub-lord evidence review.

## 0.71.0+75

- Added KP Native Chart Casting v1 (`astro-logic-kp-native` / `kp-native-chart-v1`) on top of the v074 deterministic Star/Sub foundation, without changing Vedic/Numerology/report schemas or SQLite schema v11.
- Added native ABI v7 `al_calculate_kp_frame` with a governed classic Krishnamurti Reader-1 reconstruction (`kp-krishnamurti-classic-j1900-newcomb-v1`) and independently implemented Newcomb/Kinoshita precession. The profile remains explicitly versioned because historical KP ayanamsha definitions are not perfectly unique.
- Added native Placidus time-division twelve-cusp calculation (`kp-placidus-time-division-native-v1`) with no silent Porphyry fallback. Unsupported polar geometry is rejected.
- Added full Sun/Moon/Mars/Mercury/Jupiter/Venus/Saturn/Rahu/Ketu and 12-cusp sign/star/sub classification plus ruling-planet evidence from the generated chart.
- Added development-only external numeric fixtures for classic Krishnamurti ayanamsha and tropical Placidus cusps. Swiss Ephemeris code/library is not linked, bundled or used at runtime.
- Added governed consultation integration: KP-specific immutable input snapshot (`kp-input-schema-v1`) and hash-protected generic calculation output snapshot. Existing encrypted backup/restore/merge automatically carries these rows through the governed snapshot tables.
- Upgraded the KP workspace to include native Android/Windows casting while retaining manual sidereal-point and supplied-cusp tools as cross-checks.
- Native C verification now compiles/runs the ABI and checks KP ayanamsha, all 12 Placidus cusps, sidereal projection, polar rejection and required export symbols.
- Western, Vastu, Palmistry and Practice remain incomplete and continue to block the full-scope commercial release gate.

## 0.70.0+74

- Added KP Astrology Foundation v1 (`kp-foundation-v1`) while keeping SQLite schema v11 and all Vedic, Numerology, report/signing/QR, encrypted-backup and governed-merge contracts unchanged.
- Added exact micro-arcsecond sign/star/sub classification using Vimshottari-proportional sub spans instead of a copied global lookup table; exact nakshatra/sub boundaries are derived deterministically from the nine Dasha-year ratios.
- Added supplied twelve-cusp classification framework, four-level KP significator evidence collector and a versioned seven-role ruling-planet review panel. These are evidence tools only and do not create guaranteed event predictions.
- Added bilingual KP Foundation workspace and promoted the KP Dashboard tile from Coming Soon to an available foundation module.
- Exact native KP chart casting remains deliberately gated: the current native ephemeris is verified for Lahiri only and does not yet expose independently verified Placidus twelve-cusp output. No Krishnamurti ayanamsha formula is invented or silently approximated.
- Added `KP_RULE_SOURCES.md` and `V074_KP_FOUNDATION_STATUS.md`; Western, Vastu, Palmistry and Practice remain Coming Soon and continue to block the full-scope commercial release gate.
- Flutter/Dart SDK is still unavailable in this container, so runtime analyzer/test/APK/Windows success is not claimed.

## 0.69.0+73

- Added Final Flutter CI & Release Gate Preparation v1 without changing SQLite schema v11, astrology/numerology calculation or judgment contracts, professional report/signing/QR contracts, encrypted-backup contracts or governed merge/ledger contracts.
- Added release source gate `astro-logic-final-release-source-gate-v1` with exact pubspec/changelog/tag alignment, committed-lock enforcement and optional full-product-scope blocking for dashboard modules still marked Coming Soon.
- Removed `pubspec.lock` from `.gitignore` so the exact tested lock can be committed after the first final CI resolution; tagged release workflows require lock-enforced package resolution with `--enforce-lockfile`.
- Upgraded Android and Windows GitHub Actions to capture analyzer, Flutter-test, native-verification and dependency evidence, then package versioned platform artifacts with SHA-256 manifests through `astro-logic-platform-release-evidence-v1`.
- Added deterministic Windows Release ZIP packaging with per-file inventory hashes, Android versioned APK packaging, and explicit no-code-signing/no-PKI claims.
- Added `astro-logic-final-release-bundle-v1` assembler that refuses to combine Android and Windows evidence unless app version, release tag, source commit, Flutter version, lock SHA-256 and Astronomy Engine backend all match.
- Added `RELEASE_GATE.md` and updated the Termux flow with the two-stage tested-lock process, exact release-tag contract and real-device acceptance checklist.
- Final `v*` tagged source gate intentionally requires full product scope; KP, Western, Vastu, Palmistry and Practice still being Coming Soon therefore blocks a full-scope commercial tag at this milestone.
- This container still has no Flutter/Dart SDK, so runtime analyzer/test/APK/Windows success and a tested `pubspec.lock` are not claimed.

## 0.68.0+72

- Completed Core Maintainability Refactor v1 without changing SQLite schema v11, Vedic calculation/judgment contracts, Numerology contracts, report/signing hashes, signed-report QR identity, encrypted-backup contracts or merge-receipt contracts.
- Split the 2921-line Vedic Lagna judgment implementation into a 363-line public engine plus governed timing/yoga, house-rule and support part files. Rule functions and lookup data remain in the same Dart library and preserve the existing private symbols and call order.
- Split the 1842-line Shadbala implementation into a 111-line public engine plus profile, Kala/geometry and support part files while retaining `shadbala-foundation-v10` and the same serialized outputs.
- Split pure encrypted-backup merge/envelope/integrity helpers from the public service, reducing the main service from 2087 to 764 lines without changing backup engine 1.3.0, schema/reader support, encryption parameters, merge transaction semantics, ledger receipts or integrity checks.
- Split Consultation Detail read-only analysis widgets into library part files, reducing the screen from 1426 to 594 lines without changing navigation, actions or persisted state.
- Static build-readiness `LARGE_DART_FILES` gate now passes: no Dart file is >=2500 lines. The only remaining readiness warning in this source-only environment is the final `pubspec.lock` release gate.
- Flutter/Dart SDK is still unavailable in this container, so `flutter analyze`, `flutter test`, Android APK and Windows build success are not claimed.

## 0.67.0+71

- Added Backup Merge Recovery & Import Batch Ledger v1 with durable local `backup_import_batches` and immutable `backup_import_mappings` tables; promoted SQLite to schema v11 while keeping the encrypted `.albackup` envelope/payload contract v1 and governed merge contract v1.
- Every governed merge now creates a `started` batch record before data mutation. Imported rows plus source→local mapping ledger rows are committed in the same all-or-nothing SQLite transaction; the batch is atomically terminalized as `committed` with counts and receipt SHA-256.
- Transaction failures retain no partial imported rows/mappings and terminalize the durable batch as `failed` with bounded diagnostics. A process interruption leaves only a `started` batch; startup recovery safely marks it failed because a committed merge necessarily terminalizes the batch inside the same transaction.
- Added per-row provenance ledger entries with table name, source ID, local ID, resolution (`inserted`, `equivalent`, `remapped`), source-row SHA-256 and local-row SHA-256. Ledger mapping rows and terminal batch rows are protected by SQLite immutability triggers.
- Added merge receipt contract `astro-logic-backup-merge-receipt-v1`. The receipt SHA-256 binds source manifest/version/schema, batch counts, rollback/source-integrity policy and the complete deterministic source→local mapping list. Committed receipts are re-hashed from the ledger before JSON export/share.
- Duplicate-manifest blocking now consults the durable committed batch ledger as well as legacy `governedBackupMerged` audit history, preserving compatibility with v070-era imports. Reader compatibility remains engines 1.0.0–1.3.0 and governed merge supports source schemas v9, v10 and v11.
- Added bilingual Backup Import Batch Ledger UI with batch status, diagnostics, mapping inspection and committed receipt export. Import-ledger operational metadata remains local-only and is intentionally not recursively included in portable protected backup tables.
- Added recovery/ledger model tests and v071 validation coverage. Flutter/Dart SDK runtime validation, APK and Windows builds remain deferred to the final build checkpoint.

## 0.66.0+70

- Added Governed Backup Merge/Migration Adapter v1 (`astro-logic-governed-backup-merge-v1`) and promoted SQLite to schema v10 while keeping the encrypted `.albackup` envelope/payload contract v1.
- Added deterministic primary-key remapping for non-empty-workspace import: free source IDs are preserved, canonically equivalent rows are reused, and same-ID/different-content rows are moved above the occupied/source ID range without overwriting local records.
- Added v9→v10 merge adaptation with source integrity-ID columns for Kundli analysis, Numerology, professional reports and approvals. Local foreign keys may be remapped while original hash/signature identity IDs remain available for immutable hash recomputation and signed-report QR verification.
- Added semantic unique-key conflict gates for Numerology snapshots, professional reports and report approvals. Different content under the same immutable unique identity blocks the entire merge instead of being silently remapped.
- Added all-or-nothing transactional merge execution, foreign-key verification, governed hash revalidation after insertion, duplicate-manifest blocking and a `governedBackupMerged` audit event with source version/schema/manifest, remap counts and rollback policy.
- Imported audit rows retain their original summary inside provenance metadata while client entity IDs are mapped to the local client identity. Active local astrology settings are never overwritten by merge; historical calculation snapshots retain their embedded source settings.
- Backup writer engine is now `1.2.0`; reader compatibility remains `1.0.0`, `1.1.0` and `1.2.0`. New backups advertise governed merge support while older v068/v069 empty-restore policies remain readable.
- Added bilingual merge eligibility/confirmation/results UI. Flutter/Dart SDK runtime validation, APK and Windows builds remain deferred to the final build checkpoint.

## 0.65.0+69

- Added Backup Restore Preview & Conflict/Migration Planner v1 without changing SQLite schema v9 or the encrypted `.albackup` contract. Preview decrypts/authenticates the file, verifies the canonical manifest, shows source app/backup-engine/schema metadata and performs governed snapshot-hash verification when the source schema matches the current schema.
- Preview is read-only: it records no audit event, performs no INSERT/UPDATE/DELETE, never stores the password, and exposes `databaseMutationPerformed=false`. Actual restore requires a second password entry and reruns authentication/integrity gates.
- Added table-by-table same-ID planning: incoming IDs are classified as new, canonically equivalent, or conflicting. Same-ID/different-content records are blocking conflicts; equivalent records are recognized but never rewritten. Automatic overwrite, merge and ID remapping remain disabled.
- Non-empty workspaces are previewable but not restorable in v1. Current-schema + empty-workspace + verified snapshot integrity is the only executable restore path. Older/newer schema backups can be authenticated and manifest-checked when the reader contract is supported, but require an explicit migration adapter before restore.
- Backup reader compatibility now accepts engine `1.0.0` (v068 backups) and `1.1.0` (v069) under the unchanged v1 envelope/payload contract; new backups are written with engine `1.1.0`.
- Added bilingual restore-preview UI, source metadata, manifest/snapshot integrity states, local governed-row count, per-table conflict counts, and restore gating. GitHub push, Flutter runtime tests, APK and Windows builds remain deferred to the final build checkpoint.

## 0.64.0+68

- Added Encrypted Backup & Restore v1 (`astro-logic-encrypted-backup-v1`) for all governed user-data tables while keeping SQLite schema v9 unchanged.
- Backup encryption uses password-derived Argon2id (19 MiB, parallelism 1, iterations 2, 32-byte key) plus AES-256-GCM authenticated encryption. Every backup gets a random 16-byte salt and a fresh cipher nonce; contract/version/schema/KDF/cipher/timestamp envelope metadata is authenticated as AES-GCM AAD, and the password is never persisted.
- Added a versioned encrypted envelope, encrypted logical payload, per-table SHA-256 integrity entries and an overall canonical manifest hash (`sorted-json-keys-v1`).
- Backup creation refuses to seal data if SQLite foreign-key checks fail or any immutable calculation, Kundli, Numerology, professional-report, approval or signed-report hash fails recomputation. Restore performs the same checks before insertion and rechecks table manifests after transactional insertion.
- Restore v1 is deliberately `emptyWorkspaceOnly`: it never overwrites or merges existing records. Original primary keys, foreign-key links, immutable snapshots, approvals, audit history and settings are restored transactionally; a local restore audit event is appended only after exact-content verification.
- Added Settings > Encrypted backup & restore, password confirmation, `.albackup` export/share, native Android/Windows-oriented file selection, wrong-password/tamper rejection and bilingual disclosures that ASTRO LOGIC cannot recover a lost backup password.
- Added `cryptography` 2.9.0 and `file_picker` 11.0.3 dependencies, encrypted-backup contract tests and v068 source-validation coverage. GitHub push, Flutter runtime tests, APK and Windows builds remain deferred to the final build checkpoint.

## 0.63.0+67

- Added Signed Report Verification & QR Engine v1 (`astro-logic-signed-report-verification-v1`) without changing astrology calculation/judgment contracts or SQLite schema v9.
- Signed-report QR payload is deliberately minimal: verification contract, local report/consultation ids, report SHA-256, approval SHA-256, signed-report SHA-256 and approval-statement version only. Client name, birth data and report narratives are excluded from the QR payload.
- Added a fully offline verifier with four truthful states: verified against matching local immutable records; structurally valid payload with no local record; mismatch/tamper detected; invalid/unsupported payload. A valid standalone QR never claims practitioner authenticity without matching local immutable report and approval records.
- Verification recomputes source report hash from persisted report JSON/source manifest/engine identity, approval hash from immutable practitioner metadata, and signed-report hash from the report+approval binding before returning a verified state.
- Added QR presentation to signed-report preview plus a Dashboard verifier entry point. Camera scanning is intentionally not required; payload paste and locally pre-filled verification work offline on Android and Windows-oriented source.
- Promoted Professional Report Export Engine to `1.2.0` / `professional-report-export-v3`. Signed PDFs render the verification QR directly; signed DOCX embeds a generated PNG QR and relationship metadata while keeping visible approval/signed hashes and disclosures.
- Added pure-Dart `qr` 4.0.0 generation dependency and an internal PNG rasterizer for DOCX export; no online QR service is used.
- Added regression coverage for local verification, no-local-record truthfulness, payload hash tamper, persisted report-content tamper, QR privacy minimisation, PNG encoding and DOCX QR packaging. GitHub push, Flutter runtime tests, APK and Windows builds remain deferred to the final build checkpoint.

## 0.62.0+66

- Added Professional Report Signing & Approval Workflow v1 with immutable practitioner identity metadata, explicit client-delivery approval decisions and report-level post-sign locking.
- Promoted SQLite to schema v9 with `professional_report_approvals`, one approval per report snapshot, foreign-key linkage, report-hash/consultation insert guards, immutable UPDATE/DELETE triggers and transactional audit history.
- Added approval integrity contract `professional-report-approval-statement-v1`: `approvalHash` binds report identity/hash, practitioner metadata, decision/note and UTC approval instant; `signedReportHash` binds source report hash to the approval hash and statement version.
- Approval requires practitioner name/designation and explicit UI acknowledgement. Credential/registration reference remains optional and is never invented. `approvedWithReservations` requires a note. Existing approval cannot be edited or re-signed; a changed opinion requires a new report snapshot.
- Promoted Professional Report Export Engine to `1.1.0` / `professional-report-export-v2`. Signed PDF/DOCX exports re-verify report, approval and signed-report hashes; include visible bilingual approval/verification metadata; use `_signed` filenames bound to the signed-report hash; and preserve unsigned export compatibility.
- Added explicit disclosure that ASTRO LOGIC sign-off is an in-app practitioner electronic approval, not a certificate-backed PKI/cryptographic digital signature.
- Added regression coverage for identity-bound approval hashes, reservations-note policy, signed export naming/metadata and tamper rejection. Vedic calculation remains `vedic-chart-v10`, Vedic judgment remains `32.0.0` / `kundli-analysis-v32`, Numerology remains `2.1.0` / v3, and GitHub/APK remain deferred.

## 0.61.0+65

- Added Numerology Name Candidate Comparison Engine v1 and promoted calculation to `2.1.0` / `numerology-profile-v3` and judgment to `2.1.0` / `numerology-analysis-v3`.
- The exact stored original Latin spelling remains the immutable baseline. Up to eight practitioner-entered alternate Latin spellings can be compared under the same frozen Pythagorean/Chaldean mappings; baseline-equivalent and normalized duplicate candidates are rejected.
- Each comparison persists compound/reduced deltas, Pythagorean Soul Urge/Personality change flags, Pythagorean/Chaldean core-number arithmetic overlaps and neutral `noReducedChange` / `oneSystemReducedChange` / `bothSystemsReducedChange` status. Core overlap is explicitly not a favourability score.
- Candidate ranking, best/lucky-name claims, automatic selection and legal-name-change recommendations are disabled. At most one optional professional discussion focus may be explicitly selected by a human and is stored as discussion context only, never as engine endorsement.
- Candidate inputs and explicit professional focus are included in immutable Numerology snapshot integrity binding; no SQLite migration is required because the governed comparison lives in versioned JSON payloads.
- Expanded the Numerology workspace and Professional Report Engine `1.4.0` to display alternate-name arithmetic comparison records and any explicit professional focus with caution text.
- Added regression coverage for duplicate rejection, candidate limits, explicit-selection membership, no-ranking policy, snapshot binding and report integration. Vedic calculation remains `vedic-chart-v10`, Vedic judgment remains `32.0.0` / `kundli-analysis-v32`, SQLite remains schema v8, and GitHub/APK remain deferred.

## 0.60.0+64

- Finalized Numerology v2: calculation engine `2.0.0` / `numerology-profile-v2` and judgment engine `2.0.0` / `numerology-analysis-v2`.
- Split the frozen Life Path component-reduction policy from the calendar-cycle Personal Year policy, with explicit formula evidence and documented published-school disagreement instead of silently mixing reduction conventions.
- Added Maturity synthesis, Soul Urge and Personality interpretation, explicit zero-vowel-subtotal handling, and previous/target/next Personal Year planning context.
- Added a global Low prediction-confidence contract: deterministic arithmetic never upgrades traditional symbolic prediction confidence.
- Added guarded Numerology↔Vedic cross-check v1 for Driver, Life Path and Pythagorean Expression using only an immutable Kundli judgment snapshot from the same consultation. Cross-system records stay Low confidence, do not count as independent Vedic evidence and cannot approve gemstones.
- Restricted Numerology automatic remedies to non-planetary behavioural reflection. Gemstone, mantra, charity, ritual, automatic name change and high-stakes directives remain prohibited.
- Expanded the Numerology workspace and promoted Professional Report Engine to `1.3.0` for v2 findings, confidence policy, three-year cycle and guarded cross-system context.
- Fixed a v063 Professional Report source syntax regression: the Bengali remedy/gemstone section summary named argument was missing its trailing comma. Vedic calculation remains `vedic-chart-v10`, Vedic judgment remains `32.0.0` / `kundli-analysis-v32`, SQLite remains schema v8, and GitHub/APK remain deferred.

## 0.59.0+63

- Added `Vedic Gemstone Candidate & Contraindication Engine v1` and promoted Vedic judgment to `32.0.0` / `kundli-analysis-v32`.
- The engine emits a structured review for each of the seven classical planets with `eligible`, `contraindicated`, or `insufficientEvidence`; Rahu/Ketu gemstone automation remains outside v1.
- Eligibility requires supportive functional lordship, complete governed Shadbala below its required threshold, active Mahadasha/Antardasha relevance at the immutable analysis instant, no same-sign node contact, and no unresolved planetary-war state.
- Functional-lordship score <= -2 is a hard v1 strengthening contraindication. Complete-strength sufficiency, missing active Dasha context, node contact and unresolved war evidence block eligibility rather than being silently ignored. Combustion and computed Yuddha loss are retained as weakness-review context, not standalone approval triggers.
- Added an explicit operational Navaratna mapping profile for candidate display only. The engine does not automate substitute gemstones or approve weight, metal, finger, wearing day, ritual, medical claims or guaranteed outcomes. Practitioner-entered gemstone records still pass the existing verified-output/evidence/astrologer-approval policy.
- Professional Report engine is promoted to `1.2.0` and can render the structured gemstone review states alongside behavioural remedies and practitioner-reviewed records. Calculation remains `vedic-chart-v10`, SQLite remains schema v8, and GitHub/APK remain deferred.

## 0.58.0+62

- Added `Vedic Remedy Recommendation Engine v1` as a separate maintainable module and promoted Vedic judgment to `31.0.0` / `kundli-analysis-v31`.
- Removed the legacy `negative Lagna-lord score => gemstone candidate` shortcut. v1 now requires at least two independent challenging chart-rule evidence records before it drafts a remedy.
- Automated output in this milestone is intentionally limited to bilingual behavioural risk-management guidance for actionable life areas; health, finance, career, relationship, property and child-related cautions explicitly defer high-stakes decisions to qualified professionals.
- Longevity/death-type remedy automation is excluded. Mantra, charity, ritual and automated gemstone selection remain gated until separate source and contraindication profiles are enabled.
- Professional Report engine is promoted to `1.1.0` and now renders persisted automated behavioural remedy candidates alongside practitioner-reviewed gemstone records while clearly marking automated gemstone selection as disabled.
- Added dedicated remedy-engine regression coverage for independent-evidence gating, high-stakes exclusion and supportive/mixed non-trigger behaviour. Calculation remains `vedic-chart-v10`, SQLite remains schema v8, and no database migration is required. GitHub push and APK build remain intentionally deferred.

## 0.57.0+61

- Added `Advanced Rahu/Ketu Analysis v1` as a separate maintainable rule module with source-bounded natal whole-sign house review from Phaladeepika VIII.25-34.
- Added explicit node sign-dispositor and same-sign association evidence without inventing Rahu/Ketu dignity, exaltation/debilitation or node aspects.
- Upgraded Rahu/Ketu Dasha activation: Phaladeepika XX.39 Rahu associated-planet carrier review plus XX.52-53 Kendra/Trikona and benefic-sign connection candidates; opposing carrier directions remain Mixed.
- Promoted `VedicTransitEngine` to v3 / `vedic-transit-analysis-v3` and enabled Rahu Moon-relative directional transit from Phaladeepika XXVI.24; Ketu transit direction remains gated.
- Updated timing layers to accept source-bounded Rahu transit while retaining Ketu/Mixed/Sade-Sati as non-directional; High confidence and high-stakes node conclusions remain disabled.
- Promoted Vedic judgment to `30.0.0` / `kundli-analysis-v30`; calculation remains `vedic-chart-v10`, SQLite remains schema v8, and no database migration is required. GitHub push and APK build remain intentionally deferred.

## 0.56.0+60

- Added `Advanced Yoga & Dosha Engine v1` as a separate maintainable rule module instead of further enlarging the legacy Lagna judgment file.
- Added source-bounded Raja-Yoga conjunction subsets for ninth/tenth and selected Kendra/Kona lords; out-of-profile ninth/tenth conjunctions are retained only as candidates.
- Added exact enabled BPHS Chapter 41 verses 2-8 Dhana formations with participant weakening review and no guaranteed wealth/status outcome.
- Added Phaladeepika VI.57 Harsha/Sarala/Vimala dusthana-lord structural profiles and Phaladeepika VII.27-29 Neecha-bhanga review conditions; natal debilitation is never erased or automatically converted to benefic strength.
- Added multi-reference Kuja review from Lagna, Moon and Venus with separate second-house extension, explicit D1/D9/Jupiter mitigation evidence and a prohibition on standalone marriage-harm predictions.
- Added contradiction-preserving multi-Yoga/Dosha synthesis capped at Medium confidence; no majority vote or High confidence is enabled.
- Promoted Vedic judgment to `29.0.0` / `kundli-analysis-v29`; calculation remains `vedic-chart-v10`, SQLite remains schema v8, and no database migration is required. GitHub push and APK build remain intentionally deferred.

## 0.55.0+59

- Added Build Readiness & Maintainability Audit v1 without changing any astrology calculation or judgment schema.
- Added `tool/static_build_readiness_audit.py` and machine-readable `BUILD_READINESS_AUDIT.json` coverage for version alignment, local imports, required build files, CI gates, generated-runner policy, font-binary exclusion, unresolved markers, dashboard placeholder governance and large-file/reproducibility warnings.
- Added governed Windows runner generation (`tool/bootstrap_windows_runner.dart`) and a Windows GitHub Actions release-build gate that packages and verifies `astro_logic_astronomy.dll`; Android bootstrap was made idempotent for its reviewed native Gradle/CMake injection.
- Pinned Android and Windows CI to Flutter 3.44.9 instead of floating `stable`, while retaining the stable channel and the existing Dart/package constraints. Both workflows capture the resolved `pubspec.lock` and dependency graph as build artifacts.
- Fixed product-surface readiness gaps: the dashboard New Consultation control now enters the client workflow; Vedic, Reports and Gemstone/Remedy tiles route into the implemented consultation workflow; KP, Western, Vastu, Palmistry and Practice are explicitly governed as Coming Soon.
- Added dashboard module-availability regression coverage and documented maintainability hotspots. No SQLite migration, Vedic schema, Numerology schema or professional-report schema change is required. GitHub push and APK build remain intentionally deferred.

## 0.54.0+58

- Added Professional Report Export Engine v1 with offline PDF and DOCX generation from immutable `professional-consultation-report-v1` snapshots.
- Export re-verifies the persisted professional-report SHA-256 before any file is generated; tampered/mismatched snapshots are rejected.
- Added deterministic source-bound filenames, per-export SHA-256, source report hash metadata, A4 multi-page PDF rendering, minimal OOXML DOCX generation and report-preview export/share actions.
- Bengali PDF export resolves a compatible system font at runtime (Android Noto / Windows Nirmala UI / common Linux/macOS candidates) and refuses to emit broken glyphs if no compatible font is available; no font binary is bundled. DOCX stores Unicode text without embedded fonts.
- Added `pdf`, `archive`, `share_plus` and `cross_file` dependencies using current compatible package lines; exports are saved under the app documents `ASTRO_LOGIC/exports` directory and can be shared through the platform share sheet.
- Added export regression fixtures for DOCX package structure/Unicode/no-font-embedding, English PDF signature, deterministic filename/content hash and source-hash tamper rejection. No SQLite migration is required. GitHub push and APK build remain intentionally deferred.

## 0.53.0+57

- Added Professional Consultation Report Engine v1 with a governed 13-section bilingual structured report derived only from persisted consultation evidence.
- Added curated Executive Summary plus D1, D9, D10, Yoga/Dosha, Shadbala, Ashtakavarga, Dasha/Pratyantardasha, Numerology, practitioner-entered Remedy/Gemstone and professional-warning sections. Missing selected-date Transit/Question Timing persistence is surfaced as Unavailable rather than fabricated.
- Added `professional-consultation-report-v1` source manifest binding immutable Kundli/Numerology snapshot ids, schema versions and SHA-256 hashes.
- Added SQLite schema v8 `professional_report_snapshots` with immutable UPDATE/DELETE triggers, report SHA-256, idempotent `(consultation_id, report_hash)` uniqueness and transactional audit event.
- Added bilingual report generation/history/preview UI. PDF/DOCX export is intentionally deferred to a separate task.
- Added Professional Report policy validation and regression coverage for the exact 13-section contract, source requirement, UTC as-of handling and no-fabrication selected-date timing behavior.
- Vedic calculation remains `vedic-chart-v10`; Vedic judgment remains `28.0.0` / `kundli-analysis-v28`. GitHub push and APK build remain intentionally deferred.

## 0.52.0+56

- Added `D10 Career Chart & Interpretation Engine v1` and promoted calculation output to `vedic-chart-v10`.
- Implements the BPHS Dashamsa mapping: ten 3-degree divisions per sign; odd signs count from themselves and even signs from the ninth sign. Explicit D10 ascendant and all nine displayed planetary D10 signs are persisted under profile `bphs-dashamsa-odd-self-even-ninth-v1`.
- Added `dashamsa-career-interpretation-v1`: twelve D10 house/lord/full-sign-aspect structural records with bilingual narratives, transparent scores, contradiction preservation and node-neutral occupancy.
- Added a conservative D1 tenth-lord × D10 tenth-house career synthesis. Both structural families must be directional and agree for a Medium Supportive/Challenging result; conflict or missing direction remains Mixed/Low. D10 does not guarantee profession, promotion, income or timing.
- Added a dedicated D10 career UI group, immutable analysis persistence and policy validation; promoted Vedic judgment to `28.0.0` / `kundli-analysis-v28`. No SQLite migration is required.
- Added derivation and D10 regression fixtures, including explicit-chart consistency, node-neutral review and D1×D10 conflict preservation. GitHub push and APK build remain deferred.

## 0.51.0+55

- Added `Ashtakavarga Kaksha & Transit Micro-Zone Engine v1` and promoted Question-specific Timing to `3.0.0` / `vedic-question-timing-v3`.
- Divides every sign into eight half-open 3°45′ Kaksha zones in the fixed Saturn, Jupiter, Mars, Sun, Venus, Mercury, Moon, Lagna order and records the active zone from the transiting planet's exact sidereal degree-in-sign.
- Reads the active Kaksha lord directly against that transiting planet's unreduced BAV contributor list for the transit sign. A contributor mark is supportive; absence is challenging.
- The whole-sign BAV+SAV direction must agree with the Kaksha micro-zone before the Ashtakavarga timing family becomes directional. Kaksha disagreement downgrades the family to Mixed rather than overriding the whole-sign evidence.
- Added Kaksha number/lord/start/end/degree/positive-mark/polarity audit metadata to each Ashtakavarga transit check. Pinda and reduced BAV values remain separate and are not silently used for timing.
- `VedicConflictConfidenceEngine` is now 2.1.0 with unchanged `vedic-conflict-confidence-v2` output and accepts timing-v3 while validating Kaksha geometry and final-polarity consistency. High confidence remains disabled.
- Added dedicated Kaksha boundary/order/support tests and Question Timing regressions for Kaksha agreement/disagreement. Calculation schema remains `vedic-chart-v9`, Kundli analysis remains `kundli-analysis-v27`, and no SQLite migration is required. GitHub push and APK build remain deferred.

## 0.50.0+54

- Added `Ashtakavarga Pinda Calculation Engine v1` and promoted the immutable Ashtakavarga contract to `ashtakavarga-foundation-v3`.
- Computes Rashi Pinda from each planet's Ekadhipatya-reduced BAV using fixed Aries-to-Pisces multipliers 7/10/8/4/10/5/7/8/9/5/11/12.
- Computes Graha Pinda from the same reduced BAV at the D1 signs occupied by Sun through Saturn using fixed factors Sun 5, Moon 5, Mars 8, Mercury 5, Jupiter 10, Venus 7 and Saturn 5; Rashi + Graha is stored as Shodhya/Yoga Pinda.
- Persists per-sign and per-reference-planet product audits for all seven BAVs and validates multiplier, reduced-mark source, product and total identities in `KundliJudgmentPolicy`.
- Ashtakavarga UI now shows the seven Rashi/Graha/Shodhya totals. Question Timing v2 remains intentionally governed by unreduced BAV+raw SAV only; Pinda timing is not silently enabled.
- Promoted Vedic judgment to `27.0.0` and immutable analysis schema to `kundli-analysis-v27`; calculation schema remains `vedic-chart-v9` and no SQLite migration is required.
- Added Pinda regression/golden assertions using the existing B.V. Raman fixture. GitHub push and APK build remain intentionally deferred.

## 0.49.0+53

- Added `Ashtakavarga Trikona & Ekadhipatya Reduction Engine v1` and promoted the immutable Ashtakavarga contract to `ashtakavarga-foundation-v2`.
- Trikona Shodhana is applied independently to every planetary BAV using the four Rashi trines. The implementation preserves BPHS Chapter 67 edge cases: any zero in a trine means no reduction, all-equal nonzero values reduce to zero, otherwise the trine minimum is subtracted from all three.
- Ekadhipatya Shodhana runs only after Trikona and applies the BPHS Chapter 68 occupancy-sensitive cases to the Mars, Mercury, Jupiter, Venus and Saturn dual-sign pairs. Sun/Moon are unchanged; v1 occupancy uses D1 Sun-through-Saturn only, with Rahu/Ketu excluded as an explicit versioned convention.
- Persisted a full audit trail for raw, Trikona-reduced and Ekadhipatya-reduced values, per-trine actions, per-dual-lord occupancy/actions and a separately labelled reduced aggregate. Raw 337-point SAV and its BPHS-72 bands remain unchanged and are never applied to the reduced aggregate.
- Mobile/desktop Ashtakavarga UI now shows `Raw→Trikona→Ekadhipatya` values per BAV sign and the reduced aggregate separately. Question Timing v2 continues to use the existing governed unreduced BAV+SAV transit profile; reduced-value timing remains separate work.
- Promoted Vedic judgment to `26.0.0` and immutable analysis schema to `kundli-analysis-v26`; calculation schema remains `vedic-chart-v9` and no SQLite migration is required.
- Added regression coverage for Trikona common/zero/equal cases, all major Ekadhipatya occupancy branches, B.V. Raman raw-golden preservation and reduced-aggregate separation. GitHub push and APK build remain intentionally deferred.

## 0.48.0+52

- Promoted `VedicConflictConfidenceEngine` to v2 with output contract `vedic-conflict-confidence-v2` and added Ashtakavarga as a governed conflict/confidence evidence group on top of Structure, Dasha and Moon-gochara transit.
- The resolver now exposes five visible layers: D1, D1-D9, Dasha, Moon-gochara transit and Ashtakavarga transit. D1/D1-D9 still collapse to one structural group, while all Ashtakavarga planet checks collapse to one Ashtakavarga group so repeated planets cannot inflate confidence.
- Directional disagreement between Moon-gochara and Ashtakavarga, or between Ashtakavarga and any other governed group, remains Mixed/Low. Internal opposing Ashtakavarga checks also produce an explicit `ashtakavarga_internal_directional_conflict` result instead of being majority-voted away.
- Four agreeing governed groups produce Medium confidence only. High remains disabled because Moon-gochara and Ashtakavarga share selected-date transit-position evidence and are not statistically independent timing observations. Three-group convergence remains Medium; two-group convergence remains Low.
- Added strict timing-v2 metadata validation for Ashtakavarga directional flag, directional planet list and aggregate polarity, plus four new conflict-confidence regression scenarios covering four-group convergence, cross-family conflict, internal Ashtakavarga conflict and inconsistent metadata rejection.
- Calculation schema remains `vedic-chart-v9`, Kundli judgment remains `25.0.0` / `kundli-analysis-v25`, and Question Timing remains `vedic-question-timing-v2`; no SQLite migration is required. GitHub push and APK build remain intentionally deferred.

## 0.47.0+51

- Promoted `VedicQuestionTimingEngine` to v2 with the immutable `vedic-question-timing-v2` output contract and added governed Ashtakavarga transit/timing confirmation on top of the existing topic-house, MD/AD/PD and Moon-gochara layers.
- For each classical planet transiting a versioned target house, v2 reads that planet's unreduced BAV positive marks in the transit sign and the same sign's SAV context. The versioned BAV transit profile treats 5-8 positive marks as supportive, 4 as Mixed and 0-3 as challenging; a directional Ashtakavarga signal is emitted only when BAV and SAV agree.
- Added auditable per-transit Ashtakavarga records containing planet, sign, target house, BAV/SAV scores, individual polarities, combined polarity and evidence. Rahu/Ketu remain excluded because the v1 BAV foundation has no node tables.
- Ashtakavarga can now confirm an active topic Dasha when Moon-gochara is non-directional, but it cannot open a directional timing window without Dasha topic activation. Moon-gochara versus Ashtakavarga disagreement, BAV/SAV disagreement and opposing multiple Ashtakavarga checks remain Mixed/Low rather than being majority-voted away.
- High confidence remains disabled. Conflict-confidence v1 accepts question-timing v2 but does not yet count Ashtakavarga as a separate independence group. Trikona/Ekadhipatya reductions, exact-degree triggers and D10/divisional timing remain separate work.
- Added four Ashtakavarga timing regression scenarios for Ashtakavarga-only confirmation, Moon-gochara conflict, neutral BAV=4 handling and BAV/SAV contradiction preservation.
- Calculation schema remains `vedic-chart-v9`, Kundli analysis remains `kundli-analysis-v25`, and no SQLite migration is required. GitHub push and APK build remain intentionally deferred.

## 0.46.0+50

- Added `ashtakavarga-foundation-v1`: seven unreduced Bhinnashtakavarga tables for Sun through Saturn using eight references (Sun through Saturn plus Lagna), with contributor-level positive-mark audit.
- Added fixed BAV integrity checks Sun=48, Moon=49, Mars=39, Mercury=54, Jupiter=56, Venus=52, Saturn=39 and unreduced Sarvashtakavarga grand-total check 337.
- Added twelve SAV sign/whole-sign-house records with the selected BPHS-72 comparative bands (>30 favourable, 25-30 medium, <25 adverse), capped at Medium confidence and explicitly non-deterministic.
- Added immutable Ashtakavarga JSON persistence, 12 bilingual house findings, mobile/desktop score matrix UI, policy validation and a B.V. Raman standard-horoscope golden distribution fixture.
- Promoted Vedic judgment to `25.0.0` and immutable analysis schema to `kundli-analysis-v25`. Calculation schema remains `vedic-chart-v9`; no SQLite schema migration is required.
- Fixed a latent duplicate `_houseLifeAreas` constant name in the judgment engine by separating the Dasha multi-area map from the primary house-area list.
- Did not add Trikona/Ekadhipatya reductions, Ashtakavarga-based transit/timing confirmation, D10, new yoga/cancellation families or guaranteed event prediction.

## 0.45.0+49

- Added `Full Shadbala Aggregate & Required Strength Threshold Engine v1`; governed strength contract is now `shadbala-foundation-v10`.
- When Sthana, Dig, complete Kala, Cheshta, Naisargika and Drik are all available, the engine now publishes `totalShadbalaVirupas`, `totalShadbalaRupas`, the BPHS 27.32-33 required total, required-strength ratio, surplus/deficit and an auditable `meetsRequired` / `belowRequired` status.
- BPHS total requirements are versioned as Sun 390, Moon 360, Mars 300, Mercury 420, Jupiter 390, Venus 330 and Saturn 300 virupas. These thresholds are treated strictly as quantitative strength sufficiency and never as automatic beneficence, event success or remedy approval.
- Incomplete legacy/current evidence still leaves the aggregate and threshold status unavailable; no missing component is silently zero-filled.
- Promoted Vedic judgment to `24.0.0` and immutable analysis schema to `kundli-analysis-v24`; aggregate/threshold fields are persisted and policy-validated.
- Added regression coverage for sixfold identity, Rupa conversion, all seven required totals, ratio/delta/status identity and legacy aggregate gating.
- GitHub push and APK build remain intentionally deferred until the complete application is ready.

## 0.44.0+48

- Added `Yuddha Bala Engine v1`; governed strength contract is now `shadbala-foundation-v9`.
- Promoted the native Astronomy Engine wrapper to ABI v6 and calculation output to `vedic-chart-v9`; current physical-planet payloads persist exact geocentric ecliptic latitude in addition to longitude and daily speed.
- Yuddha eligibility is limited to Mars, Mercury, Jupiter, Venus and Saturn. The versioned operational profile detects isolated same-sign pairs within 1 degree, uses northern geocentric ecliptic latitude as the computational victor criterion, and applies the BPHS 27.20 pre-war-strength difference symmetrically: add to winner, deduct from loser.
- No-war cases are computed as 0 virupas. Latitude ties, multi-war clusters, missing latitude and incomplete pre-war sixfold strength remain unavailable instead of fabricating a victor or correction.
- Current v9 charts can now publish complete Kala Bala as Nathonnata + Paksha + Tribhaga + Varsha + Masa + Dina + Hora + Ayana + Yuddha when all required evidence exists.
- Promoted Vedic judgment to `23.0.0` and immutable analysis schema to `kundli-analysis-v23`; Yuddha role, partner, separation, latitudes, pre-war difference and resulting Kala total are persisted and policy-validated.
- Full six-component Shadbala aggregate/minimum-threshold interpretation remains intentionally disabled as the next separate governed task.
- GitHub push and APK build remain intentionally deferred until the complete application is ready.

## 0.43.0+47

- Added `Varsha–Masa–Dina–Hora Bala Engine v1` inside `VedicShadbalaEngine`; governed strength contract is now `shadbala-foundation-v8`.
- Promoted native Astronomy Engine wrapper to ABI v5. The frame supplement now also returns the prior observer sunrise, prior sidereal Aries ingress, prior current-sidereal-sign ingress, and the sunrise that starts each ingress's astrological weekday when those solar events are available.
- Promoted calculation output to `vedic-chart-v8`. Current metadata stores the versioned `siderealSolarIngressAstrologicalDayV1` profile, Varsha/Masa/Dina/Hora lords, Hora number/period, relevant UTC audit instants, and the recorded birth UTC offset used for weekday conversion.
- Applied BPHS 27.13 allocations without redistribution: Varsha lord 15, Masa lord 30, Dina lord 45 and Hora lord 60 virupas. One planet may receive multiple allocations when it rules multiple periods.
- Hora uses the actual sunrise-to-sunset or sunset-to-next-sunrise interval split into twelve seasonal horas, with the Chaldean Saturn-Jupiter-Mars-Sun-Venus-Mercury-Moon sequence starting from the Dina lord; it does not use fixed 60-minute civil hours.
- Current Kala partial subtotal now includes Nathonnata + Paksha + Tribhaga + Varsha + Masa + Dina + Hora + Ayana wherever their required solar-event context is available. Only Yuddha Bala remains gated before full Kala/full Shadbala aggregation.
- Promoted Vedic judgment to `22.0.0` and immutable analysis schema to `kundli-analysis-v22`; policy validation locks temporal-lord identity, 15/30/45/60 allocation, Hora range and cross-planet context consistency.
- Added regression coverage for allocation, cumulative multi-lord strength, legacy-v7 gating, derivation lord/Hora metadata, native ingress/rise-set golden values and polar unavailability.
- Weekday conversion intentionally uses the birth record's stored UTC offset because the current input contract does not persist an IANA time-zone identifier; DST-sensitive historical records therefore retain an explicit audit limitation instead of silently inferring a zone rule.
- GitHub push and APK build remain intentionally deferred until the complete application is ready.

## 0.42.0+46

- Added `Tribhaga Bala Engine v1` inside `VedicShadbalaEngine`; governed strength contract is now `shadbala-foundation-v7`.
- Promoted the native Astronomy Engine wrapper to ABI v4. It now uses `Astronomy_SearchRiseSet` to find the solar rise/set interval bracketing the birth instant and identifies the exact one-based third of that daylight/night interval.
- Promoted calculation output to `vedic-chart-v7`; metadata persists `tribhagaIsDay`, `tribhagaThird`, `tribhagaPeriodStartUtc` and `tribhagaPeriodEndUtc` when rise/set search is available. Polar/no-rise-set cases leave Tribhaga unavailable instead of approximating it.
- Implemented BPHS 27.12 Tribhaga ordering: day thirds Mercury/Sun/Saturn; night thirds Moon/Venus/Mars; Jupiter always receives 60 virupas. Other planets receive 0 outside their assigned third.
- Current Kala partial subtotal is now Nathonnata + Paksha + Tribhaga + Ayana where Tribhaga is available. Varsha-Masa-Dina-Hora and Yuddha remain gated, so full Shadbala total/minimum ratio remains disabled.
- Promoted Vedic judgment to `21.0.0` and immutable analysis schema to `kundli-analysis-v21`.
- Added day/night-third, Jupiter-always-full, legacy-v6 gating, polar-unavailable, derivation metadata and native rise/set golden regressions.

## 0.41.0+45

- Added `Nathonnata Bala Engine v1` inside `VedicShadbalaEngine`; the governed strength contract is now `shadbala-foundation-v6`.
- Promoted the native Astronomy Engine wrapper to ABI v3 and persisted observer-specific Sun apparent hour angle, calculated by the bundled `Astronomy_HourAngle` API, in current `vedic-chart-v6` output metadata.
- Applied BPHS 27.9 without civil-time approximation: apparent midnight (Sun HA 12h) gives Moon/Mars/Saturn maximum 60 virupas and Sun/Jupiter/Venus zero; apparent noon (Sun HA 0h) reverses those values; Mercury remains 60 throughout.
- Added nullable `nathonnataBalaVirupas` and `sunHourAngleHours` to immutable Shadbala records. Legacy v1-v5 outputs leave Nathonnata unavailable rather than guessing apparent solar time.
- Kala partial subtotal for current v6 output is now Nathonnata + Paksha + Ayana. Tribhaga, Varsha-Masa-Dina-Hora and Yuddha remain gated, so the full six-component Shadbala total remains disabled.
- Promoted Vedic judgment to `20.0.0` and immutable analysis schema to `kundli-analysis-v20`.
- Extended native golden validation with Sun apparent hour angle `12.430224160748h` for the committed 1984-03-12 Kalna-area reference fixture; prior JPL/ayanamsha/ascendant/node regressions remain unchanged.
- GitHub push and APK build remain intentionally deferred until the complete application is ready.

## 0.40.0+44

- Added `Drik Bala Engine v1` inside `VedicShadbalaEngine`; the governed strength contract is now `shadbala-foundation-v5`.
- Added exact-longitude Sphuta-Drishti calculation for the seven classical planets with the common Chapter-26 piecewise curve and versioned Mars/Jupiter/Saturn special-aspect curves; Rahu/Ketu remain excluded from Shadbala.
- Added `DrikBalaContribution` audit records containing aspector, exact forward angle, raw aspect virupas, benefic/malefic nature, BPHS-27.19 quarter contribution, Mercury/Jupiter full super-addition and net contribution.
- Added waxing/waning Moon nature and a governed same-sign classical-malefic association rule for Mercury's Drik quarter term.
- Explicitly versioned the disputed Jupiter 240°–270° Sphuta-Drishti branch as a continuity-preserving corrected envelope instead of silently mixing translation variants.
- Promoted the Vedic judgment engine to `19.0.0` and immutable analysis contract to `kundli-analysis-v19`; Shadbala snapshots now retain signed Drik Bala and its complete contribution trail.
- Updated policy validation so Drik Bala may be negative while every raw aspect remains finite and within 0..60 virupas, contribution weights reconcile exactly, and no aspector is duplicated.
- Full six-component Shadbala total remains disabled only because Kala Bala is still partial: Nathonnata, Tribhaga, Varsha-Masa-Dina-Hora and Yuddha Bala remain gated.
- GitHub push and APK build remain intentionally deferred until the complete application is ready.

# Changelog

## 0.39.0+43

- Added `Cheshta Bala Engine v1` inside `VedicShadbalaEngine`; the governed strength contract is now `shadbala-foundation-v4`.
- Promoted Vedic calculation output to `vedic-chart-v5` and now persist exact daily longitudinal speed for every calculated body instead of reducing motional evidence to a retrograde flag.
- Applied BPHS 27.18 directly: Sun Cheshta equals computed Ayana Bala and Moon Cheshta equals computed Paksha Bala.
- Added the explicit `bphsMotionStateSpeedProfileV1` operational profile for Mars through Saturn, preserving the BPHS eight motion-state virupa values while using versioned speed bands, governed mean daily motions and one-day sign-entry projection.
- Kept the separate BPHS 27.24-25 mean/true-longitude Cheshta-kendra algorithm gated because its required audited inputs are not yet in the calculation contract; legacy v1-v4 snapshots do not guess Mars-Saturn Cheshta.
- Promoted the Vedic judgment engine to `18.0.0` and immutable analysis contract to `kundli-analysis-v18`; Shadbala snapshots now retain Cheshta virupas, method/state and speed evidence.
- Added direct Sun/Moon equivalence, Vakra/Anuvakra/Vikala/Mandatara/Manda/Sama/Chara/Atichara boundary and legacy-speed regression coverage.
- Full six-component Shadbala total remains disabled until the remaining Kala subcomponents and Drik Bala are governed.

## 0.38.0+42

- Added `Kala Bala Engine v1` as a governed **partial** temporal-strength layer inside `VedicShadbalaEngine`; the rule contract is now `shadbala-foundation-v3`.
- Promoted the Vedic judgment engine to `17.0.0` and immutable analysis contract to `kundli-analysis-v17`.
- Added BPHS 27.10-11 `Paksha Bala` for all seven classical planets from the folded Sun-Moon separation: Moon/Mercury/Jupiter/Venus receive the benefic value and Sun/Mars/Saturn its 60-virupa complement.
- Added BPHS 27.15-17 `Ayana Bala` from each planet's exact tropical longitude using the 45/33/12 khanda interpolation and the classical planet-group north/south adjustment; regression coverage includes the published Taurus example and Cancer/Capricorn extrema.
- Persisted `pakshaBalaVirupas`, `ayanaBalaVirupas`, `kalaBalaPartialVirupas`, computed/missing Kala subcomponent lists and an explicit `kalaBalaComplete=false` gate in every seven-planet Shadbala profile.
- Kept Nathonnata, Tribhaga, Varsha-Masa-Dina-Hora and Yuddha Bala disabled until their apparent-time/sunrise, calendrical/hora and planetary-war contracts are audited.
- Kept the six-component Shadbala total and minimum-strength ratio disabled; Cheshta and Drik Bala also remain pending.
- Added regression and policy checks for 0..60 Paksha/Ayana bounds, exact partial-Kala identity, incomplete-Kala governance and unchanged seven-planet-only coverage.
- GitHub push and APK build remain intentionally deferred until the complete application is ready.

## 0.37.0+41

- Added exact `Dig Bala` to `VedicShadbalaEngine` and promoted the rule contract to `shadbala-foundation-v2`; Rahu/Ketu remain excluded.
- Promoted the Vedic judgment engine to `16.0.0` and immutable analysis contract to `kundli-analysis-v16`.
- Implemented BPHS 27.7 directional strength from exact sidereal planet and Ascendant longitudes: Sun/Mars zero at the 4th direction, Jupiter/Mercury zero at the 7th, Moon/Venus zero at the 10th, Saturn zero at Lagna; angular distance is folded to <=180 degrees and divided by 3, producing 0..60 virupas.
- Persisted `digBalaVirupas` beside Sthana and Naisargika Bala for all seven classical planets, with bilingual evidence and source-versioned narrative.
- Added policy validation for finite 0..60 Dig Bala, exact computed-component contract `sthana,dig,naisargika`, and the remaining `kala,cheshta,drik` aggregate gate.
- Added regression coverage for all seven planets at exact maximum and zero Dig-Bala directions plus a non-zero Ascendant degree test proving exact-longitude use rather than whole-sign approximation.
- Kept the full six-component Shadbala total, minimum-strength ratio and automatic favourable/adverse strength conclusion disabled until Kala, Cheshta and Drik Bala are audited and implemented.
- GitHub push and APK build remain intentionally deferred until the complete application is ready.

## 0.36.0+40

- Added `VedicShadbalaEngine` foundation v1 with the `shadbala-foundation-v1` contract for the seven classical planets; Rahu/Ketu are explicitly excluded from Shadbala.
- Promoted the Vedic judgment engine to `15.0.0` and the immutable analysis contract to `kundli-analysis-v15`.
- Added governed Sthana Bala from Uccha, Saptavargaja, Ojhayugma, Kendradi and BPHS-27.6 Drekkana components with transparent virupa values and bilingual evidence.
- Added seven-varga Saptavargaja derivation for D1/D2/D3/D7/D9/D12/D30 and a versioned Rasi-position-based Tatkalika Maitri choice for compound friendship because traditions differ on recalculating temporary friendship inside derived vargas.
- Added fixed Naisargika Bala for Sun, Moon, Mars, Mercury, Jupiter, Venus and Saturn.
- Persisted seven Shadbala foundation profiles in the immutable Kundli snapshot and rendered them as a separate bilingual consultation finding group.
- Added policy validation for seven-planet coverage, five-component Sthana identity, complete seven-varga coverage, allowed contribution values, bilingual evidence and the incomplete-aggregate gate.
- Added eight dedicated Shadbala regression scenarios and v4 Kundli integration assertions.
- Kept Dig, Kala, Cheshta and Drik Bala disabled; therefore full six-component Shadbala total, minimum-strength ratio and Shadbala-derived outcome polarity remain unavailable rather than being approximated.
- Did not add D10, Ashtakavarga, node Shadbala, exact war-victor calculation or guaranteed event prediction.

## 0.35.0+39

- Added `VedicNavamsaInterpretationEngine` v1 with the `navamsa-house-interpretation-v1` record contract.
- Promoted the Vedic judgment engine to `14.0.0` and the immutable analysis contract to `kundli-analysis-v14`.
- Added 12 structured D9 house records using the explicit Navamsha ascendant, house sign/lord, lord D9 placement and broad D9 dignity.
- Added visible D9 occupants and enabled Parashari full-sign aspects; Rahu/Ketu occupancy remains review-only and node aspects/dignity are not invented.
- Added transparent component scores for lord placement, lord dignity, other classical occupants and classical aspectors, while preventing house-lord occupancy double counting.
- Preserved opposing D9 components as Mixed regardless of arithmetic and capped directional D9 v1 results at Medium confidence.
- Persisted the 12 D9 records in the immutable Kundli snapshot and mirrored them into the existing divisional-review UI through evidence-backed findings.
- Added policy validation for complete 1–12 house coverage, version, structural fields, component-score consistency, bilingual evidence and the High-confidence prohibition.
- Added seven dedicated D9 regression scenarios plus v4 Kundli integration assertions.
- Updated conflict-engine warnings to reflect that the new D9 house family exists but is not yet counted by conflict-confidence v1.
- Did not add D10, Shadbala, Ashtakavarga, partial aspect strength, node aspects or guaranteed event prediction.

## 0.34.0+38

- Added `VedicConflictConfidenceEngine` v1 with the `vedic-conflict-confidence-v1` output contract.
- Added topic-specific four-layer conflict review across D1 target-house structure, D1-D9 dignity agreement of unique target-house lords, active topic-weighted MD/AD/PD and enabled topical transit.
- Grouped D1 and D1-D9 under one structural independence group so correlated chart evidence cannot inflate confidence.
- Added deterministic target-house-lord derivation from the sidereal Ascendant and required D9-capable `vedic-chart-v2` or later calculation output.
- Added structural-conflict preservation: opposite D1 and D1-D9 directions force Mixed/Low and cannot be overridden by Dasha/transit agreement.
- Added independent-group conflict preservation with majority voting disabled; opposite Structure/Dasha/Transit directions remain Mixed/Low.
- Added confidence governance: three-group convergence is capped at Medium, two-group convergence remains Low, and one/zero directional groups do not publish a combined direction.
- Added consistency validation that question-timing natal polarity matches the immutable target-house Kundli findings.
- Added nine regression scenarios covering three-group convergence, structural conflict, Dasha/transit conflict, missing transit, Mixed divisional confirmation, immutable-polarity mismatch, D9-capable input gating, versioned topic-house validation and the v1 High-confidence prohibition.
- Did not add new event-prediction rules, D9 house/lord/aspect interpretation, Shadbala, Ashtakavarga, exact-degree triggers or High confidence.

## 0.33.0+37

- Added `VedicQuestionTimingEngine` v1 with the immutable `vedic-question-timing-v1` output contract.
- Added governed selected-date timing profiles for Career/Employment, Business/Partnership, Marriage, Finance, Education, Property, Children and Travel/Relocation.
- Added versioned topic-house profiles and required the detailed natal house-synthesis findings for every target house instead of using a one-house shortcut.
- Added topic-weighted active Mahadasha/Antardasha/Pratyantardasha scoring that only counts a Dasha lord when its governed activation areas overlap the selected consultation topic.
- Added topical transit gating: an enabled directional Moon-gochara finding contributes only when that same transiting planet occupies a versioned target house from Lagna. Mixed transits and Rahu/Ketu remain non-directional.
- Added convergence states for supportive/challenging agreement, natal conflict, Dasha/transit conflict, Dasha-only review and insufficient Dasha topic activation; High confidence remains disabled in v1.
- Added Business and Travel/Relocation consultation categories with Bengali/English labels and deterministic category-to-topic routing; General and Health are intentionally not auto-routed.
- Added eight regression scenarios covering category routing, supportive convergence, natal conflict, missing Dasha activation, missing topical transit, Dasha/transit conflict, Mixed-transit exclusion and UTC mismatch rejection.
- Did not add exact-event guarantees, medical timing, Ashtakavarga, divisional timing, exact-degree triggers or Rahu/Ketu transit polarity.

## 0.32.0+36

- Promoted `VedicTransitEngine` to `2.0.0` and `vedic-transit-analysis-v2`.
- Added a source-bounded Brihat Samhita Chapter 104 Moon-gochara direction matrix for Sun, Moon, Mars, Mercury, Jupiter, Venus and Saturn.
- Added explicit Supportive, Challenging and Mixed review directions with medium confidence only for source-governed directional houses.
- Preserved intentionally ambiguous houses as Mixed instead of forcing a binary result.
- Preserved Saturn 12th/1st/2nd Sade Sati phase detection as Mixed rather than automatically adverse.
- Kept Rahu/Ketu sidereal positions and Moon/Lagna house distances while leaving node transit-result polarity disabled pending a separately governed source profile.
- Updated Dasha × transit synthesis wording for the expanded seven-planet directional input and kept Mixed/node/Sade-Sati signals non-directional.
- Added regression coverage for all seven classical findings, universal 11th-house support, ambiguous-house preservation, challenging signals, Sade Sati governance and node exclusion.
- Did not add Ashtakavarga, exact-degree transit triggers, question-specific event timing or high-stakes event claims.

## 0.31.0+35

- Added `PratyantardashaInterpretationEngine` v1 and persisted 729 chart-specific MD/AD/PD interpretation records in the immutable Kundli analysis snapshot.
- Promoted the Vedic judgment engine to `13.0.0` and the output contract to `kundli-analysis-v13` for the new interpretation collection.
- Kept Mahadasha as the broad activation field, Antardasha as modifier and Pratyantardasha as the immediate activation/trigger layer without hard-coded planet-pair event promises.
- Reused the governed 3:2:1 MD/AD/PD weighting, preserved contradictory non-zero lord signals as Mixed, and classified the PD trigger as reinforcing, counter-trend or neutral relative to the weighted MD/AD direction.
- Prioritized life areas repeated across two or more Dasha levels, with the Pratyantardasha lord's own areas as the no-repeat fallback.
- Added bilingual detailed narratives, evidence paths, low/medium confidence governance, professional-review validation and Dasha-timeline rendering with legacy snapshot fallback.
- Added six dedicated interpretation regression fixtures and extended the Dasha timeline regression to verify detailed interpretation UI.
- Did not add question-specific event promises, broader transit rules, Ashtakavarga, Shadbala or exact-event timing.

## 0.30.0+34

- Added `VedicTimingSynthesisEngine` v1 to compare an explicitly selected date's active Vimshottari Mahadasha/Antardasha/Pratyantardasha chain with the already-enabled transit findings.
- Moved the governed 3:2:1 MD/AD/PD weighting into a reusable timing-confirmation output with the active sub-period boundaries and repeated Dasha life areas.
- Added conservative convergence states: supportive agreement, challenging agreement for future explicitly challenging transit rules, directional conflict, and insufficient directional confirmation.
- Kept Mixed transit signals non-directional and prohibited treating the absence of a supportive transit as an adverse transit.
- Added bilingual narratives, evidence merging, professional-review gating and six regression fixtures including exact half-open period-boundary behavior.
- Updated the Vedic judgment engine patch version to `12.0.1` only to remove the obsolete warning that transit was unavailable; the `kundli-analysis-v12` schema remains unchanged.
- Did not add question-specific event prediction, Ashtakavarga, exact-degree triggers, divisional timing or guaranteed outcomes.

## 0.29.0+33

- Added a deterministic offline Vedic transit-analysis foundation backed by the existing audited ephemeris provider.
- Added all nine sidereal transit positions with retrograde state and whole-sign distance from both natal Lagna and natal Moon.
- Added a conservative Jupiter Moon-gochara v1 review profile for houses 2, 5, 7, 9 and 11.
- Added a Saturn Moon-gochara v1 profile with 3/6/11 support review and explicit 12/1/2 Sade Sati phase detection.
- Kept Sade Sati Mixed rather than automatically adverse and required natal-chart plus Dasha confirmation.
- Added bilingual evidence, cautions, professional-review gating and regression fixtures.
- Did not enable exact-event, medical, legal, financial or mortality predictions from transit alone.

## 0.28.0+32

- Promoted the Vedic judgment engine to `12.0.0` and its immutable output
  contract to `kundli-analysis-v12`.
- Added nine chart-specific Dasha activation profiles with transparent scores,
  bilingual explanations, evidence and activated life areas.
- Derived classical-planet areas from occupied and owned houses; derived
  Rahu/Ketu areas from occupied house plus the sign dispositor's ownership.
- Added each Pratyantardasha lord's own tendency to the lifetime timeline.
- Added a dominance-preserving three-level synthesis: Mahadasha ×3,
  Antardasha ×2 and Pratyantardasha ×1.
- Kept opposite lord signals explicitly Mixed and surfaced life areas repeated
  at two or more Dasha levels.
- Retained the professional-review and transit-confirmation requirement; the
  synthesis does not promise an event or exact outcome.

## 0.27.0+31

- Promoted calculation output to `vedic-chart-v4` and the Vimshottari calendar
  to `vimshottari-calendar-v2`.
- Recursively divided every Antardasha into nine proportional
  Pratyantardashas, producing 729 validated sub-sub-periods.
- Preserved exact parent boundaries by forcing the ninth child to end at the
  immutable Antardasha endpoint.
- Added full Pratyantardasha lord, sequence and boundary validation.
- Added a lazy bilingual Dasha dashboard with Current, Past and Future filters
  and the active Mahadasha/Antardasha/Pratyantardasha chain.
- Linked each Pratyantardasha row to its parent Antardasha tendency without
  claiming separate event certainty.

## 0.26.0+30

- Promoted calculation output to `vedic-chart-v3` with a deterministic
  Vimshottari Mahadasha-Antardasha calendar.
- Derived the starting Mahadasha and its birth balance from the Moon's exact
  sidereal Nakshatra position.
- Added all nine Mahadashas and 81 Antardashas with auditable UTC boundaries,
  using an explicit 365.25636-day sidereal-solar-year policy.
- Added medium-confidence timing tendencies that combine each Dasha lord's
  whole-sign placement, D1/D9 dignity and ascendant-specific functional role.
- Added node-period qualification through Rahu/Ketu placement and the D1/D9
  condition of their sign dispositor.
- Preserved contradictory Mahadasha/Antardasha indications as Mixed and kept
  transit, Pratyantardasha and guaranteed-event claims disabled.
- Added bilingual timing cards, validation of period order/boundaries and
  regression fixtures.

## 0.25.0+29

- Promoted calculation output to `vedic-chart-v2` with an explicit D9 chart
  containing Navamsha ascendant and all planetary signs.
- Preserved judgment compatibility with immutable `vedic-chart-v1` snapshots.
- Validated any supplied Navamsha sign against sidereal longitude and rejected
  inconsistent calculation output.
- Added seven bilingual D1-D9 dignity-agreement findings.
- Added Vargottama detection without treating every same-sign placement as
  automatically favourable.
- Preserved opposing D1/D9 dignity as Mixed with both evidence paths visible.
- Added a dedicated D1-D9 Navamsha review group and regression fixtures.

## 0.24.0+28

- Added a full BPHS-profile Gajakesari formation check rather than treating
  Jupiter-Moon angularity alone as a completed yoga.
- Required Jupiter in a Kendra from Lagna or Moon, enabled Mercury/Venus
  benefic support, and freedom from debilitation, combustion and enemy sign.
- Preserved incomplete angular formations as medium-confidence candidates with
  every failed qualifier visible.
- Added a Raja Yoga v1 formation for conjunction of Lagna and fifth lords in a
  Kendra/Trikona.
- Added a Dhana Yoga v1 formation for fifth and eleventh lords occupying their
  own fifth and eleventh houses.
- Added participant debilitation/combustion review and explicit no-guarantee
  language for office, status and wealth.
- Added Bengali/English evidence and regression fixtures for all three rules.

## 0.23.0+27

- Added versioned Panch Mahapurusha D1 formation detection for Ruchaka, Bhadra,
  Hamsa, Malavya and Shasha yogas.
- Required both Lagna Kendra placement and own/exalted dignity, with separate
  auditable evidence for each condition.
- Added combustion, retrograde, planetary-war-proximity and node-conjunction
  strength-review modifiers without erasing a structurally formed yoga.
- Added a conservative Kuja-dosha Lagna screen: houses 1/4/7/8/12 are the core
  profile and the disputed 2nd-house rule is labelled as an extended variant.
- Recorded own/exalted Mars and enabled Jupiter support as possible mitigation,
  never as automatic cancellation.
- Prohibited divorce, spouse-harm or death predictions from the Kuja screen.
- Added a dedicated bilingual Yoga/Dosha review section and regression fixtures.

## 0.22.0+26

- Added twelve integrated Vedic life-area judgments after Kundli calculation.
- Combined each house sign/lord, lord placement and dignity, functional role,
  occupants and enabled Parashari full-sign aspects into one detailed draft.
- Preserved contradictory supportive and challenging evidence as Mixed instead
  of flattening it into a one-word good/bad result.
- Added a transparent net rule score and conservative confidence assignment.
- Added Bengali/English narratives, rule ids and calculation-output paths for
  every integrated house judgment.
- Added a dedicated detailed-life-area section to the consultation workspace.
- Kept Dasha/transit event dates disabled until verified timing rules exist.

## 0.21.0+25

- Added reproducible GitHub Actions Android APK build and artifact upload.
- Added Termux script for creating a new private GitHub repository and pushing
  the proprietary source in one governed step.
- Added Android Flutter-runner bootstrap that wires the pinned native astronomy
  C target through Gradle/CMake for arm64-v8a, armeabi-v7a and x86_64.
- Switched Android database opening to the mobile sqflite factory while keeping
  the FFI database factory for Windows and host-side tests.
- Added APK SHA-256 artifact and Bengali Termux/GitHub build instructions.
- Documented that this is a test-signed foundation APK, not a commercially
  signed production release.

## 0.20.0+24

- Recovered the previously truncated ClientStore tail from the verified v018 archive.
- Added non-destructive database migration from schema v6 to v7.
- Added dedicated immutable `numerology_snapshots` with UPDATE/DELETE triggers.
- Bound input, calculation, analysis and both engine/schema identities by SHA-256.
- Added idempotent snapshot creation and transactional client audit history.
- Added consultation client-name and locked birth-date prefill.
- Added governed Save action and saved-version/hash summary in consultation UI.
- Counted Numerology snapshots for review/finalization, never for gemstone approval.

## 0.19.0+23

- Replaced the Numerology dashboard placeholder with a working workspace.
- Added exact Latin-name validation without silent transliteration.
- Added controlled birth-date picker and Personal Year selector.
- Added responsive number-summary cards for Android and Windows widths.
- Added expandable calculation formulas and stable rule ids.
- Added bilingual strength/challenge, Personal Year, remedy and warning views.
- Added UI regression fixtures for inputs and Bengali-name rejection.
- Kept the v1 preview in memory pending immutable consultation persistence.

## 0.18.0+22

- Added versioned `numerology-analysis-v1` interpretation output.
- Added bilingual strengths and review tendencies for 1–9, 11, 22 and 33.
- Added Driver, Life Path, Pythagorean Expression and Chaldean Name findings.
- Added evidence-backed dual-system comparison without false conflict claims.
- Added a January–December Personal Year planning window.
- Added one number-specific, low-risk behavioural remedy review candidate.
- Prohibited automatic spelling changes and Numerology-only gemstones by policy.
- Added scientific-status, no-guarantee and professional-review safeguards.

## 0.17.0+21

- Added deterministic offline `numerology-profile-v1` calculation core.
- Added Driver/Birth, Life Path and target Personal Year calculations.
- Preserved Pythagorean master numbers 11, 22 and 33 in versioned profiles.
- Added audited Pythagorean Expression, Soul Urge and Personality calculations.
- Added Chaldean compound and reduced name numbers with the standard 1–8 table.
- Required explicit Latin spelling and rejected silent Bengali transliteration.
- Added per-letter values, formulas, rule ids and professional-review metadata.
- Added bilingual-product documentation and regression fixtures.

## 0.16.0+20

- Added temporary friendship from relative 2/3/4/10/11/12 sign positions.
- Added five-fold compound relationships with two independent evidence records.
- Kept own-sign placements separate from temporary/compound classification.
- Added pairwise 1° planetary-war proximity review for five classical planets.
- Excluded Sun, Moon and lunar nodes from the planetary-war profile.
- Refused to declare a victor without verified latitude/declination evidence.
- Added bilingual UI sections, rule documentation and regression fixtures.

## 0.15.0+19

- Added permanent natural friendship toward each occupied sign's dispositor.
- Kept temporary and compound friendship explicitly out of scope.
- Added degree-specific, half-open Moolatrikona range findings for seven planets.
- Added same-sign conjunction records with circular angular separation.
- Added target-house synthesis for two or more unique full-sign aspectors.
- Added bilingual review sections, evidence paths, fixtures and rule sources.
- Kept partial aspect strength, planetary war and Shadbala disabled.

## 0.14.0+18

- Added twelve explicit house-occupancy findings and empty-house safeguards.
- Added universal seventh and Mars/Jupiter/Saturn special full sign aspects.
- Excluded disputed Rahu/Ketu aspects from the verified rule profile.
- Added versioned direct/retrograde combustion thresholds and angular evidence.
- Added retrograde review findings without automatic good/bad classification.
- Added source sign/longitude consistency validation.
- Added separate occupancy, aspect and planet-condition UI sections.
- Recorded public rule references and interpretation limits.

## 0.13.0+17

- Added all twelve whole-sign house condition findings.
- Added each house sign, classical lord, lord placement and dignity evidence.
- Added ascendant-specific functional ownership scoring for seven planets.
- Added a transparent Yoga-karaka ownership flag.
- Added bilingual house domains and expanded life-area classifications.
- Grouped review UI into Lagna, twelve-house and functional-role sections.
- Documented scoring limits and kept unverified aspects/timing disabled.

## 0.12.0+16

- Added consultation-level Run Kundli Analysis calculation workflow.
- Added immutable orchestration from calculation output to judgment snapshot.
- Added the first production Vedic rule family for Lagna and Lagna lord.
- Added whole-sign house placement and transparent dignity/house scoring.
- Added Bengali/English findings with visible rule ids and output paths.
- Added confidence labels and review-only Lagna-lord gemstone candidates.
- Added latest-analysis display, immutable version count and safety warnings.
- Kept event timing disabled until verified Dasha and transit rules exist.

## 0.11.1+15

- Added Android Gradle external-native-build CMake integration.
- Added Windows CMake build-and-install integration for the FFI DLL.
- Ensured both platforms compile the same pinned native source and ABI target.
- Added a reusable temporary-build validation script for calculations and
  required exported FFI symbols.
- Documented exact runner hooks and the required guarded Dart build flag.

## 0.11.0+14

- Added a direct Dart FFI bridge for Android and Windows native libraries.
- Added a Spica-anchored Lahiri/Chitrapaksha ayanamsha calculation.
- Added instantaneous true Rahu and polynomial mean Rahu with daily speeds.
- Added tropical ascendant from local sidereal time and true obliquity.
- Added production composition of the native provider and Vedic derivations.
- Added a complete-frame regression fixture and native ABI golden checks.
- Kept Raman and Krishnamurti ayanamshas disabled pending separate review.

## 0.10.0+13

- Added the bilingual Complete Kundli Judgment output schema.
- Added supportive, challenging and mixed life-area findings.
- Added past/future timing windows with confidence and evidence.
- Added gemstone/mantra/charity/ritual/behavioural remedy candidates.
- Required bilingual evidence and cautions for every conclusion.
- Required two independent rules for High confidence.
- Blocked High-confidence timing for approximate/unknown birth time.
- Added immutable calculation-bound analysis snapshots, SHA-256 integrity,
  database schema v6 and transactional audit history.

## 0.9.1+12

- Added Bengali/English gemstone remedy Add/Edit screen.
- Added controlled planet, carat/ratti and astrologer-decision selectors.
- Added primary/substitute stone, metal, finger, day, instructions, reason,
  evidence and caution inputs.
- Added remedy cards and locked-state display inside consultation details.
- Added inline weight and Approved-state evidence/output validation.
- Added a visible traditional-guidance and no-guaranteed-outcome notice.

## 0.9.0+11

- Added the governed professional gemstone-remedy domain model.
- Added planet, primary/substitute gemstone, carat/ratti, metal, finger,
  wearing day, instructions, astrological reason, evidence and cautions.
- Added Draft, Approved and Rejected remedy decisions.
- Required verified calculation output and evidence before approval.
- Added database schema version 5, consultation linkage and transactional audit
  history for remedy creation and editing.
- Locked gemstone remedy changes after consultation finalization.

## 0.8.2+10

- Pinned the reviewed Astronomy Engine C source at tag v2.1.19.
- Recorded source-archive and per-file SHA-256 checksums.
- Bundled the complete upstream MIT licence notice.
- Added a stable C ABI for geocentric tropical longitude and daily speed.
- Added a shared-library CMake target for Android and Windows integration.
- Added seven-body NASA/JPL Horizons DE441 accuracy evidence with a strict
  0.01-degree maximum error threshold.

## 0.8.1+9

- Removed Swiss Ephemeris as a product dependency and deleted its licence gate.
- Selected MIT-licensed Astronomy Engine as the offline astronomical base.
- Added a guarded Android/Windows Astronomy Engine native bridge boundary.
- Added third-party notice and release-time licence/checksum requirements.
- Added tests for missing backend, initialize-once and invalid coordinates.

## 0.8.0+8

- Locked the product to proprietary commercial distribution.
- Removed AGPL as an enabled Swiss Ephemeris build mode.
- Added the commercial-entitlement-only native provider boundary.
- Added UTC/coordinate validation and initialize-once native bridge behavior.
- Added tests proving unlicensed execution is blocked before native code loads.
- Kept all Swiss source, binary and data files outside the repository pending
  a valid commercial licence package.

## 0.7.0+7

- Added a vendor-neutral offline ephemeris provider contract.
- Added explicit Swiss Ephemeris AGPL/commercial licence gating.
- Added pure Dart Vedic derivations for sidereal positions, D1, D9,
  Nakshatra, Pada, Tithi, Paksha, Yoga and Rahu/Ketu.
- Added fixed-evidence derivation tests without bundling unlicensed binaries.

## 0.6.0+6

- Added consultation detail and editing workspace.
- Added idempotent input preparation to prevent duplicate snapshots.
- Added calculation orchestration and selected-engine system validation.
- Added governed review/finalization transitions requiring verified output.
- Locked finalized consultations against edits and new outputs.

## 0.5.0+5

- Added professional consultation records linked to a client and birth record.
- Added category, selected-system and status workflow fields.
- Added an engine-only immutable calculation-output snapshot contract.
- Added output engine/schema versioning and SHA-256 integrity hashes.
- Added non-destructive database migration from version 3 to 4.

## 0.4.0+4

- Added transaction-bound audit history for governed client data changes.
- Added immutable calculation input snapshots.
- Added canonical snapshot payloads and SHA-256 integrity hashes.
- Added database triggers that reject snapshot updates and deletions.
- Added non-destructive schema migration from database version 2 to 3.

## 0.3.0+3

- Added client detail and client edit screens.
- Added multiple birth-record creation and birth-record editing.
- Added persistent calculation defaults for ayanamsha, Vedic chart style,
  Western house system and true/mean lunar nodes.
- Added non-destructive schema migration from database version 1 to 2.

## 0.2.0+2

- Added offline client and primary birth-record persistence.
- Added controlled date/time input and coordinate validation.

## 0.1.0+1

- Added bilingual professional application shell and module dashboard.
