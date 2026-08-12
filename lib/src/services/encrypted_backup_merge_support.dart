part of 'encrypted_backup_service.dart';

Map<String, Object?> _buildMergeReceiptBody({
  required int batchId,
  required String manifestHash,
  required String sourceAppVersion,
  required String sourceEngineVersion,
  required int sourceDatabaseSchemaVersion,
  required DateTime backupCreatedAtUtc,
  required DateTime mergedAtUtc,
  required int insertedRows,
  required int equivalentRows,
  required int remappedRows,
  required int importedAuditEvents,
  required List<_BackupImportMappingDraft> mappings,
}) => <String, Object?>{
      'contract': EncryptedBackupService.mergeReceiptContractVersion,
      'ledgerContract': EncryptedBackupService.importLedgerContractVersion,
      'mergeContract': EncryptedBackupService.mergeContractVersion,
      'batchId': batchId,
      'manifestHash': manifestHash,
      'sourceAppVersion': sourceAppVersion,
      'sourceEngineVersion': sourceEngineVersion,
      'sourceDatabaseSchemaVersion': sourceDatabaseSchemaVersion,
      'backupCreatedAtUtc': backupCreatedAtUtc.toIso8601String(),
      'mergedAtUtc': mergedAtUtc.toIso8601String(),
      'insertedRows': insertedRows,
      'equivalentRows': equivalentRows,
      'remappedRows': remappedRows,
      'importedAuditEvents': importedAuditEvents,
      'mappingRows': mappings.length,
      'rollbackPolicy': 'allOrNothing',
      'sourceIntegrityIdsPreserved': true,
      'mappings': [
        for (final mapping in mappings)
          {
            'table': mapping.tableName,
            'sourceId': mapping.sourceId,
            'localId': mapping.localId,
            'resolution': mapping.resolution.name,
            'sourceRowSha256': mapping.sourceRowSha256,
            'localRowSha256': mapping.localRowSha256,
          },
      ],
    };

Map<String, Object?> _buildReceiptBodyFromRecords(
  BackupImportBatchRecord batch,
  List<BackupImportMappingRecord> mappings,
) => <String, Object?>{
      'contract': EncryptedBackupService.mergeReceiptContractVersion,
      'ledgerContract': EncryptedBackupService.importLedgerContractVersion,
      'mergeContract': EncryptedBackupService.mergeContractVersion,
      'batchId': batch.id,
      'manifestHash': batch.manifestHash,
      'sourceAppVersion': batch.sourceAppVersion,
      'sourceEngineVersion': batch.sourceEngineVersion,
      'sourceDatabaseSchemaVersion': batch.sourceDatabaseSchemaVersion,
      'backupCreatedAtUtc': batch.backupCreatedAtUtc.toIso8601String(),
      'mergedAtUtc': batch.completedAtUtc!.toIso8601String(),
      'insertedRows': batch.insertedRows,
      'equivalentRows': batch.equivalentRows,
      'remappedRows': batch.remappedRows,
      'importedAuditEvents': batch.importedAuditEvents,
      'mappingRows': batch.mappingRows,
      'rollbackPolicy': batch.rollbackPolicy,
      'sourceIntegrityIdsPreserved': batch.sourceIntegrityIdsPreserved,
      'mappings': [
        for (final mapping in mappings)
          {
            'table': mapping.tableName,
            'sourceId': mapping.sourceId,
            'localId': mapping.localId,
            'resolution': mapping.resolution.name,
            'sourceRowSha256': mapping.sourceRowSha256,
            'localRowSha256': mapping.localRowSha256,
          },
      ],
    };

