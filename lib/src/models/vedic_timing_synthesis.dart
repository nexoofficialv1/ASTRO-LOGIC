import 'kundli_analysis.dart';

class VedicActiveDashaChain {
  const VedicActiveDashaChain({
    required this.mahadashaLord,
    required this.antardashaLord,
    required this.pratyantardashaLord,
    required this.startUtc,
    required this.endUtc,
    required this.weightedScore,
    required this.polarity,
    required this.contradictorySignals,
    required this.reinforcedLifeAreas,
  });

  final String mahadashaLord;
  final String antardashaLord;
  final String pratyantardashaLord;
  final DateTime startUtc;
  final DateTime endUtc;
  final int weightedScore;
  final AnalysisPolarity polarity;
  final bool contradictorySignals;
  final List<LifeArea> reinforcedLifeAreas;

  Map<String, Object?> toJson() => {
        'mahadashaLord': mahadashaLord,
        'antardashaLord': antardashaLord,
        'pratyantardashaLord': pratyantardashaLord,
        'startUtc': startUtc.toUtc().toIso8601String(),
        'endUtc': endUtc.toUtc().toIso8601String(),
        'weightedScore': weightedScore,
        'polarity': polarity.name,
        'contradictorySignals': contradictorySignals,
        'reinforcedLifeAreas':
            reinforcedLifeAreas.map((value) => value.name).toList(),
      };
}

class VedicTimingSynthesis {
  const VedicTimingSynthesis({
    required this.asOfUtc,
    required this.engineId,
    required this.engineVersion,
    required this.schemaVersion,
    required this.activeDasha,
    required this.transitPolarity,
    required this.polarity,
    required this.confidence,
    required this.confirmationCode,
    required this.titleEn,
    required this.titleBn,
    required this.narrativeEn,
    required this.narrativeBn,
    required this.transitFindingCodes,
    required this.evidence,
    required this.warningsEn,
    required this.warningsBn,
    required this.professionalReviewRequired,
  });

  final DateTime asOfUtc;
  final String engineId;
  final String engineVersion;
  final String schemaVersion;
  final VedicActiveDashaChain activeDasha;
  final AnalysisPolarity transitPolarity;
  final AnalysisPolarity polarity;
  final AnalysisConfidence confidence;
  final String confirmationCode;
  final String titleEn;
  final String titleBn;
  final String narrativeEn;
  final String narrativeBn;
  final List<String> transitFindingCodes;
  final List<ChartEvidence> evidence;
  final List<String> warningsEn;
  final List<String> warningsBn;
  final bool professionalReviewRequired;

  Map<String, Object?> toJson() => {
        'asOfUtc': asOfUtc.toUtc().toIso8601String(),
        'engineId': engineId,
        'engineVersion': engineVersion,
        'schemaVersion': schemaVersion,
        'activeDasha': activeDasha.toJson(),
        'transitPolarity': transitPolarity.name,
        'polarity': polarity.name,
        'confidence': confidence.name,
        'confirmationCode': confirmationCode,
        'titleEn': titleEn,
        'titleBn': titleBn,
        'narrativeEn': narrativeEn,
        'narrativeBn': narrativeBn,
        'transitFindingCodes': transitFindingCodes,
        'evidence': evidence.map((value) => value.toJson()).toList(),
        'warningsEn': warningsEn,
        'warningsBn': warningsBn,
        'professionalReviewRequired': professionalReviewRequired,
      };
}
