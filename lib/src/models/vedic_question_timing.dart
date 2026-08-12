import 'kundli_analysis.dart';

class VedicAshtakavargaKakshaProfile {
  const VedicAshtakavargaKakshaProfile({
    required this.ruleVersion,
    required this.kakshaNumber,
    required this.kakshaLord,
    required this.startDegree,
    required this.endDegree,
    required this.degreeInSign,
    required this.positiveMark,
    required this.polarity,
    required this.evidence,
  });

  final String ruleVersion;
  final int kakshaNumber;
  final String kakshaLord;
  final double startDegree;
  final double endDegree;
  final double degreeInSign;
  final bool positiveMark;
  final AnalysisPolarity polarity;
  final List<ChartEvidence> evidence;

  Map<String, Object?> toJson() => {
        'ruleVersion': ruleVersion,
        'kakshaNumber': kakshaNumber,
        'kakshaLord': kakshaLord,
        'startDegree': startDegree,
        'endDegree': endDegree,
        'degreeInSign': degreeInSign,
        'positiveMark': positiveMark,
        'polarity': polarity.name,
        'evidence': evidence.map((value) => value.toJson()).toList(),
      };
}


class VedicAshtakavargaTransitCheck {
  const VedicAshtakavargaTransitCheck({
    required this.planet,
    required this.signIndex,
    required this.houseFromAscendant,
    required this.bavPositiveMarks,
    required this.savPositiveMarks,
    required this.bavPolarity,
    required this.savPolarity,
    this.wholeSignPolarity,
    this.kaksha,
    required this.polarity,
    required this.evidence,
  });

  final String planet;
  final int signIndex;
  final int houseFromAscendant;
  final int bavPositiveMarks;
  final int savPositiveMarks;
  final AnalysisPolarity bavPolarity;
  final AnalysisPolarity savPolarity;
  final AnalysisPolarity? wholeSignPolarity;
  final VedicAshtakavargaKakshaProfile? kaksha;
  final AnalysisPolarity polarity;
  final List<ChartEvidence> evidence;

  Map<String, Object?> toJson() => {
        'planet': planet,
        'signIndex': signIndex,
        'houseFromAscendant': houseFromAscendant,
        'bavPositiveMarks': bavPositiveMarks,
        'savPositiveMarks': savPositiveMarks,
        'bavPolarity': bavPolarity.name,
        'savPolarity': savPolarity.name,
        'wholeSignPolarity': wholeSignPolarity?.name,
        'kaksha': kaksha?.toJson(),
        'polarity': polarity.name,
        'evidence': evidence.map((value) => value.toJson()).toList(),
      };
}

enum VedicQuestionTopic {
  career,
  business,
  marriage,
  finance,
  education,
  property,
  children,
  travelRelocation,
}

class VedicQuestionTiming {
  const VedicQuestionTiming({
    required this.asOfUtc,
    required this.engineId,
    required this.engineVersion,
    required this.schemaVersion,
    required this.topic,
    required this.targetHouses,
    required this.targetLifeAreas,
    required this.natalPolarity,
    required this.dashaPolarity,
    required this.transitPolarity,
    required this.polarity,
    required this.confidence,
    required this.confirmationCode,
    required this.dashaTopicScore,
    required this.targetedTransitPlanets,
    this.ashtakavargaPolarity = AnalysisPolarity.mixed,
    this.hasDirectionalAshtakavarga = false,
    this.ashtakavargaTransitPlanets = const [],
    this.ashtakavargaTransitChecks = const [],
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
  final List<LifeArea> targetLifeAreas;
  final AnalysisPolarity natalPolarity;
  final AnalysisPolarity dashaPolarity;
  final AnalysisPolarity transitPolarity;
  final AnalysisPolarity polarity;
  final AnalysisConfidence confidence;
  final String confirmationCode;
  final int dashaTopicScore;
  final List<String> targetedTransitPlanets;
  final AnalysisPolarity ashtakavargaPolarity;
  final bool hasDirectionalAshtakavarga;
  final List<String> ashtakavargaTransitPlanets;
  final List<VedicAshtakavargaTransitCheck> ashtakavargaTransitChecks;
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
        'targetLifeAreas': targetLifeAreas.map((value) => value.name).toList(),
        'natalPolarity': natalPolarity.name,
        'dashaPolarity': dashaPolarity.name,
        'transitPolarity': transitPolarity.name,
        'polarity': polarity.name,
        'confidence': confidence.name,
        'confirmationCode': confirmationCode,
        'dashaTopicScore': dashaTopicScore,
        'targetedTransitPlanets': targetedTransitPlanets,
        'ashtakavargaPolarity': ashtakavargaPolarity.name,
        'hasDirectionalAshtakavarga': hasDirectionalAshtakavarga,
        'ashtakavargaTransitPlanets': ashtakavargaTransitPlanets,
        'ashtakavargaTransitChecks':
            ashtakavargaTransitChecks.map((value) => value.toJson()).toList(),
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
