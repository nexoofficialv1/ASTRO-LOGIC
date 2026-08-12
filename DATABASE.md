# ASTRO LOGIC Database v12

## clients

Stores the professional client's identity and contact metadata. Client deletion
must be explicit and audited in a later migration.

## birth_records

Stores one or more immutable-source birth inputs for a client. The local civil
date/time, entered UTC offset and derived UTC timestamp are stored separately so
calculation results never depend on the device timezone.

Coordinates are protected by database constraints:

- latitude: -90 through 90
- longitude: -180 through 180
- UTC offset: selected in 15-minute steps from UTC-12:00 through UTC+14:00

Birth-time confidence uses: Exact, Recorded, Approximate or Unknown.

## astrology_settings

Version 2 adds one governed default calculation profile containing ayanamsha,
Vedic chart style, Western house system and true/mean lunar-node mode. Migration
from version 1 creates this table without modifying client or birth-record data.


## v081 Western Foundation — schema unchanged

## v082 Western v2 immutable calculation snapshots

Western v082 does not add a mutable settings table or a new calculation table. `western-input-schema-v2` rows continue in `calculation_snapshots` with `snapshot_kind = western-input`; `settings_json` now binds zodiac/house/node settings plus rulership profile/version, aspect profile/version, minor-aspect enabled state, modern-planet enabled state/profile, aspect-pattern engine version and the unchanged traditional dignity profile. `western-natal-chart-v2` remains in `calculation_output_snapshots`, protected by the existing output hash and immutable workflow. SQLite therefore remains schema 12.

Western consultation calculations use the existing immutable `calculation_snapshots` and `calculation_output_snapshots` tables. Western input rows use `snapshot_kind = western-input` and `schema_version = western-input-schema-v1`; the settings payload binds the tropical zodiac profile, selected house system/profile, lunar-node mode, aspect profile and dignity profile. No new table or migration is required, so SQLite remains schema 12.

## Migration policy

Schema updates use monotonically increasing database versions. Existing client
and consultation data must never be dropped during an automatic migration.

## audit_events

Version 3 records critical client, birth-record, settings and snapshot actions.
Audit writes occur in the same transaction as the governed change.

## calculation_snapshots

Version 3 stores canonical birth input, calculation settings, schema version and
SHA-256 hash. Database triggers reject UPDATE and DELETE statements, making each
snapshot immutable. A future calculation engine will add its version and output
to a new governed snapshot type without rewriting these input records.

## consultations

Version 4 links each professional question to one client, one governed birth
record and selected astrology systems. Status moves through Draft, Reviewed and
Finalized without altering linked calculation snapshots.

## calculation_output_snapshots

Version 4 reserves immutable, engine-generated results. Each record identifies
the input snapshot, engine id, engine version and output schema version, and
contains a non-empty structured output plus SHA-256 hash. The app does not create
placeholder astrology results; only a calculation-engine adapter may use this
write path.

## gemstone_remedies

Version 5 stores professional gemstone-remedy drafts linked to consultations.
Each record preserves the target planet, primary/substitute stone, governed
weight and unit, metal, finger, wearing day, traditional instructions,
astrological reason, evidence references, cautions and the astrologer's Draft,
Approved or Rejected decision.

Approval requires an existing verified calculation output and at least one
non-empty evidence reference. Finalized consultations reject remedy creation or
editing. Every create/update action is written to the client audit history in
the same database transaction.

## kundli_analysis_snapshots

