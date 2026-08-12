import '../models/professional_report_approval.dart';
import '../models/professional_report_export.dart';
import '../models/professional_report_snapshot.dart';

class ProfessionalReportExportProjection {
  const ProfessionalReportExportProjection._({
    required this.snapshot,
    required this.locale,
    required this.approval,
  });

  factory ProfessionalReportExportProjection.fromSnapshot({
    required ProfessionalReportSnapshot snapshot,
    required ProfessionalReportExportLocale locale,
    ProfessionalReportApproval? approval,
  }) =>
      ProfessionalReportExportProjection._(
        snapshot: snapshot,
        locale: locale,
        approval: approval,
      );

  final ProfessionalReportSnapshot snapshot;
  final ProfessionalReportExportLocale locale;
  final ProfessionalReportApproval? approval;

  bool get bengali => locale == ProfessionalReportExportLocale.bengali;

  Map<String, Object?> get report => snapshot.report;

  String get clientName => _text(report['clientName']);
  String get subject => _text(report['consultationSubject']);
  String get category => _text(report['consultationCategory']);
  String get birthLabel => _text(report['birthLabel']);
  String get birthLocalDateTime => _text(report['birthLocalDateTime']);
  String get birthPlace => _text(report['birthPlace']);
  String get birthTimeConfidence => _text(report['birthTimeConfidence']);
  String get asOfUtc => _text(report['asOfUtc']);
  String get languageCode => bengali ? 'bn' : 'en';
  String get languageLabel => bengali ? 'বাংলা' : 'English';
  String get reportTitle => bengali
      ? 'পেশাদার জ্যোতিষ পরামর্শ রিপোর্ট'
      : 'Professional Astrology Consultation Report';
  String get reportHashLabel => bengali ? 'রিপোর্ট SHA-256' : 'Report SHA-256';
  String get sourceSchemaLabel => bengali ? 'রিপোর্ট স্কিমা' : 'Report schema';
  String get asOfLabel => bengali ? 'রিপোর্টের সময়সীমা' : 'Report as of';
  String get confidenceLabel => bengali ? 'নির্ভরযোগ্যতা' : 'Confidence';
  String get evidenceLabel => 'Evidence';
  String get warningsTitle => bengali
      ? 'নিরাপত্তা ও পরিধি সতর্কতা'
      : 'Safety and scope warnings';
  String get professionalReviewLabel => bengali
      ? 'পেশাদার পর্যালোচনা আবশ্যক'
      : 'Professional review required';

  String get approvalTitle => bengali
      ? 'পেশাদার অনুমোদন ও সাইন-অফ'
      : 'Professional approval and sign-off';
  String get approvalStatusLabel => bengali ? 'অনুমোদন অবস্থা' : 'Approval status';
  String get practitionerLabel => bengali ? 'অনুমোদনকারী' : 'Approved by';
  String get designationLabel => bengali ? 'পদবি / পরিচয়' : 'Designation';
  String get credentialLabel => bengali ? 'রেজিস্ট্রেশন / পরিচয় রেফারেন্স' : 'Credential / registration reference';
  String get approvedAtLabel => bengali ? 'অনুমোদনের সময় (UTC)' : 'Approved at (UTC)';
  String get approvalNoteLabel => bengali ? 'অনুমোদন নোট' : 'Approval note';
  String get approvalStatementLabel => bengali ? 'Approval contract' : 'Approval contract';
  String get approvalHashLabel => bengali ? 'Approval SHA-256' : 'Approval SHA-256';
  String get signedReportHashLabel => bengali ? 'Signed-report SHA-256' : 'Signed-report SHA-256';
  String get verificationQrLabel => bengali ? 'অফলাইন যাচাই QR' : 'Offline verification QR';
  String get verificationPayloadLabel => bengali ? 'Verification payload' : 'Verification payload';
  String get verificationContractLabel => bengali ? 'Verification contract' : 'Verification contract';
  String get verificationDisclosure => bengali
      ? 'QR/payload এই report-এর hash binding বহন করে। Authenticity verified বলতে হলে একই ASTRO LOGIC database-এ immutable report ও approval record মিলতে হবে।'
      : 'The QR/payload carries this report hash binding. Authenticity is verified only when the immutable report and approval records match inside the same ASTRO LOGIC database.';
  String get approvalDisclosure => bengali
      ? 'এটি ASTRO LOGIC-এর ভিতরে সংরক্ষিত practitioner electronic sign-off; certificate-backed cryptographic/digital signature নয়।'
      : 'This is a practitioner electronic sign-off recorded inside ASTRO LOGIC; it is not a certificate-backed cryptographic/digital signature.';

