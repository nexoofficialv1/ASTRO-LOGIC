import 'kundli_analysis.dart';
import 'vedic_question_timing.dart';

enum VedicEvidenceLayer {
  natalD1,
  divisionalD1D9,
  dasha,
  transit,
  ashtakavargaTransit,
}

class VedicLayerVerdict {
  const VedicLayerVerdict({
    required this.layer,
    required this.independenceGroup,
    required this.available,
    required this.polarity,
    required this.sourceCodes,
    required this.summaryEn,
    required this.summaryBn,
    required this.evidence,
  });

  final VedicEvidenceLayer layer;
  final String independenceGroup;
  final bool available;
  final AnalysisPolarity polarity;
  final List<String> sourceCodes;
  final String summaryEn;
  final String summaryBn;
  final List<ChartEvidence> evidence;

  Map<String, Object?> toJson() => {
        'layer': layer.name,
        'independenceGroup': independenceGroup,
        'available': available,
        'polarity': polarity.name,
        'sourceCodes': sourceCodes,
        'summaryEn': summaryEn,
        'summaryBn': summaryBn,
        'evidence': evidence.map((value) => value.toJson()).toList(),
      };
}

class VedicConflictConfidence {
  const VedicConflictConfidence({
    required this.asOfUtc,
    required this.engineId,
    required this.engineVersion,
    required this.schemaVersion,
    required this.topic,
    required this.targetHouses,
    required this.targetHouseLords,
    required this.layers,
    required this.structuralPolarity,
    required this.polarity,
    required this.confidence,
    required this.resolutionCode,
    required this.directionalIndependentGroups,
    required this.agreeingIndependentGroups,
    required this.conflictDetected,
    required this.titleEn,
    required this.titleBn,
    required this.narrativeEn,
    required this.narrativeBn,
    required this.evidence,
    required this.warningsEn,
    required this.warningsBn,
    required this.professionalReviewRequired,
  });

  final DateTime asOfUtc;
  final String engineId;
  final String engineVersion;
  final String schemaVersion;
  final VedicQuestionTopic topic;
  final List<int> targetHouses;
  final List<String> targetHouseLords;
  final List<VedicLayerVerdict> layers;
  final AnalysisPolarity structuralPolarity;
  final AnalysisPolarity polarity;
  final AnalysisConfidence confidence;
  final String resolutionCode;
  final int directionalIndependentGroups;
  final int agreeingIndependentGroups;
  final bool conflictDetected;
  final String titleEn;
  final String titleBn;
  final String narrativeEn;
  final String narrativeBn;
  final List<ChartEvidence> evidence;
  final List<String> warningsEn;
  final List<String> warningsBn;
  final bool professionalReviewRequired;

  Map<String, Object?> toJson() => {
        'asOfUtc': asOfUtc.toUtc().toIso8601String(),
        'engineId': engineId,
        'engineVersion': engineVersion,
        'schemaVersion': schemaVersion,
        'topic': topic.name,
        'targetHouses': targetHouses,
        'targetHouseLords': targetHouseLords,
        'layers': layers.map((value) => value.toJson()).toList(),
        'structuralPolarity': structuralPolarity.name,
        'polarity': polarity.name,
        'confidence': confidence.name,
        'resolutionCode': resolutionCode,
        'directionalIndependentGroups': directionalIndependentGroups,
        'agreeingIndependentGroups': agreeingIndependentGroups,
        'conflictDetected': conflictDetected,
        'titleEn': titleEn,
        'titleBn': titleBn,
        'narrativeEn': narrativeEn,
        'narrativeBn': narrativeBn,
        'evidence': evidence.map((value) => value.toJson()).toList(),
        'warningsEn': warningsEn,
        'warningsBn': warningsBn,
        'professionalReviewRequired': professionalReviewRequired,
      };
}
