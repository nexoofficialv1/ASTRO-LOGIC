import '../models/calculation_output_snapshot.dart';
import '../models/kundli_analysis.dart';
import '../models/vedic_timing_synthesis.dart';
import '../models/vedic_transit_analysis.dart';

/// Conservative Dasha × transit comparison using already-enabled rule families.
///
/// This engine does not add a new event-prediction rule. It identifies the
/// active Vimshottari MD/AD/PD chain, reproduces the governed 3:2:1 Dasha
/// weighting and compares that polarity with the selected-date transit output.
class VedicTimingSynthesisEngine {
  const VedicTimingSynthesisEngine();

  String get engineId => 'astro-logic-vedic-timing-synthesis';

  String get engineVersion => '1.1.0';

  String get schemaVersion => 'vedic-timing-synthesis-v1';

  VedicTimingSynthesis synthesize({
    required CalculationOutputSnapshot natalOutput,
    required KundliAnalysis kundliAnalysis,
    required VedicTransitAnalysis transitAnalysis,
    required DateTime asOfUtc,
  }) {
    _validateInputs(
      natalOutput: natalOutput,
      kundliAnalysis: kundliAnalysis,
      transitAnalysis: transitAnalysis,
      asOfUtc: asOfUtc,
    );

    final active = _activeDasha(
      natalOutput.output['vimshottari'],
      kundliAnalysis.dashaActivationProfiles,
      asOfUtc,
    );
    final transitPolarity = _aggregateTransit(transitAnalysis.findings);
    final comparison = _compare(active.polarity, transitPolarity);
    final supportiveTransitCount = transitAnalysis.findings
        .where((finding) => finding.polarity == AnalysisPolarity.supportive)
        .length;
    final challengingTransitCount = transitAnalysis.findings
        .where((finding) => finding.polarity == AnalysisPolarity.challenging)
        .length;
    final transitSummaryEn = supportiveTransitCount > 0 ||
            challengingTransitCount > 0
        ? 'Enabled transit findings include $supportiveTransitCount supportive and $challengingTransitCount challenging signal(s); Mixed signals remain review-only.'
        : 'The enabled transit profile provides no directional confirmation on this date.';
    final transitSummaryBn = supportiveTransitCount > 0 ||
            challengingTransitCount > 0
        ? 'সক্রিয় গোচর-ফলে $supportiveTransitCountটি সহায়ক এবং $challengingTransitCountটি চ্যালেঞ্জিং signal আছে; Mixed signal শুধু review-এর জন্য রাখা হয়েছে।'
        : 'এই তারিখে সক্রিয় গোচর profile কোনো directional confirmation দেয়নি।';
    final dashaChainEn =
        '${_planetEn(active.mahadashaLord)} Mahadasha / ${_planetEn(active.antardashaLord)} Antardasha / ${_planetEn(active.pratyantardashaLord)} Pratyantardasha';
    final dashaChainBn =
        '${_planetBn(active.mahadashaLord)} মহাদশা / ${_planetBn(active.antardashaLord)} অন্তর্দশা / ${_planetBn(active.pratyantardashaLord)} প্রত্যন্তরদশা';
    final contradictionEn = active.contradictorySignals
        ? ' The three Dasha levels contain opposite directional lord signals, so their Dasha result is already Mixed.'
        : '';
    final contradictionBn = active.contradictorySignals
        ? ' তিনটি দশা-স্তরে বিপরীতমুখী দশাপতি signal থাকায় দশার ফল আগেই Mixed রাখা হয়েছে।'
        : '';
    final areasEn = active.reinforcedLifeAreas.isEmpty
        ? 'No repeated life area is established across two or more active Dasha levels.'
        : 'Repeated active Dasha areas: ${active.reinforcedLifeAreas.map((value) => value.name).join(', ')}.';
    final areasBn = active.reinforcedLifeAreas.isEmpty
        ? 'সক্রিয় দশার অন্তত দুই স্তরে পুনরাবৃত্ত কোনো life area প্রতিষ্ঠিত হয়নি।'
        : 'সক্রিয় দশায় পুনরাবৃত্ত life area: ${active.reinforcedLifeAreas.map((value) => value.name).join(', ')}।';

    return VedicTimingSynthesis(
      asOfUtc: asOfUtc,
      engineId: engineId,
      engineVersion: engineVersion,
      schemaVersion: schemaVersion,
      activeDasha: active,
      transitPolarity: transitPolarity,
      polarity: comparison.polarity,
      confidence: comparison.confidence,
      confirmationCode: comparison.code,
      titleEn: comparison.titleEn,
      titleBn: comparison.titleBn,
      narrativeEn:
          '$dashaChainEn has a 3:2:1 weighted Dasha score of ${active.weightedScore} and is ${active.polarity.name}.$contradictionEn $transitSummaryEn ${comparison.explanationEn} $areasEn This is a timing-confirmation layer only, not a promise that a specific event will occur.',
      narrativeBn:
          '$dashaChainBn-এর ৩:২:১ weighted Dasha score ${active.weightedScore} এবং ফল ${active.polarity.name}।$contradictionBn $transitSummaryBn ${comparison.explanationBn} $areasBn এটি শুধু timing-confirmation layer; কোনো নির্দিষ্ট ঘটনা ঘটবেই—এমন ঘোষণা নয়।',
      transitFindingCodes:
          transitAnalysis.findings.map((value) => value.code).toList(),
      evidence: [
        ChartEvidence(
          ruleId: 'vedic.timing.dasha_transit.active_chain.v1',
          outputPath: r'$.vimshottari.mahadashas[*].antardashas[*].pratyantardashas[*]',
          kind: EvidenceKind.dasha,
          descriptionEn:
              '$dashaChainEn is active at ${asOfUtc.toIso8601String()} with a governed 3:2:1 weighted score of ${active.weightedScore}.',
          descriptionBn:
              '${asOfUtc.toIso8601String()} সময়ে $dashaChainBn সক্রিয়; governed ৩:২:১ weighted score ${active.weightedScore}।',
        ),
        for (final finding in transitAnalysis.findings) ...finding.evidence,
      ],
      warningsEn: const [
        'Dasha and transit are compared as distinct traditional timing layers; agreement raises review confidence but does not prove an event.',
        'The transit side uses explicitly directional findings from the governed Moon-gochara profiles; v3 includes source-bounded Rahu direction, while Ketu and Mixed/Sade-Sati findings remain non-directional.',
        'Question-specific house triggers, divisional timing, broader exact-degree triggers and Ketu transit direction remain outside this synthesis.',
        'Do not use this output alone for medical, legal, financial, mortality or other high-stakes decisions.',
      ],
      warningsBn: const [
        'দশা ও গোচরকে আলাদা প্রথাগত timing layer হিসেবে তুলনা করা হয়; মিল পাওয়া review confidence বাড়ায়, কিন্তু কোনো ঘটনা প্রমাণ করে না।',
        'গোচর অংশে governed Moon-gochara profile-এর explicitly directional finding ব্যবহার হয়; v3-এ source-bounded Rahu direction অন্তর্ভুক্ত, কিন্তু Ketu এবং Mixed/সাড়ে সাতি finding non-directional থাকে।',
        'Question-specific house trigger, অষ্টকবর্গ, divisional timing, exact-degree trigger এবং Ketu transit direction এখনো এই synthesis-এর বাইরে।',
        'চিকিৎসা, আইন, অর্থ, মৃত্যু বা অন্য high-stakes সিদ্ধান্তে শুধু এই output ব্যবহার করা যাবে না।',
      ],
      professionalReviewRequired: true,
    );
  }