  String approvalDecision(ProfessionalReportApprovalDecision decision) {
    switch (decision) {
      case ProfessionalReportApprovalDecision.approvedForClientDelivery:
        return bengali ? 'ক্লায়েন্ট ডেলিভারির জন্য অনুমোদিত' : 'Approved for client delivery';
      case ProfessionalReportApprovalDecision.approvedWithReservations:
        return bengali ? 'সতর্কতা/শর্তসহ অনুমোদিত' : 'Approved with reservations';
    }
  }

  List<Map<String, Object?>> get sections =>
      (report['sections'] as List? ?? const [])
          .whereType<Map>()
          .map((value) => Map<String, Object?>.from(value))
          .toList(growable: false);

  List<String> get warnings =>
      (report[bengali ? 'warningsBn' : 'warningsEn'] as List? ?? const [])
          .map(_text)
          .where((value) => value.isNotEmpty)
          .toList(growable: false);

  String sectionTitle(Map<String, Object?> section) =>
      _text(section[bengali ? 'titleBn' : 'titleEn']);

  String sectionSummary(Map<String, Object?> section) =>
      _text(section[bengali ? 'summaryBn' : 'summaryEn']);

  String sectionStatus(Map<String, Object?> section) {
    switch (_text(section['status'])) {
      case 'available':
        return bengali ? 'উপলব্ধ' : 'Available';
      case 'limited':
        return bengali ? 'সীমিত / curated' : 'Limited / curated';
      default:
        return bengali ? 'অনুপলব্ধ' : 'Unavailable';
    }
  }

  List<Map<String, Object?>> sectionItems(Map<String, Object?> section) =>
      (section['items'] as List? ?? const [])
          .whereType<Map>()
          .map((value) => Map<String, Object?>.from(value))
          .toList(growable: false);

  String itemTitle(Map<String, Object?> item) =>
      _text(item[bengali ? 'titleBn' : 'titleEn']);

  String itemNarrative(Map<String, Object?> item) =>
      _text(item[bengali ? 'narrativeBn' : 'narrativeEn']);

  String itemConfidence(Map<String, Object?> item) => _text(item['confidence']);

  List<String> itemEvidence(Map<String, Object?> item) =>
      (item['evidencePaths'] as List? ?? const [])
          .map(_text)
          .where((value) => value.isNotEmpty)
          .toList(growable: false);

  bool get professionalReviewRequired => report['professionalReviewRequired'] == true;

  bool get requiresUnicodePdfFont {
    for (final text in selectedText()) {
      if (text.runes.any((rune) => rune > 0x7f)) return true;
    }
    return false;
  }

  Iterable<String> selectedText() sync* {
    yield clientName;
    yield subject;
    yield category;
    yield birthLabel;
    yield birthLocalDateTime;
    yield birthPlace;
    yield birthTimeConfidence;
    yield reportTitle;
    for (final section in sections) {
      yield sectionTitle(section);
      yield sectionSummary(section);
      for (final item in sectionItems(section)) {
        yield itemTitle(item);
        yield itemNarrative(item);
        yield itemConfidence(item);
        yield* itemEvidence(item);
      }
    }
    yield* warnings;
    final signOff = approval;
    if (signOff != null) {
      yield approvalTitle;
      yield approvalDecision(signOff.decision);
      yield signOff.practitionerName;
      yield signOff.practitionerDesignation;
      yield signOff.credentialReference;
      yield signOff.approvalNote;
      yield approvalDisclosure;
    }
  }

  static String _text(Object? value) => value?.toString().trim() ?? '';
}
