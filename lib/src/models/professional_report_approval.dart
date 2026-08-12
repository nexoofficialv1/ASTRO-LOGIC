enum ProfessionalReportApprovalDecision {
  approvedForClientDelivery,
  approvedWithReservations,
}

class ProfessionalReportApproval {
  const ProfessionalReportApproval({
    required this.id,
    required this.reportSnapshotId,
    required this.consultationId,
    this.sourceReportSnapshotId,
    this.sourceConsultationId,
    required this.reportHash,
    required this.practitionerName,
    required this.practitionerDesignation,
    required this.credentialReference,
    required this.decision,
    required this.approvalNote,
    required this.approvalEngineId,
    required this.approvalEngineVersion,
    required this.approvalStatementVersion,
    required this.approvedAt,
    required this.approvalHash,
    required this.signedReportHash,
  });

  final int id;
  final int reportSnapshotId;
  final int consultationId;
  final int? sourceReportSnapshotId;
  final int? sourceConsultationId;
  int get integrityReportSnapshotId => sourceReportSnapshotId ?? reportSnapshotId;
  int get integrityConsultationId => sourceConsultationId ?? consultationId;
  final String reportHash;
  final String practitionerName;
  final String practitionerDesignation;
  final String credentialReference;
  final ProfessionalReportApprovalDecision decision;
  final String approvalNote;
  final String approvalEngineId;
  final String approvalEngineVersion;
  final String approvalStatementVersion;
  final DateTime approvedAt;
  final String approvalHash;
  final String signedReportHash;

  Map<String, Object?> integrityPayload() => {
        'reportSnapshotId': integrityReportSnapshotId,
        'consultationId': integrityConsultationId,
        'reportHash': reportHash,
        'practitionerName': practitionerName,
        'practitionerDesignation': practitionerDesignation,
        'credentialReference': credentialReference,
        'decision': decision.name,
        'approvalNote': approvalNote,
        'approvedAtUtc': approvedAt.toUtc().toIso8601String(),
      };

  factory ProfessionalReportApproval.fromDatabaseMap(
    Map<String, Object?> map,
  ) =>
      ProfessionalReportApproval(
        id: map['id'] as int,
        reportSnapshotId: map['report_snapshot_id'] as int,
        consultationId: map['consultation_id'] as int,
        sourceReportSnapshotId: map['source_report_snapshot_id'] as int?,
        sourceConsultationId: map['source_consultation_id'] as int?,
        reportHash: map['report_hash'] as String,
        practitionerName: map['practitioner_name'] as String,
        practitionerDesignation: map['practitioner_designation'] as String,
        credentialReference: map['credential_reference'] as String,
        decision: ProfessionalReportApprovalDecision.values.byName(
          map['decision'] as String,
        ),
        approvalNote: map['approval_note'] as String,
        approvalEngineId: map['approval_engine_id'] as String,
        approvalEngineVersion: map['approval_engine_version'] as String,
        approvalStatementVersion: map['approval_statement_version'] as String,
        approvedAt: DateTime.parse(map['approved_at'] as String),
        approvalHash: map['approval_hash'] as String,
        signedReportHash: map['signed_report_hash'] as String,
      );
}
