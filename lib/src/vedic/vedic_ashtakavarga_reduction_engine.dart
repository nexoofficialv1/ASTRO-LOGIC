import '../models/kundli_analysis.dart';

/// Classical Ashtakavarga reduction stage applied to each raw planetary BAV.
///
/// This engine deliberately keeps reductions separate from the unreduced SAV
/// interpretation contract. Trikona Shodhana is applied first, followed by
/// Ekadhipatya Shodhana using D1 occupancy from the seven classical planets.
class VedicAshtakavargaReductionEngine {
  const VedicAshtakavargaReductionEngine();

  static const String ruleVersion = 'ashtakavarga-reductions-v1';
  static const String rulesetProfile =
      'bphs67Trikona_bphs68Ekadhipatya_classicalOccupancyV1';
  static const String occupancyConvention =
      'D1 occupancy uses Sun through Saturn only; Rahu/Ketu are excluded from v1 reduction decisions';

  static const List<List<int>> _trikonaGroups = <List<int>>[
    [0, 4, 8], // Aries, Leo, Sagittarius
    [1, 5, 9], // Taurus, Virgo, Capricorn
    [2, 6, 10], // Gemini, Libra, Aquarius
    [3, 7, 11], // Cancer, Scorpio, Pisces
  ];

  static const Map<String, List<int>> _dualLordSigns = <String, List<int>>{
    'mars': [0, 7],
    'mercury': [2, 5],
    'jupiter': [8, 11],
    'venus': [1, 6],
    'saturn': [9, 10],
  };

  AshtakavargaReductionProfile reduce({
    required List<BhinnashtakavargaPlanetProfile> bhinnashtakavarga,
    required Map<String, int> classicalPlanetSigns,
  }) {
    _validateInputs(bhinnashtakavarga, classicalPlanetSigns);
    final occupiedSigns = classicalPlanetSigns.values.toSet();
    final reducedPlanets = <AshtakavargaReducedPlanetProfile>[];

    for (final bav in bhinnashtakavarga) {
      final raw = List<int>.generate(
        12,
        (index) => bav.signs
            .firstWhere((value) => value.signIndex == index)
            .positiveMarks,
        growable: false,
      );
      final trikona = _applyTrikona(raw);
      final ekadhipatya = _applyEkadhipatya(
        trikona.output,
        occupiedSigns,
      );
      reducedPlanets.add(
        AshtakavargaReducedPlanetProfile(
          planet: bav.planet,
          rawMarks: List.unmodifiable(raw),
          trikonaReducedMarks: List.unmodifiable(trikona.output),
          ekadhipatyaReducedMarks: List.unmodifiable(ekadhipatya.output),
          trikonaAudits: List.unmodifiable(trikona.audits),
          ekadhipatyaAudits: List.unmodifiable(ekadhipatya.audits),
        ),
      );
    }

    final aggregate = List<int>.generate(
      12,
      (signIndex) => reducedPlanets.fold<int>(
        0,
        (sum, planet) => sum + planet.ekadhipatyaReducedMarks[signIndex],
      ),
      growable: false,
    );

    return AshtakavargaReductionProfile(
      code: 'vedic.ashtakavarga.reductions',
      ruleVersion: ruleVersion,
      rulesetProfile: rulesetProfile,
      occupancyConvention: occupancyConvention,
      planets: List.unmodifiable(reducedPlanets),
      reducedAggregateMarks: List.unmodifiable(aggregate),
      evidence: const [
        ChartEvidence(
          ruleId: 'vedic.ashtakavarga.trikona.bphs67.v1',
          outputPath: r'analysis.ashtakavargaProfile.bhinnashtakavarga[*]',
          kind: EvidenceKind.ashtakavarga,
          descriptionEn:
              'Trikona Shodhana is applied independently to each planetary BAV before Ekadhipatya Shodhana, preserving zero-present and all-equal edge cases.',
          descriptionBn:
              'প্রতিটি planetary BAV-এ Ekadhipatya Shodhana-এর আগে আলাদাভাবে Trikona Shodhana করা হয়েছে; zero-present এবং all-equal edge case আলাদা রাখা হয়েছে।',
        ),
        ChartEvidence(
          ruleId: 'vedic.ashtakavarga.ekadhipatya.bphs68.v1',
          outputPath: r'$.planets[*].signIndex',
          kind: EvidenceKind.ashtakavarga,
          descriptionEn:
              'Ekadhipatya Shodhana follows the Trikona stage and uses sign occupancy plus the paired signs of Mars, Mercury, Jupiter, Venus and Saturn. Sun and Moon are unchanged because they own one sign each.',
          descriptionBn:
              'Trikona পর্যায়ের পরে sign occupancy এবং মঙ্গল, বুধ, বৃহস্পতি, শুক্র ও শনির দ্বৈত-রাশির জোড়া ব্যবহার করে Ekadhipatya Shodhana করা হয়েছে। সূর্য ও চন্দ্র একটিমাত্র রাশির অধিপতি বলে অপরিবর্তিত।',
        ),
      ],
    );
  }

