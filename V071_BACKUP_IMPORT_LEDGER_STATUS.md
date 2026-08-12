# ASTRO LOGIC v071 — Backup Merge Recovery & Import Batch Ledger v1

App version: `0.67.0+71`  
SQLite schema: `11`  
Backup engine: `1.3.0`  
Encrypted backup contract: `astro-logic-encrypted-backup-v1`  
Governed merge contract: `astro-logic-governed-backup-merge-v1`  
Import ledger contract: `astro-logic-backup-import-ledger-v1`  
Merge receipt contract: `astro-logic-backup-merge-receipt-v1`

## Completed

- Added durable local `backup_import_batches` history for every governed non-empty-workspace merge attempt.
- Added immutable `backup_import_mappings` with source ID, local ID, resolution, source-row SHA-256 and local-row SHA-256.
- A batch is created as `started` before the merge transaction. Imported governed rows, mapping ledger rows and `committed` terminalization occur atomically in the same SQLite transaction.
- Transaction failure rolls back all imported rows and mappings, then terminalizes the durable batch as `failed` with bounded diagnostics.
- Startup recovery marks any still-`started` batch failed/interrupted. This is safe because a successfully committed merge necessarily terminalizes its batch inside the same transaction.
- Terminal batch rows cannot be updated or deleted. Mapping rows cannot be updated or deleted.
- A partial unique index allows failed-manifest retries but prevents duplicate committed import of one manifest.
- Duplicate-manifest protection checks the new committed batch ledger and legacy `governedBackupMerged` audit rows for v070-era compatibility.
- Added SHA-256-bound merge receipts that cover source manifest/version/schema, result counts, rollback/source-integrity policy and the complete deterministic source→local mapping list.
- Receipt export recomputes the canonical hash from the immutable ledger before writing JSON.
- Added bilingual Import Batch Ledger UI with batch status, diagnostics, source/local mapping inspection and receipt export/share.
- Import-batch operational metadata stays local-only and is intentionally excluded from recursively portable protected backup tables.
- Backup reader compatibility remains engines `1.0.0`, `1.1.0`, `1.2.0`, `1.3.0`; governed merge accepts source schemas `9`, `10`, `11`.

## Validation boundary

This milestone is source/readiness validated in the current environment. Flutter/Dart SDK runtime is unavailable here, so `flutter analyze`, `flutter test`, APK and Windows runtime build success are not claimed.

## Next locked milestone

**Core Maintainability Refactor v1** — split the largest service/judgment/UI files into stable submodules without changing SQLite schema, persisted calculation/judgment contracts, report hashes, signed-report identity, encrypted-backup format or merge-receipt hashes; then prepare the final Flutter analyzer/test/build checkpoint before new KP/Western/Vastu/Palmistry expansion.
