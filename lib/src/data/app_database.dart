import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart' as mobile;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class AppDatabase {
  const AppDatabase._();

  static const schemaVersion = 12;

  static Future<Database> open() async {
    final databaseFactory = Platform.isAndroid
        ? mobile.databaseFactory
        : _desktopDatabaseFactory();
    final supportDirectory = await getApplicationSupportDirectory();
    final databaseDirectory = Directory(p.join(supportDirectory.path, 'database'));
    await databaseDirectory.create(recursive: true);
    final databasePath = p.join(databaseDirectory.path, 'astro_logic.db');

    return databaseFactory.openDatabase(
      databasePath,
      options: OpenDatabaseOptions(
        version: schemaVersion,
        onConfigure: (database) async {
          await database.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: (database, version) async {
          await database.execute('''
            CREATE TABLE clients (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              full_name TEXT NOT NULL,
              mobile TEXT NOT NULL DEFAULT '',
              email TEXT NOT NULL DEFAULT '',
              gender TEXT NOT NULL,
              notes TEXT NOT NULL DEFAULT '',
              created_at TEXT NOT NULL
            )
          ''');
          await database.execute('''
            CREATE TABLE birth_records (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              client_id INTEGER NOT NULL,
              label TEXT NOT NULL,
              local_datetime TEXT NOT NULL,
              utc_datetime TEXT NOT NULL,
              utc_offset_minutes INTEGER NOT NULL,
              place_name TEXT NOT NULL,
              latitude REAL NOT NULL CHECK(latitude BETWEEN -90 AND 90),
              longitude REAL NOT NULL CHECK(longitude BETWEEN -180 AND 180),
              confidence TEXT NOT NULL,
              source_note TEXT NOT NULL DEFAULT '',
              FOREIGN KEY(client_id) REFERENCES clients(id) ON DELETE CASCADE
            )
          ''');
          await database.execute(
            'CREATE INDEX birth_records_client_idx ON birth_records(client_id)',
          );
          await database.execute(
            'CREATE INDEX clients_name_idx ON clients(full_name COLLATE NOCASE)',
          );
          await _createSettingsTable(database);
          await _createGovernanceTables(database);
          await _createConsultationTables(database);
          await _createGemstoneRemedyTables(database);
          await _createKundliAnalysisTables(database);
          await _createNumerologySnapshotTables(database);
          await _createProfessionalReportTables(database);
          await _createProfessionalReportApprovalTables(database);
          await _createBackupImportLedgerTables(database);
          await _createKpHorarySnapshotTables(database);
        },
        onUpgrade: (database, oldVersion, newVersion) async {
          if (oldVersion < 2) {
            await _createSettingsTable(database);
          }
          if (oldVersion < 3) {
            await _createGovernanceTables(database);
          }
          if (oldVersion < 4) {
            await _createConsultationTables(database);
          }
          if (oldVersion < 5) {
            await _createGemstoneRemedyTables(database);
          }
          if (oldVersion < 6) {
            await _createKundliAnalysisTables(database);
          }
          if (oldVersion < 7) {
            await _createNumerologySnapshotTables(database);
          }
          if (oldVersion < 8) {
            await _createProfessionalReportTables(database);
          }
          if (oldVersion < 9) {
            await _createProfessionalReportApprovalTables(database);
          }
          if (oldVersion < 10) {
            await _addGovernedMergeIntegrityColumns(database);
          }
          if (oldVersion < 11) {
            await _createBackupImportLedgerTables(database);
          }
          if (oldVersion < 12) {
            await _createKpHorarySnapshotTables(database);
          }
        },
      ),
    );
  }

  static DatabaseFactory _desktopDatabaseFactory() {
    sqfliteFfiInit();
    return databaseFactoryFfi;
  }

  static Future<void> _createSettingsTable(Database database) async {
    await database.execute('''
      CREATE TABLE IF NOT EXISTS astrology_settings (
        id INTEGER PRIMARY KEY CHECK(id = 1),
        ayanamsha TEXT NOT NULL,
        vedic_chart_style TEXT NOT NULL,
        western_house_system TEXT NOT NULL,
        lunar_node_mode TEXT NOT NULL
      )
    ''');
    await database.insert(
      'astrology_settings',
      {
        'id': 1,
        'ayanamsha': 'lahiri',
        'vedic_chart_style': 'northIndian',
        'western_house_system': 'placidus',
        'lunar_node_mode': 'trueNode',
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  static Future<void> _createGovernanceTables(Database database) async {
    await database.execute('''
      CREATE TABLE IF NOT EXISTS audit_events (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        entity_type TEXT NOT NULL,
        entity_id INTEGER,
        action TEXT NOT NULL,
        summary_json TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
    await database.execute('''
      CREATE TABLE IF NOT EXISTS calculation_snapshots (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        client_id INTEGER NOT NULL,
        birth_record_id INTEGER NOT NULL,
        label TEXT NOT NULL,
        snapshot_kind TEXT NOT NULL,
        schema_version TEXT NOT NULL,
        input_json TEXT NOT NULL,
        settings_json TEXT NOT NULL,
        input_hash TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY(client_id) REFERENCES clients(id) ON DELETE RESTRICT,
        FOREIGN KEY(birth_record_id) REFERENCES birth_records(id) ON DELETE RESTRICT
      )
    ''');
    await database.execute(
      'CREATE INDEX IF NOT EXISTS audit_entity_idx '
      'ON audit_events(entity_type, entity_id, created_at)',
    );
    await database.execute(
      'CREATE INDEX IF NOT EXISTS snapshot_client_idx '
      'ON calculation_snapshots(client_id, created_at)',
    );
    await database.execute('''
      CREATE TRIGGER IF NOT EXISTS calculation_snapshots_no_update
      BEFORE UPDATE ON calculation_snapshots
      BEGIN
        SELECT RAISE(ABORT, 'calculation snapshots are immutable');
      END
    ''');
    await database.execute('''
      CREATE TRIGGER IF NOT EXISTS calculation_snapshots_no_delete
      BEFORE DELETE ON calculation_snapshots
      BEGIN
        SELECT RAISE(ABORT, 'calculation snapshots are immutable');
      END
    ''');
  }

  static Future<void> _createConsultationTables(Database database) async {
    await database.execute('''
      CREATE TABLE IF NOT EXISTS consultations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        client_id INTEGER NOT NULL,
        birth_record_id INTEGER NOT NULL,
        subject TEXT NOT NULL,
        category TEXT NOT NULL,
        systems_json TEXT NOT NULL,
        status TEXT NOT NULL,
        notes TEXT NOT NULL DEFAULT '',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY(client_id) REFERENCES clients(id) ON DELETE RESTRICT,
        FOREIGN KEY(birth_record_id) REFERENCES birth_records(id) ON DELETE RESTRICT
      )
    ''');
    await database.execute('''
      CREATE TABLE IF NOT EXISTS calculation_output_snapshots (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        consultation_id INTEGER NOT NULL,
        input_snapshot_id INTEGER NOT NULL,
        engine_id TEXT NOT NULL,
        engine_version TEXT NOT NULL,
        output_schema_version TEXT NOT NULL,
        output_json TEXT NOT NULL,
        output_hash TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY(consultation_id) REFERENCES consultations(id) ON DELETE RESTRICT,
        FOREIGN KEY(input_snapshot_id) REFERENCES calculation_snapshots(id) ON DELETE RESTRICT
      )
    ''');
    await database.execute(
      'CREATE INDEX IF NOT EXISTS consultation_client_idx '
      'ON consultations(client_id, created_at)',
    );
    await database.execute(
      'CREATE INDEX IF NOT EXISTS output_consultation_idx '
      'ON calculation_output_snapshots(consultation_id, created_at)',
    );
    await database.execute('''
      CREATE TRIGGER IF NOT EXISTS calculation_outputs_no_update
      BEFORE UPDATE ON calculation_output_snapshots
      BEGIN
        SELECT RAISE(ABORT, 'calculation output snapshots are immutable');
      END
    ''');
    await database.execute('''
      CREATE TRIGGER IF NOT EXISTS calculation_outputs_no_delete
      BEFORE DELETE ON calculation_output_snapshots
      BEGIN
        SELECT RAISE(ABORT, 'calculation output snapshots are immutable');
      END
    ''');
  }

  static Future<void> _createGemstoneRemedyTables(Database database) async {
    await database.execute('''
      CREATE TABLE IF NOT EXISTS gemstone_remedies (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        consultation_id INTEGER NOT NULL,
        planet TEXT NOT NULL,
        primary_gemstone TEXT NOT NULL,
        substitute_gemstone TEXT NOT NULL DEFAULT '',
        weight_value REAL NOT NULL CHECK(weight_value > 0 AND weight_value <= 100),
        weight_unit TEXT NOT NULL,
        metal TEXT NOT NULL DEFAULT '',
        finger TEXT NOT NULL DEFAULT '',
        wearing_day TEXT NOT NULL DEFAULT '',
        instructions TEXT NOT NULL DEFAULT '',
        astrological_reason TEXT NOT NULL,
        evidence_json TEXT NOT NULL,
        cautions TEXT NOT NULL,
        decision TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY(consultation_id) REFERENCES consultations(id) ON DELETE RESTRICT
      )
    ''');
    await database.execute(
      'CREATE INDEX IF NOT EXISTS gemstone_consultation_idx '
      'ON gemstone_remedies(consultation_id, created_at)',
    );
  }

  static Future<void> _createKundliAnalysisTables(Database database) async {
    await database.execute('''
      CREATE TABLE IF NOT EXISTS kundli_analysis_snapshots (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        consultation_id INTEGER NOT NULL,
        calculation_output_id INTEGER NOT NULL,
        source_calculation_output_id INTEGER,
        engine_id TEXT NOT NULL,
        engine_version TEXT NOT NULL,
        analysis_schema_version TEXT NOT NULL,
        analysis_json TEXT NOT NULL,
        analysis_hash TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY(consultation_id) REFERENCES consultations(id) ON DELETE RESTRICT,
        FOREIGN KEY(calculation_output_id) REFERENCES calculation_output_snapshots(id) ON DELETE RESTRICT
      )
    ''');
    await database.execute(
      'CREATE INDEX IF NOT EXISTS analysis_consultation_idx '
      'ON kundli_analysis_snapshots(consultation_id, created_at)',
    );
    await database.execute('''
      CREATE TRIGGER IF NOT EXISTS kundli_analysis_no_update
      BEFORE UPDATE ON kundli_analysis_snapshots
      BEGIN
        SELECT RAISE(ABORT, 'kundli analysis snapshots are immutable');
      END
    ''');
    await database.execute('''
      CREATE TRIGGER IF NOT EXISTS kundli_analysis_no_delete
      BEFORE DELETE ON kundli_analysis_snapshots
      BEGIN
        SELECT RAISE(ABORT, 'kundli analysis snapshots are immutable');
      END
    ''');
  }

  static Future<void> _createNumerologySnapshotTables(
    Database database,
  ) async {
    await database.execute('''
      CREATE TABLE IF NOT EXISTS numerology_snapshots (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        consultation_id INTEGER NOT NULL,
        client_id INTEGER NOT NULL,
        birth_record_id INTEGER NOT NULL,
        source_consultation_id INTEGER,
        source_client_id INTEGER,
        source_birth_record_id INTEGER,
        target_year INTEGER NOT NULL CHECK(target_year BETWEEN 1900 AND 9999),
        name_latin TEXT NOT NULL,
        calculation_engine_id TEXT NOT NULL,
        calculation_engine_version TEXT NOT NULL,
        calculation_schema_version TEXT NOT NULL,
        calculation_json TEXT NOT NULL,
        analysis_engine_id TEXT NOT NULL,
        analysis_engine_version TEXT NOT NULL,
        analysis_schema_version TEXT NOT NULL,
        analysis_json TEXT NOT NULL,
        snapshot_hash TEXT NOT NULL CHECK(length(snapshot_hash) = 64),
        created_at TEXT NOT NULL,
        UNIQUE(consultation_id, snapshot_hash),
        FOREIGN KEY(consultation_id) REFERENCES consultations(id) ON DELETE RESTRICT,
        FOREIGN KEY(client_id) REFERENCES clients(id) ON DELETE RESTRICT,
        FOREIGN KEY(birth_record_id) REFERENCES birth_records(id) ON DELETE RESTRICT
      )
    ''');
    await database.execute(
      'CREATE INDEX IF NOT EXISTS numerology_consultation_idx '
      'ON numerology_snapshots(consultation_id, created_at)',
    );
    await database.execute('''
      CREATE TRIGGER IF NOT EXISTS numerology_snapshots_no_update
      BEFORE UPDATE ON numerology_snapshots
      BEGIN
        SELECT RAISE(ABORT, 'numerology snapshots are immutable');
      END
    ''');
    await database.execute('''
      CREATE TRIGGER IF NOT EXISTS numerology_snapshots_no_delete
      BEFORE DELETE ON numerology_snapshots
      BEGIN
        SELECT RAISE(ABORT, 'numerology snapshots are immutable');
      END
    ''');
  }

  static Future<void> _createProfessionalReportTables(Database database) async {
    await database.execute('''
      CREATE TABLE IF NOT EXISTS professional_report_snapshots (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        consultation_id INTEGER NOT NULL,
        source_report_snapshot_id INTEGER,
        source_consultation_id INTEGER,
        engine_id TEXT NOT NULL,
        engine_version TEXT NOT NULL,
        report_schema_version TEXT NOT NULL,
        source_manifest_json TEXT NOT NULL,
        report_json TEXT NOT NULL,
        report_hash TEXT NOT NULL CHECK(length(report_hash) = 64),
        created_at TEXT NOT NULL,
        UNIQUE(consultation_id, report_hash),
        FOREIGN KEY(consultation_id) REFERENCES consultations(id) ON DELETE RESTRICT
      )
    ''');
    await database.execute(
      'CREATE INDEX IF NOT EXISTS professional_report_consultation_idx '
      'ON professional_report_snapshots(consultation_id, created_at)',
    );
    await database.execute('''
      CREATE TRIGGER IF NOT EXISTS professional_report_snapshots_no_update
      BEFORE UPDATE ON professional_report_snapshots
      BEGIN
        SELECT RAISE(ABORT, 'professional report snapshots are immutable');
      END
    ''');
    await database.execute('''
      CREATE TRIGGER IF NOT EXISTS professional_report_snapshots_no_delete
      BEFORE DELETE ON professional_report_snapshots
      BEGIN
        SELECT RAISE(ABORT, 'professional report snapshots are immutable');
      END
    ''');
  }


  static Future<void> _createProfessionalReportApprovalTables(
    Database database,
  ) async {
    await database.execute('''
      CREATE TABLE IF NOT EXISTS professional_report_approvals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        report_snapshot_id INTEGER NOT NULL UNIQUE,
        consultation_id INTEGER NOT NULL,
        source_report_snapshot_id INTEGER,
        source_consultation_id INTEGER,
        report_hash TEXT NOT NULL CHECK(length(report_hash) = 64),
        practitioner_name TEXT NOT NULL,
        practitioner_designation TEXT NOT NULL,
        credential_reference TEXT NOT NULL DEFAULT '',
        decision TEXT NOT NULL,
        approval_note TEXT NOT NULL DEFAULT '',
        approval_engine_id TEXT NOT NULL,
        approval_engine_version TEXT NOT NULL,
        approval_statement_version TEXT NOT NULL,
        approved_at TEXT NOT NULL,
        approval_hash TEXT NOT NULL CHECK(length(approval_hash) = 64),
        signed_report_hash TEXT NOT NULL CHECK(length(signed_report_hash) = 64),
        UNIQUE(consultation_id, signed_report_hash),
        FOREIGN KEY(report_snapshot_id) REFERENCES professional_report_snapshots(id) ON DELETE RESTRICT,
        FOREIGN KEY(consultation_id) REFERENCES consultations(id) ON DELETE RESTRICT
      )
    ''');
    await database.execute(
      'CREATE INDEX IF NOT EXISTS professional_report_approval_consultation_idx '
      'ON professional_report_approvals(consultation_id, approved_at)',
    );
    await database.execute('''
      CREATE TRIGGER IF NOT EXISTS professional_report_approvals_report_guard
      BEFORE INSERT ON professional_report_approvals
      WHEN NEW.report_hash != (
        SELECT report_hash FROM professional_report_snapshots
        WHERE id = NEW.report_snapshot_id
      )
      BEGIN
        SELECT RAISE(ABORT, 'approval report hash does not match immutable report snapshot');
      END
    ''');
    await database.execute('''
      CREATE TRIGGER IF NOT EXISTS professional_report_approvals_consultation_guard
      BEFORE INSERT ON professional_report_approvals
      WHEN NEW.consultation_id != (
        SELECT consultation_id FROM professional_report_snapshots
        WHERE id = NEW.report_snapshot_id
      )
      BEGIN
        SELECT RAISE(ABORT, 'approval consultation does not match report snapshot');
      END
    ''');
    await database.execute('''
      CREATE TRIGGER IF NOT EXISTS professional_report_approvals_no_update
      BEFORE UPDATE ON professional_report_approvals
      BEGIN
        SELECT RAISE(ABORT, 'professional report approvals are immutable');
      END
    ''');
    await database.execute('''
      CREATE TRIGGER IF NOT EXISTS professional_report_approvals_no_delete
      BEFORE DELETE ON professional_report_approvals
      BEGIN
        SELECT RAISE(ABORT, 'professional report approvals are immutable');
      END
    ''');
  }



  static Future<void> _createKpHorarySnapshotTables(Database database) async {
    await database.execute('''
      CREATE TABLE IF NOT EXISTS kp_horary_snapshots (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        question_text TEXT NOT NULL,
        topic TEXT,
        horary_number INTEGER NOT NULL CHECK(horary_number BETWEEN 1 AND 249),
        query_utc TEXT NOT NULL,
        latitude REAL NOT NULL CHECK(latitude BETWEEN -89 AND 89),
        longitude REAL NOT NULL CHECK(longitude BETWEEN -180 AND 180),
        node_mode TEXT NOT NULL,
        input_schema_version TEXT NOT NULL,
        input_json TEXT NOT NULL,
        settings_json TEXT NOT NULL,
        input_hash TEXT NOT NULL,
        engine_id TEXT NOT NULL,
        engine_version TEXT NOT NULL,
        output_schema_version TEXT NOT NULL,
        output_json TEXT NOT NULL,
        output_hash TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
    await database.execute(
      'CREATE INDEX IF NOT EXISTS kp_horary_created_idx '
      'ON kp_horary_snapshots(created_at DESC)',
    );
    await database.execute(
      'CREATE INDEX IF NOT EXISTS kp_horary_number_idx '
      'ON kp_horary_snapshots(horary_number, query_utc)',
    );
    await database.execute('''
      CREATE TRIGGER IF NOT EXISTS kp_horary_snapshots_no_update
      BEFORE UPDATE ON kp_horary_snapshots
      BEGIN
        SELECT RAISE(ABORT, 'KP horary snapshots are immutable');
      END
    ''');
    await database.execute('''
      CREATE TRIGGER IF NOT EXISTS kp_horary_snapshots_no_delete
      BEFORE DELETE ON kp_horary_snapshots
      BEGIN
        SELECT RAISE(ABORT, 'KP horary snapshots are immutable');
      END
    ''');
  }

  static Future<void> _createBackupImportLedgerTables(Database database) async {
    await database.execute('''
      CREATE TABLE IF NOT EXISTS backup_import_batches (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        manifest_hash TEXT NOT NULL CHECK(length(manifest_hash) = 64),
        source_app_version TEXT NOT NULL,
        source_engine_version TEXT NOT NULL,
        source_database_schema_version INTEGER NOT NULL,
        backup_created_at TEXT NOT NULL,
        started_at TEXT NOT NULL,
        completed_at TEXT,
        status TEXT NOT NULL CHECK(status IN ('started', 'committed', 'failed')),
        inserted_rows INTEGER NOT NULL DEFAULT 0 CHECK(inserted_rows >= 0),
        equivalent_rows INTEGER NOT NULL DEFAULT 0 CHECK(equivalent_rows >= 0),
        remapped_rows INTEGER NOT NULL DEFAULT 0 CHECK(remapped_rows >= 0),
        imported_audit_events INTEGER NOT NULL DEFAULT 0 CHECK(imported_audit_events >= 0),
        mapping_rows INTEGER NOT NULL DEFAULT 0 CHECK(mapping_rows >= 0),
        rollback_policy TEXT NOT NULL,
        source_integrity_ids_preserved INTEGER NOT NULL CHECK(source_integrity_ids_preserved IN (0, 1)),
        diagnostics_json TEXT NOT NULL DEFAULT '{}',
        receipt_hash TEXT CHECK(receipt_hash IS NULL OR length(receipt_hash) = 64)
      )
    ''');
    await database.execute('''
      CREATE UNIQUE INDEX IF NOT EXISTS backup_import_committed_manifest_idx
      ON backup_import_batches(manifest_hash)
      WHERE status = 'committed'
    ''');
    await database.execute('''
      CREATE INDEX IF NOT EXISTS backup_import_batches_status_idx
      ON backup_import_batches(status, started_at)
    ''');
    await database.execute('''
      CREATE TABLE IF NOT EXISTS backup_import_mappings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        batch_id INTEGER NOT NULL,
        table_name TEXT NOT NULL,
        source_id INTEGER NOT NULL CHECK(source_id > 0),
        local_id INTEGER NOT NULL CHECK(local_id > 0),
        resolution TEXT NOT NULL CHECK(resolution IN ('inserted', 'equivalent', 'remapped')),
        source_row_sha256 TEXT NOT NULL CHECK(length(source_row_sha256) = 64),
        local_row_sha256 TEXT NOT NULL CHECK(length(local_row_sha256) = 64),
        created_at TEXT NOT NULL,
        UNIQUE(batch_id, table_name, source_id),
        FOREIGN KEY(batch_id) REFERENCES backup_import_batches(id) ON DELETE RESTRICT
      )
    ''');
    await database.execute('''
      CREATE INDEX IF NOT EXISTS backup_import_mappings_lookup_idx
      ON backup_import_mappings(table_name, source_id, local_id)
    ''');
    await database.execute('''
      CREATE TRIGGER IF NOT EXISTS backup_import_batches_no_delete
      BEFORE DELETE ON backup_import_batches
      BEGIN
        SELECT RAISE(ABORT, 'backup import batch ledger is append-preserving');
      END
    ''');
    await database.execute('''
      CREATE TRIGGER IF NOT EXISTS backup_import_batches_terminal_no_update
      BEFORE UPDATE ON backup_import_batches
      WHEN OLD.status IN ('committed', 'failed')
      BEGIN
        SELECT RAISE(ABORT, 'terminal backup import batches are immutable');
      END
    ''');
    await database.execute('''
      CREATE TRIGGER IF NOT EXISTS backup_import_mappings_no_update
      BEFORE UPDATE ON backup_import_mappings
      BEGIN
        SELECT RAISE(ABORT, 'backup import mappings are immutable');
      END
    ''');
    await database.execute('''
      CREATE TRIGGER IF NOT EXISTS backup_import_mappings_no_delete
      BEFORE DELETE ON backup_import_mappings
      BEGIN
        SELECT RAISE(ABORT, 'backup import mappings are immutable');
      END
    ''');
  }

  static Future<void> _addGovernedMergeIntegrityColumns(
    Database database,
  ) async {
    Future<void> addColumn(String table, String definition) async {
      final columns = await database.rawQuery('PRAGMA table_info($table)');
      final name = definition.split(' ').first;
      if (columns.any((row) => row['name'] == name)) return;
      await database.execute('ALTER TABLE $table ADD COLUMN $definition');
    }

    await addColumn(
      'kundli_analysis_snapshots',
      'source_calculation_output_id INTEGER',
    );
    await addColumn(
      'numerology_snapshots',
      'source_consultation_id INTEGER',
    );
    await addColumn('numerology_snapshots', 'source_client_id INTEGER');
    await addColumn(
      'numerology_snapshots',
      'source_birth_record_id INTEGER',
    );
    await addColumn(
      'professional_report_snapshots',
      'source_report_snapshot_id INTEGER',
    );
    await addColumn(
      'professional_report_snapshots',
      'source_consultation_id INTEGER',
    );
    await addColumn(
      'professional_report_approvals',
      'source_report_snapshot_id INTEGER',
    );
    await addColumn(
      'professional_report_approvals',
      'source_consultation_id INTEGER',
    );
  }

}