  _TrikonaResult _applyTrikona(List<int> input) {
    final output = List<int>.from(input);
    final audits = <AshtakavargaTrikonaAudit>[];
    for (final group in _trikonaGroups) {
      final values = group.map((index) => input[index]).toList(growable: false);
      final next = List<int>.from(values);
      late final String action;
      if (values.any((value) => value == 0)) {
        action = 'zero_present_no_reduction';
      } else if (values.toSet().length == 1) {
        for (var index = 0; index < 3; index += 1) {
          next[index] = 0;
        }
        action = 'all_equal_reduce_all_to_zero';
      } else {
        final minimum = values.reduce((a, b) => a < b ? a : b);
        for (var index = 0; index < 3; index += 1) {
          next[index] = values[index] - minimum;
        }
        action = 'subtract_group_minimum';
      }
      for (var index = 0; index < 3; index += 1) {
        output[group[index]] = next[index];
      }
      audits.add(
        AshtakavargaTrikonaAudit(
          signIndexes: List.unmodifiable(group),
          inputMarks: List.unmodifiable(values),
          outputMarks: List.unmodifiable(next),
          action: action,
        ),
      );
    }
    return _TrikonaResult(output: output, audits: audits);
  }

  _EkadhipatyaResult _applyEkadhipatya(
    List<int> input,
    Set<int> occupiedSigns,
  ) {
    final output = List<int>.from(input);
    final audits = <AshtakavargaEkadhipatyaAudit>[];
    for (final entry in _dualLordSigns.entries) {
      final signs = entry.value;
      final a = input[signs[0]];
      final b = input[signs[1]];
      final occupied = <bool>[
        occupiedSigns.contains(signs[0]),
        occupiedSigns.contains(signs[1]),
      ];
      var nextA = a;
      var nextB = b;
      late final String action;

      if (a == 0 || b == 0) {
        action = 'zero_present_no_reduction';
      } else if (occupied[0] && occupied[1]) {
        action = 'both_occupied_no_reduction';
      } else if (!occupied[0] && !occupied[1]) {
        if (a == b) {
          nextA = 0;
          nextB = 0;
          action = 'both_empty_equal_reduce_both_to_zero';
        } else {
          final minimum = a < b ? a : b;
          nextA = minimum;
          nextB = minimum;
          action = 'both_empty_unequal_set_both_to_smaller';
        }
      } else {
        final occupiedIndex = occupied[0] ? 0 : 1;
        final emptyIndex = occupiedIndex == 0 ? 1 : 0;
        final occupiedValue = occupiedIndex == 0 ? a : b;
        final emptyValue = emptyIndex == 0 ? a : b;
        final reducedEmpty = occupiedValue < emptyValue
            ? emptyValue - occupiedValue
            : 0;
        if (emptyIndex == 0) {
          nextA = reducedEmpty;
        } else {
          nextB = reducedEmpty;
        }
        action = occupiedValue < emptyValue
            ? 'occupied_smaller_subtract_from_empty'
            : 'occupied_greater_or_equal_reduce_empty_to_zero';
      }

      output[signs[0]] = nextA;
      output[signs[1]] = nextB;
      audits.add(
        AshtakavargaEkadhipatyaAudit(
          lord: entry.key,
          signIndexes: List.unmodifiable(signs),
          inputMarks: List.unmodifiable(<int>[a, b]),
          outputMarks: List.unmodifiable(<int>[nextA, nextB]),
          occupied: List.unmodifiable(occupied),
          action: action,
        ),
      );
    }
    return _EkadhipatyaResult(output: output, audits: audits);
  }

  static void _validateInputs(
    List<BhinnashtakavargaPlanetProfile> bav,
    Map<String, int> planetSigns,
  ) {
    const planets = <String>{
      'sun',
      'moon',
      'mars',
      'mercury',
      'jupiter',
      'venus',
      'saturn',
    };
    final bavPlanets = bav.map((value) => value.planet).toSet();
    if (bav.length != 7 ||
        bavPlanets.length != 7 ||
        !planets.every(bavPlanets.contains)) {
      throw StateError('Ashtakavarga reductions require seven classical BAV tables');
    }
    final signPlanets = planetSigns.keys.toSet();
    if (signPlanets.length != 7 ||
        !planets.every(signPlanets.contains) ||
        planetSigns.values.any((value) => value < 0 || value > 11)) {
      throw StateError('Ashtakavarga reductions require seven classical D1 sign positions');
    }
    for (final profile in bav) {
      if (profile.signs.length != 12 ||
          profile.signs.map((value) => value.signIndex).toSet().length != 12) {
        throw StateError('Ashtakavarga reduction input must cover twelve signs');
      }
    }
  }
}

class _TrikonaResult {
  const _TrikonaResult({required this.output, required this.audits});
  final List<int> output;
  final List<AshtakavargaTrikonaAudit> audits;
}

class _EkadhipatyaResult {
  const _EkadhipatyaResult({required this.output, required this.audits});
  final List<int> output;
  final List<AshtakavargaEkadhipatyaAudit> audits;
}
