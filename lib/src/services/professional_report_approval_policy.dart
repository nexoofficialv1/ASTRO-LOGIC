import '../models/professional_report_approval.dart';

class ProfessionalReportApprovalPolicy {
  const ProfessionalReportApprovalPolicy._();

  static const engineId = 'astro-logic-professional-report-approval';
  static const engineVersion = '1.0.0';
  static const statementVersion = 'professional-report-approval-statement-v1';

  static void validateInput({
    required String practitionerName,
    required String practitionerDesignation,
    required String credentialReference,
    required ProfessionalReportApprovalDecision decision,
    required String approvalNote,
  }) {
    final name = practitionerName.trim();
    final designation = practitionerDesignation.trim();
    if (name.length < 2) {
      throw ArgumentError('Practitioner name is required for report approval');
    }
    if (designation.length < 2) {
      throw ArgumentError('Practitioner designation is required for report approval');
    }
    if (name.length > 120 ||
        designation.length > 120 ||
        credentialReference.trim().length > 160 ||
        approvalNote.trim().length > 1200) {
      throw ArgumentError('Approval metadata exceeds the governed length limit');
    }
    if (decision ==
            ProfessionalReportApprovalDecision.approvedWithReservations &&
        approvalNote.trim().isEmpty) {
      throw ArgumentError('Approval note is required when approving with reservations');
    }
  }

  static void validateStored(ProfessionalReportApproval approval) {
    validateInput(
      practitionerName: approval.practitionerName,
      practitionerDesignation: approval.practitionerDesignation,
      credentialReference: approval.credentialReference,
      decision: approval.decision,
      approvalNote: approval.approvalNote,
    );
    if (approval.reportSnapshotId <= 0 ||
        approval.consultationId <= 0 ||
        approval.integrityReportSnapshotId <= 0 ||
        approval.integrityConsultationId <= 0) {
      throw ArgumentError('Saved report and integrity consultation ids are required');
    }
    if (approval.reportHash.length != 64 ||
        approval.approvalHash.length != 64 ||
        approval.signedReportHash.length != 64) {
      throw ArgumentError('Approval integrity hashes must be SHA-256 values');
    }
    if (!approval.approvedAt.isUtc) {
      throw ArgumentError('Approval time must be stored in UTC');
    }
    if (approval.approvalEngineId != engineId ||
        approval.approvalEngineVersion != engineVersion ||
        approval.approvalStatementVersion != statementVersion) {
      throw ArgumentError('Unsupported professional-report approval contract');
    }
  }
}
