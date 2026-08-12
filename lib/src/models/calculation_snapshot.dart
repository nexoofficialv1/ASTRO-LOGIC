import 'dart:convert';

class CalculationSnapshot {
  const CalculationSnapshot({
    required this.id,
    required this.clientId,
    required this.birthRecordId,
    required this.label,
    required this.snapshotKind,
    required this.schemaVersion,
    required this.inputHash,
    required this.input,
    required this.settings,
    required this.createdAt,
  });

  final int id;
  final int clientId;
  final int birthRecordId;
  final String label;
  final String snapshotKind;
  final String schemaVersion;
  final String inputHash;
  final Map<String, Object?> input;
  final Map<String, Object?> settings;
  final DateTime createdAt;

  factory CalculationSnapshot.fromDatabaseMap(Map<String, Object?> map) =>
      CalculationSnapshot(
        id: map['id'] as int,
        clientId: map['client_id'] as int,
        birthRecordId: map['birth_record_id'] as int,
        label: map['label'] as String,
        snapshotKind: map['snapshot_kind'] as String,
        schemaVersion: map['schema_version'] as String,
        inputHash: map['input_hash'] as String,
        input: Map<String, Object?>.from(
          jsonDecode(map['input_json'] as String) as Map,
        ),
        settings: Map<String, Object?>.from(
          jsonDecode(map['settings_json'] as String) as Map,
        ),
        createdAt: DateTime.parse(map['created_at'] as String),
      );
}