Version 6 stores immutable bilingual judgment-engine drafts linked to one
consultation and one verified calculation output. Each snapshot records engine
identity/version, analysis schema, structured findings/timing/remedy candidates,
nine reusable Dasha activation profiles, 729 chart-specific Pratyantardasha
interpretation records, 12 structured D9 house/lord/full-sign-aspect
interpretation records, 12 D10 career house records plus one D1×D10 career synthesis and—under current `kundli-analysis-v32`—seven Shadbala
foundation profiles inside the immutable `analysis_json`, plus SHA-256 hash and
creation time. Database triggers reject UPDATE and DELETE. The v25 Shadbala JSON record retains the v21 Tribhaga, v20 Nathonnata and v19 Drik audit fields and adds nullable `varshaBalaVirupas`, `masaBalaVirupas`, `dinaBalaVirupas`, `horaBalaVirupas`, the four corresponding lords, one-based `horaNumber` and the versioned temporal-lord profile id. Current `vedic-chart-v10` calculation snapshots carry the exact speed needed for Mars-Saturn Cheshta, apparent Sun hour angle for Nathonnata, solar-period boundaries for Tribhaga/Hora, and prior sidereal solar-ingress plus astrological-day metadata for Varsha/Masa/Dina. The v25 record additionally persists nullable Yuddha correction, war role/partner, angular separation, both ecliptic latitudes, pre-war strength difference, complete Kala total when available, and its governed profile id. Current `vedic-chart-v10` calculation snapshots also persist geocentric ecliptic latitude for the planetary-war audit. The v25 Shadbala record additionally persists the evidence-gated sixfold total in Virupas/Rupas, BPHS 27.32-33 required total in Virupas/Rupas, required-strength ratio, signed surplus/deficit, threshold status and threshold-profile id. These additions remain in immutable JSON contracts and do not change the normalized SQLite table shape; the database schema was version 7 through the D10 milestone; Report Engine v1 promoted the normalized SQLite schema to version 8; Professional Report Approval v1 promotes it to schema version 9.

`kundli-analysis-v32` persists one `ashtakavarga-foundation-v3` object inside `analysis_json`: seven unreduced BAV tables, each sign's contributor audit, fixed table checksum, twelve raw-SAV sign/house records, 337 total, average and notation/ruleset profile, an `ashtakavarga-reductions-v1` child containing raw/Trikona/Ekadhipatya values and audits, plus `ashtakavarga-pinda-v1` containing fixed Rashi/Graha multipliers, per-contribution products, Rashi Pinda, Graha Pinda and Shodhya/Yoga Pinda for all seven BAVs. No normalized table migration is required.

High-confidence timing is disallowed for approximate/unknown birth time before
the snapshot is written. Finalized consultations cannot receive new analysis.

## numerology_snapshots

Version 7 adds a dedicated immutable snapshot chain for Numerology. Each record
links one consultation, client and governed birth record and stores:

- exact normalized Latin spelling used for calculation;
- versioned alternate-name comparison payload plus optional explicit professional discussion focus;
- locked birth record and selected Personal Year target;
- calculation engine/schema identity and complete calculation JSON;
- judgment engine/schema identity and complete bilingual analysis JSON;
- one SHA-256 binding input, both payloads and both versioned engines;
- UTC creation time.

Database triggers reject UPDATE and DELETE. Re-running identical input is
idempotent and returns the existing snapshot. A changed spelling, alternate candidate set, explicit professional focus, target year,
rule schema or engine version creates a new immutable version. Finalized
consultations reject new snapshots, and Numerology must be selected on the
consultation.

A Numerology snapshot is a verified artifact for Draft → Reviewed → Finalized
workflow. It is never treated as Vedic evidence for gemstone approval.

`vedic-chart-v10` adds explicit D10 ascendant/per-planet signs to calculation JSON, while `kundli-analysis-v28` adds twelve `dashamsa-career-interpretation-v1` house records and one career synthesis to analysis JSON. D10 data remains inside immutable JSON contracts, so no normalized SQLite migration is required.

`kundli-analysis-v32` adds `advanced-yoga-dosha-v1` findings and the contradiction-preserving Yoga/Dosha synthesis inside the same immutable `analysis_json`. No normalized SQLite migration is required for this rule-family extension.


## professional_report_snapshots

Version 8 adds immutable professional consultation report snapshots. Each record links one consultation and stores the report engine id/version, `professional-consultation-report-v1` schema id, source-manifest JSON, complete bilingual structured report JSON, SHA-256 report hash and UTC creation time. The source manifest binds every included immutable Kundli/Numerology source by record id, source schema and source hash.

Database triggers reject UPDATE and DELETE. Re-generating byte-identical report content from the same source manifest is idempotent through the unique `(consultation_id, report_hash)` constraint. Finalized consultations reject new report generation. Report snapshots remain the persisted source of truth. Professional Report Export Engine v2 creates PDF/DOCX as derived filesystem artifacts only after re-verifying the stored report hash and any linked approval hash; export files are not added to SQLite and do not mutate the immutable report/approval rows.