_GovernedMergePlan _buildGovernedMergePlan({
  required Map<String, List<Map<String, Object?>>> incomingTables,
  required Map<String, List<Map<String, Object?>>> localTables,
  required String manifestHash,
}) {
  final idMaps = <String, Map<int, int>>{};
  final rowsToInsert = <String, List<Map<String, Object?>>>{
    for (final table in EncryptedBackupService.protectedTables) table: <Map<String, Object?>>[],
  };
  final tablePlans = <BackupTableConflictPlan>[];
  var insertedRows = 0;
  var equivalentRows = 0;
  var remappedRows = 0;
  var importedAuditEvents = 0;
  var hasBlockingConflicts = false;
  final mappingDrafts = <_BackupImportMappingDraft>[];

  final incomingSettings = incomingTables['astrology_settings']!;
  final localSettings = localTables['astrology_settings']!;
  final settingsEquivalent = incomingSettings.length == 1 &&
      localSettings.length == 1 &&
      _rowsEquivalent(incomingSettings.single, localSettings.single);
  tablePlans.add(
    BackupTableConflictPlan(
      tableName: 'astrology_settings',
      incomingRows: incomingSettings.length,
      localRows: localSettings.length,
      newIds: 0,
      equivalentIds: settingsEquivalent ? 1 : 0,
      conflictingIds: 0,
      remappedIds: 0,
      severity: settingsEquivalent
          ? BackupConflictSeverity.equivalent
          : BackupConflictSeverity.warning,
      note: settingsEquivalent
          ? 'Backup settings are canonically equivalent to local settings.'
          : 'Governed merge never overwrites local active settings. Historical calculation snapshots keep their original embedded settings.',
    ),
  );
  idMaps['astrology_settings'] = const <int, int>{1: 1};

  for (final table in EncryptedBackupService._restoreOrder) {
    final incoming = [...incomingTables[table]!]
      ..sort((a, b) => _requiredRowId(a, table).compareTo(_requiredRowId(b, table)));
    final local = localTables[table]!;
    final localById = <int, Map<String, Object?>>{
      for (final row in local) _requiredRowId(row, table): row,
    };
    final sourceIds = incoming.map((row) => _requiredRowId(row, table)).toList();
    if (sourceIds.toSet().length != sourceIds.length) {
      throw EncryptedBackupException(
        'Backup table $table contains duplicate primary keys.',
      );
    }
    var nextId = 1;
    for (final id in [...localById.keys, ...sourceIds]) {
      if (id >= nextId) nextId = id + 1;
    }
    final tableMap = <int, int>{};
    idMaps[table] = tableMap;
    var newIds = 0;
    var equivalentIds = 0;
    var unresolvedConflicts = 0;
    var remappedIds = 0;

    for (final sourceRow in incoming) {
      final sourceId = _requiredRowId(sourceRow, table);
      final candidate = _transformForeignKeys(
        table: table,
        sourceRow: sourceRow,
        idMaps: idMaps,
        manifestHash: manifestHash,
      );
      final naturalCollision = _findNaturalCollision(table, candidate, local);
      if (naturalCollision != null) {
        final localId = _requiredRowId(naturalCollision, table);
        tableMap[sourceId] = localId;
        if (_rowsEquivalent(candidate, naturalCollision)) {
          equivalentIds += 1;
          equivalentRows += 1;
          mappingDrafts.add(_BackupImportMappingDraft(
            tableName: table,
            sourceId: sourceId,
            localId: localId,
            resolution: BackupImportMappingResolution.equivalent,
            sourceRowSha256: _sha256Canonical(sourceRow),
            localRowSha256: _sha256Canonical(naturalCollision),
          ));
        } else {
          unresolvedConflicts += 1;
          hasBlockingConflicts = true;
        }
        continue;
      }

      final sameIdLocal = localById[sourceId];
      if (sameIdLocal != null && _rowsEquivalent(candidate, sameIdLocal)) {
        tableMap[sourceId] = sourceId;
        equivalentIds += 1;
        equivalentRows += 1;
        mappingDrafts.add(_BackupImportMappingDraft(
          tableName: table,
          sourceId: sourceId,
          localId: sourceId,
          resolution: BackupImportMappingResolution.equivalent,
          sourceRowSha256: _sha256Canonical(sourceRow),
          localRowSha256: _sha256Canonical(sameIdLocal),
        ));
        continue;
      }

      late final int localId;
      if (sameIdLocal == null) {
        localId = sourceId;
        newIds += 1;
      } else {
        localId = nextId++;
        remappedIds += 1;
        remappedRows += 1;
      }
      tableMap[sourceId] = localId;
      candidate['id'] = localId;
      _attachIntegritySourceIds(
        table: table,
        sourceRow: sourceRow,
        targetRow: candidate,
        sourceId: sourceId,
        localId: localId,
      );
      rowsToInsert[table]!.add(candidate);
      insertedRows += 1;
      mappingDrafts.add(_BackupImportMappingDraft(
        tableName: table,
        sourceId: sourceId,
        localId: localId,
        resolution: localId == sourceId
            ? BackupImportMappingResolution.inserted
            : BackupImportMappingResolution.remapped,
        sourceRowSha256: _sha256Canonical(sourceRow),
        localRowSha256: _sha256Canonical(candidate),
      ));
      if (table == 'audit_events') importedAuditEvents += 1;
    }

    final severity = unresolvedConflicts > 0
        ? BackupConflictSeverity.blocking
        : remappedIds > 0
            ? BackupConflictSeverity.warning
            : equivalentIds > 0
                ? BackupConflictSeverity.equivalent
                : BackupConflictSeverity.none;
    tablePlans.add(
      BackupTableConflictPlan(
        tableName: table,
        incomingRows: incoming.length,
        localRows: local.length,
        newIds: newIds,
        equivalentIds: equivalentIds,
        conflictingIds: unresolvedConflicts,
        remappedIds: remappedIds,
        severity: severity,
        note: unresolvedConflicts > 0
            ? 'An immutable unique identity exists locally with different content. Merge is blocked for the entire transaction.'
            : remappedIds > 0
                ? 'Primary-key collisions are resolved deterministically above the occupied/source ID range; source integrity IDs remain preserved.'
                : equivalentIds > 0
                    ? 'Equivalent governed rows are reused and not duplicated.'
                    : incoming.isEmpty
                        ? 'No incoming rows.'
                        : 'Incoming IDs can be preserved without collision.',
      ),
    );
  }

  return _GovernedMergePlan(
    rowsToInsert: rowsToInsert,
    idMaps: idMaps,
    tablePlans: List.unmodifiable(tablePlans),
    insertedRows: insertedRows,
    equivalentRows: equivalentRows,
    remappedRows: remappedRows,
    importedAuditEvents: importedAuditEvents,
    hasBlockingConflicts: hasBlockingConflicts,
    mappingDrafts: List.unmodifiable(mappingDrafts),
  );
}

