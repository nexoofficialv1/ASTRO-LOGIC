import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:cryptography/cryptography.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../data/app_database.dart';
import '../models/encrypted_backup.dart';
import 'professional_report_approval_policy.dart';
import 'snapshot_integrity.dart';

part 'encrypted_backup_merge_support.dart';
part 'encrypted_backup_envelope_support.dart';
part 'encrypted_backup_integrity_support.dart';

class EncryptedBackupService {
  const EncryptedBackupService(this._database);

  static const contractVersion = 'astro-logic-encrypted-backup-v1';
  static const payloadContractVersion = 'astro-logic-backup-payload-v1';
  static const engineId = 'astro-logic-encrypted-backup';
  static const engineVersion = '1.4.0';
  static const supportedReaderEngineVersions = {'1.0.0', '1.1.0', '1.2.0', '1.3.0', '1.4.0'};
  static const mergeContractVersion = 'astro-logic-governed-backup-merge-v1';
  static const importLedgerContractVersion = 'astro-logic-backup-import-ledger-v1';
  static const mergeReceiptContractVersion = 'astro-logic-backup-merge-receipt-v1';
  static const supportedMergeSourceSchemas = {9, 10, 11, 12};
  static const fileExtension = 'albackup';
  static const maxEncryptedBackupBytes = 128 * 1024 * 1024;

  static const kdfAlgorithm = 'Argon2id';
  static const kdfMemoryKiB = 19 * 1024;
  static const kdfParallelism = 1;
  static const kdfIterations = 2;
  static const kdfKeyLength = 32;
  static const kdfSaltLength = 16;
  static const cipherAlgorithm = 'AES-256-GCM';

  static const List<String> legacyProtectedTablesV1 = [
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
  ];

  static const List<String> protectedTables = [
    ...legacyProtectedTablesV1,
    'kp_horary_snapshots',
  ];

  static List<String> protectedTablesForSchema(int schemaVersion) =>
      schemaVersion >= 12 ? protectedTables : legacyProtectedTablesV1;

  static const List<String> sensitiveWorkspaceTables = [
    'clients',
    'birth_records',
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
  ];

  static const List<String> _restoreOrder = [
    'clients',
    'birth_records',
    'calculation_snapshots',
    'consultations',
    'calculation_output_snapshots',
    'gemstone_remedies',
    'kundli_analysis_snapshots',
    'numerology_snapshots',
    'professional_report_snapshots',
    'professional_report_approvals',
    'kp_horary_snapshots',
    'audit_events',
  ];

  final Database _database;

