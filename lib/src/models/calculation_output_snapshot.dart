import 'dart:convert';

class CalculationOutputSnapshot {
  const CalculationOutputSnapshot({
    required this.id,
    required this.consultationId,
    required this.inputSnapshotId,
    required this.engineId,
    required this.engineVersion,
    required this.outputSchemaVersion,
    required this.output,
    required this.outputHash,
    required this.createdAt,
  });

  final int id;
  final int consultationId;
  final int inputSnapshotId;
  final String engineId;
  final String engineVersion;
  final String outputSchemaVersion;
  final Map<String, Object?> output;
  final String outputHash;
  final DateTime createdAt;

  factory CalculationOutputSnapshot.fromDatabaseMap(
    Map<String, Object?> map,
  ) =>
      CalculationOutputSnapshot(
        id: map['id'] as int,
        consultationId: map['consultation_id'] as int,
        inputSnapshotId: map['input_snapshot_id'] as int,
        engineId: map['engine_id'] as String,
        engineVersion: map['engine_version'] as String,
        outputSchemaVersion: map['output_schema_version'] as String,
        output: Map<String, Object?>.from(
          jsonDecode(map['output_json'] as String) as Map,
        ),
        outputHash: map['output_hash'] as String,
        createdAt: DateTime.parse(map['created_at'] as String),
      );
}

