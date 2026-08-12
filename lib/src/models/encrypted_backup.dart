enum BackupRestoreEligibility {
  eligibleEmptyWorkspace,
  eligibleGovernedMerge,
  blockedNonEmptyWorkspace,
  requiresSchemaMigration,
  unsupportedBackup,
}

enum BackupConflictSeverity { none, equivalent, warning, blocking }

enum BackupImportBatchStatus { started, committed, failed }

enum BackupImportMappingResolution { inserted, equivalent, remapped }

class EncryptedBackupArtifact {
  const EncryptedBackupArtifact({
    required this.fileName,
    required this.filePath,
    required this.sha256,
    required this.byteLength,
    required this.createdAtUtc,
    required this.manifestHash,
    required this.tableRowCounts,
  });

  final String fileName;
  final String filePath;
  final String sha256;
  final int byteLength;
  final DateTime createdAtUtc;
  final String manifestHash;
  final Map<String, int> tableRowCounts;
}

class BackupTableConflictPlan {
  const BackupTableConflictPlan({
    required this.tableName,
    required this.incomingRows,
    required this.localRows,
    required this.newIds,
    required this.equivalentIds,
    required this.conflictingIds,
    required this.remappedIds,
    required this.severity,
    required this.note,
  });

  final String tableName;
  final int incomingRows;
  final int localRows;
  final int newIds;
  final int equivalentIds;
  final int conflictingIds;
  final int remappedIds;
  final BackupConflictSeverity severity;
  final String note;

  bool get hasCollision => equivalentIds > 0 || conflictingIds > 0;
}

class EncryptedBackupPreview {
  const EncryptedBackupPreview({
    required this.sourceAppVersion,
    required this.sourceEngineVersion,
    required this.sourceDatabaseSchemaVersion,
    required this.backupCreatedAtUtc,
    required this.manifestHash,
    required this.manifestVerified,
    required this.snapshotIntegrityVerified,
    required this.tableRowCounts,
    required this.localTableRowCounts,
    required this.localSensitiveRowCount,
    required this.tablePlans,
    required this.eligibility,
    required this.migrationSummary,
    required this.mergeExecutable,
    required this.databaseMutationPerformed,
  });

  final String sourceAppVersion;
  final String sourceEngineVersion;
  final int sourceDatabaseSchemaVersion;
  final DateTime backupCreatedAtUtc;
  final String manifestHash;
  final bool manifestVerified;
  final bool snapshotIntegrityVerified;
  final Map<String, int> tableRowCounts;
  final Map<String, int> localTableRowCounts;
  final int localSensitiveRowCount;
  final List<BackupTableConflictPlan> tablePlans;
  final BackupRestoreEligibility eligibility;
  final String migrationSummary;
  final bool mergeExecutable;
  final bool databaseMutationPerformed;

  bool get canRestoreNow =>
      eligibility == BackupRestoreEligibility.eligibleEmptyWorkspace &&
      manifestVerified &&
      snapshotIntegrityVerified &&
      !databaseMutationPerformed;

  bool get canMergeNow =>
      eligibility == BackupRestoreEligibility.eligibleGovernedMerge &&
      manifestVerified &&
      snapshotIntegrityVerified &&
      mergeExecutable &&
      !databaseMutationPerformed;

  int get incomingProtectedRows =>
      tableRowCounts.values.fold<int>(0, (total, count) => total + count);

  int get localProtectedRows =>
      localTableRowCounts.values.fold<int>(0, (total, count) => total + count);

  int get conflictingIdCount => tablePlans.fold<int>(
        0,
        (total, plan) => total + plan.conflictingIds,
      );

  int get equivalentIdCount => tablePlans.fold<int>(
        0,
        (total, plan) => total + plan.equivalentIds,
      );
}

class EncryptedBackupRestoreResult {
  const EncryptedBackupRestoreResult({
    required this.backupCreatedAtUtc,
    required this.restoredAtUtc,
    required this.manifestHash,
    required this.tableRowCounts,
    required this.importedAuditEvents,
  });

  final DateTime backupCreatedAtUtc;
  final DateTime restoredAtUtc;
  final String manifestHash;
  final Map<String, int> tableRowCounts;
  final int importedAuditEvents;
}


class EncryptedBackupMergeResult {
  const EncryptedBackupMergeResult({
    required this.batchId,
    required this.sourceAppVersion,
    required this.sourceDatabaseSchemaVersion,
    required this.backupCreatedAtUtc,
    required this.mergedAtUtc,
    required this.manifestHash,
    required this.insertedRows,
    required this.equivalentRowsSkipped,
    required this.remappedRows,
    required this.importedAuditEvents,
    required this.mappingRows,
    required this.receiptHash,
    required this.transactionalRollbackPolicy,
  });