Map<String, Object?> _transformForeignKeys({
  required String table,
  required Map<String, Object?> sourceRow,
  required Map<String, Map<int, int>> idMaps,
  required String manifestHash,
}) {
  final row = Map<String, Object?>.from(sourceRow);
  int mapId(String parentTable, Object? value, String field) {
    if (value is! int || value <= 0) {
      throw EncryptedBackupException('$table.$field is not a valid source id.');
    }
    final mapped = idMaps[parentTable]?[value];
    if (mapped == null) {
      throw EncryptedBackupException(
        '$table.$field references an unmapped $parentTable id.',
      );
    }
    return mapped;
  }

  switch (table) {
    case 'birth_records':
      row['client_id'] = mapId('clients', sourceRow['client_id'], 'client_id');
      break;
    case 'calculation_snapshots':
      row['client_id'] = mapId('clients', sourceRow['client_id'], 'client_id');
      row['birth_record_id'] =
          mapId('birth_records', sourceRow['birth_record_id'], 'birth_record_id');
      break;
    case 'consultations':
      row['client_id'] = mapId('clients', sourceRow['client_id'], 'client_id');
      row['birth_record_id'] =
          mapId('birth_records', sourceRow['birth_record_id'], 'birth_record_id');
      break;
    case 'calculation_output_snapshots':
      row['consultation_id'] =
          mapId('consultations', sourceRow['consultation_id'], 'consultation_id');
      row['input_snapshot_id'] = mapId(
        'calculation_snapshots',
        sourceRow['input_snapshot_id'],
        'input_snapshot_id',
      );
      break;
    case 'gemstone_remedies':
      row['consultation_id'] =
          mapId('consultations', sourceRow['consultation_id'], 'consultation_id');
      break;
    case 'kundli_analysis_snapshots':
      row['consultation_id'] =
          mapId('consultations', sourceRow['consultation_id'], 'consultation_id');
      row['calculation_output_id'] = mapId(
        'calculation_output_snapshots',
        sourceRow['calculation_output_id'],
        'calculation_output_id',
      );
      break;
    case 'numerology_snapshots':
      row['consultation_id'] =
          mapId('consultations', sourceRow['consultation_id'], 'consultation_id');
      row['client_id'] = mapId('clients', sourceRow['client_id'], 'client_id');
      row['birth_record_id'] =
          mapId('birth_records', sourceRow['birth_record_id'], 'birth_record_id');
      break;
    case 'professional_report_snapshots':
      row['consultation_id'] =
          mapId('consultations', sourceRow['consultation_id'], 'consultation_id');
      break;
    case 'professional_report_approvals':
      row['report_snapshot_id'] = mapId(
        'professional_report_snapshots',
        sourceRow['report_snapshot_id'],
        'report_snapshot_id',
      );
      row['consultation_id'] =
          mapId('consultations', sourceRow['consultation_id'], 'consultation_id');
      break;
    case 'audit_events':
      if (sourceRow['entity_type'] == 'client' && sourceRow['entity_id'] != null) {
        row['entity_id'] = mapId('clients', sourceRow['entity_id'], 'entity_id');
      } else if (sourceRow['entity_type'] == 'kpHorary' &&
          sourceRow['entity_id'] != null) {
        row['entity_id'] = mapId(
          'kp_horary_snapshots',
          sourceRow['entity_id'],
          'entity_id',
        );
      }
      Object? sourceSummary = sourceRow['summary_json'];
      if (sourceSummary is String) {
        try {
          sourceSummary = jsonDecode(sourceSummary);
        } on Object {
          // Preserve malformed historical audit text verbatim inside provenance.
        }
      }
      row['summary_json'] = jsonEncode({
        'importedFromBackup': true,
        'sourceManifestHash': manifestHash,
        'sourceAuditId': sourceRow['id'],
        'sourceEntityId': sourceRow['entity_id'],
        'sourceSummary': sourceSummary,
      });
      break;
    default:
      break;
  }
  return row;
}

