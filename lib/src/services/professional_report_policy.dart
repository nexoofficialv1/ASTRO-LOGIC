import '../models/professional_report.dart';

class ProfessionalReportPolicy {
  const ProfessionalReportPolicy._();

  static const requiredSectionCodes = <String>{
    'client_profile',
    'executive_summary',
    'd1_overview',
    'd9_navamsa',
    'd10_career',
    'yoga_dosha',
    'shadbala',
    'ashtakavarga',
    'dasha_timing',
    'transit_question_timing',
    'numerology',
    'remedy_gemstone',
    'professional_notes_warnings',
  };

  static void validate(ProfessionalConsultationReport report) {
    if (!report.asOfUtc.isUtc) {
      throw StateError('Professional report asOfUtc must be UTC');
    }
    if (!report.professionalReviewRequired) {
      throw StateError('Professional review gate cannot be disabled');
    }
    if (report.sources.isEmpty) {
      throw StateError('At least one immutable report source is required');
    }
    for (final source in report.sources) {
      if (source.id <= 0 ||
          source.hash.length != 64 ||
          source.schemaVersion.trim().isEmpty ||
          source.kind.trim().isEmpty) {
        throw StateError('Invalid professional report source manifest');
      }
    }
    final codes = report.sections.map((value) => value.code).toList();
    if (codes.toSet().length != codes.length ||
        codes.toSet().difference(requiredSectionCodes).isNotEmpty ||
        requiredSectionCodes.difference(codes.toSet()).isNotEmpty) {
      throw StateError('Professional report must contain the governed 13-section contract exactly once');
    }
    for (final section in report.sections) {
      if (section.titleEn.trim().isEmpty ||
          section.titleBn.trim().isEmpty ||
          section.summaryEn.trim().isEmpty ||
          section.summaryBn.trim().isEmpty) {
        throw StateError('Report section text cannot be blank');
      }
      if (section.status == ProfessionalReportSectionStatus.unavailable &&
          section.items.isNotEmpty) {
        throw StateError('Unavailable report sections cannot contain fabricated items');
      }
      final itemCodes = <String>{};
      for (final item in section.items) {
        if (item.code.trim().isEmpty || !itemCodes.add(item.code)) {
          throw StateError('Report item codes must be unique within a section');
        }
        if (item.titleEn.trim().isEmpty || item.titleBn.trim().isEmpty) {
          throw StateError('Report item title cannot be blank');
        }
      }
    }
  }
}
