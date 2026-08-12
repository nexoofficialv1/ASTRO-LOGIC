import 'kundli_analysis.dart';

class VedicTransitPosition {
  const VedicTransitPosition({
    required this.body,
    required this.siderealLongitude,
    required this.signIndex,
    required this.sign,
    required this.degreeInSign,
    required this.retrograde,
    required this.houseFromAscendant,
    required this.houseFromMoon,
  });

  final String body;
  final double siderealLongitude;
  final int signIndex;
  final String sign;
  final double degreeInSign;
  final bool retrograde;
  final int houseFromAscendant;
  final int houseFromMoon;

  Map<String, Object?> toJson() => {
        'body': body,
        'siderealLongitude': siderealLongitude,
        'signIndex': signIndex,
        'sign': sign,
        'degreeInSign': degreeInSign,
        'retrograde': retrograde,
        'houseFromAscendant': houseFromAscendant,
        'houseFromMoon': houseFromMoon,
      };
}

class VedicTransitFinding {
  const VedicTransitFinding({
    required this.code,
    required this.planet,
    required this.houseFromMoon,
    required this.polarity,
    required this.confidence,
    required this.titleEn,
    required this.titleBn,
    required this.narrativeEn,
    required this.narrativeBn,
    required this.evidence,
  });

  final String code;
  final String planet;
  final int houseFromMoon;
  final AnalysisPolarity polarity;
  final AnalysisConfidence confidence;
  final String titleEn;
  final String titleBn;
  final String narrativeEn;
  final String narrativeBn;
  final List<ChartEvidence> evidence;

  Map<String, Object?> toJson() => {
        'code': code,
        'planet': planet,
        'houseFromMoon': houseFromMoon,
        'polarity': polarity.name,
        'confidence': confidence.name,
        'titleEn': titleEn,
        'titleBn': titleBn,
        'narrativeEn': narrativeEn,
        'narrativeBn': narrativeBn,
        'evidence': evidence.map((value) => value.toJson()).toList(),
      };
}

class VedicTransitAnalysis {
  const VedicTransitAnalysis({
    required this.asOfUtc,
    required this.engineId,
    required this.engineVersion,
    required this.schemaVersion,
    required this.ayanamsha,
    required this.lunarNodeMode,
    required this.positions,
    required this.findings,
    required this.warningsEn,
    required this.warningsBn,
    required this.professionalReviewRequired,
  });

  final DateTime asOfUtc;
  final String engineId;
  final String engineVersion;
  final String schemaVersion;
  final String ayanamsha;
  final String lunarNodeMode;
  final List<VedicTransitPosition> positions;
  final List<VedicTransitFinding> findings;
  final List<String> warningsEn;
  final List<String> warningsBn;
  final bool professionalReviewRequired;

  Map<String, Object?> toJson() => {
        'asOfUtc': asOfUtc.toUtc().toIso8601String(),
        'engineId': engineId,
        'engineVersion': engineVersion,
        'schemaVersion': schemaVersion,
        'ayanamsha': ayanamsha,
        'lunarNodeMode': lunarNodeMode,
        'positions': positions.map((value) => value.toJson()).toList(),
        'findings': findings.map((value) => value.toJson()).toList(),
        'warningsEn': warningsEn,
        'warningsBn': warningsBn,
        'professionalReviewRequired': professionalReviewRequired,
      };
}