  void _validateInputs({
    required CalculationOutputSnapshot natalOutput,
    required KundliAnalysis kundliAnalysis,
    required VedicTransitAnalysis transitAnalysis,
    required DateTime asOfUtc,
  }) {
    if (!asOfUtc.isUtc) {
      throw ArgumentError.value(
        asOfUtc,
        'asOfUtc',
        'Timing synthesis date-time must be explicitly UTC',
      );
    }
    if (!natalOutput.outputSchemaVersion.startsWith('vedic-chart-v')) {
      throw ArgumentError.value(
        natalOutput.outputSchemaVersion,
        'natalOutput.outputSchemaVersion',
        'Timing synthesis requires a Vedic natal output',
      );
    }
    if (natalOutput.output['vimshottari'] == null) {
      throw StateError('Timing synthesis requires Vimshottari output');
    }
    if (kundliAnalysis.dashaActivationProfiles.length != 9) {
      throw StateError('Timing synthesis requires nine Dasha activation profiles');
    }
    if (!transitAnalysis.asOfUtc.isUtc ||
        transitAnalysis.asOfUtc != asOfUtc) {
      throw ArgumentError(
        'Transit analysis date must be UTC and exactly match the timing synthesis date',
      );
    }
    if (!transitAnalysis.schemaVersion.startsWith('vedic-transit-analysis-v')) {
      throw ArgumentError.value(
        transitAnalysis.schemaVersion,
        'transitAnalysis.schemaVersion',
      );
    }
  }