  Future<EncryptedBackupArtifact> createEncryptedBackup({
    required String password,
    Directory? outputDirectory,
    DateTime? createdAtUtc,
  }) async {
    _validatePassword(password);
    final createdAt = (createdAtUtc ?? DateTime.now()).toUtc();
    final foreignKeyIssues = await _database.rawQuery('PRAGMA foreign_key_check');
    if (foreignKeyIssues.isNotEmpty) {
      throw const EncryptedBackupException(
        'Local database failed foreign-key validation; backup was not created.',
      );
    }
    final tables = await _readAllProtectedTables(_database);
    _validateProtectedSnapshotHashes(tables);
    final manifest = _buildManifest(tables);
    final manifestHash = manifest['overallSha256']! as String;
    final payload = <String, Object?>{
      'contract': payloadContractVersion,
      'engineId': engineId,
      'engineVersion': engineVersion,
      'appVersion': '0.76.0+80',
      'databaseSchemaVersion': AppDatabase.schemaVersion,
      'createdAtUtc': createdAt.toIso8601String(),
      'tables': tables,
      'manifest': manifest,
      'restorePolicy': {
        'mode': 'emptyWorkspaceOrGovernedMerge',
        'mergeEnabled': true,
        'mergeContract': mergeContractVersion,
        'overwriteExistingRecords': false,
        'automaticIdRemap': true,
      },
    };

    final salt = _randomBytes(kdfSaltLength);
    final secretKey = await _deriveKey(password: password, salt: salt);
    final cipher = AesGcm.with256bits();
    final authenticatedHeader = _buildAuthenticatedHeader(
      createdAt: createdAt,
      salt: salt,
      cipher: cipher,
    );
    final nonce = cipher.newNonce();
    late final SecretBox secretBox;
    try {
      secretBox = await cipher.encrypt(
        utf8.encode(_canonicalJson(payload)),
        secretKey: secretKey,
        nonce: nonce,
        aad: utf8.encode(_canonicalJson(authenticatedHeader)),
      );
    } finally {
      secretKey.destroy();
    }
    final cipherHeader = Map<String, Object?>.from(
      authenticatedHeader['cipher']! as Map,
    );
    final envelope = <String, Object?>{
      ...authenticatedHeader,
      'cipher': {
        ...cipherHeader,
        'secretBoxBase64': base64Encode(secretBox.concatenation()),
      },
    };
    final bytes = utf8.encode(_canonicalJson(envelope));
    if (bytes.length > maxEncryptedBackupBytes) {
      throw const EncryptedBackupException(
        'Encrypted backup exceeds the v1 portable-backup size limit.',
      );
    }
    final directory = outputDirectory ?? await _defaultDirectory();
    await directory.create(recursive: true);
    final stamp = createdAt
        .toIso8601String()
        .replaceAll(':', '-')
        .replaceAll('.', '-');
    final fileName = 'astro_logic_backup_$stamp.$fileExtension';
    final file = File(p.join(directory.path, fileName));
    await file.writeAsBytes(bytes, flush: true);
    final digest = sha256.convert(bytes).toString();

    await _database.insert('audit_events', {
      'entity_type': 'backup',
      'entity_id': null,
      'action': 'encryptedBackupCreated',
      'summary_json': jsonEncode({
        'contract': contractVersion,
        'engineVersion': engineVersion,
        'manifestHash': manifestHash,
        'backupFileSha256': digest,
        'rowCounts': _rowCounts(tables),
        'passwordStored': false,
      }),
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });

    return EncryptedBackupArtifact(
      fileName: fileName,
      filePath: file.path,
      sha256: digest,
      byteLength: bytes.length,
      createdAtUtc: createdAt,
      manifestHash: manifestHash,
      tableRowCounts: _rowCounts(tables),
    );
  }

