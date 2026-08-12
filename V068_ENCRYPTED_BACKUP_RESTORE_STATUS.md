# ASTRO LOGIC v068 — Encrypted Backup & Restore v1

## Status

Completed at source level. Flutter/Dart SDK runtime was not available in the development environment, so analyzer/test/APK/Windows runtime success is not claimed.

## Frozen contracts

- App: `0.64.0+68`
- SQLite: schema `v9` (unchanged)
- Backup engine: `astro-logic-encrypted-backup` `1.0.0`
- Envelope: `astro-logic-encrypted-backup-v1`
- Encrypted payload: `astro-logic-backup-payload-v1`
- File extension: `.albackup`
- Portable backup size limit: 128 MiB in v1
- Canonical manifest: `sorted-json-keys-v1` + SHA-256

## Cryptography

- KDF: Argon2id
  - memory: 19 MiB / 19456 KiB
  - parallelism: 1
  - iterations: 2
  - derived key: 32 bytes
  - salt: fresh random 16 bytes per backup
- Cipher: AES-256-GCM
  - fresh cipher nonce per backup
  - authenticated encryption; wrong password or ciphertext/tag corruption must fail authentication
  - contract/version/schema/KDF/cipher/timestamp privacy header is bound as AES-GCM AAD, so outer metadata modification also fails authentication
- Password: minimum 12 characters in v1 UI/policy and never stored.

## Protected records

`clients`, `birth_records`, `astrology_settings`, `audit_events`, `calculation_snapshots`, `consultations`, `calculation_output_snapshots`, `gemstone_remedies`, `kundli_analysis_snapshots`, `numerology_snapshots`, `professional_report_snapshots`, `professional_report_approvals`.

## Backup integrity gates

Before encryption:

1. `PRAGMA foreign_key_check` must be clean.
2. Input snapshot hashes are recomputed.
3. Calculation-output hashes are recomputed.
4. Kundli-analysis hashes are recomputed.
5. Numerology snapshot hashes are reconstructed from persisted governed fields and recomputed.
6. Professional report hashes are recomputed.
7. Approval hashes and signed-report bindings are recomputed.
8. Every table receives row-count + canonical SHA-256 manifest data.
9. The complete protected table set receives one overall SHA-256.

## Restore policy

v1 is deliberately `emptyWorkspaceOnly`:

- no merge;
- no overwrite;
- no automatic ID remapping;
- original IDs and foreign-key bindings are preserved;
- all rows restore in one SQLite transaction;
- post-insert foreign-key check must pass;
- post-insert protected table manifests must exactly match the decrypted backup;
- only after exact verification is a new local `encryptedBackupRestored` audit event appended.

This conservative policy prevents silent corruption of immutable calculation/report/approval identities.

## UI

Settings now links to **Encrypted backup & restore** with:

- password + confirmation for backup creation;
- explicit notice that ASTRO LOGIC cannot recover a lost password;
- encrypted backup file creation and platform share;
- native `.albackup` file selection for restore;
- restore warning and password prompt;
- bilingual completion/integrity metadata.

## Dependencies

- `cryptography: ^2.9.0`
- `file_picker: ^11.0.3`

No online backup, cloud account, server-side key escrow or password recovery is introduced in v1.

## Source validation

- `124/124` v068 source-contract/readiness checks passed.
- `140` Dart source/test/tool files were scanned for relative-import and lexical-structure issues with zero issues.
- Independent Python reference simulation of the frozen Argon2id + AES-GCM contract passed round-trip, wrong-password rejection, ciphertext-tamper rejection and AAD-header-tamper rejection. This is not claimed as Flutter/Dart runtime execution.
- Static build-readiness errors: `0`; known warnings remain large-file maintainability and generation/retention of `pubspec.lock` at the final Flutter build checkpoint.

## Next milestone

**Backup Restore Preview & Conflict/Migration Planner v1** — decrypt/validate without mutation, show source app/schema/table counts/manifest before restore, and design a governed future migration path for non-empty workspaces without weakening immutable IDs or approvals.
