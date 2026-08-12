import '../models/calculation_output_snapshot.dart';
import '../models/kundli_analysis.dart';
import 'vedic_ashtakavarga_pinda_engine.dart';
import 'vedic_ashtakavarga_reduction_engine.dart';

/// Source-bounded Ashtakavarga foundation using the received-standard
/// Parashari positive-place tables. The persisted field name `positiveMarks`
/// avoids silently conflating recension-specific Bindu/Rekha terminology.
class VedicAshtakavargaEngine {
  const VedicAshtakavargaEngine();

  static const String ruleVersion = 'ashtakavarga-foundation-v3';
  static const String rulesetProfile =
      'receivedStandardParashariPositivePlacesV1';
  static const String notationConvention =
      'positiveMark1; modern displays may label this bindu, while some BPHS recensions label auspicious 1 as rekha/sthana';

  static const List<String> _planets = <String>[
    'sun',
    'moon',
    'mars',
    'mercury',
    'jupiter',
    'venus',
    'saturn',
  ];

  static const List<String> _references = <String>[
    ..._planets,
    'lagna',
  ];

  static const Map<String, int> _fixedTotals = <String, int>{
    'sun': 48,
    'moon': 49,
    'mars': 39,
    'mercury': 54,
    'jupiter': 56,
    'venus': 52,
    'saturn': 39,
  };

  static const Map<String, Map<String, List<int>>> _positivePlaces =
      <String, Map<String, List<int>>>{
    'sun': <String, List<int>>{
      'sun': [1, 2, 4, 7, 8, 9, 10, 11],
      'moon': [3, 6, 10, 11],
      'mars': [1, 2, 4, 7, 8, 9, 10, 11],
      'mercury': [3, 5, 6, 9, 10, 11, 12],
      'jupiter': [5, 6, 9, 11],
      'venus': [6, 7, 12],
      'saturn': [1, 2, 4, 7, 8, 9, 10, 11],
      'lagna': [3, 4, 6, 10, 11, 12],
    },
    'moon': <String, List<int>>{
      'sun': [3, 6, 7, 8, 10, 11],
      'moon': [1, 3, 6, 7, 10, 11],
      'mars': [2, 3, 5, 6, 9, 10, 11],
      'mercury': [1, 3, 4, 5, 7, 8, 10, 11],
      'jupiter': [1, 4, 7, 8, 10, 11, 12],
      'venus': [3, 4, 5, 7, 9, 10, 11],
      'saturn': [3, 5, 6, 11],
      'lagna': [3, 6, 10, 11],
    },
    'mars': <String, List<int>>{
      'sun': [3, 5, 6, 10, 11],
      'moon': [3, 6, 11],
      'mars': [1, 2, 4, 7, 8, 10, 11],
      'mercury': [3, 5, 6, 11],
      'jupiter': [6, 10, 11, 12],
      'venus': [6, 8, 11, 12],
      'saturn': [1, 4, 7, 8, 9, 10, 11],
      'lagna': [1, 3, 6, 10, 11],
    },
    'mercury': <String, List<int>>{
      'sun': [5, 6, 9, 11, 12],
      'moon': [2, 4, 6, 8, 10, 11],
      'mars': [1, 2, 4, 7, 8, 9, 10, 11],
      'mercury': [1, 3, 5, 6, 9, 10, 11, 12],
      'jupiter': [6, 8, 11, 12],
      'venus': [1, 2, 3, 4, 5, 8, 9, 11],
      'saturn': [1, 2, 4, 7, 8, 9, 10, 11],
      'lagna': [1, 2, 4, 6, 8, 10, 11],
    },
    'jupiter': <String, List<int>>{
      'sun': [1, 2, 3, 4, 7, 8, 9, 10, 11],
      'moon': [2, 5, 7, 9, 11],
      'mars': [1, 2, 4, 7, 8, 10, 11],
      'mercury': [1, 2, 4, 5, 6, 9, 10, 11],
      'jupiter': [1, 2, 3, 4, 7, 8, 10, 11],
      'venus': [2, 5, 6, 9, 10, 11],
      'saturn': [3, 5, 6, 12],
      'lagna': [1, 2, 4, 5, 6, 7, 9, 10, 11],
    },
    'venus': <String, List<int>>{
      'sun': [8, 11, 12],
      'moon': [1, 2, 3, 4, 5, 8, 9, 11, 12],
      'mars': [3, 5, 6, 9, 11, 12],
      'mercury': [3, 5, 6, 9, 11],
      'jupiter': [5, 8, 9, 10, 11],
      'venus': [1, 2, 3, 4, 5, 8, 9, 10, 11],
      'saturn': [3, 4, 5, 8, 9, 10, 11],
      'lagna': [1, 2, 3, 4, 5, 8, 9, 11],
    },
    'saturn': <String, List<int>>{
      'sun': [1, 2, 4, 7, 8, 10, 11],
      'moon': [3, 6, 11],
      'mars': [3, 5, 6, 10, 11, 12],
      'mercury': [6, 8, 9, 10, 11, 12],
      'jupiter': [5, 6, 11, 12],
      'venus': [6, 11, 12],
      'saturn': [3, 5, 6, 11],
      'lagna': [1, 3, 4, 6, 10, 11],
    },
  };

