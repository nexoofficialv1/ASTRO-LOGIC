part of 'encrypted_backup_service.dart';

void _validateProtectedSnapshotHashes(
  Map<String, List<Map<String, Object?>>> tables,
) {
  for (final row in tables['calculation_snapshots']!) {
    final input = _decodeJsonMap(row['input_json'], 'calculation snapshot input');
    final settings = _decodeJsonMap(row['settings_json'], 'calculation snapshot settings');
    final calculated = SnapshotIntegrity.sha256For(
      input: input,
      settings: settings,
      schemaVersion: row['schema_version']! as String,
    );
    if (calculated != row['input_hash']) {
      throw const EncryptedBackupException(
        'An immutable calculation input snapshot failed hash validation.',
      );
    }
  }
  for (final row in tables['kp_horary_snapshots']!) {
    final input = _decodeJsonMap(row['input_json'], 'KP horary input');
    final settings = _decodeJsonMap(row['settings_json'], 'KP horary settings');
    final inputHash = SnapshotIntegrity.sha256For(
      input: input,
      settings: settings,
      schemaVersion: row['input_schema_version']! as String,
    );
    if (inputHash != row['input_hash']) {
      throw const EncryptedBackupException(
        'An immutable KP horary input snapshot failed hash validation.',
      );
    }
    final output = _decodeJsonMap(row['output_json'], 'KP horary output');
    final outputHash = SnapshotIntegrity.sha256ForOutput(
      output: output,
      engineId: row['engine_id']! as String,
      engineVersion: row['engine_version']! as String,
      outputSchemaVersion: row['output_schema_version']! as String,
    );
    if (outputHash != row['output_hash']) {
      throw const EncryptedBackupException(
        'An immutable KP horary output snapshot failed hash validation.',
      );
    }
  }
  for (final row in tables['calculation_output_snapshots']!) {
    final output = _decodeJsonMap(row['output_json'], 'calculation output');
    final calculated = SnapshotIntegrity.sha256ForOutput(
      output: output,
      engineId: row['engine_id']! as String,
      engineVersion: row['engine_version']! as String,
      outputSchemaVersion: row['output_schema_version']! as String,
    );
    if (calculated != row['output_hash']) {
      throw const EncryptedBackupException(
        'An immutable calculation output snapshot failed hash validation.',
      );
    }
  }
  for (final row in tables['kundli_analysis_snapshots']!) {
    final analysis = _decodeJsonMap(row['analysis_json'], 'Kundli analysis');
    final calculated = SnapshotIntegrity.sha256ForAnalysis(
      analysis: analysis,
      engineId: row['engine_id']! as String,
      engineVersion: row['engine_version']! as String,
      analysisSchemaVersion: row['analysis_schema_version']! as String,
      calculationOutputId:
          (row['source_calculation_output_id'] as int?) ??
          row['calculation_output_id']! as int,
    );
    if (calculated != row['analysis_hash']) {
      throw const EncryptedBackupException(
        'An immutable Kundli analysis snapshot failed hash validation.',
      );
    }
  }
  for (final row in tables['numerology_snapshots']!) {
    final calculation = _decodeJsonMap(row['calculation_json'], 'Numerology calculation');
    final analysis = _decodeJsonMap(row['analysis_json'], 'Numerology analysis');
    final comparisons = calculation['nameCandidateComparisons'];
    final alternateNames = comparisons is List
        ? comparisons
            .whereType<Map>()
            .map((value) => value['candidateName'])
            .whereType<String>()
            .toList(growable: false)
        : const <String>[];
    final input = <String, Object?>{
      'consultationId':
          row['source_consultation_id'] ?? row['consultation_id'],
      'clientId': row['source_client_id'] ?? row['client_id'],
      'birthRecordId':
          row['source_birth_record_id'] ?? row['birth_record_id'],
      'nameLatin': row['name_latin'],
      'birthDate': calculation['birthDate'],
      'targetYear': row['target_year'],
      'alternateNamesLatin': alternateNames,
      'professionalSelectedNameLatin': calculation['professionalSelectedNameLatin'],
    };
    final calculated = SnapshotIntegrity.sha256ForNumerology(
      input: input,
      calculation: calculation,
      analysis: analysis,
      calculationEngineId: row['calculation_engine_id']! as String,
      calculationEngineVersion: row['calculation_engine_version']! as String,
      calculationSchemaVersion: row['calculation_schema_version']! as String,
      analysisEngineId: row['analysis_engine_id']! as String,
      analysisEngineVersion: row['analysis_engine_version']! as String,
      analysisSchemaVersion: row['analysis_schema_version']! as String,
    );
    if (calculated != row['snapshot_hash']) {
      throw const EncryptedBackupException(
        'An immutable Numerology snapshot failed hash validation.',
      );
    }
  }
  final reportsById = <int, Map<String, Object?>>{};
  for (final row in tables['professional_report_snapshots']!) {
    final report = _decodeJsonMap(row['report_json'], 'professional report');
    final sources = _decodeJsonMapList(row['source_manifest_json'], 'report source manifest');
    final calculated = SnapshotIntegrity.sha256ForProfessionalReport(
      report: report,
      sourceManifest: sources,
      engineId: row['engine_id']! as String,
      engineVersion: row['engine_version']! as String,
      reportSchemaVersion: row['report_schema_version']! as String,
    );
    if (calculated != row['report_hash']) {
      throw const EncryptedBackupException(
        'An immutable professional report snapshot failed hash validation.',
      );
    }
    reportsById[row['id']! as int] = row;
  }
  for (final row in tables['professional_report_approvals']!) {
    final report = reportsById[row['report_snapshot_id']! as int];
    if (report == null ||
        report['consultation_id'] != row['consultation_id'] ||
        report['report_hash'] != row['report_hash']) {
      throw const EncryptedBackupException(
        'A professional report approval is not bound to its immutable report.',
      );
    }
    final payload = <String, Object?>{
      'reportSnapshotId':
          row['source_report_snapshot_id'] ?? row['report_snapshot_id'],
      'consultationId':
          row['source_consultation_id'] ?? row['consultation_id'],
      'reportHash': row['report_hash'],
      'practitionerName': row['practitioner_name'],
      'practitionerDesignation': row['practitioner_designation'],
      'credentialReference': row['credential_reference'],
      'decision': row['decision'],
      'approvalNote': row['approval_note'],
      'approvedAtUtc': row['approved_at'],
    };
    final approvalHash = SnapshotIntegrity.sha256ForProfessionalReportApproval(
      approvalPayload: payload,
      approvalEngineId: row['approval_engine_id']! as String,
      approvalEngineVersion: row['approval_engine_version']! as String,
      approvalStatementVersion: row['approval_statement_version']! as String,
    );
    if (approvalHash != row['approval_hash']) {
      throw const EncryptedBackupException(
        'An immutable professional report approval failed hash validation.',
      );
    }
    final signedHash = SnapshotIntegrity.sha256ForSignedProfessionalReport(
      reportHash: row['report_hash']! as String,
      approvalHash: row['approval_hash']! as String,
      approvalStatementVersion: row['approval_statement_version']! as String,
    );
    if (signedHash != row['signed_report_hash']) {
      throw const EncryptedBackupException(
        'A signed professional report binding failed hash validation.',
      );
    }
    if (row['approval_statement_version'] !=
        ProfessionalReportApprovalPolicy.statementVersion) {
      throw const EncryptedBackupException(
        'Backup contains an unsupported professional approval contract.',
      );
    }
  }
}

