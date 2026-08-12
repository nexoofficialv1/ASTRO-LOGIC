# Encrypted Backup Security Profile v1

Contract: `astro-logic-encrypted-backup-v1`

## Source profile

The implementation uses `package:cryptography` 2.9.0. Its published API provides cross-platform AES-GCM and Argon2id support and documents Argon2id parameters of 19 MiB memory, parallelism 1 and iterations 2 as the OWASP-referenced baseline. ASTRO LOGIC freezes that set for backup v1 rather than silently changing KDF cost between releases.

Primary package documentation:

- https://pub.dev/packages/cryptography
- https://pub.dev/documentation/cryptography/latest/cryptography/Argon2id-class.html
- https://pub.dev/documentation/cryptography/latest/cryptography/AesGcm-class.html

Native file selection uses stable `file_picker` 11.0.3:

- https://pub.dev/packages/file_picker


## v0.77.0+81 — Western Foundation snapshot coverage

Western v082 likewise requires no database migration. `western-input-schema-v2` and `western-natal-chart-v2` are serialized inside the same generic immutable calculation snapshot tables already covered by manifest hashing, encrypted backup/restore and governed merge/import validation. The new rulership/aspect/modern-planet/pattern metadata is therefore hash-bound without changing backup engine `1.4.0` or SQLite schema 12.

Western Foundation v1 does not add a database table. Its `western-input-schema-v1` rows are stored in `calculation_snapshots` and its `western-natal-chart-v1` results are stored in `calculation_output_snapshots`; both tables are already part of the governed encrypted-backup manifest and merge/hash validation path. Therefore backup engine `1.4.0` and SQLite schema 12 remain unchanged.

## Threat boundary

v1 protects a copied backup file against casual disclosure and authenticated modification of both ciphertext and the declared plaintext envelope metadata when the password remains secret. It does not protect data after a legitimate user has unlocked and restored it, does not provide remote key escrow, and does not claim resistance to a compromised operating system, keylogger or maliciously modified app binary.

## Password handling

- Password is entered only for backup encryption or restore decryption.
- Password is never written to SQLite, audit history, manifest or backup envelope.
- v1 enforces a 12-character minimum and recommends a longer unique passphrase.
- v1 refuses encrypted backup files larger than 128 MiB before restore processing.
- There is no password recovery or reset mechanism for an existing encrypted backup.

## Cryptographic envelope

- KDF: Argon2id, 19456 KiB, p=1, t=2, output 32 bytes.
- Salt: fresh 16 random bytes per backup.
- Cipher: AES-256-GCM.
- Plaintext envelope metadata (contract/version/schema/KDF/cipher parameters and timestamp) is authenticated as AES-GCM AAD; changing it causes authentication failure.
- Nonce: fresh random cipher nonce per encryption operation.
- Ciphertext authentication failure is treated as wrong-password/tamper/truncation failure, never as a partially recoverable backup.

## Integrity beyond AEAD

Authenticated encryption protects the encrypted payload, while the internal manifest protects the application's logical restore contract. Every governed table has a canonical SHA-256 and row count; the complete table set also has an overall SHA-256. Domain-specific immutable hashes are recomputed independently before backup and before restore.

## Restore safety

Empty-workspace restore still refuses overwrite. From v0.66.0+70, a separate governed merge path may import into a non-empty workspace without overwriting existing rows. It reuses equivalent rows, deterministically remaps colliding primary keys, preserves hash-bound source IDs in schema-v10 integrity columns and schema-v11 local import-batch provenance, runs in foreign-key order, validates SQLite foreign keys, recomputes governed hashes, and rolls back the entire transaction on any failure.

## Pre-restore preview & conflict planner v1 (v0.65.0+69)

- Preview decrypts and authenticates the backup but performs no database mutation and creates no audit event.
- The source app version, backup-engine version, database schema, created-at timestamp, per-table row counts and overall manifest hash are shown before restore.
- Current-schema backups also rerun all governed snapshot/report/approval hash checks before they can become restore-eligible.
- Existing local records are compared by primary-key ID. Same-ID rows with identical canonical content are classified as equivalent; same-ID rows with different canonical content are conflicts.
- Non-empty workspace execution is enabled only through Governed Backup Merge/Migration Adapter v1. Existing rows are never overwritten; equivalent rows are reused, resolvable primary-key collisions are remapped deterministically, and semantic unique-identity conflicts block the whole transaction.
- Passwords are not retained after preview. Executable restore requires password re-entry and repeats authentication/integrity validation.
- Reader compatibility accepts encrypted-backup engines 1.0.0, 1.1.0, 1.2.0 and 1.3.0 under the unchanged v1 envelope/payload contract.


## Governed merge adapter v1 (v0.66.0+70)

- Supported source schemas: v9, v10 and v11.
- Free source IDs are preserved. Same-ID identical rows are reused. Same-ID different rows receive deterministic IDs above the occupied/source range.
- Immutable natural-identity collisions (Numerology snapshot, professional report or report approval) with different content are blocking conflicts, not remap candidates.
- Active local astrology settings are not overwritten by merge; historical calculation snapshots already carry their original settings JSON.
- Imported audit summaries are retained inside provenance metadata and client audit entity IDs are remapped to the local client identity.
- `governedBackupMerged` records source app/schema/manifest, inserted/equivalent/remapped counts and the all-or-nothing rollback policy. The same manifest cannot be merged twice.
- Merge password is re-entered for execution; preview does not retain it.


## Import batch ledger & merge receipts v1 (v0.67.0+71)

- `backup_import_batches` is local operational provenance and is intentionally not recursively included inside the portable protected backup payload.
- A `started` batch is inserted before the merge transaction. Imported governed rows and `backup_import_mappings` rows then commit atomically together; successful terminalization to `committed` occurs in that same transaction.
- If the merge transaction fails, no partial imported rows or mapping rows remain. The pre-existing batch is terminalized as `failed` with bounded diagnostics. If the app/process stops while a batch is still `started`, next startup safely classifies it as failed/interrupted because a successful commit necessarily terminalizes the batch atomically.
- Mapping rows are immutable and bind table name, source ID, resolved local ID, resolution mode and both source/local row SHA-256 values.
- Terminal batch rows and all mapping rows are protected by SQLite triggers against mutation/deletion. A partial unique index permits retry after failed attempts while preventing duplicate committed imports of the same manifest.
- Merge receipt contract `astro-logic-backup-merge-receipt-v1` hashes the complete deterministic mapping list plus source manifest/version/schema, row counts, all-or-nothing rollback policy and source-integrity preservation flag. Receipt JSON export recomputes and verifies that SHA-256 from the ledger first.
- Merge receipts contain IDs/hashes and governance metadata, not client narrative or birth-data payloads.


## v0.75.0+79 — schema-aware KP Horary backup coverage

Backup engine 1.4.0 supports reader engines 1.0.0 through 1.4.0 and merge source schemas 9 through 12. Schema 12 adds `kp_horary_snapshots` to the protected/sensitive table set. Older schema manifests are verified against their original table set before an empty Horary table is introduced only in the in-memory normalized representation. KP Horary input/settings and output hashes are recomputed during governed backup integrity validation. Imported `kpHorary` audit entity IDs are remapped together with collided Horary row IDs; existing local rows are never overwritten.

## v0.76.0+80 — Horary RP confirmation hash coverage

Backup engine remains 1.4.0 and SQLite remains schema 12. The new `timingConfirmation` object lives inside each immutable KP Horary `output_json`; restore/preview/merge reuses the stored engine/output-schema metadata to recompute the complete output SHA-256, so RP evidence tampering is rejected without a backup-format change.