  AshtakavargaAnalysisProfile build(CalculationOutputSnapshot output) {
    final ascendant = _requiredMap(output.output['ascendant'], 'ascendant');
    final ascendantSign = _requiredSign(ascendant['signIndex'], 'ascendant.signIndex');
    final planetSigns = _planetSigns(output.output['planets']);

    final references = <String, int>{
      for (final planet in _planets) planet: planetSigns[planet]!,
      'lagna': ascendantSign,
    };

    final bav = <BhinnashtakavargaPlanetProfile>[];
    for (final target in _planets) {
      final scores = <BhinnashtakavargaSignProfile>[];
      for (var signIndex = 0; signIndex < 12; signIndex += 1) {
        final contributors = <AshtakavargaContribution>[];
        for (final reference in _references) {
          final referenceSign = references[reference]!;
          final relativeHouse = ((signIndex - referenceSign + 12) % 12) + 1;
          if (_positivePlaces[target]![reference]!.contains(relativeHouse)) {
            contributors.add(
              AshtakavargaContribution(
                reference: reference,
                referenceSignIndex: referenceSign,
                relativeHouse: relativeHouse,
              ),
            );
          }
        }
        scores.add(
          BhinnashtakavargaSignProfile(
            signIndex: signIndex,
            positiveMarks: contributors.length,
            contributors: List.unmodifiable(contributors),
          ),
        );
      }
      final profile = BhinnashtakavargaPlanetProfile(
        planet: target,
        fixedTotalPositiveMarks: _fixedTotals[target]!,
        signs: List.unmodifiable(scores),
      );
      if (profile.totalPositiveMarks != profile.fixedTotalPositiveMarks) {
        throw StateError(
          'Ashtakavarga checksum failed for $target: '
          '${profile.totalPositiveMarks} != ${profile.fixedTotalPositiveMarks}',
        );
      }
      bav.add(profile);
    }

    final sav = <SarvashtakavargaSignProfile>[];
    for (var signIndex = 0; signIndex < 12; signIndex += 1) {
      final marks = bav.fold<int>(
        0,
        (sum, planet) => sum + planet.signs[signIndex].positiveMarks,
      );
      final houseNumber = ((signIndex - ascendantSign + 12) % 12) + 1;
      final (band, polarity, en, bn) = _savBand(marks);
      sav.add(
        SarvashtakavargaSignProfile(
          signIndex: signIndex,
          houseNumber: houseNumber,
          positiveMarks: marks,
          band: band,
          polarity: polarity,
          confidence: AnalysisConfidence.medium,
          narrativeEn:
              'Whole-sign house $houseNumber has $marks positive marks in the unreduced seven-planet aggregate. BPHS 72 classifies this score as $en. Treat it as comparative house support, not a guaranteed event result.',
          narrativeBn:
              'হোল-সাইন $houseNumber নম্বর ভাবে unreduced সাত-গ্রহের aggregate-এ $marksটি positive mark আছে। BPHS 72 অনুযায়ী এই স্কোর $bn শ্রেণিতে পড়ে। এটিকে তুলনামূলক ভাব-সমর্থন হিসেবে দেখুন, নিশ্চিত ঘটনার ফল হিসেবে নয়।',
          evidence: const [
            ChartEvidence(
              ruleId: 'vedic.ashtakavarga.sav.bphs72.v1',
              outputPath: r'$.ascendant.signIndex + $.planets[*].signIndex',
              kind: EvidenceKind.ashtakavarga,
              descriptionEn:
                  'Sarvashtakavarga is derived by summing the seven unreduced planetary Ashtakavargas sign by sign.',
              descriptionBn:
                  'সাতটি unreduced planetary Ashtakavarga রাশি অনুযায়ী যোগ করে Sarvashtakavarga তৈরি করা হয়েছে।',
            ),
          ],
        ),
      );
    }
    final total = sav.fold<int>(0, (sum, value) => sum + value.positiveMarks);
    if (total != 337) {
      throw StateError('Sarvashtakavarga checksum failed: $total != 337');
    }
    final reductionProfile = const VedicAshtakavargaReductionEngine().reduce(
      bhinnashtakavarga: bav,
      classicalPlanetSigns: planetSigns,
    );
    final pindaProfile = const VedicAshtakavargaPindaEngine().calculate(
      reductionProfile: reductionProfile,
      classicalPlanetSigns: planetSigns,
    );

    return AshtakavargaAnalysisProfile(
      code: 'vedic.ashtakavarga.foundation',
      ruleVersion: ruleVersion,
      rulesetProfile: rulesetProfile,
      notationConvention: notationConvention,
      bhinnashtakavarga: List.unmodifiable(bav),
      sarvashtakavarga: List.unmodifiable(sav),
      totalPositiveMarks: total,
      averagePositiveMarks: total / 12.0,
      reductionProfile: reductionProfile,
      pindaProfile: pindaProfile,
      evidence: const [
        ChartEvidence(
          ruleId: 'vedic.ashtakavarga.bav.received_standard.v1',
          outputPath: r'$.planets[*].signIndex + $.ascendant.signIndex',
          kind: EvidenceKind.ashtakavarga,
          descriptionEn:
              'Each planetary table uses eight references: Sun through Saturn plus Lagna; Rahu and Ketu are excluded.',
          descriptionBn:
              'প্রতিটি planetary table-এ আটটি reference ব্যবহৃত হয়েছে: সূর্য থেকে শনি এবং লগ্ন; রাহু-কেতু অন্তর্ভুক্ত নয়।',
        ),
      ],
    );
  }

