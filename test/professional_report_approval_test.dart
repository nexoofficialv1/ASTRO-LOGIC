import 'package:astro_logic/src/models/professional_report_approval.dart';
import 'package:astro_logic/src/services/professional_report_approval_policy.dart';
import 'package:astro_logic/src/services/snapshot_integrity.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/professional_report_export_fixture.dart';

void main() {
  test('approval fixture preserves immutable report/sign-off binding', () {
    final snapshot = professionalReportExportFixture();
    final approval = professionalReportApprovalFixture(snapshot: snapshot);
    ProfessionalReportApprovalPolicy.validateStored(approval);

    final approvalHash = SnapshotIntegrity.sha256ForProfessionalReportApproval(
      approvalPayload: approval.integrityPayload(),
      approvalEngineId: approval.approvalEngineId,
      approvalEngineVersion: approval.approvalEngineVersion,
      approvalStatementVersion: approval.approvalStatementVersion,
    );
    final signedHash = SnapshotIntegrity.sha256ForSignedProfessionalReport(
      reportHash: snapshot.reportHash,
      approvalHash: approvalHash,
      approvalStatementVersion: approval.approvalStatementVersion,
    );

    expect(approval.reportHash, snapshot.reportHash);
    expect(approvalHash, approval.approvalHash);
    expect(signedHash, approval.signedReportHash);
  });

  test('approval hash changes when practitioner identity changes', () {
    final first = professionalReportApprovalFixture();
    final changed = professionalReportApprovalFixture(
      practitionerName: 'Another Practitioner',
    );
    expect(changed.approvalHash, isNot(first.approvalHash));
    expect(changed.signedReportHash, isNot(first.signedReportHash));
  });

  test('reservations require an explicit approval note', () {
    expect(
      () => ProfessionalReportApprovalPolicy.validateInput(
        practitionerName: 'Test Practitioner',
        practitionerDesignation: 'Professional Astrologer',
        credentialReference: '',
        decision: ProfessionalReportApprovalDecision.approvedWithReservations,
        approvalNote: '',
      ),
      throwsArgumentError,
    );
  });

  test('database-shaped approval restores all integrity metadata', () {
    final approval = ProfessionalReportApproval.fromDatabaseMap({
      'id': 4,
      'report_snapshot_id': 19,
      'consultation_id': 7,
      'report_hash': 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
      'practitioner_name': 'Test Practitioner',
      'practitioner_designation': 'Professional Astrologer',
      'credential_reference': 'ASTRO-01',
      'decision': 'approvedForClientDelivery',
      'approval_note': '',
      'approval_engine_id': ProfessionalReportApprovalPolicy.engineId,
      'approval_engine_version': ProfessionalReportApprovalPolicy.engineVersion,
      'approval_statement_version': ProfessionalReportApprovalPolicy.statementVersion,
      'approved_at': '2026-08-10T04:30:00.000Z',
      'approval_hash': 'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
      'signed_report_hash': 'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc',
    });
    expect(approval.reportSnapshotId, 19);
    expect(approval.approvedAt.isUtc, isTrue);
    expect(approval.signedReportHash, hasLength(64));
  });
}
