import 'package:flutter_test/flutter_test.dart';

import 'package:astro_logic/src/models/kundli_analysis_snapshot.dart';
import 'package:astro_logic/src/models/numerology_snapshot.dart';
import 'package:astro_logic/src/models/professional_report_approval.dart';
import 'package:astro_logic/src/models/professional_report_snapshot.dart';
import 'package:astro_logic/src/models/professional_report_verification.dart';

void main() {
  test('imported immutable models retain source integrity ids', () {
    final kundli = KundliAnalysisSnapshot.fromDatabaseMap({
      'id': 41,
      'consultation_id': 51,
      'calculation_output_id': 61,
      'source_calculation_output_id': 7,
      'engine_id': 'engine',
      'engine_version': '1',
      'analysis_schema_version': 'a1',
      'analysis_json': '{}',
      'analysis_hash': List.filled(64, 'a').join(),
      'created_at': '2026-08-10T00:00:00.000Z',
    });
    expect(kundli.integrityCalculationOutputId, 7);

    final numerology = NumerologySnapshot.fromDatabaseMap({
      'id': 42,
      'consultation_id': 52,
      'client_id': 62,
      'birth_record_id': 72,
      'source_consultation_id': 2,
      'source_client_id': 3,
      'source_birth_record_id': 4,
      'target_year': 2026,
      'name_latin': 'TEST',
      'calculation_engine_id': 'n',
      'calculation_engine_version': '1',
      'calculation_schema_version': 'n1',
      'calculation_json': '{}',
      'analysis_engine_id': 'na',
      'analysis_engine_version': '1',
      'analysis_schema_version': 'na1',
      'analysis_json': '{}',
      'snapshot_hash': List.filled(64, 'b').join(),
      'created_at': '2026-08-10T00:00:00.000Z',
    });
    expect(numerology.integrityConsultationId, 2);
    expect(numerology.integrityClientId, 3);
    expect(numerology.integrityBirthRecordId, 4);

    final report = ProfessionalReportSnapshot.fromDatabaseMap({
      'id': 43,
      'consultation_id': 53,
      'source_report_snapshot_id': 5,
      'source_consultation_id': 6,
      'engine_id': 'r',
      'engine_version': '1',
      'report_schema_version': 'r1',
      'source_manifest_json': '[]',
      'report_json': '{}',
      'report_hash': List.filled(64, 'c').join(),
      'created_at': '2026-08-10T00:00:00.000Z',
    });
    expect(report.integrityReportSnapshotId, 5);
    expect(report.integrityConsultationId, 6);

    final approval = ProfessionalReportApproval.fromDatabaseMap({
      'id': 44,
      'report_snapshot_id': 43,
      'consultation_id': 53,
      'source_report_snapshot_id': 5,
      'source_consultation_id': 6,
      'report_hash': List.filled(64, 'c').join(),
      'practitioner_name': 'Practitioner',
      'practitioner_designation': 'Astrologer',
      'credential_reference': '',
      'decision': 'approvedForClientDelivery',
      'approval_note': '',
      'approval_engine_id': 'astro-logic-professional-report-approval',
      'approval_engine_version': '1.0.0',
      'approval_statement_version': 'professional-report-approval-statement-v1',
      'approved_at': '2026-08-10T00:00:00.000Z',
      'approval_hash': List.filled(64, 'd').join(),
      'signed_report_hash': List.filled(64, 'e').join(),
    });
    expect(approval.integrityPayload()['reportSnapshotId'], 5);
    expect(approval.integrityPayload()['consultationId'], 6);

    final verification = SignedReportVerificationPayload.fromSignedReport(
      snapshot: report,
      approval: approval,
    );
    expect(verification.reportSnapshotId, 5);
    expect(verification.consultationId, 6);
  });
}
