import 'dart:io';

import 'package:astro_logic/src/models/professional_report_approval.dart';
import 'package:astro_logic/src/models/professional_report_export.dart';
import 'package:astro_logic/src/models/professional_report_snapshot.dart';
import 'package:astro_logic/src/services/professional_report_export_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/professional_report_export_fixture.dart';

void main() {
  test('DOCX export uses deterministic source-bound filename and content hash', () async {
    final directory = await Directory.systemTemp.createTemp('astro_logic_report_export_');
    addTearDown(() => directory.delete(recursive: true));
    final snapshot = professionalReportExportFixture();
    final artifact = await const ProfessionalReportExportService().exportDocx(
      snapshot: snapshot,
      locale: ProfessionalReportExportLocale.english,
      outputDirectory: directory,
    );
    expect(
      artifact.fileName,
      'astro_logic_report_c7_${snapshot.reportHash.substring(0, 12)}_en.docx',
    );
    expect(artifact.sourceReportHash, snapshot.reportHash);
    expect(artifact.sha256, hasLength(64));
    expect(artifact.byteLength, greaterThan(500));
    expect(await File(artifact.filePath).exists(), isTrue);
  });

  test('export rejects a report whose persisted hash no longer matches content', () async {
    final valid = professionalReportExportFixture();
    final tamperedReport = Map<String, Object?>.from(valid.report)
      ..['consultationSubject'] = 'Tampered subject';
    final tampered = ProfessionalReportSnapshot(
      id: valid.id,
      consultationId: valid.consultationId,
      engineId: valid.engineId,
      engineVersion: valid.engineVersion,
      reportSchemaVersion: valid.reportSchemaVersion,
      sourceManifest: valid.sourceManifest,
      report: tamperedReport,
      reportHash: valid.reportHash,
      createdAt: valid.createdAt,
    );
    final directory = await Directory.systemTemp.createTemp('astro_logic_report_tamper_');
    addTearDown(() => directory.delete(recursive: true));
    await expectLater(
      const ProfessionalReportExportService().exportDocx(
        snapshot: tampered,
        locale: ProfessionalReportExportLocale.english,
        outputDirectory: directory,
      ),
      throwsA(isA<ProfessionalReportExportException>()),
    );
  });

  test('signed DOCX export binds approval and uses signed verification filename', () async {
    final directory = await Directory.systemTemp.createTemp('astro_logic_signed_export_');
    addTearDown(() => directory.delete(recursive: true));
    final snapshot = professionalReportExportFixture();
    final approval = professionalReportApprovalFixture(snapshot: snapshot);
    final artifact = await const ProfessionalReportExportService().exportDocx(
      snapshot: snapshot,
      approval: approval,
      locale: ProfessionalReportExportLocale.english,
      outputDirectory: directory,
    );
    expect(artifact.isApprovedExport, isTrue);
    expect(artifact.sourceApprovalHash, approval.approvalHash);
    expect(artifact.signedReportHash, approval.signedReportHash);
    expect(artifact.fileName, contains(approval.signedReportHash.substring(0, 12)));
    expect(artifact.fileName, contains('_signed.docx'));
  });

  test('signed export rejects tampered approval metadata', () async {
    final directory = await Directory.systemTemp.createTemp('astro_logic_signed_tamper_');
    addTearDown(() => directory.delete(recursive: true));
    final snapshot = professionalReportExportFixture();
    final valid = professionalReportApprovalFixture(snapshot: snapshot);
    final tampered = ProfessionalReportApproval(
      id: valid.id,
      reportSnapshotId: valid.reportSnapshotId,
      consultationId: valid.consultationId,
      reportHash: valid.reportHash,
      practitionerName: 'Tampered Name',
      practitionerDesignation: valid.practitionerDesignation,
      credentialReference: valid.credentialReference,
      decision: valid.decision,
      approvalNote: valid.approvalNote,
      approvalEngineId: valid.approvalEngineId,
      approvalEngineVersion: valid.approvalEngineVersion,
      approvalStatementVersion: valid.approvalStatementVersion,
      approvedAt: valid.approvedAt,
      approvalHash: valid.approvalHash,
      signedReportHash: valid.signedReportHash,
    );
    await expectLater(
      const ProfessionalReportExportService().exportDocx(
        snapshot: snapshot,
        approval: tampered,
        locale: ProfessionalReportExportLocale.english,
        outputDirectory: directory,
      ),
      throwsA(isA<ProfessionalReportExportException>()),
    );
  });

}
