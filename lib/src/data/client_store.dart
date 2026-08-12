import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../models/birth_record.dart';
import '../models/client.dart';
import '../models/astrology_settings.dart';
import '../models/audit_event.dart';
import '../models/calculation_snapshot.dart';
import '../models/calculation_output_snapshot.dart';
import '../models/consultation.dart';
import '../models/encrypted_backup.dart';
import '../models/gemstone_remedy.dart';
import '../models/kundli_analysis.dart';
import '../models/kundli_analysis_snapshot.dart';
import '../models/kp_horary_snapshot.dart';
import '../kp/kp_governance.dart';
import '../kp/kp_horary_engine.dart';
import '../western/western_chart_engine.dart';
import '../western/western_governance.dart';
import '../models/numerology_snapshot.dart';
import '../models/professional_report.dart';
import '../models/professional_report_approval.dart';
import '../models/professional_report_snapshot.dart';
import '../numerology/numerology_analysis.dart';
import '../numerology/numerology_analysis_policy.dart';
import '../numerology/numerology_engine.dart';
import '../numerology/numerology_judgment_engine.dart';
import '../services/snapshot_integrity.dart';
import '../services/consultation_workflow.dart';
import '../services/encrypted_backup_service.dart';
import '../services/gemstone_remedy_policy.dart';
import '../services/kundli_judgment_policy.dart';
import '../services/professional_report_policy.dart';
import '../services/professional_report_approval_policy.dart';
import 'app_database.dart';

class ClientStore extends ChangeNotifier {
  ClientStore._(this._database);

  final Database _database;
  final List<Client> _clients = [];
  final List<CalculationSnapshot> _snapshots = [];
  final List<Consultation> _consultations = [];
  final List<CalculationOutputSnapshot> _outputs = [];
  final List<GemstoneRemedy> _gemstoneRemedies = [];
  final List<KundliAnalysisSnapshot> _kundliAnalyses = [];
  final List<NumerologySnapshot> _numerologySnapshots = [];
  final List<ProfessionalReportSnapshot> _professionalReports = [];
  final List<ProfessionalReportApproval> _professionalReportApprovals = [];
  final List<KpHorarySnapshot> _kpHorarySnapshots = [];
  AstrologySettings _settings = AstrologySettings.defaults;

  List<Client> get clients => List.unmodifiable(_clients);
  List<CalculationSnapshot> get snapshots => List.unmodifiable(_snapshots);
  List<Consultation> get consultations => List.unmodifiable(_consultations);
  List<CalculationOutputSnapshot> get outputs => List.unmodifiable(_outputs);
  List<GemstoneRemedy> get gemstoneRemedies =>
      List.unmodifiable(_gemstoneRemedies);
  List<KundliAnalysisSnapshot> get kundliAnalyses =>
      List.unmodifiable(_kundliAnalyses);
  List<NumerologySnapshot> get numerologySnapshots =>
      List.unmodifiable(_numerologySnapshots);
  List<ProfessionalReportSnapshot> get professionalReports =>
      List.unmodifiable(_professionalReports);
  List<ProfessionalReportApproval> get professionalReportApprovals =>
      List.unmodifiable(_professionalReportApprovals);
  List<KpHorarySnapshot> get kpHorarySnapshots =>
      List.unmodifiable(_kpHorarySnapshots);
  AstrologySettings get settings => _settings;

  static Future<ClientStore> open() async {
    final store = ClientStore._(await AppDatabase.open());
    await EncryptedBackupService(store._database).recoverInterruptedImportBatches();
    await store.reload();
    await store.reloadSettings();
    await store.reloadSnapshots();
    await store.reloadConsultations();
    await store.reloadOutputs();
    await store.reloadGemstoneRemedies();
    await store.reloadKundliAnalyses();
    await store.reloadNumerologySnapshots();
    await store.reloadProfessionalReports();
    await store.reloadProfessionalReportApprovals();
    await store.reloadKpHorarySnapshots();
    return store;
  }


  Future<EncryptedBackupArtifact> createEncryptedBackup({
    required String password,
  }) async {
    final artifact = await EncryptedBackupService(_database)
        .createEncryptedBackup(password: password);
    return artifact;
  }

  Future<EncryptedBackupPreview> previewEncryptedBackup({
    required List<int> encryptedBytes,
    required String password,
  }) => EncryptedBackupService(_database).previewEncryptedBackup(
        encryptedBytes: encryptedBytes,
        password: password,
      );

  Future<EncryptedBackupRestoreResult> restoreEncryptedBackup({
    required List<int> encryptedBytes,
    required String password,
  }) async {
    final result = await EncryptedBackupService(_database).restoreEncryptedBackup(
      encryptedBytes: encryptedBytes,
      password: password,
    );
    await reload();
    await reloadSettings();
    await reloadSnapshots();
    await reloadConsultations();
    await reloadOutputs();
    await reloadGemstoneRemedies();
    await reloadKundliAnalyses();
    await reloadNumerologySnapshots();
    await reloadProfessionalReports();
    await reloadProfessionalReportApprovals();
    await reloadKpHorarySnapshots();
    return result;
  }

  Future<EncryptedBackupMergeResult> mergeEncryptedBackup({
    required List<int> encryptedBytes,
    required String password,
  }) async {
    final result = await EncryptedBackupService(_database).mergeEncryptedBackup(
      encryptedBytes: encryptedBytes,
      password: password,
    );
    await reload();
    await reloadSettings();
    await reloadSnapshots();
    await reloadConsultations();
    await reloadOutputs();
    await reloadGemstoneRemedies();
    await reloadKundliAnalyses();
    await reloadNumerologySnapshots();
    await reloadProfessionalReports();
    await reloadProfessionalReportApprovals();
    await reloadKpHorarySnapshots();
    return result;
  }

  Future<List<BackupImportBatchRecord>> listBackupImportBatches() =>
      EncryptedBackupService(_database).listImportBatches(
        recoverInterrupted: false,
      );

  Future<List<BackupImportMappingRecord>> listBackupImportMappings(
    int batchId,
  ) =>
      EncryptedBackupService(_database).listImportMappings(batchId);