Schema v9 adds `professional_report_approvals`. Exactly one immutable approval may reference a report snapshot. The row stores the bound report/consultation ids, exact source report hash, practitioner name/designation, optional credential reference, decision/note, approval engine/statement versions, UTC approval time, `approval_hash` and `signed_report_hash`. SQLite BEFORE INSERT guards reject report-hash or consultation mismatch against `professional_report_snapshots`; UPDATE and DELETE triggers make sign-off append-only. This is an in-app practitioner electronic sign-off, not a certificate-backed digital-signature store.

`kundli-analysis-v32` adds `rahu-ketu-analysis-v1` ChartFinding evidence and node-Dasha adjustment evidence inside the existing immutable `analysis_json`; the astrology payload itself requires no migration. The professional-report approval layer originally promoted the application to schema v9; the current application is schema v11 because the backup import-batch ledger adds durable merge provenance on top of schema-v10 source-integrity identity columns.

## Kundli analysis v32 remedy and gemstone-review extension

`kundli-analysis-v32` adds `vedic-remedy-recommendation-v1` behavioural remedy
candidates inside the existing immutable `analysis_json`. Each candidate keeps
bilingual action/rationale/caution text plus the triggering chart evidence. No
no astrology-specific normalized table is introduced. The professional-report approval layer originally used schema v9; the current application is schema v11 because the backup import-batch ledger adds durable merge provenance on top of schema-v10 source-ID preservation. `kundli-analysis-v32` also persists seven `vedic-gemstone-candidate-v1` review records inside `analysis_json`, each carrying functional ownership, D1/D9 dignity, complete-Shadbala sufficiency, combustion/Yuddha/node-contact state, analysis-time Dasha role, bilingual rationale/caution and auditable evidence. These are review statuses only; practitioner-entered gemstone approvals continue to use the existing governed remedy table and audit workflow.


## Signed-report verification v1 (v0.63.0+67)

Signed-report verification itself introduced no migration. The current application is schema v11; verification reads the existing immutable `professional_report_snapshots` and `professional_report_approvals` records and recomputes report, approval and signed-report hashes in memory. QR verification payloads are derived transport metadata and are not stored as a new mutable database entity.

## Encrypted backup & restore v1 (v0.64.0+68)

Encrypted backup v1 originally introduced no schema migration. The current application is schema v11; backup is a versioned logical export of `clients`, `birth_records`, `astrology_settings`, `audit_events`, `calculation_snapshots`, `consultations`, `calculation_output_snapshots`, `gemstone_remedies`, `kundli_analysis_snapshots`, `numerology_snapshots`, `professional_report_snapshots` and `professional_report_approvals`.

The portable `.albackup` file is an outer JSON envelope whose payload is authenticated-encrypted. Passwords are converted to a 32-byte key with Argon2id (`memory=19456 KiB`, `parallelism=1`, `iterations=2`) using a fresh 16-byte salt. The payload is encrypted with AES-256-GCM using a fresh nonce. The plaintext contract/version/schema/KDF/cipher/timestamp header is supplied as AES-GCM AAD, so modification of that metadata also invalidates authentication. The password itself is not stored.

Inside the encrypted payload, each protected table has a canonical `sorted-json-keys-v1` SHA-256 plus row count, and the complete table set has an overall SHA-256. Before backup and before restore, immutable input/output/Kundli/Numerology/report/approval/signed-report hashes are recomputed and SQLite foreign keys are checked.

The original restore-v1 path remains `emptyWorkspaceOnly`: it does not merge or overwrite existing records. Rows are inserted in foreign-key order with original IDs inside one transaction, then `PRAGMA foreign_key_check` and the exact table manifest are verified before commit. A new local `encryptedBackupRestored` audit event is appended after exact-content verification, so restored historical audit rows remain intact while the restore operation itself is also recorded. From v0.66.0+70, non-empty workspaces use the separate governed merge adapter described below rather than weakening this exact-restore path.

## Restore preview planner (v0.65.0+69)

The preview planner itself introduced no migration. In v0.65.0+69 the application was schema v9; the current schema is v11. The planner is read-only and compares decrypted incoming rows with local protected tables by original primary-key ID. It never inserts, updates, deletes, merges or remaps records. Empty-workspace eligibility excludes the singleton `astrology_settings` row from the sensitive-row count because that row always exists and is replaced only inside the already governed empty-workspace restore transaction.

