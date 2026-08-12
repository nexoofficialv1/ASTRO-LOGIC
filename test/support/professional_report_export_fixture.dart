import 'package:astro_logic/src/models/professional_report_approval.dart';
import 'package:astro_logic/src/models/professional_report_snapshot.dart';
import 'package:astro_logic/src/services/professional_report_approval_policy.dart';
import 'package:astro_logic/src/services/snapshot_integrity.dart';

ProfessionalReportSnapshot professionalReportExportFixture({
  Map<String, Object?>? overrideReport,
}) {
  final report = overrideReport ?? <String, Object?>{
    'consultationId': 7,
    'clientId': 3,
    'birthRecordId': 5,
    'clientName': 'Test Client',
    'consultationSubject': 'Career review',
    'consultationCategory': 'career',
    'birthLabel': 'Primary',
    'birthLocalDateTime': '1984-03-13T00:12:00.000',
    'birthPlace': 'Kalna',
    'birthTimeConfidence': 'exact',
    'asOfUtc': '2026-08-08T20:00:00.000Z',
    'sources': <Object?>[],
    'sections': <Object?>[
      {
        'code': 'executive_summary',
        'titleEn': 'Executive summary',
        'titleBn': 'কার্যকর সারাংশ',
        'status': 'limited',
        'summaryEn': 'A balanced professional-review summary.',
        'summaryBn': 'একটি ভারসাম্যপূর্ণ পেশাদার-পর্যালোচনা সারাংশ।',
        'items': <Object?>[
          {
            'code': 'fixture.item',
            'titleEn': 'Career structure',
            'titleBn': 'কর্মজীবনের কাঠামো',
            'narrativeEn': 'D1 and D10 evidence is retained without a guaranteed event claim.',
            'narrativeBn': 'D1 ও D10 evidence নিশ্চিত ঘটনা দাবি না করে সংরক্ষিত হয়েছে।',
            'tone': 'mixed',
            'confidence': 'medium',
            'evidencePaths': <Object?>['analysis.d10CareerSynthesis'],
          },
        ],
      },
      {
        'code': 'professional_notes',
        'titleEn': 'Professional notes',
        'titleBn': 'পেশাদার নোট',
        'status': 'available',
        'summaryEn': 'Review before client delivery.',
        'summaryBn': 'ক্লায়েন্টকে দেওয়ার আগে পর্যালোচনা করুন।',
        'items': <Object?>[],
      },
    ],
    'warningsEn': <Object?>['Traditional review framework; not a guaranteed outcome.'],
    'warningsBn': <Object?>['প্রচলিত পর্যালোচনা-পদ্ধতি; নিশ্চিত ফল নয়।'],
    'professionalReviewRequired': true,
  };
  final sourceManifest = <Map<String, Object?>>[
    {
      'kind': 'kundliAnalysis',
      'id': 11,
      'hash': 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
      'schemaVersion': 'kundli-analysis-v28',
    },
  ];
  const engineId = 'astro-logic-professional-report';
  const engineVersion = '1.0.0';
  const reportSchema = 'professional-consultation-report-v1';
  final hash = SnapshotIntegrity.sha256ForProfessionalReport(
    report: report,
    sourceManifest: sourceManifest,
    engineId: engineId,
    engineVersion: engineVersion,
    reportSchemaVersion: reportSchema,
  );
  return ProfessionalReportSnapshot(
    id: 19,
    consultationId: 7,
    engineId: engineId,
    engineVersion: engineVersion,
    reportSchemaVersion: reportSchema,
    sourceManifest: sourceManifest,
    report: report,
    reportHash: hash,
    createdAt: DateTime.utc(2026, 8, 8, 20),
  );
}

ProfessionalReportApproval professionalReportApprovalFixture({
  ProfessionalReportSnapshot? snapshot,
  String practitionerName = 'Test Practitioner',
  String practitionerDesignation = 'Professional Astrologer',
  String credentialReference = 'ASTRO-TEST-01',
  ProfessionalReportApprovalDecision decision =
      ProfessionalReportApprovalDecision.approvedForClientDelivery,
  String approvalNote = '',
}) {
  final source = snapshot ?? professionalReportExportFixture();
  final approvedAt = DateTime.utc(2026, 8, 10, 4, 30);
  final payload = <String, Object?>{
    'reportSnapshotId': source.id,
    'consultationId': source.consultationId,
    'reportHash': source.reportHash,
    'practitionerName': practitionerName,
    'practitionerDesignation': practitionerDesignation,
    'credentialReference': credentialReference,
    'decision': decision.name,
    'approvalNote': approvalNote,
    'approvedAtUtc': approvedAt.toIso8601String(),
  };
  final approvalHash = SnapshotIntegrity.sha256ForProfessionalReportApproval(
    approvalPayload: payload,
    approvalEngineId: ProfessionalReportApprovalPolicy.engineId,
    approvalEngineVersion: ProfessionalReportApprovalPolicy.engineVersion,
    approvalStatementVersion: ProfessionalReportApprovalPolicy.statementVersion,
  );
  final signedHash = SnapshotIntegrity.sha256ForSignedProfessionalReport(
    reportHash: source.reportHash,
    approvalHash: approvalHash,
    approvalStatementVersion: ProfessionalReportApprovalPolicy.statementVersion,
  );
  return ProfessionalReportApproval(
    id: 41,
    reportSnapshotId: source.id,
    consultationId: source.consultationId,
    reportHash: source.reportHash,
    practitionerName: practitionerName,
    practitionerDesignation: practitionerDesignation,
    credentialReference: credentialReference,
    decision: decision,
    approvalNote: approvalNote,
    approvalEngineId: ProfessionalReportApprovalPolicy.engineId,
    approvalEngineVersion: ProfessionalReportApprovalPolicy.engineVersion,
    approvalStatementVersion: ProfessionalReportApprovalPolicy.statementVersion,
    approvedAt: approvedAt,
    approvalHash: approvalHash,
    signedReportHash: signedHash,
  );
}
