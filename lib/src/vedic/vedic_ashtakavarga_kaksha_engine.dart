import '../models/kundli_analysis.dart';
import '../models/vedic_question_timing.dart';

/// Governed Ashtakavarga Kaksha micro-zone review.
///
/// Each 30-degree sign is divided into eight equal 3.75-degree half-open
/// zones in the fixed Saturn, Jupiter, Mars, Sun, Venus, Mercury, Moon, Lagna
/// order. A micro-zone is supportive only when its Kaksha lord is one of the
/// positive contributors in the transiting planet's unreduced BAV sign.
class VedicAshtakavargaKakshaEngine {
  const VedicAshtakavargaKakshaEngine();

  static const String ruleVersion = 'ashtakavarga-kaksha-v1';
  static const Set<String> _classicalPlanets = <String>{
    'sun', 'moon', 'mars', 'mercury', 'jupiter', 'venus', 'saturn',
  };
  static const double kakshaWidthDegrees = 3.75;
  static const List<String> kakshaLords = <String>[
    'saturn',
    'jupiter',
    'mars',
    'sun',
    'venus',
    'mercury',
    'moon',
    'lagna',
  ];

  VedicAshtakavargaKakshaProfile review({
    required String transitingPlanet,
    required int signIndex,
    required double degreeInSign,
    required BhinnashtakavargaSignProfile bavSign,
  }) {
    if (!_classicalPlanets.contains(transitingPlanet)) {
      throw ArgumentError.value(
        transitingPlanet,
        'transitingPlanet',
        'Kaksha BAV review supports Sun through Saturn only',
      );
    }
    if (signIndex < 0 || signIndex > 11 || bavSign.signIndex != signIndex) {
      throw ArgumentError('Kaksha review requires a matching sign index 0..11');
    }
    if (!degreeInSign.isFinite || degreeInSign < 0 || degreeInSign >= 30) {
      throw ArgumentError.value(
        degreeInSign,
        'degreeInSign',
        'Kaksha degree must be finite and in [0, 30)',
      );
    }

    final zeroBased = (degreeInSign / kakshaWidthDegrees).floor();
    final kakshaNumber = zeroBased + 1;
    final lord = kakshaLords[zeroBased];
    final start = zeroBased * kakshaWidthDegrees;
    final end = start + kakshaWidthDegrees;
    final positive = bavSign.contributors.any((value) => value.reference == lord);
    final polarity = positive
        ? AnalysisPolarity.supportive
        : AnalysisPolarity.challenging;
    final statusEn = positive
        ? 'supportive because $lord contributed a positive mark'
        : 'challenging because $lord did not contribute a positive mark';
    final statusBn = positive
        ? 'positive mark দিয়েছে, তাই Kaksha supportive'
        : 'positive mark দেয়নি, তাই Kaksha challenging';

    return VedicAshtakavargaKakshaProfile(
      ruleVersion: ruleVersion,
      kakshaNumber: kakshaNumber,
      kakshaLord: lord,
      startDegree: start,
      endDegree: end,
      degreeInSign: degreeInSign,
      positiveMark: positive,
      polarity: polarity,
      evidence: <ChartEvidence>[
        ChartEvidence(
          ruleId: 'vedic.ashtakavarga.kaksha.prasthara.v1',
          outputPath:
              'analysis.ashtakavargaProfile.bhinnashtakavarga.$transitingPlanet.sign.$signIndex.contributors',
          kind: EvidenceKind.ashtakavarga,
          descriptionEn:
              '$transitingPlanet at ${degreeInSign.toStringAsFixed(4)} degrees in sign $signIndex occupies Kaksha $kakshaNumber ($lord, ${start.toStringAsFixed(2)}-${end.toStringAsFixed(2)} degrees). The Kaksha is $statusEn in this unreduced BAV sign.',
          descriptionBn:
              '$transitingPlanet sign $signIndex-এ ${degreeInSign.toStringAsFixed(4)} ডিগ্রিতে Kaksha $kakshaNumber ($lord, ${start.toStringAsFixed(2)}-${end.toStringAsFixed(2)} ডিগ্রি)-এ আছে। এই unreduced BAV sign-এ $lord $statusBn।',
        ),
      ],
    );
  }
}