For current-schema backups, incoming rows are classified per table as new ID, same-ID canonical equivalent, or same-ID content conflict. Equivalent status is informational and does not authorize rewriting. Any non-empty governed workspace remains blocked from executable restore in this milestone.


## Schema v10 — governed backup merge integrity identities

Version 10 adds nullable source-identity columns only to hash contracts whose original database IDs are part of the immutable digest or signed-report verification identity. Native records leave these columns NULL; governed imports populate them only when needed to preserve the original source identity after local primary/foreign-key remapping.

- `kundli_analysis_snapshots.source_calculation_output_id` preserves the calculation-output ID used by the original analysis hash.
- `numerology_snapshots.source_consultation_id`, `source_client_id` and `source_birth_record_id` preserve the IDs bound into the original Numerology snapshot hash.
- `professional_report_snapshots.source_report_snapshot_id` and `source_consultation_id` preserve the signed-report/QR identity after local remapping.
- `professional_report_approvals.source_report_snapshot_id` and `source_consultation_id` preserve the original approval-hash payload.

The local FK columns always point to valid local rows. Source-integrity columns are not foreign keys and are never used for navigation or cascade behavior; they exist only for immutable hash/signature provenance. Migration from v9 adds these columns without rewriting existing rows.


## Schema v11 — backup import batch ledger and provenance mappings

Version 11 adds two **local operational provenance** tables. They are deliberately not part of the portable protected-table payload, so importing a backup never recursively imports another workspace's merge ledger.

### `backup_import_batches`

Each governed non-empty-workspace merge receives a durable batch row before any imported data transaction begins. The row records source manifest/app/backup-engine/schema identity, backup timestamp, start/completion UTC, terminal status, inserted/equivalent/remapped/imported-audit counts, mapping-row count, rollback policy, source-integrity preservation flag, bounded diagnostics and the committed merge-receipt SHA-256.

Allowed status transitions are intentionally narrow: `started` may become `committed` or `failed`; terminal rows cannot be updated and no batch row can be deleted. A partial unique index allows failed attempts to be retried while preventing more than one committed batch for the same manifest hash.

### `backup_import_mappings`

Every incoming governed row participating in a committed merge gets an immutable source/local identity record containing batch id, table name, source primary key, resolved local primary key, resolution (`inserted`, `equivalent`, `remapped`), source-row SHA-256, local-row SHA-256 and UTC creation time. UPDATE/DELETE triggers make the mapping ledger append-preserving.

The mapping ledger is inserted inside the same SQLite transaction as imported rows. Therefore a failed transaction retains no mapping rows. The parent batch is created outside that transaction so a rollback can still be diagnosed; if the process stops before terminalization, startup recovery marks the still-`started` batch failed because a successfully committed merge necessarily updates the batch to `committed` inside the same transaction.

The merge receipt contract `astro-logic-backup-merge-receipt-v1` hashes the complete deterministic mapping list together with source manifest/version/schema, batch counts and rollback/source-integrity policy. Receipt export recomputes that canonical SHA-256 from the immutable ledger before writing JSON.


## Schema v12 — KP Horary immutable snapshots

`kp_horary_snapshots` stores standalone KP Horary work and deliberately has no client or birth-record foreign key. Each row binds one explicit question, the selected 1–249 number, query UTC/location, node mode, input/settings JSON and output JSON to SHA-256 integrity hashes. UPDATE and DELETE triggers make committed rows immutable.

The Horary input contract explicitly records `natalBirthDataUsed: false`. Query-moment planetary positions and the number-selected Ascendant/cusps are therefore auditable without silently inheriting natal data. A `kpHorarySnapshotCreated` audit event is written transactionally.

Encrypted backup schema handling is version-aware: schema 9–11 payloads retain the original twelve protected tables; schema 12 adds `kp_horary_snapshots`. Older payloads normalize the new table to an empty set during read/merge so their original manifest hash remains verifiable.

## v080 KP Horary RP confirmation — schema unchanged

SQLite remains schema 12. No mutable timing table was added. Query-time Ruling-Planet corroboration is serialized inside the immutable `kp_horary_snapshots.output_json` document and is therefore covered by the existing `output_hash`, no-update trigger, no-delete trigger, audit event and governed backup/merge path.