  Future<EncryptedBackupPreview> previewEncryptedBackup({
    required List<int> encryptedBytes,
    required String password,
  }) async {
    _validatePassword(password);
    if (encryptedBytes.isEmpty ||
        encryptedBytes.length > maxEncryptedBackupBytes) {
      throw const EncryptedBackupException(
        'Encrypted backup file is empty or exceeds the v1 size limit.',
      );
    }

    final envelope = _decodeEnvelope(encryptedBytes);
    final payload = await _decryptPayload(envelope, password);
    _validatePreviewPayloadBase(payload);

    final sourceSchemaVersion = payload['databaseSchemaVersion']! as int;
    final sourceAppVersion = payload['appVersion']! as String;
    final sourceEngineVersion = payload['engineVersion']! as String;
    final backupCreatedAt =
        DateTime.parse(payload['createdAtUtc']! as String).toUtc();
    final rawTables = Map<String, Object?>.from(payload['tables']! as Map);
    final manifest = Map<String, Object?>.from(payload['manifest']! as Map);

    _verifyRawManifest(
      rawTables,
      manifest,
      databaseSchemaVersion: sourceSchemaVersion,
    );
    final manifestHash = manifest['overallSha256'];
    if (manifestHash is! String || manifestHash.length != 64) {
      throw const EncryptedBackupException(
        'Backup overall manifest hash is invalid.',
      );
    }

    final tableRowCounts = _rowCountsFromRawTables(rawTables);
    final localTables = await _readAllProtectedTables(_database);
    final localTableRowCounts = _rowCounts(localTables);
    final localSensitiveRows = _sensitiveWorkspaceRowCount(localTables);

    var snapshotIntegrityVerified = false;
    var tablePlans = const <BackupTableConflictPlan>[];
    var mergeExecutable = false;
    late final BackupRestoreEligibility eligibility;
    late final String migrationSummary;

    if (supportedMergeSourceSchemas.contains(sourceSchemaVersion)) {
      final tables = _tablesFromPayload(payload);
      _verifyManifest(
        tables,
        manifest,
        databaseSchemaVersion: sourceSchemaVersion,
      );
      _validateProtectedSnapshotHashes(tables);
      snapshotIntegrityVerified = true;
      final mergePlan = _buildGovernedMergePlan(
        incomingTables: tables,
        localTables: localTables,
        manifestHash: manifestHash,
      );
      tablePlans = mergePlan.tablePlans;
      final alreadyImported = await _hasCommittedImportBatch(manifestHash) ||
          _hasImportedManifest(localTables, manifestHash);
      final exactCurrentSchema = sourceSchemaVersion == AppDatabase.schemaVersion;
      if (localSensitiveRows == 0 && exactCurrentSchema) {
        eligibility = BackupRestoreEligibility.eligibleEmptyWorkspace;
        migrationSummary =
            'Current schema and integrity contracts match. Empty-workspace restore is eligible; governed merge is not needed.';
      } else if (alreadyImported) {
        eligibility = BackupRestoreEligibility.blockedNonEmptyWorkspace;
        migrationSummary =
            'This backup manifest is already recorded as a governed merge in the local audit history. Duplicate import is blocked.';
      } else if (mergePlan.hasBlockingConflicts) {
        eligibility = BackupRestoreEligibility.blockedNonEmptyWorkspace;
        migrationSummary =
            'At least one immutable unique identity collides with different content. Deterministic primary-key remapping cannot resolve that semantic conflict safely.';
      } else {
        eligibility = BackupRestoreEligibility.eligibleGovernedMerge;
        mergeExecutable = true;
        migrationSummary = sourceSchemaVersion == AppDatabase.schemaVersion
            ? 'Governed merge v1 can execute transactionally. Existing rows are never overwritten; equivalent rows are reused and primary-key collisions are deterministically remapped.'
            : 'Older supported backup schemas are adapted through the governed merge path. Source integrity IDs remain preserved while local foreign keys are deterministically remapped.';
      }
    } else {
      eligibility = BackupRestoreEligibility.requiresSchemaMigration;
      migrationSummary = sourceSchemaVersion < AppDatabase.schemaVersion
          ? 'The backup schema is older than the supported governed migration range. A dedicated migration adapter is required.'
          : 'The backup uses a newer database schema than this app and cannot be interpreted safely.';
    }

    return EncryptedBackupPreview(
      sourceAppVersion: sourceAppVersion,
      sourceEngineVersion: sourceEngineVersion,
      sourceDatabaseSchemaVersion: sourceSchemaVersion,
      backupCreatedAtUtc: backupCreatedAt,
      manifestHash: manifestHash,
      manifestVerified: true,
      snapshotIntegrityVerified: snapshotIntegrityVerified,
      tableRowCounts: tableRowCounts,
      localTableRowCounts: localTableRowCounts,
      localSensitiveRowCount: localSensitiveRows,
      tablePlans: tablePlans,
      eligibility: eligibility,
      migrationSummary: migrationSummary,
      mergeExecutable: mergeExecutable,
      databaseMutationPerformed: false,
    );
  }

