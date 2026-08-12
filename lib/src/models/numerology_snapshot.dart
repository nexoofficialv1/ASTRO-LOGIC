import 'dart:convert';

class NumerologySnapshot {
  const NumerologySnapshot({
    required this.id,
    required this.consultationId,
    required this.clientId,
    required this.birthRecordId,
    this.sourceConsultationId,
    this.sourceClientId,
    this.sourceBirthRecordId,
    required this.targetYear,
    required this.nameLatin,
    required this.calculationEngineId,
    required this.calculationEngineVersion,
    required this.calculationSchemaVersion,
    required this.calculation,
    required this.analysisEngineId,
    required this.analysisEngineVersion,
    required this.analysisSchemaVersion,
    required this.analysis,
    required this.snapshotHash,
    required this.createdAt,
  });

  final int id;
  final int consultationId;
  final int clientId;
  final int birthRecordId;
  final int? sourceConsultationId;
  final int? sourceClientId;
  final int? sourceBirthRecordId;
  int get integrityConsultationId => sourceConsultationId ?? consultationId;
  int get integrityClientId => sourceClientId ?? clientId;
  int get integrityBirthRecordId => sourceBirthRecordId ?? birthRecordId;
  final int targetYear;
  final String nameLatin;
  final String calculationEngineId;
  final String calculationEngineVersion;
  final String calculationSchemaVersion;
  final Map<String, Object?> calculation;
  final String analysisEngineId;
  final String analysisEngineVersion;
  final String analysisSchemaVersion;
  final Map<String, Object?> analysis;
  final String snapshotHash;
  final DateTime createdAt;

  factory NumerologySnapshot.fromDatabaseMap(Map<String, Object?> map) =>
      NumerologySnapshot(
        id: map['id'] as int,
        consultationId: map['consultation_id'] as int,
        clientId: map['client_id'] as int,
        birthRecordId: map['birth_record_id'] as int,
        sourceConsultationId: map['source_consultation_id'] as int?,
        sourceClientId: map['source_client_id'] as int?,
        sourceBirthRecordId: map['source_birth_record_id'] as int?,
        targetYear: map['target_year'] as int,
        nameLatin: map['name_latin'] as String,
        calculationEngineId: map['calculation_engine_id'] as String,
        calculationEngineVersion:
            map['calculation_engine_version'] as String,
        calculationSchemaVersion:
            map['calculation_schema_version'] as String,
        calculation: Map<String, Object?>.from(
          jsonDecode(map['calculation_json'] as String) as Map,
        ),
        analysisEngineId: map['analysis_engine_id'] as String,
        analysisEngineVersion: map['analysis_engine_version'] as String,
        analysisSchemaVersion: map['analysis_schema_version'] as String,
        analysis: Map<String, Object?>.from(
          jsonDecode(map['analysis_json'] as String) as Map,
        ),
        snapshotHash: map['snapshot_hash'] as String,
        createdAt: DateTime.parse(map['created_at'] as String),
      );
}
