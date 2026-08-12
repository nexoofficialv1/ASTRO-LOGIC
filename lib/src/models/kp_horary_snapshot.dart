import 'dart:convert';

class KpHorarySnapshot {
  const KpHorarySnapshot({
    required this.id,
    required this.question,
    required this.topic,
    required this.horaryNumber,
    required this.queryUtc,
    required this.latitude,
    required this.longitude,
    required this.nodeMode,
    required this.inputSchemaVersion,
    required this.input,
    required this.settings,
    required this.inputHash,
    required this.engineId,
    required this.engineVersion,
    required this.outputSchemaVersion,
    required this.output,
    required this.outputHash,
    required this.createdAt,
  });

  final int id;
  final String question;
  final String? topic;
  final int horaryNumber;
  final DateTime queryUtc;
  final double latitude;
  final double longitude;
  final String nodeMode;
  final String inputSchemaVersion;
  final Map<String, Object?> input;
  final Map<String, Object?> settings;
  final String inputHash;
  final String engineId;
  final String engineVersion;
  final String outputSchemaVersion;
  final Map<String, Object?> output;
  final String outputHash;
  final DateTime createdAt;

  factory KpHorarySnapshot.fromDatabaseMap(Map<String, Object?> map) =>
      KpHorarySnapshot(
        id: map['id'] as int,
        question: map['question_text'] as String,
        topic: map['topic'] as String?,
        horaryNumber: map['horary_number'] as int,
        queryUtc: DateTime.parse(map['query_utc'] as String).toUtc(),
        latitude: (map['latitude'] as num).toDouble(),
        longitude: (map['longitude'] as num).toDouble(),
        nodeMode: map['node_mode'] as String,
        inputSchemaVersion: map['input_schema_version'] as String,
        input: Map<String, Object?>.from(
          jsonDecode(map['input_json'] as String) as Map,
        ),
        settings: Map<String, Object?>.from(
          jsonDecode(map['settings_json'] as String) as Map,
        ),
        inputHash: map['input_hash'] as String,
        engineId: map['engine_id'] as String,
        engineVersion: map['engine_version'] as String,
        outputSchemaVersion: map['output_schema_version'] as String,
        output: Map<String, Object?>.from(
          jsonDecode(map['output_json'] as String) as Map,
        ),
        outputHash: map['output_hash'] as String,
        createdAt: DateTime.parse(map['created_at'] as String).toUtc(),
      );
}
