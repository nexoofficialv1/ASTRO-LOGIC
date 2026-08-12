part of 'encrypted_backup_service.dart';

Map<String, Object?> _buildAuthenticatedHeader({
  required DateTime createdAt,
  required List<int> salt,
  required AesGcm cipher,
}) => <String, Object?>{
      'contract': EncryptedBackupService.contractVersion,
      'formatVersion': 1,
      'engineId': EncryptedBackupService.engineId,
      'engineVersion': EncryptedBackupService.engineVersion,
      'createdAtUtc': createdAt.toIso8601String(),
      'databaseSchemaVersion': AppDatabase.schemaVersion,
      'kdf': {
        'algorithm': EncryptedBackupService.kdfAlgorithm,
        'memoryKiB': EncryptedBackupService.kdfMemoryKiB,
        'parallelism': EncryptedBackupService.kdfParallelism,
        'iterations': EncryptedBackupService.kdfIterations,
        'keyLengthBytes': EncryptedBackupService.kdfKeyLength,
        'saltBase64': base64Encode(salt),
      },
      'cipher': {
        'algorithm': EncryptedBackupService.cipherAlgorithm,
        'nonceLengthBytes': cipher.nonceLength,
        'macLengthBytes': cipher.macAlgorithm.macLength,
      },
      'privacy': {
        'passwordStored': false,
        'plaintextMetadataOutsideCiphertext': [
          'contract',
          'formatVersion',
          'engineId',
          'engineVersion',
          'createdAtUtc',
          'databaseSchemaVersion',
          'kdf',
          'cipher.algorithm',
          'cipher.nonceLengthBytes',
          'cipher.macLengthBytes',
          'privacy',
        ],
        'plaintextMetadataAuthenticatedAsAad': true,
      },
    };

Map<String, Object?> _validatedAuthenticatedHeader(
  Map<String, Object?> envelope,
) {
  final kdfRaw = envelope['kdf'];
  final cipherRaw = envelope['cipher'];
  final privacyRaw = envelope['privacy'];
  if (kdfRaw is! Map || cipherRaw is! Map || privacyRaw is! Map) {
    throw const EncryptedBackupException('Backup envelope is incomplete.');
  }
  final cipherEnvelope = Map<String, Object?>.from(cipherRaw);
  final header = <String, Object?>{
    'contract': envelope['contract'],
    'formatVersion': envelope['formatVersion'],
    'engineId': envelope['engineId'],
    'engineVersion': envelope['engineVersion'],
    'createdAtUtc': envelope['createdAtUtc'],
    'databaseSchemaVersion': envelope['databaseSchemaVersion'],
    'kdf': Map<String, Object?>.from(kdfRaw),
    'cipher': <String, Object?>{
      'algorithm': cipherEnvelope['algorithm'],
      'nonceLengthBytes': cipherEnvelope['nonceLengthBytes'],
      'macLengthBytes': cipherEnvelope['macLengthBytes'],
    },
    'privacy': Map<String, Object?>.from(privacyRaw),
  };
  final sourceEngineVersion = header['engineVersion'];
  final sourceSchemaVersion = header['databaseSchemaVersion'];
  if (header['contract'] != EncryptedBackupService.contractVersion ||
      header['formatVersion'] != 1 ||
      header['engineId'] != EncryptedBackupService.engineId ||
      sourceEngineVersion is! String ||
      !EncryptedBackupService.supportedReaderEngineVersions.contains(sourceEngineVersion) ||
      sourceSchemaVersion is! int ||
      sourceSchemaVersion < 1) {
    throw const EncryptedBackupException(
      'Unsupported or modified encrypted backup header.',
    );
  }
  final createdAt = header['createdAtUtc'];
  if (createdAt is! String || DateTime.tryParse(createdAt) == null) {
    throw const EncryptedBackupException(
      'Encrypted backup creation timestamp is invalid.',
    );
  }
  final privacy = Map<String, Object?>.from(header['privacy']! as Map);
  if (privacy['passwordStored'] != false ||
      privacy['plaintextMetadataAuthenticatedAsAad'] != true) {
    throw const EncryptedBackupException(
      'Encrypted backup privacy header is invalid.',
    );
  }
  return header;
}