  Future<EncryptedBackupRestoreResult> restoreEncryptedBackup({
    required List<int> encryptedBytes,
    required String password,
    DateTime? restoredAtUtc,
  }) async {
    _validatePassword(password);
    if (encryptedBytes.isEmpty || encryptedBytes.length > maxEncryptedBackupBytes) {
      throw const EncryptedBackupException(
        'Encrypted backup file is empty or exceeds the v1 size limit.',
      );
    }
    final envelope = _decodeEnvelope(encryptedBytes);
    final payload = await _decryptPayload(envelope, password);
    _validatePayload(payload);

    final tables = _tablesFromPayload(payload);
    _verifyManifest(
      tables,
      payload['manifest'],
      databaseSchemaVersion: payload['databaseSchemaVersion']! as int,
    );
    _validateProtectedSnapshotHashes(tables);
    await _requireEmptyWorkspace(_database);

    final restoredAt = (restoredAtUtc ?? DateTime.now()).toUtc();
    final manifest = Map<String, Object?>.from(payload['manifest']! as Map);
    final manifestHash = manifest['overallSha256']! as String;
    final backupCreatedAt = DateTime.parse(payload['createdAtUtc']! as String).toUtc();

    await _database.transaction((transaction) async {
      final settingsRows = tables['astrology_settings']!;
      if (settingsRows.length != 1) {
        throw const EncryptedBackupException(
          'Backup must contain exactly one astrology settings row.',
        );
      }
      await transaction.update(
        'astrology_settings',
        settingsRows.single,
        where: 'id = ?',
        whereArgs: [1],
      );

      for (final table in _restoreOrder) {
        for (final row in tables[table]!) {
          await transaction.insert(table, row);
        }
      }

      final foreignKeyIssues = await transaction.rawQuery('PRAGMA foreign_key_check');
      if (foreignKeyIssues.isNotEmpty) {
        throw const EncryptedBackupException(
          'Restored data failed SQLite foreign-key validation.',
        );
      }

      final restoredTables = await _readAllProtectedTables(transaction);
      // The restore audit event is appended only after this exact-content check.
      _verifyTableSetAgainstManifest(
        restoredTables,
        manifest,
        databaseSchemaVersion: AppDatabase.schemaVersion,
      );

      await transaction.insert('audit_events', {
        'entity_type': 'backup',
        'entity_id': null,
        'action': 'encryptedBackupRestored',
        'summary_json': jsonEncode({
          'contract': contractVersion,
          'engineVersion': engineVersion,
          'manifestHash': manifestHash,
          'backupCreatedAtUtc': backupCreatedAt.toIso8601String(),
          'restoreMode': 'emptyWorkspaceOnly',
          'importedAuditEvents': tables['audit_events']!.length,
        }),
        'created_at': restoredAt.toIso8601String(),
      });
    });

    return EncryptedBackupRestoreResult(
      backupCreatedAtUtc: backupCreatedAt,
      restoredAtUtc: restoredAt,
      manifestHash: manifestHash,
      tableRowCounts: _rowCounts(tables),
      importedAuditEvents: tables['audit_events']!.length,
    );
  }