void _attachIntegritySourceIds({
  required String table,
  required Map<String, Object?> sourceRow,
  required Map<String, Object?> targetRow,
  required int sourceId,
  required int localId,
}) {
  int integrityId(String sourceField, String localField) =>
      (sourceRow[sourceField] as int?) ?? (sourceRow[localField]! as int);

  switch (table) {
    case 'kundli_analysis_snapshots':
      final integrityOutput = integrityId(
        'source_calculation_output_id',
        'calculation_output_id',
      );
      targetRow['source_calculation_output_id'] =
          sourceRow['source_calculation_output_id'] != null ||
                  targetRow['calculation_output_id'] != integrityOutput
              ? integrityOutput
              : null;
      break;
    case 'numerology_snapshots':
      final integrityConsultation =
          integrityId('source_consultation_id', 'consultation_id');
      final integrityClient = integrityId('source_client_id', 'client_id');
      final integrityBirth =
          integrityId('source_birth_record_id', 'birth_record_id');
      targetRow['source_consultation_id'] =
          sourceRow['source_consultation_id'] != null ||
                  targetRow['consultation_id'] != integrityConsultation
              ? integrityConsultation
              : null;
      targetRow['source_client_id'] = sourceRow['source_client_id'] != null ||
              targetRow['client_id'] != integrityClient
          ? integrityClient
          : null;
      targetRow['source_birth_record_id'] =
          sourceRow['source_birth_record_id'] != null ||
                  targetRow['birth_record_id'] != integrityBirth
              ? integrityBirth
              : null;
      break;
    case 'professional_report_snapshots':
      final integrityReportId =
          (sourceRow['source_report_snapshot_id'] as int?) ?? sourceId;
      final integrityConsultation =
          integrityId('source_consultation_id', 'consultation_id');
      targetRow['source_report_snapshot_id'] =
          sourceRow['source_report_snapshot_id'] != null ||
                  localId != integrityReportId
              ? integrityReportId
              : null;
      targetRow['source_consultation_id'] =
          sourceRow['source_consultation_id'] != null ||
                  targetRow['consultation_id'] != integrityConsultation
              ? integrityConsultation
              : null;
      break;
    case 'professional_report_approvals':
      final integrityReport =
          integrityId('source_report_snapshot_id', 'report_snapshot_id');
      final integrityConsultation =
          integrityId('source_consultation_id', 'consultation_id');
      targetRow['source_report_snapshot_id'] =
          sourceRow['source_report_snapshot_id'] != null ||
                  targetRow['report_snapshot_id'] != integrityReport
              ? integrityReport
              : null;
      targetRow['source_consultation_id'] =
          sourceRow['source_consultation_id'] != null ||
                  targetRow['consultation_id'] != integrityConsultation
              ? integrityConsultation
              : null;
      break;
    default:
      break;
  }
}