  VedicActiveDashaChain _activeDasha(
    Object? rawVimshottari,
    List<DashaActivationProfile> profiles,
    DateTime asOfUtc,
  ) {
    final vimshottari = _requiredMap(rawVimshottari, 'vimshottari');
    if (vimshottari['ruleVersion'] != 'vimshottari-calendar-v2') {
      throw StateError(
        'Dasha × transit synthesis requires Pratyantardasha calendar v2',
      );
    }
    final profileByLord = <String, DashaActivationProfile>{
      for (final profile in profiles) profile.lord: profile,
    };
    if (profileByLord.length != 9) {
      throw StateError('Dasha activation profiles must contain nine unique lords');
    }

    final mahadashas = vimshottari['mahadashas'];
    if (mahadashas is! List || mahadashas.length != 9) {
      throw StateError('Vimshottari output requires nine Mahadashas');
    }
    for (final rawMaha in mahadashas) {
      final maha = _requiredMap(rawMaha, 'mahadasha');
      final mahaStart = _requiredUtc(maha['startUtc'], 'mahadasha.startUtc');
      final mahaEnd = _requiredUtc(maha['endUtc'], 'mahadasha.endUtc');
      if (!_contains(mahaStart, mahaEnd, asOfUtc)) continue;
      final mahaLord = _requiredLord(maha['lord'], 'mahadasha.lord');
      final antardashas = maha['antardashas'];
      if (antardashas is! List || antardashas.length != 9) {
        throw StateError('Active Mahadasha requires nine Antardashas');
      }
      for (final rawAntar in antardashas) {
        final antar = _requiredMap(rawAntar, 'antardasha');
        final antarStart =
            _requiredUtc(antar['startUtc'], 'antardasha.startUtc');
        final antarEnd = _requiredUtc(antar['endUtc'], 'antardasha.endUtc');
        if (!_contains(antarStart, antarEnd, asOfUtc)) continue;
        final recordedMahaLord = _requiredLord(
          antar['mahadashaLord'],
          'antardasha.mahadashaLord',
        );
        final antarLord =
            _requiredLord(antar['antardashaLord'], 'antardasha.lord');
        if (recordedMahaLord != mahaLord || !antarEnd.isAfter(antarStart)) {
          throw StateError('Active Antardasha parent/boundary is inconsistent');
        }
        final pratyantardashas = antar['pratyantardashas'];
        if (pratyantardashas is! List || pratyantardashas.length != 9) {
          throw StateError('Active Antardasha requires nine Pratyantardashas');
        }
        for (final rawPratyantar in pratyantardashas) {
          final pratyantar = _requiredMap(rawPratyantar, 'pratyantardasha');
          final start =
              _requiredUtc(pratyantar['startUtc'], 'pratyantardasha.startUtc');
          final end =
              _requiredUtc(pratyantar['endUtc'], 'pratyantardasha.endUtc');
          if (!_contains(start, end, asOfUtc)) continue;
          final recordedPratyantarMaha = _requiredLord(
            pratyantar['mahadashaLord'],
            'pratyantardasha.mahadashaLord',
          );
          final recordedPratyantarAntar = _requiredLord(
            pratyantar['antardashaLord'],
            'pratyantardasha.antardashaLord',
          );
          final pratyantarLord = _requiredLord(
            pratyantar['pratyantardashaLord'],
            'pratyantardasha.lord',
          );
          if (recordedPratyantarMaha != mahaLord ||
              recordedPratyantarAntar != antarLord ||
              !end.isAfter(start)) {
            throw StateError(
              'Active Pratyantardasha parent/boundary is inconsistent',
            );
          }
          final mahaProfile = profileByLord[mahaLord];
          final antarProfile = profileByLord[antarLord];
          final pratyantarProfile = profileByLord[pratyantarLord];
          if (mahaProfile == null ||
              antarProfile == null ||
              pratyantarProfile == null) {
            throw StateError('Active Dasha lord activation profile is missing');
          }
          final scores = [
            mahaProfile.score,
            antarProfile.score,
            pratyantarProfile.score,
          ];
          final signs = scores
              .where((score) => score != 0)
              .map((score) => score.sign)
              .toSet();
          final weightedScore = (mahaProfile.score * 3) +
              (antarProfile.score * 2) +
              pratyantarProfile.score;
          final contradictory = signs.length > 1;
          final polarity = contradictory
              ? AnalysisPolarity.mixed
              : _weightedPolarity(weightedScore);
          return VedicActiveDashaChain(
            mahadashaLord: mahaLord,
            antardashaLord: antarLord,
            pratyantardashaLord: pratyantarLord,
            startUtc: start,
            endUtc: end,
            weightedScore: weightedScore,
            polarity: polarity,
            contradictorySignals: contradictory,
            reinforcedLifeAreas: _reinforcedLifeAreas(
              [
                mahaProfile.lifeAreas,
                antarProfile.lifeAreas,
                pratyantarProfile.lifeAreas,
              ],
              pratyantarProfile.lifeAreas,
            ),
          );
        }
      }
    }
    throw StateError('No active Vimshottari Pratyantardasha at selected date');
  }