  static (String, AnalysisPolarity, String, String) _savBand(int marks) {
    if (marks > 30) {
      return ('favourable', AnalysisPolarity.supportive, 'favourable', 'অনুকূল');
    }
    if (marks >= 25) {
      return ('medium', AnalysisPolarity.mixed, 'medium', 'মধ্যম');
    }
    return ('adverse', AnalysisPolarity.challenging, 'adverse', 'প্রতিকূল');
  }

  static Map<String, int> _planetSigns(Object? raw) {
    if (raw is! List) throw StateError('Vedic output planets must be a list');
    final result = <String, int>{};
    for (var index = 0; index < raw.length; index += 1) {
      final map = _requiredMap(raw[index], 'planets[$index]');
      final body = map['body'];
      if (body is! String) throw StateError('planets[$index].body is invalid');
      if (_planets.contains(body)) {
        if (result.containsKey(body)) {
          throw StateError('Duplicate classical planet in Ashtakavarga input: $body');
        }
        result[body] = _requiredSign(map['signIndex'], 'planets[$index].signIndex');
      }
    }
    for (final planet in _planets) {
      if (!result.containsKey(planet)) {
        throw StateError('Ashtakavarga requires classical planet $planet');
      }
    }
    return result;
  }

  static Map<String, Object?> _requiredMap(Object? raw, String path) {
    if (raw is! Map) throw StateError('$path must be a map');
    return Map<String, Object?>.from(raw);
  }

  static int _requiredSign(Object? raw, String path) {
    if (raw is! num) throw StateError('$path must be numeric');
    final value = raw.toInt();
    if (value < 0 || value > 11) throw StateError('$path must be 0..11');
    return value;
  }
}