  Future<EncryptedBackupMergeResult> mergeEncryptedBackup({
    required List<int> encryptedBytes,
    required String password,
    DateTime? mergedAtUtc,
  }) async {
    _validatePassword(password);
    if (encryptedBytes.isEmpty ||
        encryptedBytes.length > maxEncryptedBackupBytes) {
      throw const EncryptedBackupException(
        'Encrypted backup file is empty or exceeds the v1 size limit.',
      );
    }
    final envelope = _decodeEnvelope(encryptedBytes);
    final payload = await _decryptPayload(envelope, password);
    _validatePreviewPayloadBase(payload);
    final sourceSchemaVersion = payload['databaseSchemaVersion']! as int;
    if (!supportedMergeSourceSchemas.contains(sourceSchemaVersion)) {
      throw const EncryptedBackupException(
        'This backup schema is outside the governed merge adapter range.',
      );
    }
    final sourceAppVersion = payload['appVersion']! as String;
    final sourceEngineVersion = payload['engineVersion']! as String;
    final backupCreatedAt =
        DateTime.parse(payload['createdAtUtc']! as String).toUtc();
    final manifest = Map<String, Object?>.from(payload['manifest']! as Map);
    final manifestHash = manifest['overallSha256'];
    if (manifestHash is! String || manifestHash.length != 64) {
      throw const EncryptedBackupException('Backup manifest hash is invalid.');
    }
    final tables = _tablesFromPayload(payload);
    _verifyManifest(
      tables,
      manifest,
      databaseSchemaVersion: sourceSchemaVersion,
    );
    _validateProtectedSnapshotHashes(tables);

    final localTables = await _readAllProtectedTables(_database);
    if (await _hasCommittedImportBatch(manifestHash) ||
        _hasImportedManifest(localTables, manifestHash)) {
      throw const EncryptedBackupException(
        'This backup manifest has already been imported into the local workspace.',
      );
    }
    final plan = _buildGovernedMergePlan(
      incomingTables: tables,
      localTables: localTables,
      manifestHash: manifestHash,
    );
    if (plan.hasBlockingConflicts) {
      throw const EncryptedBackupException(
        'Governed merge is blocked by an immutable unique-identity conflict.',
      );
    }

    final mergedAt = (mergedAtUtc ?? DateTime.now()).toUtc();
    final batchId = await _database.insert('backup_import_batches', {
      'manifest_hash': manifestHash,
      'source_app_version': sourceAppVersion,
      'source_engine_version': sourceEngineVersion,
      'source_database_schema_version': sourceSchemaVersion,
      'backup_created_at': backupCreatedAt.toIso8601String(),
      'started_at': mergedAt.toIso8601String(),
      'completed_at': null,
      'status': BackupImportBatchStatus.started.name,
      'inserted_rows': 0,
      'equivalent_rows': 0,
      'remapped_rows': 0,
      'imported_audit_events': 0,
      'mapping_rows': 0,
      'rollback_policy': 'allOrNothing',
      'source_integrity_ids_preserved': 1,
      'diagnostics_json': jsonEncode({
        'ledgerContract': importLedgerContractVersion,
        'mergeContract': mergeContractVersion,
        'phase': 'started',
        'plannedMappings': plan.mappingDrafts.length,
        'plannedInsertedRows': plan.insertedRows,
        'plannedEquivalentRows': plan.equivalentRows,
        'plannedRemappedRows': plan.remappedRows,
      }),
      'receipt_hash': null,
    });

    final receiptMappings = [...plan.mappingDrafts]
      ..sort((a, b) {
        final tableCompare = a.tableName.compareTo(b.tableName);
        return tableCompare != 0
            ? tableCompare
            : a.sourceId.compareTo(b.sourceId);
      });
    final receiptBody = _buildMergeReceiptBody(
      batchId: batchId,
      manifestHash: manifestHash,
      sourceAppVersion: sourceAppVersion,
      sourceEngineVersion: sourceEngineVersion,
      sourceDatabaseSchemaVersion: sourceSchemaVersion,
      backupCreatedAtUtc: backupCreatedAt,
      mergedAtUtc: mergedAt,
      insertedRows: plan.insertedRows,
      equivalentRows: plan.equivalentRows,
      remappedRows: plan.remappedRows,
      importedAuditEvents: plan.importedAuditEvents,
      mappings: receiptMappings,
    );
    final receiptHash = _sha256Canonical(receiptBody);

    try {
      await _database.transaction((transaction) async {
        for (final table in _restoreOrder) {
          for (final row in plan.rowsToInsert[table]!) {
            await transaction.insert(table, row);
          }
        }

        for (final mapping in plan.mappingDrafts) {
          await transaction.insert('backup_import_mappings', {
            'batch_id': batchId,
            'table_name': mapping.tableName,
            'source_id': mapping.sourceId,
            'local_id': mapping.localId,
            'resolution': mapping.resolution.name,
            'source_row_sha256': mapping.sourceRowSha256,
            'local_row_sha256': mapping.localRowSha256,
            'created_at': mergedAt.toIso8601String(),
          });
        }

        final foreignKeyIssues =
            await transaction.rawQuery('PRAGMA foreign_key_check');
        if (foreignKeyIssues.isNotEmpty) {
          throw const EncryptedBackupException(
            'Governed merge failed SQLite foreign-key validation.',
          );
        }

        final mergedTables = await _readAllProtectedTables(transaction);
        _validateProtectedSnapshotHashes(mergedTables);

        final batchUpdated = await transaction.update(
          'backup_import_batches',
          {
            'completed_at': mergedAt.toIso8601String(),
            'status': BackupImportBatchStatus.committed.name,
            'inserted_rows': plan.insertedRows,
            'equivalent_rows': plan.equivalentRows,
            'remapped_rows': plan.remappedRows,
            'imported_audit_events': plan.importedAuditEvents,
            'mapping_rows': plan.mappingDrafts.length,
            'diagnostics_json': jsonEncode({
              'ledgerContract': importLedgerContractVersion,
              'mergeContract': mergeContractVersion,
              'result': 'committed',
              'foreignKeyValidation': 'passed',
              'governedHashValidation': 'passed',
              'duplicateManifestProtection': true,
            }),
            'receipt_hash': receiptHash,
          },
          where: 'id = ? AND status = ?',
          whereArgs: [batchId, BackupImportBatchStatus.started.name],
        );
        if (batchUpdated != 1) {
          throw const EncryptedBackupException(
            'Import batch ledger could not be terminalized atomically.',
          );
        }

        await transaction.insert('audit_events', {
          'entity_type': 'backup',
          'entity_id': batchId,
          'action': 'governedBackupMerged',
          'summary_json': jsonEncode({
            'mergeContract': mergeContractVersion,
            'ledgerContract': importLedgerContractVersion,
            'receiptContract': mergeReceiptContractVersion,
            'engineVersion': engineVersion,
            'batchId': batchId,
            'manifestHash': manifestHash,
            'receiptHash': receiptHash,
            'sourceAppVersion': sourceAppVersion,
            'sourceEngineVersion': sourceEngineVersion,
            'sourceDatabaseSchemaVersion': sourceSchemaVersion,
            'backupCreatedAtUtc': backupCreatedAt.toIso8601String(),
            'insertedRows': plan.insertedRows,
            'equivalentRowsSkipped': plan.equivalentRows,
            'remappedRows': plan.remappedRows,
            'mappingRows': plan.mappingDrafts.length,
            'importedAuditEvents': plan.importedAuditEvents,
            'overwriteExistingRecords': false,
            'transactionalRollback': 'allOrNothing',
            'sourceIntegrityIdsPreserved': true,
          }),
          'created_at': mergedAt.toIso8601String(),
        });
      });
    } catch (error) {
      try {
        await _markImportBatchFailed(
          batchId: batchId,
          completedAtUtc: DateTime.now().toUtc(),
          error: error,
        );
      } on Object {
        // Preserve the original merge failure if terminal diagnostics cannot be written.
      }
      rethrow;
    }

    return EncryptedBackupMergeResult(
      batchId: batchId,
      sourceAppVersion: sourceAppVersion,
      sourceDatabaseSchemaVersion: sourceSchemaVersion,
      backupCreatedAtUtc: backupCreatedAt,
      mergedAtUtc: mergedAt,
      manifestHash: manifestHash,
      insertedRows: plan.insertedRows,
      equivalentRowsSkipped: plan.equivalentRows,
      remappedRows: plan.remappedRows,
      importedAuditEvents: plan.importedAuditEvents,
      mappingRows: plan.mappingDrafts.length,
      receiptHash: receiptHash,
      transactionalRollbackPolicy: 'allOrNothing',
    );
  }

