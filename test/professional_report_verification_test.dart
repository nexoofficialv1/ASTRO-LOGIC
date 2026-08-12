import 'package:astro_logic/src/models/professional_report_snapshot.dart';
import 'package:astro_logic/src/models/professional_report_verification.dart';
import 'package:astro_logic/src/services/professional_report_verification_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/professional_report_export_fixture.dart';

void main() {
  const service = ProfessionalReportVerificationService();

  test('signed payload verifies against matching immutable local report and approval', () {
    final snapshot = professionalReportExportFixture();
    final approval = professionalReportApprovalFixture(snapshot: snapshot);
    final payload = service.payloadFor(snapshot: snapshot, approval: approval);

    final result = service.verify(
      rawPayload: payload,
      reports: <ProfessionalReportSnapshot>[snapshot],
      approvals: [approval],
    );

    expect(
      result.status,
      ProfessionalReportVerificationStatus.verifiedAgainstLocalRecord,
    );
    expect(result.verified, isTrue);
    expect(result.reportSnapshotId, snapshot.id);
    expect(result.approvalId, approval.id);
    expect(result.evidenceCodes, contains('verificationSignedHashVerified'));
  });

  test('valid payload without local record does not claim authenticity', () {
    final snapshot = professionalReportExportFixture();
    final approval = professionalReportApprovalFixture(snapshot: snapshot);
    final payload = service.payloadFor(snapshot: snapshot, approval: approval);

    final result = service.verify(
      rawPayload: payload,
      reports: const <ProfessionalReportSnapshot>[],
      approvals: const [],
    );

    expect(
      result.status,
      ProfessionalReportVerificationStatus.validPayloadNoLocalRecord,
    );
    expect(result.verified, isFalse);
    expect(
      result.evidenceCodes,
      contains('verificationAuthenticityNotEstablished'),
    );
  });

  test('payload signed hash tamper is rejected before local lookup', () {
    final snapshot = professionalReportExportFixture();
    final approval = professionalReportApprovalFixture(snapshot: snapshot);
    final valid = SignedReportVerificationPayload.fromSignedReport(
      snapshot: snapshot,
      approval: approval,
    );
    final tampered = SignedReportVerificationPayload(
      contractVersion: valid.contractVersion,
      reportSnapshotId: valid.reportSnapshotId,
      consultationId: valid.consultationId,
      reportHash: valid.reportHash,
      approvalHash: valid.approvalHash,
      signedReportHash: List<String>.filled(64, '0').join(),
      approvalStatementVersion: valid.approvalStatementVersion,
    ).encode();

    final result = service.verify(
      rawPayload: tampered,
      reports: [snapshot],
      approvals: [approval],
    );

    expect(result.status, ProfessionalReportVerificationStatus.invalidPayload);
    expect(result.evidenceCodes, contains('verificationPayloadHashMismatch'));
  });

  test('changed local report content is detected even when stored hash was retained', () {
    final snapshot = professionalReportExportFixture();
    final approval = professionalReportApprovalFixture(snapshot: snapshot);
    final payload = service.payloadFor(snapshot: snapshot, approval: approval);
    final changedReport = Map<String, Object?>.from(snapshot.report)
      ..['consultationSubject'] = 'Altered after signing';
    final tamperedSnapshot = ProfessionalReportSnapshot(
      id: snapshot.id,
      consultationId: snapshot.consultationId,
      engineId: snapshot.engineId,
      engineVersion: snapshot.engineVersion,
      reportSchemaVersion: snapshot.reportSchemaVersion,
      sourceManifest: snapshot.sourceManifest,
      report: changedReport,
      reportHash: snapshot.reportHash,
      createdAt: snapshot.createdAt,
    );

    final result = service.verify(
      rawPayload: payload,
      reports: [tamperedSnapshot],
      approvals: [approval],
    );

    expect(
      result.status,
      ProfessionalReportVerificationStatus.mismatchDetected,
    );
    expect(
      result.evidenceCodes,
      contains('verificationStoredReportHashMismatch'),
    );
  });

  test('QR payload carries no client name, birth data, or narrative text', () {
    final snapshot = professionalReportExportFixture();
    final approval = professionalReportApprovalFixture(snapshot: snapshot);
    final payload = service.payloadFor(snapshot: snapshot, approval: approval);

    expect(payload, isNot(contains('Test Client')));
    expect(payload, isNot(contains('1984-03-13')));
    expect(payload, isNot(contains('Career review')));
    expect(payload, contains(snapshot.reportHash));
    expect(payload, contains(approval.approvalHash));
    expect(payload, contains(approval.signedReportHash));
  });
}