  AnalysisPolarity _aggregateTransit(List<VedicTransitFinding> findings) {
    if (findings.isEmpty) return AnalysisPolarity.mixed;
    final directional = findings
        .map((finding) => finding.polarity)
        .where((polarity) => polarity != AnalysisPolarity.mixed)
        .toSet();
    if (directional.length != 1) return AnalysisPolarity.mixed;
    return directional.single;
  }

  _TimingComparison _compare(
    AnalysisPolarity dasha,
    AnalysisPolarity transit,
  ) {
    if (dasha == AnalysisPolarity.supportive &&
        transit == AnalysisPolarity.supportive) {
      return const _TimingComparison(
        code: 'supportive_convergence',
        polarity: AnalysisPolarity.supportive,
        confidence: AnalysisConfidence.medium,
        titleEn: 'Dasha × transit supportive convergence',
        titleBn: 'দশা × গোচর সহায়ক মিল',
        explanationEn:
            'The active Dasha direction and the enabled transit direction agree supportively, so the date receives a medium-confidence confirmation signal.',
        explanationBn:
            'সক্রিয় দশা ও enabled গোচরের দিক সহায়কভাবে মিলে যাওয়ায় এই তারিখ medium-confidence confirmation signal পায়।',
      );
    }
    if (dasha == AnalysisPolarity.challenging &&
        transit == AnalysisPolarity.challenging) {
      return const _TimingComparison(
        code: 'challenging_convergence',
        polarity: AnalysisPolarity.challenging,
        confidence: AnalysisConfidence.medium,
        titleEn: 'Dasha × transit challenging convergence',
        titleBn: 'দশা × গোচর চ্যালেঞ্জিং মিল',
        explanationEn:
            'The active Dasha direction and an explicitly enabled challenging transit direction agree. This raises review priority but still does not establish a specific adverse event.',
        explanationBn:
            'সক্রিয় দশার দিক এবং explicitly enabled challenging গোচর একই দিকে রয়েছে। এতে review priority বাড়ে, কিন্তু কোনো নির্দিষ্ট adverse event প্রতিষ্ঠিত হয় না।',
      );
    }
    if (dasha != AnalysisPolarity.mixed &&
        transit != AnalysisPolarity.mixed &&
        dasha != transit) {
      return const _TimingComparison(
        code: 'directional_conflict',
        polarity: AnalysisPolarity.mixed,
        confidence: AnalysisConfidence.medium,
        titleEn: 'Dasha × transit directional conflict',
        titleBn: 'দশা × গোচর দিকগত বিরোধ',
        explanationEn:
            'Dasha and transit point in opposite directions, so the combined result is kept Mixed rather than forcing a prediction.',
        explanationBn:
            'দশা ও গোচর বিপরীত দিকে ইঙ্গিত করায় prediction চাপিয়ে না দিয়ে combined result Mixed রাখা হয়েছে।',
      );
    }
    return const _TimingComparison(
      code: 'insufficient_directional_confirmation',
      polarity: AnalysisPolarity.mixed,
      confidence: AnalysisConfidence.low,
      titleEn: 'Dasha × transit confirmation incomplete',
      titleBn: 'দশা × গোচর confirmation অসম্পূর্ণ',
      explanationEn:
          'At least one layer is Mixed or non-directional, so this date does not receive directional confirmation from the enabled rule set.',
      explanationBn:
          'অন্তত একটি layer Mixed বা non-directional হওয়ায় enabled rule set থেকে এই তারিখ directional confirmation পায়নি।',
    );
  }

