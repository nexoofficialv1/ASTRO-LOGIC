import '../models/kundli_analysis.dart';
import '../models/kundli_analysis_snapshot.dart';
import 'numerology_engine.dart';

/// Guarded bridge between traditional Numerology number-planet correspondence
/// and an already-persisted Vedic judgment snapshot.
///
/// This is deliberately a *review context*, not corroboration. It never raises
/// Numerology confidence and never turns a Vedic gemstone screen into a
/// Numerology gemstone recommendation.
class NumerologyVedicCrossCheckEngine {
  const NumerologyVedicCrossCheckEngine();

  static const ruleVersion = 'numerology-vedic-cross-check-v1';
  static const mappingProfile = 'traditional-number-planet-correspondence-v1';

  List<ChartFinding> build(
    NumerologyProfile profile,
    KundliAnalysisSnapshot snapshot,
  ) {
    final cores = <_CoreNumber>[
      _CoreNumber(
        code: 'driver',
        labelEn: 'Driver/Birth',
        labelBn: 'ড্রাইভার/জন্মসংখ্যা',
        outputPath: r'$.driver.reduced',
        value: profile.driver.reduced,
      ),
      _CoreNumber(
        code: 'life_path',
        labelEn: 'Life Path',
        labelBn: 'লাইফ পাথ',
        outputPath: r'$.lifePath.reduced',
        value: profile.lifePath.reduced,
      ),
      _CoreNumber(
        code: 'expression',
        labelEn: 'Pythagorean Expression',
        labelBn: 'পাইথাগোরিয়ান এক্সপ্রেশন',
        outputPath: r'$.pythagorean.expression.reduced',
        value: profile.pythagorean.expression.reduced,
      ),
    ];
    return cores
        .map((core) => _finding(core, snapshot))
        .toList(growable: false);
  }

  ChartFinding _finding(
    _CoreNumber core,
    KundliAnalysisSnapshot snapshot,
  ) {
    final root = _root(core.value);
    final planet = _planetByRoot[root]!;
    final planetEn = _planetEn[planet]!;
    final planetBn = _planetBn[planet]!;
    final mappingEvidence = ChartEvidence(
      ruleId: '$ruleVersion.mapping.$root',
      outputPath: core.outputPath,
      kind: EvidenceKind.strength,
      descriptionEn:
          '${core.labelEn} ${core.value}${core.value == root ? '' : ' (root $root)'} is traditionally associated with $planetEn under $mappingProfile.',
      descriptionBn:
          '${core.labelBn} ${core.value}${core.value == root ? '' : ' (root $root)'}-কে $mappingProfile অনুযায়ী প্রচলিতভাবে $planetBn-এর সঙ্গে যুক্ত করা হয়।',
    );

    if (planet == 'rahu' || planet == 'ketu') {
      final vedicEvidence = ChartEvidence(
        ruleId: '$ruleVersion.vedic_node_gate',
        outputPath: r'$.gemstoneCandidateReviews',
        kind: EvidenceKind.strength,
        descriptionEn:
            'Kundli snapshot ${snapshot.id} (${snapshot.analysisSchemaVersion}, ${_shortHash(snapshot.analysisHash)}) intentionally has no automated Rahu/Ketu strengthening-gemstone review.',
        descriptionBn:
            'Kundli snapshot ${snapshot.id} (${snapshot.analysisSchemaVersion}, ${_shortHash(snapshot.analysisHash)})-এ ইচ্ছাকৃতভাবে Rahu/Ketu automated strengthening-gemstone review নেই।',
      );
      return ChartFinding(
        code: 'numerology.vedic_crosscheck.${core.code}.$planet.limited',
        area: _areaFor(core.code),
        polarity: AnalysisPolarity.mixed,
        confidence: AnalysisConfidence.low,
        titleEn:
            '${core.labelEn} ${core.value} ↔ $planetEn — Vedic cross-check limited',
        titleBn:
            '${core.labelBn} ${core.value} ↔ $planetBn — বৈদিক cross-check সীমিত',
        narrativeEn:
            'The traditional number-planet correspondence is shown for review only. ASTRO LOGIC does not infer Rahu/Ketu strength, gemstone suitability, events or favourable/adverse outcomes from this Numerology mapping.',
        narrativeBn:
            'প্রচলিত number-planet correspondence শুধু review-এর জন্য দেখানো হয়েছে। এই সংখ্যাতাত্ত্বিক mapping থেকে ASTRO LOGIC Rahu/Ketu-এর শক্তি, রত্ন-উপযোগিতা, ঘটনা বা শুভ/অশুভ ফল অনুমান করে না।',
        evidence: [mappingEvidence, vedicEvidence],
      );
    }

    final review = _gemstoneReview(snapshot.analysis, planet);
    if (review == null) {
      final vedicEvidence = ChartEvidence(
        ruleId: '$ruleVersion.vedic_review_unavailable',
        outputPath: r'$.gemstoneCandidateReviews',
        kind: EvidenceKind.strength,
        descriptionEn:
            'No governed $planetEn gemstone-candidate record exists in Kundli snapshot ${snapshot.id} (${snapshot.analysisSchemaVersion}, ${_shortHash(snapshot.analysisHash)}).',
        descriptionBn:
            'Kundli snapshot ${snapshot.id} (${snapshot.analysisSchemaVersion}, ${_shortHash(snapshot.analysisHash)})-এ governed $planetBn gemstone-candidate record নেই।',
      );
      return ChartFinding(
        code: 'numerology.vedic_crosscheck.${core.code}.$planet.unavailable',
        area: _areaFor(core.code),
        polarity: AnalysisPolarity.mixed,
        confidence: AnalysisConfidence.low,
        titleEn:
            '${core.labelEn} ${core.value} ↔ $planetEn — Vedic review unavailable',
        titleBn:
            '${core.labelBn} ${core.value} ↔ $planetBn — বৈদিক review unavailable',
        narrativeEn:
            'The number-planet correspondence is not treated as independent Vedic evidence. No confidence uplift or remedy inference is permitted without a governed Vedic record.',
        narrativeBn:
            'number-planet correspondence-কে স্বাধীন বৈদিক evidence ধরা হয় না। Governed Vedic record ছাড়া confidence বৃদ্ধি বা remedy inference অনুমোদিত নয়।',
        evidence: [mappingEvidence, vedicEvidence],
      );
    }

    final status = review['status']?.toString() ?? 'insufficientEvidence';
    final functionalScore = review['functionalScore'];
    final dashaRole = review['activeDashaRole']?.toString() ?? 'unavailable';
    final rationaleEn = review['rationaleEn']?.toString().trim() ?? '';
    final rationaleBn = review['rationaleBn']?.toString().trim() ?? '';
    final vedicEvidence = ChartEvidence(
      ruleId: '$ruleVersion.vedic_gemstone_context.$planet',
      outputPath: r'$.gemstoneCandidateReviews[?(@.planet=="' + planet + r'")]',
      kind: EvidenceKind.strength,
      descriptionEn:
          'Kundli snapshot ${snapshot.id} (${snapshot.analysisSchemaVersion}, ${_shortHash(snapshot.analysisHash)}) has $planetEn strengthening-screen status=$status, functionalScore=$functionalScore, activeDashaRole=$dashaRole.',
      descriptionBn:
          'Kundli snapshot ${snapshot.id} (${snapshot.analysisSchemaVersion}, ${_shortHash(snapshot.analysisHash)})-এ $planetBn strengthening-screen status=$status, functionalScore=$functionalScore, activeDashaRole=$dashaRole।',
    );

    return ChartFinding(
      code: 'numerology.vedic_crosscheck.${core.code}.$planet.$status',
      area: _areaFor(core.code),
      polarity: AnalysisPolarity.mixed,
      confidence: AnalysisConfidence.low,
      titleEn:
          '${core.labelEn} ${core.value} ↔ $planetEn — Vedic context: $status',
      titleBn:
          '${core.labelBn} ${core.value} ↔ $planetBn — বৈদিক context: $status',
      narrativeEn:
          'This is a cautionary cross-system comparison only; it does not validate the Numerology interpretation or raise prediction confidence. The Vedic record is a strengthening-gemstone screen, not an overall verdict on $planetEn.${rationaleEn.isEmpty ? '' : ' Vedic rationale: $rationaleEn'}',
      narrativeBn:
          'এটি শুধু সতর্কতামূলক cross-system comparison; এটি সংখ্যাতত্ত্বের ব্যাখ্যাকে validate করে না বা prediction confidence বাড়ায় না। বৈদিক recordটি strengthening-gemstone screen, $planetBn-এর সামগ্রিক রায় নয়।${rationaleBn.isEmpty ? '' : ' বৈদিক rationale: $rationaleBn'}',
      evidence: [mappingEvidence, vedicEvidence],
    );
  }

