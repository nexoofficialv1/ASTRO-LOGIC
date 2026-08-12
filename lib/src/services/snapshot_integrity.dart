import 'dart:convert';

import 'package:crypto/crypto.dart';

class SnapshotIntegrity {
  const SnapshotIntegrity._();

  static String sha256For({
    required Map<String, Object?> input,
    required Map<String, Object?> settings,
    required String schemaVersion,
  }) {
    final canonicalPayload = '${jsonEncode(input)}\n'
        '${jsonEncode(settings)}\n'
        '$schemaVersion';
    return sha256.convert(utf8.encode(canonicalPayload)).toString();
  }

  static String sha256ForOutput({
    required Map<String, Object?> output,
    required String engineId,
    required String engineVersion,
    required String outputSchemaVersion,
  }) {
    final canonicalPayload = '${jsonEncode(output)}\n'
        '$engineId\n$engineVersion\n$outputSchemaVersion';
    return sha256.convert(utf8.encode(canonicalPayload)).toString();
  }

  static String sha256ForAnalysis({
    required Map<String, Object?> analysis,
    required String engineId,
    required String engineVersion,
    required String analysisSchemaVersion,
    required int calculationOutputId,
  }) {
    final canonicalPayload = '${jsonEncode(analysis)}\n'
        '$engineId\n$engineVersion\n$analysisSchemaVersion\n'
        '$calculationOutputId';
    return sha256.convert(utf8.encode(canonicalPayload)).toString();
  }

  static String sha256ForNumerology({
    required Map<String, Object?> input,
    required Map<String, Object?> calculation,
    required Map<String, Object?> analysis,
    required String calculationEngineId,
    required String calculationEngineVersion,
    required String calculationSchemaVersion,
    required String analysisEngineId,
    required String analysisEngineVersion,
    required String analysisSchemaVersion,
  }) {
    final canonicalPayload = '${jsonEncode(input)}\n'
        '${jsonEncode(calculation)}\n'
        '${jsonEncode(analysis)}\n'
        '$calculationEngineId\n$calculationEngineVersion\n'
        '$calculationSchemaVersion\n$analysisEngineId\n'
        '$analysisEngineVersion\n$analysisSchemaVersion';
    return sha256.convert(utf8.encode(canonicalPayload)).toString();
  }

  static String sha256ForProfessionalReport({
    required Map<String, Object?> report,
    required List<Map<String, Object?>> sourceManifest,
    required String engineId,
    required String engineVersion,
    required String reportSchemaVersion,
  }) {
    final canonicalPayload = '${jsonEncode(report)}\n'
        '${jsonEncode(sourceManifest)}\n'
        '$engineId\n$engineVersion\n$reportSchemaVersion';
    return sha256.convert(utf8.encode(canonicalPayload)).toString();
  }

  static String sha256ForProfessionalReportApproval({
    required Map<String, Object?> approvalPayload,
    required String approvalEngineId,
    required String approvalEngineVersion,
    required String approvalStatementVersion,
  }) {
    final canonicalPayload = '${jsonEncode(approvalPayload)}\n'
        '$approvalEngineId\n$approvalEngineVersion\n$approvalStatementVersion';
    return sha256.convert(utf8.encode(canonicalPayload)).toString();
  }

  static String sha256ForSignedProfessionalReport({
    required String reportHash,
    required String approvalHash,
    required String approvalStatementVersion,
  }) {
    final canonicalPayload = '$reportHash\n'
        '$approvalHash\n'
        '$approvalStatementVersion';
    return sha256.convert(utf8.encode(canonicalPayload)).toString();
  }

}