  Future<BackupMergeReceiptArtifact> exportBackupMergeReceipt(
    int batchId,
  ) =>
      EncryptedBackupService(_database).exportMergeReceipt(batchId: batchId);

  Future<void> reload() async {
    final clientRows = await _database.query(
      'clients',
      orderBy: 'full_name COLLATE NOCASE',
    );
    final birthRows = await _database.query(
      'birth_records',
      orderBy: 'local_datetime',
    );
    final birthsByClient = <int, List<BirthRecord>>{};
    for (final row in birthRows) {
      final record = BirthRecord.fromDatabaseMap(row);
      birthsByClient.putIfAbsent(record.clientId!, () => []).add(record);
    }
    _clients
      ..clear()
      ..addAll(clientRows.map((row) {
        final id = row['id'] as int;
        return Client.fromDatabaseMap(row, birthsByClient[id] ?? const []);
      }));
    notifyListeners();
  }

  Future<int> addClient(Client client) async {
    final clientId = await _database.transaction((transaction) async {
      final id = await transaction.insert('clients', client.toDatabaseMap());
      for (final birthRecord in client.birthRecords) {
        await transaction.insert(
          'birth_records',
          birthRecord.toDatabaseMap(ownerId: id),
        );
      }
      await _insertAudit(
        transaction,
        entityType: 'client',
        entityId: id,
        action: 'clientCreated',
        summary: {'fullName': client.fullName},
      );
      return id;
    });
    await reload();
    return clientId;
  }

  Client? findById(int id) {
    for (final client in _clients) {
      if (client.id == id) return client;
    }
    return null;
  }

  Future<void> updateClient(Client client) async {
    if (client.id == null) throw ArgumentError('Client id is required');
    await _database.transaction((transaction) async {
      await transaction.update(
        'clients',
        client.toDatabaseMap(),
        where: 'id = ?',
        whereArgs: [client.id],
      );
      await _insertAudit(
        transaction,
        entityType: 'client',
        entityId: client.id,
        action: 'clientUpdated',
        summary: {'fullName': client.fullName},
      );
    });
    await reload();
  }

  Future<void> addBirthRecord(int clientId, BirthRecord record) async {
    await _database.transaction((transaction) async {
      final id = await transaction.insert(
        'birth_records',
        record.toDatabaseMap(ownerId: clientId),
      );
      await _insertAudit(
        transaction,
        entityType: 'client',
        entityId: clientId,
        action: 'birthRecordCreated',
        summary: {'birthRecordId': id, 'label': record.label},
      );
    });
    await reload();
  }

  Future<void> updateBirthRecord(BirthRecord record) async {
    if (record.id == null || record.clientId == null) {
      throw ArgumentError('Birth record and client ids are required');
    }
    await _database.transaction((transaction) async {
      await transaction.update(
        'birth_records',
        record.toDatabaseMap(ownerId: record.clientId!),
        where: 'id = ? AND client_id = ?',
        whereArgs: [record.id, record.clientId],
      );
      await _insertAudit(
        transaction,
        entityType: 'client',
        entityId: record.clientId,
        action: 'birthRecordUpdated',
        summary: {'birthRecordId': record.id, 'label': record.label},
      );
    });
    await reload();
  }

  Future<void> reloadSettings() async {
    final rows = await _database.query(
      'astrology_settings',
      where: 'id = 1',
      limit: 1,
    );
    _settings = rows.isEmpty
        ? AstrologySettings.defaults
        : AstrologySettings.fromDatabaseMap(rows.first);
    notifyListeners();
  }