Future<void> _requireEmptyWorkspace(Database database) async {
  for (final table in EncryptedBackupService.sensitiveWorkspaceTables) {
    final countRows = await database.rawQuery(
      'SELECT COUNT(*) AS row_count FROM $table',
    );
    final rawCount = countRows.isEmpty ? null : countRows.first['row_count'];
    final count = rawCount is num ? rawCount.toInt() : 0;
    if (count != 0) {
      throw const EncryptedBackupException(
        'Restore v1 is allowed only into an empty ASTRO LOGIC workspace. Existing records are never overwritten or merged.',
      );
    }
  }
}

Future<Map<String, List<Map<String, Object?>>>> _readAllProtectedTables(
  DatabaseExecutor executor,
) async {
  final result = <String, List<Map<String, Object?>>>{};
  for (final table in EncryptedBackupService.protectedTables) {
    final rows = await executor.query(table, orderBy: 'id ASC');
    result[table] = rows
        .map((row) => Map<String, Object?>.from(row))
        .toList(growable: false);
  }
  return result;
}

Map<String, int> _rowCounts(
  Map<String, List<Map<String, Object?>>> tables,
) => {
      for (final table in EncryptedBackupService.protectedTables) table: tables[table]!.length,
    };

Future<SecretKey> _deriveKey({
  required String password,
  required List<int> salt,
}) {
  final kdf = Argon2id(
    memory: EncryptedBackupService.kdfMemoryKiB,
    parallelism: EncryptedBackupService.kdfParallelism,
    iterations: EncryptedBackupService.kdfIterations,
    hashLength: EncryptedBackupService.kdfKeyLength,
  );
  return kdf.deriveKeyFromPassword(password: password, nonce: salt);
}