  Future<List<BackupImportBatchRecord>> listImportBatches({
    bool recoverInterrupted = true,
  }) async {
    if (recoverInterrupted) {
      await recoverInterruptedImportBatches();
    }
    final rows = await _database.query(
      'backup_import_batches',
      orderBy: 'started_at DESC, id DESC',
    );
    return rows
        .map(BackupImportBatchRecord.fromDatabaseMap)
        .toList(growable: false);
  }

  Future<List<BackupImportMappingRecord>> listImportMappings(int batchId) async {
    final rows = await _database.query(
      'backup_import_mappings',
      where: 'batch_id = ?',
      whereArgs: [batchId],
      orderBy: 'table_name ASC, source_id ASC',
    );
    return rows
        .map(BackupImportMappingRecord.fromDatabaseMap)
        .toList(growable: false);
  }

  Future<int> recoverInterruptedImportBatches({DateTime? recoveredAtUtc}) async {
    final recoveredAt = (recoveredAtUtc ?? DateTime.now()).toUtc();
    final started = await _database.query(
      'backup_import_batches',
      columns: const ['id', 'diagnostics_json'],
      where: 'status = ?',
      whereArgs: [BackupImportBatchStatus.started.name],
    );
    var recovered = 0;
    for (final row in started) {
      final id = row['id']! as int;
      final updated = await _database.update(
        'backup_import_batches',
        {
          'completed_at': recoveredAt.toIso8601String(),
          'status': BackupImportBatchStatus.failed.name,
          'diagnostics_json': jsonEncode({
            'ledgerContract': importLedgerContractVersion,
            'result': 'failed',
            'failureCode': 'interrupted_before_terminalization',
            'detail': 'A previous merge attempt did not reach an atomic committed terminal state. SQLite transaction semantics retain no partial imported transaction.',
          }),
        },
        where: 'id = ? AND status = ?',
        whereArgs: [id, BackupImportBatchStatus.started.name],
      );
      recovered += updated;
    }
    return recovered;
  }

