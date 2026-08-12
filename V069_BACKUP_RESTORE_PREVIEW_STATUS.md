# ASTRO LOGIC v069 — Backup Restore Preview & Conflict/Migration Planner v1

## Status

Completed at source level. Flutter/Dart SDK runtime is not available in the development environment, so analyzer/test/APK/Windows runtime success is not claimed.

## Frozen contracts

- App: `0.65.0+69`
- SQLite: schema `v9` (unchanged)
- Encrypted backup contract: `astro-logic-encrypted-backup-v1` (unchanged)
- Encrypted payload contract: `astro-logic-backup-payload-v1` (unchanged)
- Backup writer engine: `1.1.0`
- Supported reader engine versions: `1.0.0`, `1.1.0`
- Restore execution policy: `emptyWorkspaceOnly`
- Merge/overwrite/automatic ID remap: disabled

## Read-only preview

Preview requires the backup password and authenticates/decrypts the file before showing metadata. It does not insert, update or delete database rows, does not append an audit event, does not persist the password and returns `databaseMutationPerformed=false`.

The preview shows:

- source ASTRO LOGIC app version;
- source encrypted-backup engine version;
- source database schema version;
- backup UTC creation time;
- overall manifest SHA-256;
- per-table row counts;
- encrypted manifest verification status;
- governed snapshot/report/approval integrity status when source schema equals the current schema;
- local governed-row count;
- table-by-table ID conflict plan for current-schema backups.

## Conflict model

For every current-schema protected table, incoming rows are compared to local rows by original primary-key `id`.

- `newIds`: the incoming ID does not exist locally;
- `equivalentIds`: the same ID exists and the full canonical row is byte-equivalent after `sorted-json-keys-v1` canonicalization;
- `conflictingIds`: the same ID exists with different canonical content.

Equivalent rows are informational only. They are not rewritten, merged or duplicated. Same-ID/different-content records are blocking conflicts for any future governed merge. `astrology_settings` is a singleton row and is treated as a settings difference rather than an identity-remap candidate.

## Restore eligibility

Executable restore is available only when all of these are true:

1. source schema equals current schema v9;
2. manifest validation passes;
3. governed snapshot/report/approval hash validation passes;
4. local sensitive governed tables contain zero rows (the always-present singleton settings row is excluded);
5. user explicitly confirms restore and re-enters the password.

A non-empty workspace can be previewed, but merge execution remains disabled. Older/newer schema backups may be authenticated and manifest-checked when the reader contract is supported, but require an explicit migration adapter before any restore is enabled.

## Backward compatibility

v069 keeps the v1 encrypted envelope and payload contracts. Reader compatibility explicitly accepts v068 backup engine `1.0.0` and v069 engine `1.1.0`. New backups are written as engine `1.1.0` and app `0.65.0+69`.

## Security notes

- Password is not retained after preview.
- Actual restore requires password re-entry and reruns authentication and integrity checks.
- Encrypted backup bytes may remain selected in UI memory until preview state is cleared; they remain encrypted.
- Preview itself creates no audit event because audit insertion would violate the zero-mutation contract.

## Next milestone

**Governed Backup Merge/Migration Adapter v1** — define explicit schema-adapter contracts and immutable identity remapping rules for selected non-empty-workspace imports. Execution must remain disabled until foreign-key remapping, immutable snapshot/report/approval binding and imported audit provenance can be proven transactionally.