void _validatePassword(String password) {
  if (password.length < 12) {
    throw const EncryptedBackupException(
      'Backup password must contain at least 12 characters.',
    );
  }
  if (password.trim().isEmpty) {
    throw const EncryptedBackupException('Backup password cannot be blank.');
  }
}

List<int> _randomBytes(int length) {
  final random = Random.secure();
  return List<int>.generate(length, (_) => random.nextInt(256), growable: false);
}

List<int> _decodeBase64Field(Map<String, Object?> map, String field) {
  final value = map[field];
  if (value is! String) {
    throw EncryptedBackupException('Backup field $field is missing.');
  }
  try {
    return base64Decode(value);
  } catch (_) {
    throw EncryptedBackupException('Backup field $field is not valid Base64.');
  }
}

Map<String, Object?> _decodeJsonMap(Object? raw, String label) {
  if (raw is! String) {
    throw EncryptedBackupException('$label is not stored as JSON text.');
  }
  try {
    final value = jsonDecode(raw);
    if (value is! Map) throw const FormatException();
    return Map<String, Object?>.from(value);
  } catch (_) {
    throw EncryptedBackupException('$label contains invalid JSON.');
  }
}

List<Map<String, Object?>> _decodeJsonMapList(Object? raw, String label) {
  if (raw is! String) {
    throw EncryptedBackupException('$label is not stored as JSON text.');
  }
  try {
    final value = jsonDecode(raw);
    if (value is! List) throw const FormatException();
    return value
        .map((item) {
          if (item is! Map) throw const FormatException();
          return Map<String, Object?>.from(item);
        })
        .toList(growable: false);
  } catch (_) {
    throw EncryptedBackupException('$label contains invalid JSON.');
  }
}

String _sha256Canonical(Object? value) =>
    sha256.convert(utf8.encode(_canonicalJson(value))).toString();

String _canonicalJson(Object? value) => jsonEncode(_canonicalize(value));

Object? _canonicalize(Object? value) {
  if (value is Map) {
    final keys = value.keys.map((key) => key.toString()).toList()..sort();
    return <String, Object?>{
      for (final key in keys) key: _canonicalize(value[key]),
    };
  }
  if (value is List) {
    return value.map(_canonicalize).toList(growable: false);
  }
  if (value == null || value is String || value is num || value is bool) {
    return value;
  }
  throw EncryptedBackupException(
    'Backup canonicalization does not support ${value.runtimeType}.',
  );
}

Future<Directory> _defaultReceiptDirectory() async {
  final root = await getApplicationDocumentsDirectory();
  return Directory(p.join(root.path, 'ASTRO_LOGIC', 'merge_receipts'));
}

Future<Directory> _defaultDirectory() async {
  final root = await getApplicationDocumentsDirectory();
  return Directory(p.join(root.path, 'ASTRO_LOGIC', 'backups'));
}

class _GovernedMergePlan {
  const _GovernedMergePlan({
    required this.rowsToInsert,
    required this.idMaps,
    required this.tablePlans,
    required this.insertedRows,
    required this.equivalentRows,
    required this.remappedRows,
    required this.importedAuditEvents,
    required this.hasBlockingConflicts,
    required this.mappingDrafts,
  });

  final Map<String, List<Map<String, Object?>>> rowsToInsert;
  final Map<String, Map<int, int>> idMaps;
  final List<BackupTableConflictPlan> tablePlans;
  final int insertedRows;
  final int equivalentRows;
  final int remappedRows;
  final int importedAuditEvents;
  final bool hasBlockingConflicts;
  final List<_BackupImportMappingDraft> mappingDrafts;
}

class _BackupImportMappingDraft {
  const _BackupImportMappingDraft({
    required this.tableName,
    required this.sourceId,
    required this.localId,
    required this.resolution,
    required this.sourceRowSha256,
    required this.localRowSha256,
  });

  final String tableName;
  final int sourceId;
  final int localId;
  final BackupImportMappingResolution resolution;
  final String sourceRowSha256;
  final String localRowSha256;
}