Map<String, Object?>? _findNaturalCollision(
  String table,
  Map<String, Object?> candidate,
  List<Map<String, Object?>> localRows,
) {
  for (final local in localRows) {
    switch (table) {
      case 'numerology_snapshots':
        if (local['consultation_id'] == candidate['consultation_id'] &&
            local['snapshot_hash'] == candidate['snapshot_hash']) {
          return local;
        }
        break;
      case 'professional_report_snapshots':
        if (local['consultation_id'] == candidate['consultation_id'] &&
            local['report_hash'] == candidate['report_hash']) {
          return local;
        }
        break;
      case 'professional_report_approvals':
        if (local['report_snapshot_id'] == candidate['report_snapshot_id'] ||
            (local['consultation_id'] == candidate['consultation_id'] &&
                local['signed_report_hash'] == candidate['signed_report_hash'])) {
          return local;
        }
        break;
      default:
        break;
    }
  }
  return null;
}

bool _rowsEquivalent(
  Map<String, Object?> first,
  Map<String, Object?> second,
) =>
    _canonicalJson(_comparableRow(first)) ==
    _canonicalJson(_comparableRow(second));

Map<String, Object?> _comparableRow(Map<String, Object?> source) {
  final result = Map<String, Object?>.from(source)..remove('id');
  result.removeWhere((key, value) => key.startsWith('source_'));
  return result;
}

int _requiredRowId(Map<String, Object?> row, String table) {
  final id = row['id'];
  if (id is! int || id <= 0) {
    throw EncryptedBackupException('$table contains a missing or invalid id.');
  }
  return id;
}

bool _hasImportedManifest(
  Map<String, List<Map<String, Object?>>> localTables,
  String manifestHash,
) {
  for (final row in localTables['audit_events'] ?? const <Map<String, Object?>>[]) {
    if (row['action'] != 'governedBackupMerged') continue;
    final raw = row['summary_json'];
    if (raw is! String) continue;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map && decoded['manifestHash'] == manifestHash) {
        return true;
      }
    } on Object {
      // Historical malformed audit rows do not establish import identity.
    }
  }
  return false;
}