  Future<void> updateSettings(AstrologySettings settings) async {
    await _database.transaction((transaction) async {
      await transaction.insert(
        'astrology_settings',
        settings.toDatabaseMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await _insertAudit(
        transaction,
        entityType: 'settings',
        entityId: 1,
        action: 'settingsUpdated',
        summary: settings.toDatabaseMap(),
      );
    });
    _settings = settings;
    notifyListeners();
  }

  Future<void> reloadSnapshots() async {
    final rows = await _database.query(
      'calculation_snapshots',
      orderBy: 'created_at DESC',
    );
    _snapshots
      ..clear()
      ..addAll(rows.map(CalculationSnapshot.fromDatabaseMap));
    notifyListeners();
  }

  List<CalculationSnapshot> snapshotsForClient(int clientId) => _snapshots
      .where((snapshot) => snapshot.clientId == clientId)
      .toList(growable: false);

  CalculationSnapshot? findSnapshotById(int id) {
    for (final snapshot in _snapshots) {
      if (snapshot.id == id) return snapshot;
    }
    return null;
  }

  Future<int> createInputSnapshot({
    required Client client,
    required BirthRecord birthRecord,
  }) async {
    if (client.id == null || birthRecord.id == null) {
      throw ArgumentError('Saved client and birth record are required');
    }
    final input = <String, Object?>{
      'clientId': client.id,
      'birthRecordId': birthRecord.id,
      'localDateTime': birthRecord.localDateTime.toIso8601String(),
      'utcDateTime': birthRecord.utcDateTime.toIso8601String(),
      'utcOffsetMinutes': birthRecord.utcOffsetMinutes,
      'placeName': birthRecord.placeName,
      'latitude': birthRecord.latitude,
      'longitude': birthRecord.longitude,
      'timeConfidence': birthRecord.confidence.name,
    };
    final calculationSettings = <String, Object?>{
      'ayanamsha': _settings.ayanamsha.name,
      'vedicChartStyle': _settings.vedicChartStyle.name,
      'westernHouseSystem': _settings.westernHouseSystem.name,
      'lunarNodeMode': _settings.lunarNodeMode.name,
    };
    final inputJson = jsonEncode(input);
    final settingsJson = jsonEncode(calculationSettings);
    final hash = SnapshotIntegrity.sha256For(
      input: input,
      settings: calculationSettings,
      schemaVersion: 'input-schema-v1',
    );
    for (final snapshot in _snapshots) {
      if (snapshot.clientId == client.id &&
          snapshot.birthRecordId == birthRecord.id &&
          snapshot.inputHash == hash) {
        return snapshot.id;
      }
    }
    final createdAt = DateTime.now().toUtc().toIso8601String();

    final snapshotId = await _database.transaction((transaction) async {
      final id = await transaction.insert('calculation_snapshots', {
        'client_id': client.id,
        'birth_record_id': birthRecord.id,
        'label': birthRecord.label,
        'snapshot_kind': 'input',
        'schema_version': 'input-schema-v1',
        'input_json': inputJson,
        'settings_json': settingsJson,
        'input_hash': hash,
        'created_at': createdAt,
      });
      await _insertAudit(
        transaction,
        entityType: 'client',
        entityId: client.id,
        action: 'snapshotCreated',
        summary: {'snapshotId': id, 'inputHash': hash},
      );
      return id;
    });
    await reloadSnapshots();
    return snapshotId;
  }


  Future<int> createKpInputSnapshot({
    required Client client,
    required BirthRecord birthRecord,
    required LunarNodeMode nodeMode,
  }) async {
    if (client.id == null || birthRecord.id == null) {
      throw ArgumentError('Saved client and birth record are required');
    }
    final input = <String, Object?>{
      'clientId': client.id,
      'birthRecordId': birthRecord.id,
      'localDateTime': birthRecord.localDateTime.toIso8601String(),
      'utcDateTime': birthRecord.utcDateTime.toIso8601String(),
      'utcOffsetMinutes': birthRecord.utcOffsetMinutes,
      'placeName': birthRecord.placeName,
      'latitude': birthRecord.latitude,
      'longitude': birthRecord.longitude,
      'timeConfidence': birthRecord.confidence.name,
    };
    final calculationSettings = <String, Object?>{
      'system': 'kp',
      'ayanamshaProfile': KpGovernance.ayanamshaProfile,
      'houseProfile': KpGovernance.houseProfile,
      'nodeMode': nodeMode.name,
      'governanceProfile': KpGovernance.profileVersion,
    };
    const schemaVersion = 'kp-input-schema-v1';
    final hash = SnapshotIntegrity.sha256For(
      input: input,
      settings: calculationSettings,
      schemaVersion: schemaVersion,
    );
    for (final snapshot in _snapshots) {
      if (snapshot.clientId == client.id &&
          snapshot.birthRecordId == birthRecord.id &&
          snapshot.snapshotKind == 'kp-input' &&
          snapshot.inputHash == hash) {
        return snapshot.id;
      }
    }

    final snapshotId = await _database.transaction((transaction) async {
      final id = await transaction.insert('calculation_snapshots', {
        'client_id': client.id,
        'birth_record_id': birthRecord.id,
        'label': '${birthRecord.label} • KP',
        'snapshot_kind': 'kp-input',
        'schema_version': schemaVersion,
        'input_json': jsonEncode(input),
        'settings_json': jsonEncode(calculationSettings),
        'input_hash': hash,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });
      await _insertAudit(
        transaction,
        entityType: 'client',
        entityId: client.id,
        action: 'kpInputSnapshotCreated',
        summary: {
          'snapshotId': id,
          'inputHash': hash,
          'ayanamshaProfile': KpGovernance.ayanamshaProfile,
          'houseProfile': KpGovernance.houseProfile,
        },
      );
      return id;
    });
    await reloadSnapshots();
    return snapshotId;
  }

  Future<int> createWesternInputSnapshot({
    required Client client,
    required BirthRecord birthRecord,
    required WesternHouseSystem houseSystem,
    required LunarNodeMode nodeMode,
    required WesternRulershipProfile rulershipProfile,
    required WesternAspectProfile aspectProfile,
    required bool includeModernPlanets,
  }) async {
    if (client.id == null || birthRecord.id == null) {
      throw ArgumentError('Saved client and birth record are required');
    }
    final input = <String, Object?>{
      'clientId': client.id,
      'birthRecordId': birthRecord.id,
      'localDateTime': birthRecord.localDateTime.toIso8601String(),
      'utcDateTime': birthRecord.utcDateTime.toIso8601String(),
      'utcOffsetMinutes': birthRecord.utcOffsetMinutes,
      'placeName': birthRecord.placeName,
      'latitude': birthRecord.latitude,
      'longitude': birthRecord.longitude,
      'timeConfidence': birthRecord.confidence.name,
    };
    final calculationSettings = <String, Object?>{
      'system': 'western',
      'zodiacProfile': WesternGovernance.tropicalProfile,
      'houseSystem': houseSystem.name,
      'houseProfile': WesternGovernance.houseProfile(houseSystem),
      'nodeMode': nodeMode.name,
      'rulershipProfile': rulershipProfile.name,
      'rulershipProfileVersion': WesternGovernance.rulershipProfileId(rulershipProfile),
      'aspectProfile': aspectProfile.name,
      'aspectProfileVersion': WesternGovernance.aspectProfileId(aspectProfile),
      'minorAspectEnabled': WesternGovernance.minorAspectsEnabled(aspectProfile),
      'includeModernPlanets': includeModernPlanets,
      'modernPlanetProfile': WesternGovernance.modernPlanetProfile,
      'aspectPatternEngineVersion': WesternGovernance.patternProfile,
      'dignityProfile': WesternGovernance.dignityProfile,
      'governanceProfile': WesternGovernance.profileVersion,
    };
    const schemaVersion = WesternChartEngine.inputSchemaVersion;
    final hash = SnapshotIntegrity.sha256For(
      input: input,
      settings: calculationSettings,
      schemaVersion: schemaVersion,
    );
    for (final snapshot in _snapshots) {
      if (snapshot.clientId == client.id &&
          snapshot.birthRecordId == birthRecord.id &&
          snapshot.snapshotKind == 'western-input' &&
          snapshot.inputHash == hash) {
        return snapshot.id;
      }
    }

    final snapshotId = await _database.transaction((transaction) async {
      final id = await transaction.insert('calculation_snapshots', {
        'client_id': client.id,
        'birth_record_id': birthRecord.id,
        'label': '${birthRecord.label} • Western',
        'snapshot_kind': 'western-input',
        'schema_version': schemaVersion,
        'input_json': jsonEncode(input),
        'settings_json': jsonEncode(calculationSettings),
        'input_hash': hash,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });
      await _insertAudit(
        transaction,
        entityType: 'client',
        entityId: client.id,
        action: 'westernInputSnapshotCreated',
        summary: {
          'snapshotId': id,
          'inputHash': hash,
          'houseSystem': houseSystem.name,
          'houseProfile': WesternGovernance.houseProfile(houseSystem),
          'zodiacProfile': WesternGovernance.tropicalProfile,
          'rulershipProfile': rulershipProfile.name,
          'aspectProfile': aspectProfile.name,
          'includeModernPlanets': includeModernPlanets,
        },
      );
      return id;
    });
    await reloadSnapshots();
    return snapshotId;
  }

  Future<List<AuditEvent>> auditEventsForClient(int clientId) async {
    final rows = await _database.query(
      'audit_events',
      where: 'entity_type = ? AND entity_id = ?',
      whereArgs: ['client', clientId],
      orderBy: 'created_at DESC, id DESC',
    );
    return rows.map(AuditEvent.fromDatabaseMap).toList(growable: false);
  }

  Future<void> reloadKpHorarySnapshots() async {
    final rows = await _database.query(
      'kp_horary_snapshots',
      orderBy: 'created_at DESC, id DESC',
    );
    _kpHorarySnapshots
      ..clear()
      ..addAll(rows.map(KpHorarySnapshot.fromDatabaseMap));
    notifyListeners();
  }

  KpHorarySnapshot? findKpHorarySnapshotById(int id) {
    for (final snapshot in _kpHorarySnapshots) {
      if (snapshot.id == id) return snapshot;
    }
    return null;
  }

  Future<int> createKpHorarySnapshot({
    required KpHoraryInput input,
    required KpHoraryChart chart,
  }) async {
    final inputMap = input.toJson();
    final settings = <String, Object?>{
      'system': 'kpHorary',
      'ayanamshaProfile': KpGovernance.ayanamshaProfile,
      'houseProfile': KpGovernance.houseProfile,
      'governanceProfile': KpGovernance.profileVersion,
      'numberTableProfile': KpHoraryNumberTable.profileVersion,
      'horaryProfile': KpHoraryEngine.profileVersion,
      'nodeMode': input.nodeMode.name,
      'natalBirthDataUsed': false,
    };
    final outputMap = chart.toJson();
    final inputHash = SnapshotIntegrity.sha256For(
      input: inputMap,
      settings: settings,
      schemaVersion: KpHoraryEngine.inputSchemaVersion,
    );
    final outputHash = SnapshotIntegrity.sha256ForOutput(
      output: outputMap,
      engineId: KpHoraryEngine.engineId,
      engineVersion: KpHoraryEngine.engineVersion,
      outputSchemaVersion: KpHoraryEngine.outputSchemaVersion,
    );
    for (final snapshot in _kpHorarySnapshots) {
      if (snapshot.inputHash == inputHash && snapshot.outputHash == outputHash) {
        return snapshot.id;
      }
    }
    final createdAt = DateTime.now().toUtc().toIso8601String();
    final id = await _database.transaction((transaction) async {
      final snapshotId = await transaction.insert('kp_horary_snapshots', {
        'question_text': input.question.trim(),
        'topic': input.topic?.name,
        'horary_number': input.horaryNumber,
        'query_utc': input.queryUtc.toUtc().toIso8601String(),
        'latitude': input.latitude,
        'longitude': input.longitude,
        'node_mode': input.nodeMode.name,
        'input_schema_version': KpHoraryEngine.inputSchemaVersion,
        'input_json': jsonEncode(inputMap),
        'settings_json': jsonEncode(settings),
        'input_hash': inputHash,
        'engine_id': KpHoraryEngine.engineId,
        'engine_version': KpHoraryEngine.engineVersion,
        'output_schema_version': KpHoraryEngine.outputSchemaVersion,
        'output_json': jsonEncode(outputMap),
        'output_hash': outputHash,
        'created_at': createdAt,
      });
      await _insertAudit(
        transaction,
        entityType: 'kpHorary',
        entityId: snapshotId,
        action: 'kpHorarySnapshotCreated',
        summary: {
          'horaryNumber': input.horaryNumber,
          'topic': input.topic?.name,
          'queryUtc': input.queryUtc.toUtc().toIso8601String(),
          'inputHash': inputHash,
          'outputHash': outputHash,
          'natalBirthDataUsed': false,
        },
      );
      return snapshotId;
    });
    await reloadKpHorarySnapshots();
    return id;
  }

  Future<void> reloadConsultations() async {
    final rows = await _database.query(
      'consultations',
      orderBy: 'created_at DESC',
    );
    _consultations
      ..clear()
      ..addAll(rows.map(Consultation.fromDatabaseMap));
    notifyListeners();
  }

  List<Consultation> consultationsForClient(int clientId) => _consultations
      .where((consultation) => consultation.clientId == clientId)
      .toList(growable: false);

  Consultation? findConsultationById(int id) {
    for (final consultation in _consultations) {
      if (consultation.id == id) return consultation;
    }
    return null;
  }

  Future<int> addConsultation(Consultation consultation) async {
    _validateConsultationLink(consultation);
    final id = await _database.transaction((transaction) async {
      final consultationId = await transaction.insert(
        'consultations',
        consultation.toDatabaseMap(),
      );
      await _insertAudit(
        transaction,
        entityType: 'client',
        entityId: consultation.clientId,
        action: 'consultationCreated',
        summary: {
          'consultationId': consultationId,
          'subject': consultation.subject,
          'category': consultation.category.name,
        },
      );
      return consultationId;
    });
    await reloadConsultations();
    return id;
  }

  Future<void> updateConsultation(Consultation consultation) async {
    if (consultation.id == null) {
      throw ArgumentError('Consultation id is required');
    }
    _validateConsultationLink(consultation);
    final existing = findConsultationById(consultation.id!);
    if (existing == null) throw StateError('Consultation not found');
    if (existing.status == ConsultationStatus.finalized) {
      throw StateError('Finalized consultation is locked');
    }
    final outputsExist = outputsForConsultation(existing.id!).isNotEmpty ||
        numerologySnapshotsForConsultation(existing.id!).isNotEmpty;
    final systemsChanged =
        existing.systems.toSet().difference(consultation.systems.toSet()).isNotEmpty ||
            consultation.systems
                .toSet()
                .difference(existing.systems.toSet())
                .isNotEmpty;
    if (outputsExist &&
        (existing.birthRecordId != consultation.birthRecordId ||
            systemsChanged)) {
      throw StateError('Calculated birth record and systems are locked');
    }
    if (existing.status != consultation.status) {
      _validateStatusTransition(existing, consultation.status);
    }
    await _database.transaction((transaction) async {
      await transaction.update(
        'consultations',
        consultation.toDatabaseMap(),
        where: 'id = ?',
        whereArgs: [consultation.id],
      );
      await _insertAudit(
        transaction,
        entityType: 'client',
        entityId: consultation.clientId,
        action: 'consultationUpdated',
        summary: {
          'consultationId': consultation.id,
          'status': consultation.status.name,
        },
      );
    });
    await reloadConsultations();
  }

  Future<void> reloadOutputs() async {
    final rows = await _database.query(
      'calculation_output_snapshots',
      orderBy: 'created_at DESC',
    );
    _outputs
      ..clear()
      ..addAll(rows.map(CalculationOutputSnapshot.fromDatabaseMap));
    notifyListeners();
  }

  List<CalculationOutputSnapshot> outputsForConsultation(int consultationId) =>
      _outputs
          .where((output) => output.consultationId == consultationId)
          .toList(growable: false);

  CalculationOutputSnapshot? findOutputById(int id) {
    for (final output in _outputs) {
      if (output.id == id) return output;
    }
    return null;
  }

  Future<int> createCalculationOutputSnapshot({
    required Consultation consultation,
    required CalculationSnapshot inputSnapshot,
    required String engineId,
    required String engineVersion,
    required String outputSchemaVersion,
    required Map<String, Object?> output,
  }) async {
    if (consultation.id == null) {
      throw ArgumentError('Saved consultation is required');
    }
    if (consultation.status == ConsultationStatus.finalized) {
      throw StateError('Finalized consultation cannot accept new output');
    }
    if (consultation.clientId != inputSnapshot.clientId ||
        consultation.birthRecordId != inputSnapshot.birthRecordId) {
      throw ArgumentError('Input snapshot does not belong to consultation');
    }
    if (engineId.trim().isEmpty ||
        engineVersion.trim().isEmpty ||
        outputSchemaVersion.trim().isEmpty ||
        output.isEmpty) {
      throw ArgumentError('Versioned non-empty engine output is required');
    }
    final outputHash = SnapshotIntegrity.sha256ForOutput(
      output: output,
      engineId: engineId,
      engineVersion: engineVersion,
      outputSchemaVersion: outputSchemaVersion,
    );
    final id = await _database.transaction((transaction) async {
      final outputId = await transaction.insert(
        'calculation_output_snapshots',
        {
          'consultation_id': consultation.id,
          'input_snapshot_id': inputSnapshot.id,
          'engine_id': engineId,
          'engine_version': engineVersion,
          'output_schema_version': outputSchemaVersion,
          'output_json': jsonEncode(output),
          'output_hash': outputHash,
          'created_at': DateTime.now().toUtc().toIso8601String(),
        },
      );
      await _insertAudit(
        transaction,
        entityType: 'client',
        entityId: consultation.clientId,
        action: 'calculationOutputCreated',
        summary: {
          'consultationId': consultation.id,
          'outputId': outputId,
          'engineId': engineId,
          'engineVersion': engineVersion,
          'outputHash': outputHash,
        },
      );
      return outputId;
    });
    await reloadOutputs();
    return id;
  }

  Future<void> reloadGemstoneRemedies() async {
    final rows = await _database.query(
      'gemstone_remedies',
      orderBy: 'created_at DESC',
    );
    _gemstoneRemedies
      ..clear()
      ..addAll(rows.map(GemstoneRemedy.fromDatabaseMap));
    notifyListeners();
  }

  List<GemstoneRemedy> gemstoneRemediesForConsultation(int consultationId) =>
      _gemstoneRemedies
          .where((remedy) => remedy.consultationId == consultationId)
          .toList(growable: false);

  Future<int> addGemstoneRemedy(GemstoneRemedy remedy) async {
    final consultation = _validateGemstoneRemedyLink(remedy);
    final id = await _database.transaction((transaction) async {
      final remedyId = await transaction.insert(
        'gemstone_remedies',
        remedy.toDatabaseMap(),
      );
      await _insertAudit(
        transaction,
        entityType: 'client',
        entityId: consultation.clientId,
        action: 'gemstoneRemedyCreated',
        summary: {
          'consultationId': consultation.id,
          'remedyId': remedyId,
          'planet': remedy.planet.name,
          'decision': remedy.decision.name,
        },
      );
      return remedyId;
    });
    await reloadGemstoneRemedies();
    return id;
  }

  Future<void> updateGemstoneRemedy(GemstoneRemedy remedy) async {
    if (remedy.id == null) throw ArgumentError('Gemstone remedy id is required');
    final consultation = _validateGemstoneRemedyLink(remedy);
    final changed = await _database.transaction((transaction) async {
      final count = await transaction.update(
        'gemstone_remedies',
        remedy.toDatabaseMap(),
        where: 'id = ? AND consultation_id = ?',
        whereArgs: [remedy.id, remedy.consultationId],
      );
      if (count == 0) throw StateError('Gemstone remedy not found');
      await _insertAudit(
        transaction,
        entityType: 'client',
        entityId: consultation.clientId,
        action: 'gemstoneRemedyUpdated',
        summary: {
          'consultationId': consultation.id,
          'remedyId': remedy.id,
          'planet': remedy.planet.name,
          'decision': remedy.decision.name,
        },
      );
      return count;
    });
    if (changed > 0) await reloadGemstoneRemedies();
  }

  Consultation _validateGemstoneRemedyLink(GemstoneRemedy remedy) {
    final consultation = findConsultationById(remedy.consultationId);
    if (consultation == null) throw ArgumentError('Consultation not found');
    if (consultation.status == ConsultationStatus.finalized) {
      throw StateError('Finalized consultation is locked');
    }
    GemstoneRemedyPolicy.validate(
      remedy,
      verifiedOutputExists:
          outputsForConsultation(consultation.id!).isNotEmpty,
    );
    return consultation;
  }

  Future<void> reloadKundliAnalyses() async {
    final rows = await _database.query(
      'kundli_analysis_snapshots',
      orderBy: 'created_at DESC',
    );
    _kundliAnalyses
      ..clear()
      ..addAll(rows.map(KundliAnalysisSnapshot.fromDatabaseMap));
    notifyListeners();
  }

  List<KundliAnalysisSnapshot> kundliAnalysesForConsultation(
    int consultationId,
  ) =>
      _kundliAnalyses
          .where((analysis) => analysis.consultationId == consultationId)
          .toList(growable: false);

  KundliAnalysisSnapshot? findKundliAnalysisById(int id) {
    for (final analysis in _kundliAnalyses) {
      if (analysis.id == id) return analysis;
    }
    return null;
  }

  Future<int> createKundliAnalysisSnapshot({
    required Consultation consultation,
    required CalculationOutputSnapshot calculationOutput,
    required String engineId,
    required String engineVersion,
    required String analysisSchemaVersion,
    required KundliAnalysis analysis,
  }) async {
    if (consultation.id == null ||
        calculationOutput.consultationId != consultation.id) {
      throw ArgumentError('Calculation output does not belong to consultation');
    }
    if (consultation.status == ConsultationStatus.finalized) {
      throw StateError('Finalized consultation cannot accept new analysis');
    }
    if (engineId.trim().isEmpty ||
        engineVersion.trim().isEmpty ||
        analysisSchemaVersion.trim().isEmpty) {
      throw ArgumentError('Versioned judgment engine identity is required');
    }
    final inputSnapshot = findSnapshotById(calculationOutput.inputSnapshotId);
    if (inputSnapshot == null) throw StateError('Input snapshot not found');
    final timeConfidence = inputSnapshot.input['timeConfidence'] as String?;
    final preciseBirthTime =
        timeConfidence == 'exact' || timeConfidence == 'recorded';
    KundliJudgmentPolicy.validate(
      analysis,
      preciseBirthTime: preciseBirthTime,
    );
    final analysisJson = analysis.toJson();
    final analysisHash = SnapshotIntegrity.sha256ForAnalysis(
      analysis: analysisJson,
      engineId: engineId,
      engineVersion: engineVersion,
      analysisSchemaVersion: analysisSchemaVersion,
      calculationOutputId: calculationOutput.id,
    );
    final id = await _database.transaction((transaction) async {
      final analysisId = await transaction.insert(
        'kundli_analysis_snapshots',
        {
          'consultation_id': consultation.id,
          'calculation_output_id': calculationOutput.id,
          'engine_id': engineId,
          'engine_version': engineVersion,
          'analysis_schema_version': analysisSchemaVersion,
          'analysis_json': jsonEncode(analysisJson),
          'analysis_hash': analysisHash,
          'created_at': DateTime.now().toUtc().toIso8601String(),
        },
      );
      await _insertAudit(
        transaction,
        entityType: 'client',
        entityId: consultation.clientId,
        action: 'kundliAnalysisCreated',
        summary: {
          'consultationId': consultation.id,
          'analysisId': analysisId,
          'calculationOutputId': calculationOutput.id,
          'engineId': engineId,
          'engineVersion': engineVersion,
          'analysisHash': analysisHash,
        },
      );
      return analysisId;
    });
    await reloadKundliAnalyses();
    return id;
  }

  Future<void> reloadNumerologySnapshots() async {
    final rows = await _database.query(
      'numerology_snapshots',
      orderBy: 'created_at DESC, id DESC',
    );
    _numerologySnapshots
      ..clear()
      ..addAll(rows.map(NumerologySnapshot.fromDatabaseMap));
    notifyListeners();
  }

  List<NumerologySnapshot> numerologySnapshotsForConsultation(
    int consultationId,
  ) =>
      _numerologySnapshots
          .where((snapshot) => snapshot.consultationId == consultationId)
          .toList(growable: false);

  NumerologySnapshot? findNumerologySnapshotById(int id) {
    for (final snapshot in _numerologySnapshots) {
      if (snapshot.id == id) return snapshot;
    }
    return null;
  }

  Future<int> createNumerologySnapshot({
    required Consultation consultation,
    required BirthRecord birthRecord,
    required NumerologyProfile profile,
    required NumerologyAnalysis analysis,
  }) async {
    if (consultation.id == null || birthRecord.id == null) {
      throw ArgumentError('Saved consultation and birth record are required');
    }
    if (!consultation.systems.contains(AstrologySystem.numerology)) {
      throw StateError('Numerology was not selected for this consultation');
    }
    if (consultation.status == ConsultationStatus.finalized) {
      throw StateError('Finalized consultation cannot accept Numerology');
    }
    if (consultation.birthRecordId != birthRecord.id ||
        consultation.clientId != birthRecord.clientId) {
      throw ArgumentError('Birth record does not belong to consultation');
    }
    final profileDate = profile.birthDate;
    final recordDate = birthRecord.localDateTime;
    if (profileDate.year != recordDate.year ||
        profileDate.month != recordDate.month ||
        profileDate.day != recordDate.day) {
      throw ArgumentError('Numerology birth date must match consultation');
    }
    NumerologyAnalysisPolicy.validate(analysis);
    final input = <String, Object?>{
      'consultationId': consultation.id,
      'clientId': consultation.clientId,
      'birthRecordId': birthRecord.id,
      'nameLatin': profile.normalizedName,
      'birthDate':
          '${profileDate.year.toString().padLeft(4, '0')}-'
          '${profileDate.month.toString().padLeft(2, '0')}-'
          '${profileDate.day.toString().padLeft(2, '0')}',
      'targetYear': profile.personalYearTarget,
      'alternateNamesLatin': profile.nameCandidateComparisons
          .map((value) => value.candidateName)
          .toList(growable: false),
      'professionalSelectedNameLatin': profile.professionalSelectedNameLatin,
    };
    final calculation = profile.toMap();
    final analysisMap = analysis.toMap();
    final snapshotHash = SnapshotIntegrity.sha256ForNumerology(
      input: input,
      calculation: calculation,
      analysis: analysisMap,
      calculationEngineId: NumerologyEngine.engineId,
      calculationEngineVersion: NumerologyEngine.engineVersion,
      calculationSchemaVersion: NumerologyEngine.outputSchemaVersion,
      analysisEngineId: NumerologyJudgmentEngine.engineId,
      analysisEngineVersion: NumerologyJudgmentEngine.engineVersion,
      analysisSchemaVersion: NumerologyJudgmentEngine.analysisSchemaVersion,
    );
    for (final existing
        in numerologySnapshotsForConsultation(consultation.id!)) {
      if (existing.snapshotHash == snapshotHash) return existing.id;
    }
    final id = await _database.transaction((transaction) async {
      final snapshotId = await transaction.insert('numerology_snapshots', {
        'consultation_id': consultation.id,
        'client_id': consultation.clientId,
        'birth_record_id': birthRecord.id,
        'target_year': profile.personalYearTarget,
        'name_latin': profile.normalizedName,
        'calculation_engine_id': NumerologyEngine.engineId,
        'calculation_engine_version': NumerologyEngine.engineVersion,
        'calculation_schema_version': NumerologyEngine.outputSchemaVersion,
        'calculation_json': jsonEncode(calculation),
        'analysis_engine_id': NumerologyJudgmentEngine.engineId,
        'analysis_engine_version': NumerologyJudgmentEngine.engineVersion,
        'analysis_schema_version':
            NumerologyJudgmentEngine.analysisSchemaVersion,
        'analysis_json': jsonEncode(analysisMap),
        'snapshot_hash': snapshotHash,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });
      await _insertAudit(
        transaction,
        entityType: 'client',
        entityId: consultation.clientId,
        action: 'numerologySnapshotCreated',
        summary: {
          'consultationId': consultation.id,
          'snapshotId': snapshotId,
          'targetYear': profile.personalYearTarget,
          'snapshotHash': snapshotHash,
        },
      );
      return snapshotId;
    });
    await reloadNumerologySnapshots();
    return id;
  }

  void _validateConsultationLink(Consultation consultation) {
    final client = findById(consultation.clientId);
    final belongsToClient = client?.birthRecords.any(
          (record) => record.id == consultation.birthRecordId,
        ) ??
        false;
    if (!belongsToClient) {
      throw ArgumentError('Birth record does not belong to client');
    }
    if (consultation.subject.trim().isEmpty || consultation.systems.isEmpty) {
      throw ArgumentError('Consultation subject and systems are required');
    }
  }

  void _validateStatusTransition(
    Consultation existing,
    ConsultationStatus target,
  ) {
    final outputsExist = outputsForConsultation(existing.id!).isNotEmpty ||
        numerologySnapshotsForConsultation(existing.id!).isNotEmpty;
    final allowed = ConsultationWorkflow.canTransition(
      from: existing.status,
      to: target,
      outputsExist: outputsExist,
    );
    if (!allowed) {
      throw StateError('Invalid consultation status transition');
    }
  }


  Future<void> reloadProfessionalReports() async {
    final rows = await _database.query(
      'professional_report_snapshots',
      orderBy: 'created_at DESC, id DESC',
    );
    _professionalReports
      ..clear()
      ..addAll(rows.map(ProfessionalReportSnapshot.fromDatabaseMap));
    notifyListeners();
  }

  List<ProfessionalReportSnapshot> professionalReportsForConsultation(
    int consultationId,
  ) =>
      _professionalReports
          .where((snapshot) => snapshot.consultationId == consultationId)
          .toList(growable: false);

  Future<void> reloadProfessionalReportApprovals() async {
    final rows = await _database.query(
      'professional_report_approvals',
      orderBy: 'approved_at DESC, id DESC',
    );
    _professionalReportApprovals
      ..clear()
      ..addAll(rows.map(ProfessionalReportApproval.fromDatabaseMap));
    notifyListeners();
  }

  ProfessionalReportApproval? approvalForReport(int reportSnapshotId) {
    for (final approval in _professionalReportApprovals) {
      if (approval.reportSnapshotId == reportSnapshotId) return approval;
    }
    return null;
  }

  List<ProfessionalReportApproval> approvalsForConsultation(
    int consultationId,
  ) =>
      _professionalReportApprovals
          .where((approval) => approval.consultationId == consultationId)
          .toList(growable: false);

  Future<int> approveProfessionalReport({
    required ProfessionalReportSnapshot report,
    required String practitionerName,
    required String practitionerDesignation,
    String credentialReference = '',
    required ProfessionalReportApprovalDecision decision,
    String approvalNote = '',
    DateTime? approvedAtUtc,
  }) async {
    if (approvalForReport(report.id) != null) {
      throw StateError('This immutable report snapshot has already been approved');
    }
    final stored = _professionalReports.where((value) => value.id == report.id).toList();
    if (stored.length != 1) {
      throw StateError('Saved professional report snapshot is required before approval');
    }
    if (stored.single.consultationId != report.consultationId ||
        stored.single.reportHash != report.reportHash) {
      throw StateError('Professional report identity does not match the stored snapshot');
    }
    final calculatedReportHash = SnapshotIntegrity.sha256ForProfessionalReport(
      report: report.report,
      sourceManifest: report.sourceManifest,
      engineId: report.engineId,
      engineVersion: report.engineVersion,
      reportSchemaVersion: report.reportSchemaVersion,
    );
    if (calculatedReportHash != report.reportHash) {
      throw StateError('Professional report content failed immutable hash verification');
    }
    ProfessionalReportApprovalPolicy.validateInput(
      practitionerName: practitionerName,
      practitionerDesignation: practitionerDesignation,
      credentialReference: credentialReference,
      decision: decision,
      approvalNote: approvalNote,
    );
    final approvedAt = (approvedAtUtc ?? DateTime.now()).toUtc();
    final payload = <String, Object?>{
      'reportSnapshotId': report.id,
      'consultationId': report.consultationId,
      'reportHash': report.reportHash,
      'practitionerName': practitionerName.trim(),
      'practitionerDesignation': practitionerDesignation.trim(),
      'credentialReference': credentialReference.trim(),
      'decision': decision.name,
      'approvalNote': approvalNote.trim(),
      'approvedAtUtc': approvedAt.toIso8601String(),
    };
    final approvalHash = SnapshotIntegrity.sha256ForProfessionalReportApproval(
      approvalPayload: payload,
      approvalEngineId: ProfessionalReportApprovalPolicy.engineId,
      approvalEngineVersion: ProfessionalReportApprovalPolicy.engineVersion,
      approvalStatementVersion: ProfessionalReportApprovalPolicy.statementVersion,
    );
    final signedReportHash = SnapshotIntegrity.sha256ForSignedProfessionalReport(
      reportHash: report.reportHash,
      approvalHash: approvalHash,
      approvalStatementVersion: ProfessionalReportApprovalPolicy.statementVersion,
    );
    final id = await _database.transaction((transaction) async {
      final approvalId = await transaction.insert(
        'professional_report_approvals',
        {
          'report_snapshot_id': report.id,
          'consultation_id': report.consultationId,
          'report_hash': report.reportHash,
          'practitioner_name': practitionerName.trim(),
          'practitioner_designation': practitionerDesignation.trim(),
          'credential_reference': credentialReference.trim(),
          'decision': decision.name,
          'approval_note': approvalNote.trim(),
          'approval_engine_id': ProfessionalReportApprovalPolicy.engineId,
          'approval_engine_version': ProfessionalReportApprovalPolicy.engineVersion,
          'approval_statement_version': ProfessionalReportApprovalPolicy.statementVersion,
          'approved_at': approvedAt.toIso8601String(),
          'approval_hash': approvalHash,
          'signed_report_hash': signedReportHash,
        },
      );
      await _insertAudit(
        transaction,
        entityType: 'client',
        entityId: report.report['clientId'] as int?,
        action: 'professionalReportApproved',
        summary: {
          'consultationId': report.consultationId,
          'reportId': report.id,
          'approvalId': approvalId,
          'decision': decision.name,
          'approvalStatementVersion': ProfessionalReportApprovalPolicy.statementVersion,
          'reportHash': report.reportHash,
          'approvalHash': approvalHash,
          'signedReportHash': signedReportHash,
        },
      );
      return approvalId;
    });
    await reloadProfessionalReportApprovals();
    return id;
  }

  Future<int> createProfessionalReportSnapshot({
    required Consultation consultation,
    required ProfessionalConsultationReport report,
    required String engineId,
    required String engineVersion,
    required String reportSchemaVersion,
  }) async {
    if (consultation.id == null || report.consultationId != consultation.id) {
      throw ArgumentError('Professional report does not belong to consultation');
    }
    if (consultation.status == ConsultationStatus.finalized) {
      throw StateError('Finalized consultation cannot accept a new report');
    }
    if (engineId.trim().isEmpty ||
        engineVersion.trim().isEmpty ||
        reportSchemaVersion.trim().isEmpty) {
      throw ArgumentError('Versioned report engine identity is required');
    }
    ProfessionalReportPolicy.validate(report);
    final reportJson = report.toJson();
    final sourceManifest = report.sources
        .map((value) => value.toJson())
        .toList(growable: false);
    final reportHash = SnapshotIntegrity.sha256ForProfessionalReport(
      report: reportJson,
      sourceManifest: sourceManifest,
      engineId: engineId,
      engineVersion: engineVersion,
      reportSchemaVersion: reportSchemaVersion,
    );
    for (final existing in professionalReportsForConsultation(consultation.id!)) {
      if (existing.reportHash == reportHash) return existing.id;
    }
    final id = await _database.transaction((transaction) async {
      final snapshotId = await transaction.insert(
        'professional_report_snapshots',
        {
          'consultation_id': consultation.id,
          'engine_id': engineId,
          'engine_version': engineVersion,
          'report_schema_version': reportSchemaVersion,
          'source_manifest_json': jsonEncode(sourceManifest),
          'report_json': jsonEncode(reportJson),
          'report_hash': reportHash,
          'created_at': DateTime.now().toUtc().toIso8601String(),
        },
      );
      await _insertAudit(
        transaction,
        entityType: 'client',
        entityId: consultation.clientId,
        action: 'professionalReportCreated',
        summary: {
          'consultationId': consultation.id,
          'reportId': snapshotId,
          'engineId': engineId,
          'engineVersion': engineVersion,
          'reportSchemaVersion': reportSchemaVersion,
          'reportHash': reportHash,
        },
      );
      return snapshotId;
    });
    await reloadProfessionalReports();
    return id;
  }

  static Future<void> _insertAudit(
    DatabaseExecutor executor, {
    required String entityType,
    required int? entityId,
    required String action,
    required Map<String, Object?> summary,
  }) async {
    await executor.insert('audit_events', {
      'entity_type': entityType,
      'entity_id': entityId,
      'action': action,
      'summary_json': jsonEncode(summary),
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  List<Client> search(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return clients;
    return _clients.where((client) {
      return client.fullName.toLowerCase().contains(normalized) ||
          client.mobile.toLowerCase().contains(normalized) ||
          client.birthRecords.any(
            (birth) => birth.placeName.toLowerCase().contains(normalized),
          );
    }).toList(growable: false);
  }
}
