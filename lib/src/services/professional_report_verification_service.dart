import '../models/professional_report_approval.dart';
import '../models/professional_report_snapshot.dart';
import '../models/professional_report_verification.dart';
import 'professional_report_approval_policy.dart';
import 'snapshot_integrity.dart';

class ProfessionalReportVerificationService {
  const ProfessionalReportVerificationService();

  static const engineId = 'astro-logic-signed-report-verification';
  static const engineVersion = '1.0.0';
  static const verificationContractVersion =
      SignedReportVerificationPayload.currentContractVersion;

  String payloadFor({
    required ProfessionalReportSnapshot snapshot,
    required ProfessionalReportApproval approval,
  }) =>
      SignedReportVerificationPayload.fromSignedReport(
        snapshot: snapshot,
        approval: approval,
      ).encode();

  ProfessionalReportVerificationResult verify({
    required String rawPayload,
    required Iterable<ProfessionalReportSnapshot> reports,
    required Iterable<ProfessionalReportApproval> approvals,
  }) {
    late final SignedReportVerificationPayload payload;
    try {
      payload = SignedReportVerificationPayload.parse(rawPayload);
    } on Object {
      return const ProfessionalReportVerificationResult(
        status: ProfessionalReportVerificationStatus.invalidPayload,
        summaryCode: 'verificationInvalidPayload',
        evidenceCodes: <String>['verificationPayloadParseFailed'],
      );
    }

    final payloadSignedHash = SnapshotIntegrity.sha256ForSignedProfessionalReport(
      reportHash: payload.reportHash,
      approvalHash: payload.approvalHash,
      approvalStatementVersion: payload.approvalStatementVersion,
    );
    if (payloadSignedHash != payload.signedReportHash) {
      return ProfessionalReportVerificationResult(
        status: ProfessionalReportVerificationStatus.invalidPayload,
        summaryCode: 'verificationInvalidPayload',
        evidenceCodes: const <String>['verificationPayloadHashMismatch'],
        payload: payload,
      );
    }

    ProfessionalReportSnapshot? report;
    for (final candidate in reports) {
      if (candidate.integrityReportSnapshotId == payload.reportSnapshotId &&
          candidate.integrityConsultationId == payload.consultationId &&
          candidate.reportHash == payload.reportHash) {
        report = candidate;
        break;
      }
    }
    if (report == null) {
      return ProfessionalReportVerificationResult(
        status: ProfessionalReportVerificationStatus.validPayloadNoLocalRecord,
        summaryCode: 'verificationNoLocalRecord',
        evidenceCodes: const <String>[
          'verificationPayloadInternallyConsistent',
          'verificationAuthenticityNotEstablished',
        ],
        payload: payload,
      );
    }

    final evidence = <String>[];
    if (report.integrityConsultationId != payload.consultationId ||
        report.reportHash != payload.reportHash) {
      return ProfessionalReportVerificationResult(
        status: ProfessionalReportVerificationStatus.mismatchDetected,
        summaryCode: 'verificationMismatchDetected',
        evidenceCodes: const <String>['verificationReportIdentityMismatch'],
        payload: payload,
        reportSnapshotId: report.id,
      );
    }

    final recalculatedReportHash = SnapshotIntegrity.sha256ForProfessionalReport(
      report: report.report,
      sourceManifest: report.sourceManifest,
      engineId: report.engineId,
      engineVersion: report.engineVersion,
      reportSchemaVersion: report.reportSchemaVersion,
    );
    if (recalculatedReportHash != report.reportHash) {
      return ProfessionalReportVerificationResult(
        status: ProfessionalReportVerificationStatus.mismatchDetected,
        summaryCode: 'verificationMismatchDetected',
        evidenceCodes: const <String>['verificationStoredReportHashMismatch'],
        payload: payload,
        reportSnapshotId: report.id,
      );
    }
    evidence.add('verificationReportHashVerified');

    ProfessionalReportApproval? approval;
    for (final candidate in approvals) {
      if (candidate.reportSnapshotId == report.id) {
        approval = candidate;
        break;
      }
    }
    if (approval == null) {
      return ProfessionalReportVerificationResult(
        status: ProfessionalReportVerificationStatus.mismatchDetected,
        summaryCode: 'verificationMismatchDetected',
        evidenceCodes: <String>[
          ...evidence,
          'verificationLocalApprovalMissing',
        ],
        payload: payload,
        reportSnapshotId: report.id,
      );
    }

    try {
      ProfessionalReportApprovalPolicy.validateStored(approval);
    } on Object {
      return ProfessionalReportVerificationResult(
        status: ProfessionalReportVerificationStatus.mismatchDetected,
        summaryCode: 'verificationMismatchDetected',
        evidenceCodes: <String>[...evidence, 'verificationApprovalContractInvalid'],
        payload: payload,
        reportSnapshotId: report.id,
        approvalId: approval.id,
      );
    }

    if (approval.integrityReportSnapshotId != payload.reportSnapshotId ||
        approval.integrityConsultationId != payload.consultationId ||
        approval.reportHash != payload.reportHash ||
        approval.approvalHash != payload.approvalHash ||
        approval.signedReportHash != payload.signedReportHash ||
        approval.approvalStatementVersion != payload.approvalStatementVersion) {
      return ProfessionalReportVerificationResult(
        status: ProfessionalReportVerificationStatus.mismatchDetected,
        summaryCode: 'verificationMismatchDetected',
        evidenceCodes: <String>[...evidence, 'verificationApprovalIdentityMismatch'],
        payload: payload,
        reportSnapshotId: report.id,
        approvalId: approval.id,
      );
    }

    final recalculatedApprovalHash =
        SnapshotIntegrity.sha256ForProfessionalReportApproval(
      approvalPayload: approval.integrityPayload(),
      approvalEngineId: approval.approvalEngineId,
      approvalEngineVersion: approval.approvalEngineVersion,
      approvalStatementVersion: approval.approvalStatementVersion,
    );
    if (recalculatedApprovalHash != approval.approvalHash) {
      return ProfessionalReportVerificationResult(
        status: ProfessionalReportVerificationStatus.mismatchDetected,
        summaryCode: 'verificationMismatchDetected',
        evidenceCodes: <String>[...evidence, 'verificationStoredApprovalHashMismatch'],
        payload: payload,
        reportSnapshotId: report.id,
        approvalId: approval.id,
      );
    }
    evidence.add('verificationApprovalHashVerified');

    final recalculatedSignedHash = SnapshotIntegrity.sha256ForSignedProfessionalReport(
      reportHash: report.reportHash,
      approvalHash: approval.approvalHash,
      approvalStatementVersion: approval.approvalStatementVersion,
    );
    if (recalculatedSignedHash != approval.signedReportHash) {
      return ProfessionalReportVerificationResult(
        status: ProfessionalReportVerificationStatus.mismatchDetected,
        summaryCode: 'verificationMismatchDetected',
        evidenceCodes: <String>[...evidence, 'verificationStoredSignedHashMismatch'],
        payload: payload,
        reportSnapshotId: report.id,
        approvalId: approval.id,
      );
    }
    evidence.add('verificationSignedHashVerified');
    evidence.add('verificationLocalImmutableRecordMatched');

    return ProfessionalReportVerificationResult(
      status: ProfessionalReportVerificationStatus.verifiedAgainstLocalRecord,
      summaryCode: 'verificationVerifiedLocal',
      evidenceCodes: List.unmodifiable(evidence),
      payload: payload,
      reportSnapshotId: report.id,
      approvalId: approval.id,
    );
  }
}
