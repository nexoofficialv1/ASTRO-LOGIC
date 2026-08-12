import '../models/kundli_analysis.dart';
import 'numerology_analysis.dart';

class NumerologyAnalysisPolicy {
  const NumerologyAnalysisPolicy._();

  static void validate(NumerologyAnalysis analysis) {
    if (!analysis.professionalReviewRequired || analysis.findings.isEmpty) {
      throw StateError('Professional review and non-empty findings are required');
    }
    if (analysis.confidenceSummary.predictionConfidence !=
        AnalysisConfidence.low) {
      throw StateError('Numerology prediction confidence must remain Low');
    }
    if (!analysis.confidenceSummary.arithmeticDeterministic ||
        analysis.confidenceSummary.vedicCrossCheckCanRaiseConfidence) {
      throw StateError('Numerology confidence policy is inconsistent');
    }
    _requireText([
      analysis.confidenceSummary.policyId,
      analysis.confidenceSummary.rationaleEn,
      analysis.confidenceSummary.rationaleBn,
    ]);

    for (final finding in [
      ...analysis.findings,
      ...analysis.crossSystemFindings,
    ]) {
      _requireText([
        finding.titleEn,
        finding.titleBn,
        finding.narrativeEn,
        finding.narrativeBn,
      ]);
      _requireEvidence(finding.evidence);
      if (analysis.crossSystemFindings.contains(finding) &&
          finding.confidence != AnalysisConfidence.low) {
        throw StateError('Cross-system findings cannot raise confidence');
      }
    }
    final selectedNameCandidates = analysis.nameCandidateReviews
        .where((value) => value.selectedForProfessionalReview)
        .toList(growable: false);
    if (selectedNameCandidates.length > 1) {
      throw StateError('Only one explicit professional name focus is permitted');
    }
    for (final review in analysis.nameCandidateReviews) {
      if (review.confidence != AnalysisConfidence.medium) {
        throw StateError(
          'Name candidate comparison confidence must describe arithmetic only',
        );
      }
      if (!const {
        'noReducedChange',
        'oneSystemReducedChange',
        'bothSystemsReducedChange',
      }.contains(review.comparisonStatus)) {
        throw StateError('Unknown name candidate arithmetic status');
      }
      _requireText([
        review.code,
        review.candidateNameLatin,
        review.comparisonStatus,
        review.narrativeEn,
        review.narrativeBn,
        review.cautionEn,
        review.cautionBn,
      ]);
      _requireEvidence(review.evidence);
      final unsafe = '${review.narrativeEn} ${review.narrativeBn}'
          .toLowerCase();
      for (final phrase in const [
        'guaranteed lucky name',
        'best name automatically',
        'recommended legal name',
      ]) {
        if (unsafe.contains(phrase)) {
          throw StateError('Name candidate review contains prohibited ranking language');
        }
      }
    }
    for (final timing in analysis.timingWindows) {
      if (!timing.end.isAfter(timing.start)) {
        throw StateError('Timing end must be after start');
      }
      if (timing.confidence != AnalysisConfidence.low) {
        throw StateError('Numerology timing must remain Low confidence');
      }
      _requireText([timing.narrativeEn, timing.narrativeBn]);
      _requireEvidence(timing.evidence);
    }
    for (final remedy in analysis.remedyCandidates) {
      if (remedy.kind != AnalysisRemedyKind.behavioral ||
          remedy.targetPlanet != null) {
        throw StateError(
          'Numerology v2.1 permits only non-planetary behavioural candidates',
        );
      }
      _requireText([
        remedy.actionEn,
        remedy.actionBn,
        remedy.rationaleEn,
        remedy.rationaleBn,
        remedy.cautionEn,
        remedy.cautionBn,
      ]);
      _requireEvidence(remedy.evidence);
    }
    _requireText([...analysis.warningsEn, ...analysis.warningsBn]);
  }

  static void _requireEvidence(List<ChartEvidence> evidence) {
    if (evidence.isEmpty) throw StateError('Evidence is mandatory');
    for (final item in evidence) {
      _requireText([
        item.ruleId,
        item.outputPath,
        item.descriptionEn,
        item.descriptionBn,
      ]);
    }
  }

  static void _requireText(Iterable<String> values) {
    if (values.isEmpty || values.any((value) => value.trim().isEmpty)) {
      throw StateError('Bilingual non-empty text is mandatory');
    }
  }
}