Future<Map<String, Object?>> _decryptPayload(
  Map<String, Object?> envelope,
  String password,
) async {
  final authenticatedHeader = _validatedAuthenticatedHeader(envelope);
  final kdf = Map<String, Object?>.from(authenticatedHeader['kdf']! as Map);
  final cipherEnvelope = Map<String, Object?>.from(envelope['cipher']! as Map);
  if (kdf['algorithm'] != EncryptedBackupService.kdfAlgorithm ||
      kdf['memoryKiB'] != EncryptedBackupService.kdfMemoryKiB ||
      kdf['parallelism'] != EncryptedBackupService.kdfParallelism ||
      kdf['iterations'] != EncryptedBackupService.kdfIterations ||
      kdf['keyLengthBytes'] != EncryptedBackupService.kdfKeyLength) {
    throw const EncryptedBackupException(
      'Unsupported or modified backup key-derivation parameters.',
    );
  }
  if (cipherEnvelope['algorithm'] != EncryptedBackupService.cipherAlgorithm) {
    throw const EncryptedBackupException('Unsupported backup cipher.');
  }
  final salt = _decodeBase64Field(kdf, 'saltBase64');
  if (salt.length != EncryptedBackupService.kdfSaltLength) {
    throw const EncryptedBackupException('Backup salt length is invalid.');
  }
  final cipher = AesGcm.with256bits();
  if (cipherEnvelope['nonceLengthBytes'] != cipher.nonceLength ||
      cipherEnvelope['macLengthBytes'] != cipher.macAlgorithm.macLength) {
    throw const EncryptedBackupException(
      'Backup cipher parameters do not match the supported contract.',
    );
  }
  final concatenated = _decodeBase64Field(cipherEnvelope, 'secretBoxBase64');
  final minimumLength = cipher.nonceLength + cipher.macAlgorithm.macLength;
  if (concatenated.length <= minimumLength) {
    throw const EncryptedBackupException('Encrypted backup payload is truncated.');
  }
  final secretBox = SecretBox.fromConcatenation(
    concatenated,
    nonceLength: cipher.nonceLength,
    macLength: cipher.macAlgorithm.macLength,
    copy: false,
  );
  final secretKey = await _deriveKey(password: password, salt: salt);
  List<int> clearBytes;
  try {
    clearBytes = await cipher.decrypt(
      secretBox,
      secretKey: secretKey,
      aad: utf8.encode(_canonicalJson(authenticatedHeader)),
    );
  } on SecretBoxAuthenticationError {
    throw const EncryptedBackupException(
      'Incorrect password or encrypted backup authentication failed.',
    );
  } catch (_) {
    throw const EncryptedBackupException(
      'Encrypted backup could not be authenticated or decrypted.',
    );
  } finally {
    secretKey.destroy();
  }
  try {
    final decoded = jsonDecode(utf8.decode(clearBytes));
    if (decoded is! Map) {
      throw const FormatException('Payload is not an object');
    }
    final payload = Map<String, Object?>.from(decoded);
    if (payload['createdAtUtc'] != authenticatedHeader['createdAtUtc'] ||
        payload['engineId'] != authenticatedHeader['engineId'] ||
        payload['engineVersion'] != authenticatedHeader['engineVersion'] ||
        payload['databaseSchemaVersion'] !=
            authenticatedHeader['databaseSchemaVersion']) {
      throw const EncryptedBackupException(
        'Encrypted backup header and payload identity fields do not match.',
      );
    }
    return payload;
  } catch (_) {
    throw const EncryptedBackupException('Decrypted backup payload is invalid.');
  }
}

Map<String, Object?> _decodeEnvelope(List<int> bytes) {
  try {
    final decoded = jsonDecode(utf8.decode(bytes));
    if (decoded is! Map) {
      throw const FormatException('Envelope is not an object');
    }
    final envelope = Map<String, Object?>.from(decoded);
    if (envelope['contract'] != EncryptedBackupService.contractVersion || envelope['formatVersion'] != 1) {
      throw const EncryptedBackupException(
        'Unsupported ASTRO LOGIC encrypted backup contract.',
      );
    }
    final sourceSchemaVersion = envelope['databaseSchemaVersion'];
    if (sourceSchemaVersion is! int || sourceSchemaVersion < 1) {
      throw const EncryptedBackupException(
        'Backup database schema metadata is invalid.',
      );
    }
    if (envelope['kdf'] is! Map || envelope['cipher'] is! Map) {
      throw const EncryptedBackupException('Backup envelope is incomplete.');
    }
    return envelope;
  } on EncryptedBackupException {
    rethrow;
  } catch (_) {
    throw const EncryptedBackupException(
      'File is not a valid ASTRO LOGIC encrypted backup.',
    );
  }
}

void _validatePayload(Map<String, Object?> payload) {
  final sourceEngineVersion = payload['engineVersion'];
  if (payload['contract'] != EncryptedBackupService.payloadContractVersion ||
      payload['engineId'] != EncryptedBackupService.engineId ||
      sourceEngineVersion is! String ||
      !EncryptedBackupService.supportedReaderEngineVersions.contains(sourceEngineVersion) ||
      payload['databaseSchemaVersion'] != AppDatabase.schemaVersion ||
      payload['tables'] is! Map ||
      payload['manifest'] is! Map) {
    throw const EncryptedBackupException(
      'Decrypted backup payload uses an unsupported contract or schema.',
    );
  }
  if (!_isSupportedRestorePolicy(payload['restorePolicy'])) {
    throw const EncryptedBackupException(
      'Backup restore policy is invalid or unsupported.',
    );
  }
}