  AnalysisPolarity _weightedPolarity(int score) => score >= 6
      ? AnalysisPolarity.supportive
      : score <= -6
          ? AnalysisPolarity.challenging
          : AnalysisPolarity.mixed;

  List<LifeArea> _reinforcedLifeAreas(
    List<List<LifeArea>> levels,
    List<LifeArea> fallback,
  ) {
    final counts = <LifeArea, int>{};
    for (final level in levels) {
      for (final area in level.toSet()) {
        counts[area] = (counts[area] ?? 0) + 1;
      }
    }
    final reinforced = counts.entries
        .where((entry) => entry.value >= 2)
        .map((entry) => entry.key)
        .toList(growable: false);
    return reinforced.isEmpty ? List.unmodifiable(fallback) : reinforced;
  }

  Map<String, Object?> _requiredMap(Object? value, String path) {
    if (value is! Map) throw StateError('Missing or invalid $path');
    return Map<String, Object?>.from(value);
  }

  DateTime _requiredUtc(Object? value, String path) {
    if (value is! String || !value.endsWith('Z')) {
      throw StateError('Missing or invalid $path');
    }
    final parsed = DateTime.tryParse(value);
    if (parsed == null || !parsed.isUtc) {
      throw StateError('Missing or invalid $path');
    }
    return parsed;
  }

  String _requiredLord(Object? value, String path) {
    if (value is! String || !_lords.contains(value)) {
      throw StateError('Missing or invalid $path');
    }
    return value;
  }

  bool _contains(DateTime start, DateTime end, DateTime instant) =>
      !instant.isBefore(start) && instant.isBefore(end);

  String _planetEn(String lord) => _planetNamesEn[lord] ?? lord;

  String _planetBn(String lord) => _planetNamesBn[lord] ?? lord;

  static const _lords = <String>{
    'ketu',
    'venus',
    'sun',
    'moon',
    'mars',
    'rahu',
    'jupiter',
    'saturn',
    'mercury',
  };

  static const _planetNamesEn = <String, String>{
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

  static const _planetNamesBn = <String, String>{
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

class _TimingComparison {
  const _TimingComparison({
    required this.code,
    required this.polarity,
    required this.confidence,
    required this.titleEn,
    required this.titleBn,
    required this.explanationEn,
    required this.explanationBn,
  });

  final String code;
  final AnalysisPolarity polarity;
  final AnalysisConfidence confidence;
  final String titleEn;
  final String titleBn;
  final String explanationEn;
  final String explanationBn;
}