  final int batchId;
  final String sourceAppVersion;
  final int sourceDatabaseSchemaVersion;
  final DateTime backupCreatedAtUtc;
  final DateTime mergedAtUtc;
  final String manifestHash;
  final int insertedRows;
  final int equivalentRowsSkipped;
  final int remappedRows;
  final int importedAuditEvents;
  final int mappingRows;
  final String receiptHash;
  final String transactionalRollbackPolicy;
}

class BackupImportBatchRecord {
  const BackupImportBatchRecord({
    required this.id,
    required this.manifestHash,
    required this.sourceAppVersion,
    required this.sourceEngineVersion,
    required this.sourceDatabaseSchemaVersion,
    required this.backupCreatedAtUtc,
    required this.startedAtUtc,
    required this.completedAtUtc,
    required this.status,
    required this.insertedRows,
    required this.equivalentRows,
    required this.remappedRows,
    required this.importedAuditEvents,
    required this.mappingRows,
    required this.rollbackPolicy,
    required this.sourceIntegrityIdsPreserved,
    required this.diagnosticsJson,
    required this.receiptHash,
  });

  factory BackupImportBatchRecord.fromDatabaseMap(Map<String, Object?> row) {
    final rawStatus = row['status'] as String;
    return BackupImportBatchRecord(
      id: row['id']! as int,
      manifestHash: row['manifest_hash']! as String,
      sourceAppVersion: row['source_app_version']! as String,
      sourceEngineVersion: row['source_engine_version']! as String,
      sourceDatabaseSchemaVersion: row['source_database_schema_version']! as int,
      backupCreatedAtUtc: DateTime.parse(row['backup_created_at']! as String).toUtc(),
      startedAtUtc: DateTime.parse(row['started_at']! as String).toUtc(),
      completedAtUtc: row['completed_at'] == null
          ? null
          : DateTime.parse(row['completed_at']! as String).toUtc(),
      status: BackupImportBatchStatus.values.byName(rawStatus),
      insertedRows: row['inserted_rows']! as int,
      equivalentRows: row['equivalent_rows']! as int,
      remappedRows: row['remapped_rows']! as int,
      importedAuditEvents: row['imported_audit_events']! as int,
      mappingRows: row['mapping_rows']! as int,
      rollbackPolicy: row['rollback_policy']! as String,
      sourceIntegrityIdsPreserved: (row['source_integrity_ids_preserved']! as int) == 1,
      diagnosticsJson: row['diagnostics_json']! as String,
      receiptHash: row['receipt_hash'] as String?,
    );
  }

  final int id;
  final String manifestHash;
  final String sourceAppVersion;
  final String sourceEngineVersion;
  final int sourceDatabaseSchemaVersion;
  final DateTime backupCreatedAtUtc;
  final DateTime startedAtUtc;
  final DateTime? completedAtUtc;
  final BackupImportBatchStatus status;
  final int insertedRows;
  final int equivalentRows;
  final int remappedRows;
  final int importedAuditEvents;
  final int mappingRows;
  final String rollbackPolicy;
  final bool sourceIntegrityIdsPreserved;
  final String diagnosticsJson;
  final String? receiptHash;

  bool get isTerminal => status != BackupImportBatchStatus.started;
}

class BackupImportMappingRecord {
  const BackupImportMappingRecord({
    required this.id,
    required this.batchId,
    required this.tableName,
    required this.sourceId,
    required this.localId,
    required this.resolution,
    required this.sourceRowSha256,
    required this.localRowSha256,
    required this.createdAtUtc,
  });

  factory BackupImportMappingRecord.fromDatabaseMap(Map<String, Object?> row) =>
      BackupImportMappingRecord(
        id: row['id']! as int,
        batchId: row['batch_id']! as int,
        tableName: row['table_name']! as String,
        sourceId: row['source_id']! as int,
        localId: row['local_id']! as int,
        resolution: BackupImportMappingResolution.values.byName(
          row['resolution']! as String,
        ),
        sourceRowSha256: row['source_row_sha256']! as String,
        localRowSha256: row['local_row_sha256']! as String,
        createdAtUtc: DateTime.parse(row['created_at']! as String).toUtc(),
      );

  final int id;
  final int batchId;
  final String tableName;
  final int sourceId;
  final int localId;
  final BackupImportMappingResolution resolution;
  final String sourceRowSha256;
  final String localRowSha256;
  final DateTime createdAtUtc;
}

class BackupMergeReceiptArtifact {
  const BackupMergeReceiptArtifact({
    required this.batchId,
    required this.fileName,
    required this.filePath,
    required this.receiptHash,
    required this.byteLength,
  });

  final int batchId;
  final String fileName;
  final String filePath;
  final String receiptHash;
  final int byteLength;
}

class EncryptedBackupException implements Exception {
  const EncryptedBackupException(this.message);

  final String message;

  @override
  String toString() => 'EncryptedBackupException: $message';
}