  Future<BackupMergeReceiptArtifact> exportMergeReceipt({
    required int batchId,
    Directory? outputDirectory,
  }) async {
    final batchRows = await _database.query(
      'backup_import_batches',
      where: 'id = ?',
      whereArgs: [batchId],
      limit: 1,
    );
    if (batchRows.isEmpty) {
      throw const EncryptedBackupException('Import batch was not found.');
    }
    final batch = BackupImportBatchRecord.fromDatabaseMap(batchRows.single);
    if (batch.status != BackupImportBatchStatus.committed ||
        batch.completedAtUtc == null ||
        batch.receiptHash == null) {
      throw const EncryptedBackupException(
        'Only committed import batches have an exportable merge receipt.',
      );
    }
    final mappings = await listImportMappings(batchId);
    final body = _buildReceiptBodyFromRecords(batch, mappings);
    final recomputed = _sha256Canonical(body);
    if (recomputed != batch.receiptHash) {
      throw const EncryptedBackupException(
        'Import ledger mapping data does not match the committed receipt hash.',
      );
    }
    final document = <String, Object?>{
      ...body,
      'receiptHash': recomputed,
    };
    final bytes = utf8.encode(_canonicalJson(document));
    final directory = outputDirectory ?? await _defaultReceiptDirectory();
    await directory.create(recursive: true);
    final fileName =
        'astro_logic_merge_receipt_batch_${batch.id}_${recomputed.substring(0, 12)}.json';
    final file = File(p.join(directory.path, fileName));
    await file.writeAsBytes(bytes, flush: true);
    return BackupMergeReceiptArtifact(
      batchId: batch.id,
      fileName: fileName,
      filePath: file.path,
      receiptHash: recomputed,
      byteLength: bytes.length,
    );
  }

  Future<bool> _hasCommittedImportBatch(String manifestHash) async {
    final rows = await _database.rawQuery(
      'SELECT COUNT(*) AS c FROM backup_import_batches WHERE manifest_hash = ? AND status = ?',
      [manifestHash, BackupImportBatchStatus.committed.name],
    );
    final value = rows.isEmpty ? null : rows.first['c'];
    return value is int && value > 0;
  }

  Future<void> _markImportBatchFailed({
    required int batchId,
    required DateTime completedAtUtc,
    required Object error,
  }) async {
    final message = error is EncryptedBackupException
        ? error.message
        : error.toString();
    await _database.update(
      'backup_import_batches',
      {
        'completed_at': completedAtUtc.toIso8601String(),
        'status': BackupImportBatchStatus.failed.name,
        'diagnostics_json': jsonEncode({
          'ledgerContract': importLedgerContractVersion,
          'result': 'failed',
          'failureCode': 'transaction_rolled_back',
          'detail': message.length > 500 ? message.substring(0, 500) : message,
          'partialImportedRowsRetained': false,
        }),
      },
      where: 'id = ? AND status = ?',
      whereArgs: [batchId, BackupImportBatchStatus.started.name],
    );
  }

}
