import '../models/gemstone_remedy.dart';

class GemstoneRemedyPolicy {
  const GemstoneRemedyPolicy._();

  static void validate(
    GemstoneRemedy remedy, {
    required bool verifiedOutputExists,
  }) {
    if (remedy.primaryGemstone.trim().isEmpty ||
        remedy.astrologicalReason.trim().isEmpty ||
        remedy.cautions.trim().isEmpty) {
      throw ArgumentError(
        'Gemstone, astrological reason and cautions are required',
      );
    }
    if (!remedy.weightValue.isFinite ||
        remedy.weightValue <= 0 ||
        remedy.weightValue > 100) {
      throw ArgumentError.value(remedy.weightValue, 'weightValue');
    }
    if (remedy.evidenceReferences.any((value) => value.trim().isEmpty)) {
      throw ArgumentError('Evidence references cannot be blank');
    }
    if (remedy.decision == RemedyDecision.approved) {
      if (!verifiedOutputExists) {
        throw StateError(
          'Verified calculation output is required before approval',
        );
      }
      if (remedy.evidenceReferences.isEmpty) {
        throw StateError(
          'Astrological evidence is required before approval',
        );
      }
    }
  }
}
