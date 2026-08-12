import '../models/kundli_analysis.dart';

/// Classical post-Shodhana Ashtakavarga Pinda calculation.
///
/// The engine consumes the Ekadhipatya-reduced BAV of each classical planet,
/// calculates Rashi Pinda with fixed sign multipliers, calculates Graha Pinda
/// from the seven classical D1 planetary occupancies and fixed planet
/// multipliers, and publishes Shodhya/Yoga Pinda as their sum.
class VedicAshtakavargaPindaEngine {
  const VedicAshtakavargaPindaEngine();

  static const String ruleVersion = 'ashtakavarga-pinda-v1';
  static const String rulesetProfile =
      'phaladeepika24_postShodhana_rashiGrahaMultipliersV1';

  static const List<int> rashiMultipliers = <int>[
    7, // Aries
    10, // Taurus
    8, // Gemini
    4, // Cancer
    10, // Leo
    5, // Virgo
    7, // Libra
    8, // Scorpio
    9, // Sagittarius
    5, // Capricorn
    11, // Aquarius
    12, // Pisces
  ];

  static const Map<String, int> grahaMultipliers = <String, int>{
    'sun': 5,
    'moon': 5,
    'mars': 8,
    'mercury': 5,
    'jupiter': 10,
    'venus': 7,
    'saturn': 5,
  };

  AshtakavargaPindaProfile calculate({
    required AshtakavargaReductionProfile reductionProfile,
    required Map<String, int> classicalPlanetSigns,
  }) {
    _validateInputs(reductionProfile, classicalPlanetSigns);

    final planets = <AshtakavargaPlanetPindaProfile>[];
    for (final reduced in reductionProfile.planets) {
      final rashiContributions = <AshtakavargaRashiPindaContribution>[];
      var rashiPinda = 0;
      for (var signIndex = 0; signIndex < 12; signIndex += 1) {
        final marks = reduced.ekadhipatyaReducedMarks[signIndex];
        final multiplier = rashiMultipliers[signIndex];
        final product = marks * multiplier;
        rashiPinda += product;
        rashiContributions.add(
          AshtakavargaRashiPindaContribution(
            signIndex: signIndex,
            reducedMarks: marks,
            multiplier: multiplier,
            product: product,
          ),
        );
      }

      final grahaContributions = <AshtakavargaGrahaPindaContribution>[];
      var grahaPinda = 0;
      for (final referencePlanet in grahaMultipliers.keys) {
        final signIndex = classicalPlanetSigns[referencePlanet]!;
        final marks = reduced.ekadhipatyaReducedMarks[signIndex];
        final multiplier = grahaMultipliers[referencePlanet]!;
        final product = marks * multiplier;
        grahaPinda += product;
        grahaContributions.add(
          AshtakavargaGrahaPindaContribution(
            referencePlanet: referencePlanet,
            occupiedSignIndex: signIndex,
            reducedMarks: marks,
            multiplier: multiplier,
            product: product,
          ),
        );
      }

      planets.add(
        AshtakavargaPlanetPindaProfile(
          planet: reduced.planet,
          rashiPinda: rashiPinda,
          grahaPinda: grahaPinda,
          shodhyaPinda: rashiPinda + grahaPinda,
          rashiContributions: List.unmodifiable(rashiContributions),
          grahaContributions: List.unmodifiable(grahaContributions),
        ),
      );
    }

    return AshtakavargaPindaProfile(
      code: 'vedic.ashtakavarga.pinda',
      ruleVersion: ruleVersion,
      rulesetProfile: rulesetProfile,
      rashiMultipliers: List.unmodifiable(rashiMultipliers),
      grahaMultipliers: Map.unmodifiable(grahaMultipliers),
      planets: List.unmodifiable(planets),
      evidence: const [
        ChartEvidence(
          ruleId: 'vedic.ashtakavarga.pinda.phaladeepika24.v1',
          outputPath:
              r'analysis.ashtakavargaProfile.reductionProfile.planets[*].ekadhipatyaReducedMarks',
          kind: EvidenceKind.ashtakavarga,
          descriptionEn:
              'After Trikona and Ekadhipatya reductions, each sign value is multiplied by its fixed Rashi factor for Rashi Pinda. The reduced value in each classical planet\'s occupied sign is separately multiplied by that planet\'s fixed Graha factor for Graha Pinda. Their sum is Shodhya/Yoga Pinda.',
          descriptionBn:
              'Trikona ও Ekadhipatya reduction-এর পরে প্রতিটি রাশির reduced value-কে fixed Rashi factor দিয়ে গুণ করে Rashi Pinda এবং সাতটি classical planet যে রাশিতে আছে সেই reduced value-কে সংশ্লিষ্ট Graha factor দিয়ে গুণ করে Graha Pinda করা হয়। দুইটির যোগ Shodhya/Yoga Pinda।',
        ),
      ],
    );
  }

  static void _validateInputs(
    AshtakavargaReductionProfile reductionProfile,
    Map<String, int> classicalPlanetSigns,
  ) {
    if (reductionProfile.ruleVersion != 'ashtakavarga-reductions-v1' ||
        reductionProfile.planets.length != 7 ||
        reductionProfile.planets.map((value) => value.planet).toSet().length !=
            7) {
      throw StateError('Pinda calculation requires a complete v1 reduction profile');
    }
    if (classicalPlanetSigns.length != 7 ||
        !grahaMultipliers.keys.every(classicalPlanetSigns.containsKey) ||
        classicalPlanetSigns.values.any((value) => value < 0 || value > 11)) {
      throw StateError('Pinda calculation requires seven classical D1 positions');
    }
    for (final reduced in reductionProfile.planets) {
      if (!grahaMultipliers.containsKey(reduced.planet) ||
          reduced.ekadhipatyaReducedMarks.length != 12 ||
          reduced.ekadhipatyaReducedMarks.any((value) => value < 0)) {
        throw StateError('Pinda calculation received invalid reduced BAV data');
      }
    }
  }
}
