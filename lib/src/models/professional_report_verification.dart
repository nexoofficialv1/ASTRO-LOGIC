import 'dart:convert';

import 'professional_report_approval.dart';
import 'professional_report_snapshot.dart';

enum ProfessionalReportVerificationStatus {
  verifiedAgainstLocalRecord,
  validPayloadNoLocalRecord,
  mismatchDetected,
  invalidPayload,
}

class SignedReportVerificationPayload {
  const SignedReportVerificationPayload({
    required this.contractVersion,
    required this.reportSnapshotId,
    required this.consultationId,
    required this.reportHash,
    required this.approvalHash,
    required this.signedReportHash,
    required this.approvalStatementVersion,
  });

  static const currentContractVersion =
      'astro-logic-signed-report-verification-v1';

  final String contractVersion;
  final int reportSnapshotId;
  final int consultationId;
  final String reportHash;
  final String approvalHash;
  final String signedReportHash;
  final String approvalStatementVersion;

  factory SignedReportVerificationPayload.fromSignedReport({
    required ProfessionalReportSnapshot snapshot,
    required ProfessionalReportApproval approval,
  }) {
    if (approval.reportSnapshotId != snapshot.id ||
        approval.consultationId != snapshot.consultationId ||
        approval.integrityReportSnapshotId != snapshot.integrityReportSnapshotId ||
        approval.integrityConsultationId != snapshot.integrityConsultationId ||
        approval.reportHash != snapshot.reportHash) {
      throw ArgumentError(
        'Approval does not belong to the supplied professional report snapshot',
      );
    }
    return SignedReportVerificationPayload(
      contractVersion: currentContractVersion,
      reportSnapshotId: snapshot.integrityReportSnapshotId,
      consultationId: snapshot.integrityConsultationId,
      reportHash: snapshot.reportHash,
      approvalHash: approval.approvalHash,
      signedReportHash: approval.signedReportHash,
      approvalStatementVersion: approval.approvalStatementVersion,
    );
  }

  Map<String, Object?> toCompactMap() => <String, Object?>{
        'v': contractVersion,
        'r': reportSnapshotId,
        'c': consultationId,
        'h': reportHash,
        'a': approvalHash,
        's': signedReportHash,
        'p': approvalStatementVersion,
      };

  String encode() => jsonEncode(toCompactMap());

  factory SignedReportVerificationPayload.parse(String raw) {
    final value = jsonDecode(raw.trim());
    if (value is! Map) {
      throw const FormatException('Verification payload must be a JSON object');
    }
    final map = Map<String, Object?>.from(value);
    const requiredKeys = <String>{'v', 'r', 'c', 'h', 'a', 's', 'p'};
    if (map.keys.toSet().difference(requiredKeys).isNotEmpty ||
        requiredKeys.difference(map.keys.toSet()).isNotEmpty) {
      throw const FormatException('Verification payload fields are not supported');
    }
    final contract = map['v']?.toString() ?? '';
    if (contract != currentContractVersion) {
      throw const FormatException('Unsupported verification contract version');
    }
    final reportId = _positiveInt(map['r'], 'report snapshot id');
    final consultationId = _positiveInt(map['c'], 'consultation id');
    final reportHash = _hash(map['h'], 'report hash');
    final approvalHash = _hash(map['a'], 'approval hash');
    final signedHash = _hash(map['s'], 'signed-report hash');
    final approvalContract = map['p']?.toString().trim() ?? '';
    if (approvalContract.isEmpty || approvalContract.length > 120) {
      throw const FormatException('Approval contract version is invalid');
    }
    return SignedReportVerificationPayload(
      contractVersion: contract,
      reportSnapshotId: reportId,
      consultationId: consultationId,
      reportHash: reportHash,
      approvalHash: approvalHash,
      signedReportHash: signedHash,
      approvalStatementVersion: approvalContract,
    );
  }

  static int _positiveInt(Object? value, String label) {
    final intValue = value is int
        ? value
        : value is num && value.toInt() == value
            ? value.toInt()
            : -1;
    if (intValue <= 0) throw FormatException('$label is invalid');
    return intValue;
  }

  static String _hash(Object? value, String label) {
    final text = value?.toString().trim() ?? '';
    if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(text)) {
      throw FormatException('$label is not a lowercase SHA-256 value');
    }
    return text;
  }
}

class ProfessionalReportVerificationResult {
  const ProfessionalReportVerificationResult({
    required this.status,
    required this.summaryCode,
    required this.evidenceCodes,
    this.payload,
    this.reportSnapshotId,
    this.approvalId,
  });

  final ProfessionalReportVerificationStatus status;
  final String summaryCode;
  final List<String> evidenceCodes;
  final SignedReportVerificationPayload? payload;
  final int? reportSnapshotId;
  final int? approvalId;

  bool get verified =>
      status == ProfessionalReportVerificationStatus.verifiedAgainstLocalRecord;
}
