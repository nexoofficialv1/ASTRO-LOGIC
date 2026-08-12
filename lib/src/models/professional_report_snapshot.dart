import 'dart:convert';

class ProfessionalReportSnapshot {
  const ProfessionalReportSnapshot({
    required this.id,
    required this.consultationId,
    this.sourceReportSnapshotId,
    this.sourceConsultationId,
    required this.engineId,
    required this.engineVersion,
    required this.reportSchemaVersion,
    required this.sourceManifest,
    required this.report,
    required this.reportHash,
    required this.createdAt,
  });

  final int id;
  final int consultationId;
  final int? sourceReportSnapshotId;
  final int? sourceConsultationId;
  int get integrityReportSnapshotId => sourceReportSnapshotId ?? id;
  int get integrityConsultationId => sourceConsultationId ?? consultationId;
  final String engineId;
  final String engineVersion;
  final String reportSchemaVersion;
  final List<Map<String, Object?>> sourceManifest;
  final Map<String, Object?> report;
  final String reportHash;
  final DateTime createdAt;

  factory ProfessionalReportSnapshot.fromDatabaseMap(
    Map<String, Object?> map,
  ) =>
      ProfessionalReportSnapshot(
        id: map['id'] as int,
        consultationId: map['consultation_id'] as int,
        sourceReportSnapshotId: map['source_report_snapshot_id'] as int?,
        sourceConsultationId: map['source_consultation_id'] as int?,
        engineId: map['engine_id'] as String,
        engineVersion: map['engine_version'] as String,
        reportSchemaVersion: map['report_schema_version'] as String,
        sourceManifest: (jsonDecode(map['source_manifest_json'] as String) as List)
            .whereType<Map>()
            .map((value) => Map<String, Object?>.from(value))
            .toList(growable: false),
        report: Map<String, Object?>.from(
          jsonDecode(map['report_json'] as String) as Map,
        ),
        reportHash: map['report_hash'] as String,
        createdAt: DateTime.parse(map['created_at'] as String),
      );
}