void _validatePreviewPayloadBase(Map<String, Object?> payload) {
  final sourceEngineVersion = payload['engineVersion'];
  final sourceSchemaVersion = payload['databaseSchemaVersion'];
  final sourceAppVersion = payload['appVersion'];
  if (payload['contract'] != EncryptedBackupService.payloadContractVersion ||
      payload['engineId'] != EncryptedBackupService.engineId ||
      sourceEngineVersion is! String ||
      !EncryptedBackupService.supportedReaderEngineVersions.contains(sourceEngineVersion) ||
      sourceSchemaVersion is! int ||
      sourceSchemaVersion < 1 ||
      sourceAppVersion is! String ||
      sourceAppVersion.trim().isEmpty ||
      payload['tables'] is! Map ||
      payload['manifest'] is! Map) {
    throw const EncryptedBackupException(
      'Decrypted backup payload uses an unsupported preview contract.',
    );
  }
  final createdAt = payload['createdAtUtc'];
  if (createdAt is! String || DateTime.tryParse(createdAt) == null) {
    throw const EncryptedBackupException(
      'Decrypted backup creation timestamp is invalid.',
    );
  }
  if (!_isSupportedRestorePolicy(payload['restorePolicy'])) {
    throw const EncryptedBackupException(
      'Backup restore policy is invalid or unsupported.',
    );
  }
}

bool _isSupportedRestorePolicy(Object? value) {
  if (value is! Map) return false;
  if (value['overwriteExistingRecords'] != false) return false;
  final mode = value['mode'];
  if (mode == 'emptyWorkspaceOnly') {
    return value['mergeEnabled'] == false;
  }
  if (mode == 'emptyWorkspaceOrGovernedMerge') {
    return value['mergeEnabled'] == true &&
        value['mergeContract'] == EncryptedBackupService.mergeContractVersion &&
        value['automaticIdRemap'] == true;
  }
  return false;
}

void _verifyRawManifest(
  Map<String, Object?> rawTables,
  Map<String, Object?> manifest, {
  required int databaseSchemaVersion,
}) {
  if (manifest['algorithm'] != 'SHA-256' ||
      manifest['canonicalization'] != 'sorted-json-keys-v1') {
    throw const EncryptedBackupException(
      'Backup integrity manifest uses an unsupported algorithm.',
    );
  }
  final rawTableManifest = manifest['tables'];
  if (rawTableManifest is! Map) {
    throw const EncryptedBackupException('Backup table manifest is invalid.');
  }
  final tableManifest = Map<String, Object?>.from(rawTableManifest);
  if (rawTables.isEmpty ||
      tableManifest.length != rawTables.length ||
      !rawTables.keys.every(tableManifest.containsKey)) {
    throw const EncryptedBackupException(
      'Backup table manifest does not match the encrypted table set.',
    );
  }
  for (final entry in rawTables.entries) {
    final rows = entry.value;
    final manifestEntryRaw = tableManifest[entry.key];
    if (rows is! List || manifestEntryRaw is! Map) {
      throw EncryptedBackupException(
        'Backup table ${entry.key} or its manifest entry is invalid.',
      );
    }
    for (final row in rows) {
      if (row is! Map) {
        throw EncryptedBackupException(
          'Backup table ${entry.key} contains an invalid row.',
        );
      }
    }
    final manifestEntry = Map<String, Object?>.from(manifestEntryRaw);
    if (manifestEntry['rowCount'] != rows.length ||
        manifestEntry['sha256'] != _sha256Canonical(rows)) {
      throw EncryptedBackupException(
        'Integrity check failed for backup table ${entry.key}.',
      );
    }
  }
  final expectedOverall = _sha256Canonical({
    'databaseSchemaVersion': databaseSchemaVersion,
    'tables': rawTables,
  });
  if (manifest['overallSha256'] != expectedOverall) {
    throw const EncryptedBackupException(
      'Backup overall integrity manifest does not match its content.',
    );
  }
}

Map<String, int> _rowCountsFromRawTables(
  Map<String, Object?> rawTables,
) {
  final counts = <String, int>{};
  for (final entry in rawTables.entries) {
    final rows = entry.value;
    if (rows is! List) {
      throw EncryptedBackupException(
        'Backup table ${entry.key} is invalid.',
      );
    }
    counts[entry.key] = rows.length;
  }
  return counts;
}

