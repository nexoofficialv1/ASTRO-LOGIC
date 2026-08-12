import '../models/kundli_analysis.dart';

class NumerologyConfidenceSummary {
  const NumerologyConfidenceSummary({
    required this.policyId,
    required this.predictionConfidence,
    required this.arithmeticDeterministic,
    required this.vedicCrossCheckCanRaiseConfidence,
    required this.rationaleEn,
    required this.rationaleBn,
  });

  final String policyId;
  final AnalysisConfidence predictionConfidence;
  final bool arithmeticDeterministic;
  final bool vedicCrossCheckCanRaiseConfidence;
  final String rationaleEn;
  final String rationaleBn;

  Map<String, Object?> toMap() => {
        'policyId': policyId,
        'predictionConfidence': predictionConfidence.name,
        'arithmeticDeterministic': arithmeticDeterministic,
        'vedicCrossCheckCanRaiseConfidence': vedicCrossCheckCanRaiseConfidence,
        'rationaleEn': rationaleEn,
        'rationaleBn': rationaleBn,
      };
}

class NumerologyNameCandidateReview {
  const NumerologyNameCandidateReview({
    required this.code,
    required this.candidateNameLatin,
    required this.comparisonStatus,
    required this.selectedForProfessionalReview,
    required this.confidence,
    required this.pythagoreanBaselineReduced,
    required this.pythagoreanCandidateReduced,
    required this.pythagoreanCompoundDelta,
    required this.chaldeanBaselineReduced,
    required this.chaldeanCandidateReduced,
    required this.chaldeanCompoundDelta,
    required this.flags,
    required this.narrativeEn,
    required this.narrativeBn,
    required this.cautionEn,
    required this.cautionBn,
    required this.evidence,
  });

  final String code;
  final String candidateNameLatin;
  final String comparisonStatus;
  final bool selectedForProfessionalReview;
  final AnalysisConfidence confidence;
  final int pythagoreanBaselineReduced;
  final int pythagoreanCandidateReduced;
  final int pythagoreanCompoundDelta;
  final int chaldeanBaselineReduced;
  final int chaldeanCandidateReduced;
  final int chaldeanCompoundDelta;
  final List<String> flags;
  final String narrativeEn;
  final String narrativeBn;
  final String cautionEn;
  final String cautionBn;
  final List<ChartEvidence> evidence;

  Map<String, Object?> toMap() => {
        'code': code,
        'candidateNameLatin': candidateNameLatin,
        'comparisonStatus': comparisonStatus,
        'selectedForProfessionalReview': selectedForProfessionalReview,
        'confidence': confidence.name,
        'pythagoreanBaselineReduced': pythagoreanBaselineReduced,
        'pythagoreanCandidateReduced': pythagoreanCandidateReduced,
        'pythagoreanCompoundDelta': pythagoreanCompoundDelta,
        'chaldeanBaselineReduced': chaldeanBaselineReduced,
        'chaldeanCandidateReduced': chaldeanCandidateReduced,
        'chaldeanCompoundDelta': chaldeanCompoundDelta,
        'flags': flags,
        'narrativeEn': narrativeEn,
        'narrativeBn': narrativeBn,
        'cautionEn': cautionEn,
        'cautionBn': cautionBn,
        'evidence': evidence.map((value) => value.toJson()).toList(),
        'rankingScore': null,
        'automaticRecommendation': false,
      };
}

class NumerologyAnalysis {
  const NumerologyAnalysis({
    required this.engineId,
    required this.engineVersion,
    required this.analysisSchemaVersion,
    required this.findings,
    required this.nameCandidateReviews,
    required this.crossSystemFindings,
    required this.timingWindows,
    required this.remedyCandidates,
    required this.confidenceSummary,
    required this.warningsEn,
    required this.warningsBn,
    required this.professionalReviewRequired,
  });

  final String engineId;
  final String engineVersion;
  final String analysisSchemaVersion;
  final List<ChartFinding> findings;
  final List<NumerologyNameCandidateReview> nameCandidateReviews;
  final List<ChartFinding> crossSystemFindings;
  final List<AnalysisTimingWindow> timingWindows;
  final List<AnalysisRemedyCandidate> remedyCandidates;
  final NumerologyConfidenceSummary confidenceSummary;
  final List<String> warningsEn;
  final List<String> warningsBn;
  final bool professionalReviewRequired;

  Map<String, Object?> toMap() => {
        'engineId': engineId,
        'engineVersion': engineVersion,
        'analysisSchemaVersion': analysisSchemaVersion,
        'findings': findings.map((value) => value.toJson()).toList(),
        'nameCandidateReviews':
            nameCandidateReviews.map((value) => value.toMap()).toList(),
        'crossSystemFindings':
            crossSystemFindings.map((value) => value.toJson()).toList(),
        'timingWindows': timingWindows.map((value) => value.toJson()).toList(),
        'remedyCandidates':
            remedyCandidates.map((value) => value.toJson()).toList(),
        'confidenceSummary': confidenceSummary.toMap(),
        'warningsEn': warningsEn,
        'warningsBn': warningsBn,
        'professionalReviewRequired': professionalReviewRequired,
        'scientificStatus':
            'Traditional numerology interpretation; not scientifically validated',
      };
}