  static Map<String, Object?>? _gemstoneReview(
    Map<String, Object?> analysis,
    String planet,
  ) {
    final raw = analysis['gemstoneCandidateReviews'];
    if (raw is! List) return null;
    for (final item in raw) {
      if (item is Map && item['planet']?.toString() == planet) {
        return Map<String, Object?>.from(item);
      }
    }
    return null;
  }

  static LifeArea _areaFor(String code) => switch (code) {
        'driver' => LifeArea.self,
        'life_path' => LifeArea.overall,
        _ => LifeArea.communication,
      };

  static int _root(int value) {
    var current = value;
    while (current > 9) {
      current = current
          .toString()
          .codeUnits
          .fold(0, (sum, digit) => sum + digit - 48);
    }
    return current;
  }

  static String _shortHash(String value) =>
      value.length <= 12 ? value : '${value.substring(0, 12)}…';

  static const _planetByRoot = <int, String>{
    1: 'sun',
    2: 'moon',
    3: 'jupiter',
    4: 'rahu',
    5: 'mercury',
    6: 'venus',
    7: 'ketu',
    8: 'saturn',
    9: 'mars',
  };

  static const _planetEn = <String, String>{
    'sun': 'Sun',
    'moon': 'Moon',
    'mars': 'Mars',
    'mercury': 'Mercury',
    'jupiter': 'Jupiter',
    'venus': 'Venus',
    'saturn': 'Saturn',
    'rahu': 'Rahu',
    'ketu': 'Ketu',
  };

  static const _planetBn = <String, String>{
    'sun': 'সূর্য',
    'moon': 'চন্দ্র',
    'mars': 'মঙ্গল',
    'mercury': 'বুধ',
    'jupiter': 'বৃহস্পতি',
    'venus': 'শুক্র',
    'saturn': 'শনি',
    'rahu': 'রাহু',
    'ketu': 'কেতু',
  };
}

class _CoreNumber {
  const _CoreNumber({
    required this.code,
    required this.labelEn,
    required this.labelBn,
    required this.outputPath,
    required this.value,
  });

  final String code;
  final String labelEn;
  final String labelBn;
  final String outputPath;
  final int value;
}
