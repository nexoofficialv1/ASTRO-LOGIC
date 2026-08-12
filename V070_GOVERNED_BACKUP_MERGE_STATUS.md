# ASTRO LOGIC v070 — Governed Backup Merge/Migration Adapter v1

App version: `0.66.0+70`  
SQLite schema: `10`  
Backup engine: `1.2.0`  
Merge contract: `astro-logic-governed-backup-merge-v1`

## Completed

- Non-empty workspace merge is executable only after encrypted authentication, manifest verification and governed snapshot/hash verification.
- Source schemas v9 and v10 are supported. v9 rows are adapted to schema v10 at insertion without changing source cryptographic content.
- Free primary keys are preserved; same-ID identical rows are reused; same-ID different rows are deterministically remapped above the occupied/source range.
- Numerology, professional-report and approval natural-identity collisions with different content are blocking conflicts.
- Schema v10 preserves original ID values needed by Kundli, Numerology, professional approval and signed-report QR integrity contracts. Local FK IDs and source integrity IDs are intentionally separate.
- Existing local records and active astrology settings are never overwritten by merge.
- Imported audit history retains the original source summary inside provenance metadata; client audit entity IDs are remapped locally.
- Duplicate import of the same manifest is blocked.
- Merge executes in one SQLite transaction and performs foreign-key plus governed-hash checks before the merge audit event is written. Any failure rolls back all inserted rows.
- Preview remains zero-mutation and does not retain the password. Merge execution requires password re-entry.

## Validation boundary

This milestone is source/readiness validated in the current environment. Flutter/Dart SDK runtime is unavailable here, so `flutter analyze`, `flutter test`, APK and Windows runtime build success are not claimed.

## Next locked milestone

**Backup Merge Recovery & Import Batch Ledger v1** — durable import-batch history, per-row source/local identity lookup, merge receipt export, and operator-visible recovery diagnostics without weakening immutable audit history.
