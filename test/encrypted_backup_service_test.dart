import 'package:flutter_test/flutter_test.dart';

import 'package:astro_logic/src/data/app_database.dart';
import 'package:astro_logic/src/models/encrypted_backup.dart';
import 'package:astro_logic/src/services/encrypted_backup_service.dart';

void main() {
  test('encrypted backup v1 keeps cryptography and bumps reader engine', () {
    expect(
      EncryptedBackupService.contractVersion,
      'astro-logic-encrypted-backup-v1',
    );
    expect(
      EncryptedBackupService.payloadContractVersion,
      'astro-logic-backup-payload-v1',
    );
    expect(EncryptedBackupService.engineVersion, '1.4.0');
    expect(
      EncryptedBackupService.supportedReaderEngineVersions,
      containsAll(<String>['1.0.0', '1.1.0', '1.2.0', '1.3.0', '1.4.0']),
    );
    expect(EncryptedBackupService.kdfAlgorithm, 'Argon2id');
    expect(EncryptedBackupService.kdfMemoryKiB, 19 * 1024);
    expect(EncryptedBackupService.kdfParallelism, 1);
    expect(EncryptedBackupService.kdfIterations, 2);
    expect(EncryptedBackupService.kdfKeyLength, 32);
    expect(EncryptedBackupService.cipherAlgorithm, 'AES-256-GCM');
    expect(EncryptedBackupService.fileExtension, 'albackup');
    expect(EncryptedBackupService.maxEncryptedBackupBytes, 128 * 1024 * 1024);
    expect(AppDatabase.schemaVersion, 12);
    expect(
      EncryptedBackupService.mergeContractVersion,
      'astro-logic-governed-backup-merge-v1',
    );
    expect(
      EncryptedBackupService.importLedgerContractVersion,
      'astro-logic-backup-import-ledger-v1',
    );
    expect(
      EncryptedBackupService.mergeReceiptContractVersion,
      'astro-logic-backup-merge-receipt-v1',
    );
    expect(EncryptedBackupService.supportedMergeSourceSchemas, containsAll(<int>[9, 10, 11, 12]));
  });

  test('encrypted backup covers all governed user-data tables', () {
    expect(
      EncryptedBackupService.protectedTables,
      containsAll(<String>[
        'clients',
        'birth_records',
        'astrology_settings',
        'audit_events',
        'calculation_snapshots',
        'consultations',
        'calculation_output_snapshots',
        'gemstone_remedies',
        'kundli_analysis_snapshots',
        'numerology_snapshots',
        'professional_report_snapshots',
        'professional_report_approvals',
        'kp_horary_snapshots',
      ]),
    );
    expect(
      EncryptedBackupService.protectedTables.toSet().length,
      EncryptedBackupService.protectedTables.length,
    );
    expect(
      EncryptedBackupService.sensitiveWorkspaceTables,
      isNot(contains('astrology_settings')),
    );
  });

  test('preview eligibility separates empty restore from governed merge', () {
    final eligible = EncryptedBackupPreview(
      sourceAppVersion: '0.64.0+68',
      sourceEngineVersion: '1.0.0',
      sourceDatabaseSchemaVersion: 10,
      backupCreatedAtUtc: DateTime.utc(2026, 8, 10),
      manifestHash: List.filled(64, 'a').join(),
      manifestVerified: true,
      snapshotIntegrityVerified: true,
      tableRowCounts: const {'clients': 1},
      localTableRowCounts: const {'clients': 0, 'astrology_settings': 1},
      localSensitiveRowCount: 0,
      tablePlans: const [],
      eligibility: BackupRestoreEligibility.eligibleEmptyWorkspace,
      migrationSummary: 'eligible',
      mergeExecutable: false,
      databaseMutationPerformed: false,
    );
    expect(eligible.canRestoreNow, isTrue);
    expect(eligible.mergeExecutable, isFalse);
    expect(eligible.databaseMutationPerformed, isFalse);

    final mergeEligible = EncryptedBackupPreview(
      sourceAppVersion: '0.65.0+69',
      sourceEngineVersion: '1.1.0',
      sourceDatabaseSchemaVersion: 9,
      backupCreatedAtUtc: DateTime.utc(2026, 8, 10),
      manifestHash: List.filled(64, 'c').join(),
      manifestVerified: true,
      snapshotIntegrityVerified: true,
      tableRowCounts: const {'clients': 1},
      localTableRowCounts: const {'clients': 2, 'astrology_settings': 1},
      localSensitiveRowCount: 2,
      tablePlans: const [],
      eligibility: BackupRestoreEligibility.eligibleGovernedMerge,
      migrationSummary: 'merge',
      mergeExecutable: true,
      databaseMutationPerformed: false,
    );
    expect(mergeEligible.canRestoreNow, isFalse);
    expect(mergeEligible.canMergeNow, isTrue);

    final blocked = EncryptedBackupPreview(
      sourceAppVersion: '0.64.0+68',
      sourceEngineVersion: '1.0.0',
      sourceDatabaseSchemaVersion: 9,
      backupCreatedAtUtc: DateTime.utc(2026, 8, 10),
      manifestHash: List.filled(64, 'b').join(),
      manifestVerified: true,
      snapshotIntegrityVerified: true,
      tableRowCounts: const {'clients': 1},
      localTableRowCounts: const {'clients': 1, 'astrology_settings': 1},
      localSensitiveRowCount: 1,
      tablePlans: const [],
      eligibility: BackupRestoreEligibility.blockedNonEmptyWorkspace,
      migrationSummary: 'blocked',
      mergeExecutable: false,
      databaseMutationPerformed: false,
    );
    expect(blocked.canRestoreNow, isFalse);
  });
}