int _sensitiveWorkspaceRowCount(
  Map<String, List<Map<String, Object?>>> tables,
) => EncryptedBackupService.sensitiveWorkspaceTables.fold<int>(
      0,
      (total, table) => total + (tables[table]?.length ?? 0),
    );

Map<String, List<Map<String, Object?>>> _tablesFromPayload(
  Map<String, Object?> payload,
) {
  final sourceSchemaVersion = payload['databaseSchemaVersion'];
  if (sourceSchemaVersion is! int || sourceSchemaVersion < 1) {
    throw const EncryptedBackupException('Backup database schema is invalid.');
  }
  final expectedTables =
      EncryptedBackupService.protectedTablesForSchema(sourceSchemaVersion);
  final rawTables = Map<String, Object?>.from(payload['tables']! as Map);
  if (rawTables.length != expectedTables.length ||
      !expectedTables.every(rawTables.containsKey)) {
    throw const EncryptedBackupException(
      'Backup does not contain the protected table set expected for its schema.',
    );
  }
  final result = <String, List<Map<String, Object?>>>{
    for (final table in EncryptedBackupService.protectedTables)
      table: <Map<String, Object?>>[],
  };
  for (final table in expectedTables) {
    final value = rawTables[table];
    if (value is! List) {
      throw EncryptedBackupException('Backup table $table is invalid.');
    }
    result[table] = value
        .map((row) {
          if (row is! Map) {
            throw EncryptedBackupException('Backup table $table contains an invalid row.');
          }
          return Map<String, Object?>.from(row);
        })
        .toList(growable: false);
  }
  return result;
}

Map<String, Object?> _buildManifest(
  Map<String, List<Map<String, Object?>>> tables,
) {
  final tableEntries = <String, Object?>{};
  for (final table in EncryptedBackupService.protectedTables) {
    final rows = tables[table]!;
    tableEntries[table] = {
      'rowCount': rows.length,
      'sha256': _sha256Canonical(rows),
    };
  }
  final overallSha256 = _sha256Canonical({
    'databaseSchemaVersion': AppDatabase.schemaVersion,
    'tables': tables,
  });
  return {
    'algorithm': 'SHA-256',
    'canonicalization': 'sorted-json-keys-v1',
    'tables': tableEntries,
    'overallSha256': overallSha256,
  };
}

void _verifyManifest(
  Map<String, List<Map<String, Object?>>> tables,
  Object? rawManifest, {
  required int databaseSchemaVersion,
}) {
  if (rawManifest is! Map) {
    throw const EncryptedBackupException('Backup integrity manifest is missing.');
  }
  final manifest = Map<String, Object?>.from(rawManifest);
  if (manifest['algorithm'] != 'SHA-256' ||
      manifest['canonicalization'] != 'sorted-json-keys-v1') {
    throw const EncryptedBackupException(
      'Backup integrity manifest uses an unsupported algorithm.',
    );
  }
  _verifyTableSetAgainstManifest(
    tables,
    manifest,
    databaseSchemaVersion: databaseSchemaVersion,
  );
}

void _verifyTableSetAgainstManifest(
  Map<String, List<Map<String, Object?>>> tables,
  Map<String, Object?> manifest, {
  required int databaseSchemaVersion,
}) {
  final rawTableManifest = manifest['tables'];
  if (rawTableManifest is! Map) {
    throw const EncryptedBackupException('Backup table manifest is invalid.');
  }
  final tableManifest = Map<String, Object?>.from(rawTableManifest);
  final expectedTables =
      EncryptedBackupService.protectedTablesForSchema(databaseSchemaVersion);
  if (tableManifest.length != expectedTables.length ||
      !expectedTables.every(tableManifest.containsKey)) {
    throw const EncryptedBackupException('Backup table manifest is incomplete.');
  }
  for (final table in expectedTables) {
    final entryRaw = tableManifest[table];
    if (entryRaw is! Map) {
      throw EncryptedBackupException('Manifest entry for $table is invalid.');
    }
    final entry = Map<String, Object?>.from(entryRaw);
    final rows = tables[table]!;
    if (entry['rowCount'] != rows.length ||
        entry['sha256'] != _sha256Canonical(rows)) {
      throw EncryptedBackupException(
        'Integrity check failed for backup table $table.',
      );
    }
  }
  final sourceTables = <String, List<Map<String, Object?>>>{
    for (final table in expectedTables) table: tables[table]!,
  };
  final expectedOverall = _sha256Canonical({
    'databaseSchemaVersion': databaseSchemaVersion,
    'tables': sourceTables,
  });
  if (manifest['overallSha256'] != expectedOverall) {
    throw const EncryptedBackupException(
      'Backup overall integrity manifest does not match its content.',
    );
  }
}
