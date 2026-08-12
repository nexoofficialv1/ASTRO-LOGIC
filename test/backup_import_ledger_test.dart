import 'package:flutter_test/flutter_test.dart';

import 'package:astro_logic/src/models/encrypted_backup.dart';

void main() {
  test('import batch record parses committed terminal ledger row', () {
    final batch = BackupImportBatchRecord.fromDatabaseMap({
      'id': 7,
      'manifest_hash': List.filled(64, 'a').join(),
      'source_app_version': '0.66.0+70',
      'source_engine_version': '1.2.0',
      'source_database_schema_version': 10,
      'backup_created_at': '2026-08-10T00:00:00.000Z',
      'started_at': '2026-08-10T01:00:00.000Z',
      'completed_at': '2026-08-10T01:00:01.000Z',
      'status': 'committed',
      'inserted_rows': 11,
      'equivalent_rows': 3,
      'remapped_rows': 2,
      'imported_audit_events': 4,
      'mapping_rows': 14,
      'rollback_policy': 'allOrNothing',
      'source_integrity_ids_preserved': 1,
      'diagnostics_json': '{"result":"committed"}',
      'receipt_hash': List.filled(64, 'b').join(),
    });

    expect(batch.status, BackupImportBatchStatus.committed);
    expect(batch.isTerminal, isTrue);
    expect(batch.mappingRows, 14);
    expect(batch.sourceIntegrityIdsPreserved, isTrue);
    expect(batch.receiptHash, hasLength(64));
  });

  test('source to local mapping keeps row hashes and resolution', () {
    final mapping = BackupImportMappingRecord.fromDatabaseMap({
      'id': 1,
      'batch_id': 7,
      'table_name': 'clients',
      'source_id': 4,
      'local_id': 21,
      'resolution': 'remapped',
      'source_row_sha256': List.filled(64, 'c').join(),
      'local_row_sha256': List.filled(64, 'd').join(),
      'created_at': '2026-08-10T01:00:01.000Z',
    });

    expect(mapping.resolution, BackupImportMappingResolution.remapped);
    expect(mapping.sourceId, 4);
    expect(mapping.localId, 21);
    expect(mapping.sourceRowSha256, isNot(mapping.localRowSha256));
  });

  test('merge result exposes batch and receipt identity', () {
    final result = EncryptedBackupMergeResult(
      batchId: 9,
      sourceAppVersion: '0.66.0+70',
      sourceDatabaseSchemaVersion: 10,
      backupCreatedAtUtc: DateTime.utc(2026, 8, 10),
      mergedAtUtc: DateTime.utc(2026, 8, 10, 1),
      manifestHash: List.filled(64, 'e').join(),
      insertedRows: 10,
      equivalentRowsSkipped: 1,
      remappedRows: 2,
      importedAuditEvents: 3,
      mappingRows: 11,
      receiptHash: List.filled(64, 'f').join(),
      transactionalRollbackPolicy: 'allOrNothing',
    );

    expect(result.batchId, 9);
    expect(result.mappingRows, 11);
    expect(result.receiptHash, hasLength(64));
  });
}
