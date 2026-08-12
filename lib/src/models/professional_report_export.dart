enum ProfessionalReportExportFormat { pdf, docx }

enum ProfessionalReportExportLocale { english, bengali }

class ProfessionalReportExportArtifact {
  const ProfessionalReportExportArtifact({
    required this.format,
    required this.locale,
    required this.fileName,
    required this.filePath,
    required this.sha256,
    required this.byteLength,
    required this.sourceReportHash,
    this.sourceApprovalHash,
    this.signedReportHash,
  });

  final ProfessionalReportExportFormat format;
  final ProfessionalReportExportLocale locale;
  final String fileName;
  final String filePath;
  final String sha256;
  final int byteLength;
  final String sourceReportHash;
  final String? sourceApprovalHash;
  final String? signedReportHash;

  bool get isApprovedExport => signedReportHash != null;
}

class ProfessionalReportExportException implements Exception {
  const ProfessionalReportExportException(this.message);

  final String message;

  @override
  String toString() => 'ProfessionalReportExportException: $message';
}
