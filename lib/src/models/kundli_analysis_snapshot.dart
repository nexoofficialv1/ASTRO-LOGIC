import 'dart:convert';

class KundliAnalysisSnapshot {
  const KundliAnalysisSnapshot({
    required this.id,
    required this.consultationId,
    required this.calculationOutputId,
    this.sourceCalculationOutputId,
    required this.engineId,
    required this.engineVersion,
    required this.analysisSchemaVersion,
    required this.analysis,
    required this.analysisHash,
    required this.createdAt,
  });

  final int id;
  final int consultationId;
  final int calculationOutputId;
  final int? sourceCalculationOutputId;
  int get integrityCalculationOutputId =>
      sourceCalculationOutputId ?? calculationOutputId;
  final String engineId;
  final String engineVersion;
  final String analysisSchemaVersion;
  final Map<String, Object?> analysis;
  final String analysisHash;
  final DateTime createdAt;

  factory KundliAnalysisSnapshot.fromDatabaseMap(
    Map<String, Object?> map,
  ) =>
      KundliAnalysisSnapshot(
        id: map['id'] as int,
        consultationId: map['consultation_id'] as int,
        calculationOutputId: map['calculation_output_id'] as int,
        sourceCalculationOutputId: map['source_calculation_output_id'] as int?,
        engineId: map['engine_id'] as String,
        engineVersion: map['engine_version'] as String,
        analysisSchemaVersion: map['analysis_schema_version'] as String,
        analysis: Map<String, Object?>.from(
          jsonDecode(map['analysis_json'] as String) as Map,
        ),
        analysisHash: map['analysis_hash'] as String,
        createdAt: DateTime.parse(map['created_at'] as String),
      );
}
