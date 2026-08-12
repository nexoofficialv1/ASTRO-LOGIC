import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/professional_report_approval.dart';
import '../models/professional_report_export.dart';
import '../models/professional_report_snapshot.dart';
import 'professional_report_approval_policy.dart';
import 'professional_report_docx_builder.dart';
import 'professional_report_pdf_builder.dart';
import 'snapshot_integrity.dart';

class ProfessionalReportExportService {
  const ProfessionalReportExportService({
    this.pdfBuilder = const ProfessionalReportPdfBuilder(),
    this.docxBuilder = const ProfessionalReportDocxBuilder(),
  });

  static const engineId = 'astro-logic-professional-report-export';
  static const engineVersion = '1.2.0';
  static const exportContractVersion = 'professional-report-export-v3';

  final ProfessionalReportPdfBuilder pdfBuilder;
  final ProfessionalReportDocxBuilder docxBuilder;

  Future<ProfessionalReportExportArtifact> exportPdf({
    required ProfessionalReportSnapshot snapshot,
    required ProfessionalReportExportLocale locale,
    ProfessionalReportApproval? approval,
    Directory? outputDirectory,
  }) async {
    _verifySource(snapshot, approval);
    final bytes = await pdfBuilder.build(
      snapshot: snapshot,
      locale: locale,
      approval: approval,
    );
    return _write(
      snapshot: snapshot,
      approval: approval,
      locale: locale,
      format: ProfessionalReportExportFormat.pdf,
      bytes: bytes,
      outputDirectory: outputDirectory,
    );
  }

  Future<ProfessionalReportExportArtifact> exportDocx({
    required ProfessionalReportSnapshot snapshot,
    required ProfessionalReportExportLocale locale,
    ProfessionalReportApproval? approval,
    Directory? outputDirectory,
  }) async {
    _verifySource(snapshot, approval);
    final bytes = docxBuilder.build(
      snapshot: snapshot,
      locale: locale,
      approval: approval,
    );
    return _write(
      snapshot: snapshot,
      approval: approval,
      locale: locale,
      format: ProfessionalReportExportFormat.docx,
      bytes: bytes,
      outputDirectory: outputDirectory,
    );
  }

  void _verifySource(
    ProfessionalReportSnapshot snapshot,
    ProfessionalReportApproval? approval,
  ) {
    final calculated = SnapshotIntegrity.sha256ForProfessionalReport(
      report: snapshot.report,
      sourceManifest: snapshot.sourceManifest,
      engineId: snapshot.engineId,
      engineVersion: snapshot.engineVersion,
      reportSchemaVersion: snapshot.reportSchemaVersion,
    );
    if (calculated != snapshot.reportHash) {
      throw const ProfessionalReportExportException(
        'The immutable report hash does not match the stored report content.',
      );
    }
    if (approval == null) return;
    ProfessionalReportApprovalPolicy.validateStored(approval);
    if (approval.reportSnapshotId != snapshot.id ||
        approval.consultationId != snapshot.consultationId ||
        approval.integrityReportSnapshotId != snapshot.integrityReportSnapshotId ||
        approval.integrityConsultationId != snapshot.integrityConsultationId ||
        approval.reportHash != snapshot.reportHash) {
      throw const ProfessionalReportExportException(
        'Approval metadata does not belong to this immutable report snapshot.',
      );
    }
    final approvalHash = SnapshotIntegrity.sha256ForProfessionalReportApproval(
      approvalPayload: approval.integrityPayload(),
      approvalEngineId: approval.approvalEngineId,
      approvalEngineVersion: approval.approvalEngineVersion,
      approvalStatementVersion: approval.approvalStatementVersion,
    );
    if (approvalHash != approval.approvalHash) {
      throw const ProfessionalReportExportException(
        'The stored approval hash does not match the approval metadata.',
      );
    }
    final signedHash = SnapshotIntegrity.sha256ForSignedProfessionalReport(
      reportHash: snapshot.reportHash,
      approvalHash: approval.approvalHash,
      approvalStatementVersion: approval.approvalStatementVersion,
    );
    if (signedHash != approval.signedReportHash) {
      throw const ProfessionalReportExportException(
        'The signed-report hash does not match the report and approval binding.',
      );
    }
  }

  Future<ProfessionalReportExportArtifact> _write({
    required ProfessionalReportSnapshot snapshot,
    required ProfessionalReportApproval? approval,
    required ProfessionalReportExportLocale locale,
    required ProfessionalReportExportFormat format,
    required List<int> bytes,
    Directory? outputDirectory,
  }) async {
    final directory = outputDirectory ?? await _defaultDirectory();
    await directory.create(recursive: true);
    final extension = format.name;
    final localeCode = locale == ProfessionalReportExportLocale.bengali ? 'bn' : 'en';
    final hashPrefix = (approval?.signedReportHash ?? snapshot.reportHash).substring(0, 12);
    final signedMarker = approval == null ? '' : '_signed';
    final fileName =
        'astro_logic_report_c${snapshot.consultationId}_${hashPrefix}_${localeCode}$signedMarker.$extension';
    final file = File(p.join(directory.path, fileName));
    await file.writeAsBytes(bytes, flush: true);
    final digest = sha256.convert(bytes).toString();
    return ProfessionalReportExportArtifact(
      format: format,
      locale: locale,
      fileName: fileName,
      filePath: file.path,
      sha256: digest,
      byteLength: bytes.length,
      sourceReportHash: snapshot.reportHash,
      sourceApprovalHash: approval?.approvalHash,
      signedReportHash: approval?.signedReportHash,
    );
  }

  Future<Directory> _defaultDirectory() async {
    final root = await getApplicationDocumentsDirectory();
    return Directory(p.join(root.path, 'ASTRO_LOGIC', 'exports'));
  }
}
