enum ProfessionalReportSectionStatus { available, limited, unavailable }

enum ProfessionalReportTone { supportive, challenging, mixed, neutral }

class ProfessionalReportSource {
  const ProfessionalReportSource({
    required this.kind,
    required this.id,
    required this.hash,
    required this.schemaVersion,
  });

  final String kind;
  final int id;
  final String hash;
  final String schemaVersion;

  Map<String, Object?> toJson() => {
        'kind': kind,
        'id': id,
        'hash': hash,
        'schemaVersion': schemaVersion,
      };
}

class ProfessionalReportItem {
  const ProfessionalReportItem({
    required this.code,
    required this.titleEn,
    required this.titleBn,
    required this.narrativeEn,
    required this.narrativeBn,
    required this.tone,
    this.confidence,
    this.evidencePaths = const [],
  });

  final String code;
  final String titleEn;
  final String titleBn;
  final String narrativeEn;
  final String narrativeBn;
  final ProfessionalReportTone tone;
  final String? confidence;
  final List<String> evidencePaths;

  Map<String, Object?> toJson() => {
        'code': code,
        'titleEn': titleEn,
        'titleBn': titleBn,
        'narrativeEn': narrativeEn,
        'narrativeBn': narrativeBn,
        'tone': tone.name,
        'confidence': confidence,
        'evidencePaths': evidencePaths,
      };
}

class ProfessionalReportSection {
  const ProfessionalReportSection({
    required this.code,
    required this.titleEn,
    required this.titleBn,
    required this.status,
    required this.summaryEn,
    required this.summaryBn,
    required this.items,
  });

  final String code;
  final String titleEn;
  final String titleBn;
  final ProfessionalReportSectionStatus status;
  final String summaryEn;
  final String summaryBn;
  final List<ProfessionalReportItem> items;

  Map<String, Object?> toJson() => {
        'code': code,
        'titleEn': titleEn,
        'titleBn': titleBn,
        'status': status.name,
        'summaryEn': summaryEn,
        'summaryBn': summaryBn,
        'items': items.map((value) => value.toJson()).toList(),
      };
}

class ProfessionalConsultationReport {
  const ProfessionalConsultationReport({
    required this.consultationId,
    required this.clientId,
    required this.birthRecordId,
    required this.clientName,
    required this.consultationSubject,
    required this.consultationCategory,
    required this.birthLabel,
    required this.birthLocalDateTime,
    required this.birthPlace,
    required this.birthTimeConfidence,
    required this.asOfUtc,
    required this.sources,
    required this.sections,
    required this.warningsEn,
    required this.warningsBn,
    required this.professionalReviewRequired,
  });

  final int consultationId;
  final int clientId;
  final int birthRecordId;
  final String clientName;
  final String consultationSubject;
  final String consultationCategory;
  final String birthLabel;
  final String birthLocalDateTime;
  final String birthPlace;
  final String birthTimeConfidence;
  final DateTime asOfUtc;
  final List<ProfessionalReportSource> sources;
  final List<ProfessionalReportSection> sections;
  final List<String> warningsEn;
  final List<String> warningsBn;
  final bool professionalReviewRequired;

  Map<String, Object?> toJson() => {
        'consultationId': consultationId,
        'clientId': clientId,
        'birthRecordId': birthRecordId,
        'clientName': clientName,
        'consultationSubject': consultationSubject,
        'consultationCategory': consultationCategory,
        'birthLabel': birthLabel,
        'birthLocalDateTime': birthLocalDateTime,
        'birthPlace': birthPlace,
        'birthTimeConfidence': birthTimeConfidence,
        'asOfUtc': asOfUtc.toUtc().toIso8601String(),
        'sources': sources.map((value) => value.toJson()).toList(),
        'sections': sections.map((value) => value.toJson()).toList(),
        'warningsEn': warningsEn,
        'warningsBn': warningsBn,
        'professionalReviewRequired': professionalReviewRequired,
      };
}
