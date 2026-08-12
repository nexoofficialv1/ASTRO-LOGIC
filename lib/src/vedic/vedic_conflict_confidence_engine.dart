import '../models/calculation_output_snapshot.dart';
import '../models/kundli_analysis.dart';
import '../models/vedic_conflict_confidence.dart';
import '../models/vedic_question_timing.dart';

/// Topic-specific multi-family conflict resolver.
///
/// v2 keeps five visible layers and up to four governed evidence groups:
/// - structural: D1 target-house baseline + D1/D9 dignity agreement of the
///   relevant target-house lords;
/// - Dasha: active topic-weighted MD/AD/PD signal;
/// - transit: enabled topical directional Moon-gochara transit;
/// - Ashtakavarga transit: unreduced planet-specific BAV plus SAV context.
///
/// D1 and D1/D9 are intentionally not counted as independent confirmations.
/// Multiple Ashtakavarga planets/checks also collapse to one evidence group.
/// Any explicit directional conflict is preserved as Mixed. Because both
/// transit families share selected-date positional evidence, High confidence
/// remains disabled in v2 even when all four groups agree.
class VedicConflictConfidenceEngine {
  const VedicConflictConfidenceEngine();

  String get engineId => 'astro-logic-vedic-conflict-confidence';

  String get engineVersion => '2.1.0';

  String get schemaVersion => 'vedic-conflict-confidence-v2';

  VedicConflictConfidence resolve({
    required CalculationOutputSnapshot natalOutput,
    required KundliAnalysis kundliAnalysis,
    required VedicQuestionTiming questionTiming,
  }) {
    _validateInputs(
      natalOutput: natalOutput,
      kundliAnalysis: kundliAnalysis,
      questionTiming: questionTiming,
    );

    final ascendant = _requiredMap(
      natalOutput.output['ascendant'],
      'ascendant',
    );
    final ascendantSign = _requiredSignIndex(
      ascendant['signIndex'],
      'ascendant.signIndex',
    );
    final targetHouseLords = questionTiming.targetHouses
        .map((house) => _signLords[(ascendantSign + house - 1) % 12]!)
        .toSet()
        .toList(growable: false);

    final natalFindings = _targetNatalFindings(
      kundliAnalysis.findings,
      questionTiming.targetHouses,
    );
    final divisionalFindings = _targetDivisionalFindings(
      kundliAnalysis.findings,
      targetHouseLords,
    );

    final natalPolarity = _aggregatePolarities(
      natalFindings.map((finding) => finding.polarity),
    );
    if (natalPolarity != questionTiming.natalPolarity) {
      throw StateError(
        'Question timing natal polarity does not match the immutable Kundli findings',
      );
    }
    final divisionalPolarity = _aggregatePolarities(
      divisionalFindings.map((finding) => finding.polarity),
    );

    final dashaAvailable = questionTiming.confirmationCode !=
        'insufficient_dasha_topic_activation';
    final transitAvailable = questionTiming.targetedTransitPlanets.isNotEmpty;
    final hasAshtakavargaSchema =
        questionTiming.schemaVersion == 'vedic-question-timing-v2' ||
            questionTiming.schemaVersion == 'vedic-question-timing-v3';
    final ashtakavargaAvailable = hasAshtakavargaSchema &&
        questionTiming.ashtakavargaTransitChecks.isNotEmpty;
    final ashtakavargaDirectional = hasAshtakavargaSchema &&
        questionTiming.hasDirectionalAshtakavarga;
    final ashtakavargaInternalConflict = ashtakavargaDirectional &&
        questionTiming.ashtakavargaPolarity == AnalysisPolarity.mixed;

    final layers = <VedicLayerVerdict>[
      VedicLayerVerdict(
        layer: VedicEvidenceLayer.natalD1,
        independenceGroup: 'structure',
        available: true,
        polarity: natalPolarity,
        sourceCodes: natalFindings.map((finding) => finding.code).toList(),
        summaryEn:
            'The governed D1 target-house baseline is ${natalPolarity.name} across houses ${questionTiming.targetHouses.join(', ')}.',
        summaryBn:
            'নির্ধারিত D1 target-house baseline ${questionTiming.targetHouses.join(', ')} নম্বর ভাব জুড়ে ${natalPolarity.name}।',
        evidence: [for (final finding in natalFindings) ...finding.evidence],
      ),
      VedicLayerVerdict(
        layer: VedicEvidenceLayer.divisionalD1D9,
        independenceGroup: 'structure',
        available: divisionalFindings.length == targetHouseLords.length,
        polarity: divisionalPolarity,
        sourceCodes:
            divisionalFindings.map((finding) => finding.code).toList(),
        summaryEn:
            'D1-D9 dignity agreement for the target-house lords ${targetHouseLords.join(', ')} is ${divisionalPolarity.name}. It is a structural cross-check, not an independent timing family.',
        summaryBn:
            'Target-house lord ${targetHouseLords.join(', ')}-এর D1-D9 মর্যাদা-মিল ${divisionalPolarity.name}। এটি structural cross-check, স্বতন্ত্র timing family নয়।',
        evidence: [
          for (final finding in divisionalFindings) ...finding.evidence,
        ],
      ),
      VedicLayerVerdict(
        layer: VedicEvidenceLayer.dasha,
        independenceGroup: 'dasha',
        available: dashaAvailable,
        polarity: questionTiming.dashaPolarity,
        sourceCodes: ['question_timing.${questionTiming.confirmationCode}'],
        summaryEn: dashaAvailable
            ? 'The active topic-weighted MD/AD/PD layer is ${questionTiming.dashaPolarity.name} with score ${questionTiming.dashaTopicScore}.'
            : 'The active MD/AD/PD chain has insufficient governed activation for this topic.',
        summaryBn: dashaAvailable
            ? 'সক্রিয় topic-weighted MD/AD/PD layer ${questionTiming.dashaPolarity.name}; score ${questionTiming.dashaTopicScore}।'
            : 'সক্রিয় MD/AD/PD chain-এ এই topic-এর governed activation অপর্যাপ্ত।',
        evidence: questionTiming.evidence
            .where((evidence) => evidence.kind == EvidenceKind.dasha)
            .toList(growable: false),
      ),
      VedicLayerVerdict(
        layer: VedicEvidenceLayer.transit,
        independenceGroup: 'transit',
        available: transitAvailable,
        polarity: questionTiming.transitPolarity,
        sourceCodes: questionTiming.targetedTransitPlanets
            .map((planet) => 'topical_transit.$planet')
            .toList(growable: false),
        summaryEn: transitAvailable
            ? 'The enabled topical transit layer is ${questionTiming.transitPolarity.name} through ${questionTiming.targetedTransitPlanets.join(', ')}.'
            : 'No enabled directional transit occupies a governed target house for this topic.',
        summaryBn: transitAvailable
            ? 'Enabled topical transit layer ${questionTiming.transitPolarity.name}; ${questionTiming.targetedTransitPlanets.join(', ')} এর মাধ্যমে।'
            : 'এই topic-এর governed target house-এ কোনো enabled directional transit নেই।',
        evidence: questionTiming.evidence
            .where((evidence) => evidence.kind == EvidenceKind.transit)
            .toList(growable: false),
      ),
      VedicLayerVerdict(
        layer: VedicEvidenceLayer.ashtakavargaTransit,
        independenceGroup: 'ashtakavarga',
        available: ashtakavargaAvailable,
        polarity: questionTiming.ashtakavargaPolarity,
        sourceCodes: questionTiming.ashtakavargaTransitChecks
            .map((check) =>
                'ashtakavarga_transit.${check.planet}.house_${check.houseFromAscendant}')
            .toList(growable: false),
        summaryEn: ashtakavargaAvailable
            ? 'The governed Ashtakavarga transit family is ${questionTiming.ashtakavargaPolarity.name} across ${questionTiming.ashtakavargaTransitChecks.length} target-house check(s); all checks count as one evidence group.'
            : 'No governed Ashtakavarga target-house transit check is available for this topic.',
        summaryBn: ashtakavargaAvailable
            ? 'Governed Ashtakavarga transit family ${questionTiming.ashtakavargaPolarity.name}; ${questionTiming.ashtakavargaTransitChecks.length}টি target-house check একসঙ্গে একটি evidence group হিসেবে গণনা হয়েছে।'
            : 'এই topic-এর জন্য কোনো governed Ashtakavarga target-house transit check available নয়।',
        evidence: [
          for (final check in questionTiming.ashtakavargaTransitChecks)
            ...check.evidence,
        ],
      ),
    ];

    final structural = _structuralVerdict(
      natal: natalPolarity,
      divisional: divisionalPolarity,
      divisionalAvailable: divisionalFindings.length == targetHouseLords.length,
    );
    final groupSignals = <String, AnalysisPolarity>{};
    if (structural.polarity != AnalysisPolarity.mixed) {
      groupSignals['structure'] = structural.polarity;
    }
    if (dashaAvailable &&
        questionTiming.dashaPolarity != AnalysisPolarity.mixed) {
      groupSignals['dasha'] = questionTiming.dashaPolarity;
    }
    if (transitAvailable &&
        questionTiming.transitPolarity != AnalysisPolarity.mixed) {
      groupSignals['transit'] = questionTiming.transitPolarity;
    }
    if (ashtakavargaDirectional &&
        questionTiming.ashtakavargaPolarity != AnalysisPolarity.mixed) {
      groupSignals['ashtakavarga'] = questionTiming.ashtakavargaPolarity;
    }

    final directionalSet = groupSignals.values.toSet();
    final crossGroupConflict = directionalSet.length > 1;
    final conflictDetected = structural.conflict ||
        ashtakavargaInternalConflict ||
        crossGroupConflict;
    final resolution = _resolve(
      groupSignals: groupSignals,
      structuralConflict: structural.conflict,
      ashtakavargaInternalConflict: ashtakavargaInternalConflict,
      crossGroupConflict: crossGroupConflict,
    );
    final agreeingGroups = resolution.polarity == AnalysisPolarity.mixed
        ? 0
        : groupSignals.values
            .where((value) => value == resolution.polarity)
            .length;

    final evidence = <ChartEvidence>[
      for (final layer in layers) ...layer.evidence,
    ];
    final layerSummaryEn = layers
        .map((layer) => '${layer.layer.name}=${layer.available ? layer.polarity.name : 'unavailable'}')
        .join(', ');
    final layerSummaryBn = layers
        .map((layer) => '${layer.layer.name}=${layer.available ? layer.polarity.name : 'unavailable'}')
        .join(', ');

    return VedicConflictConfidence(
      asOfUtc: questionTiming.asOfUtc,
      engineId: engineId,
      engineVersion: engineVersion,
      schemaVersion: schemaVersion,
      topic: questionTiming.topic,
      targetHouses: List.unmodifiable(questionTiming.targetHouses),
      targetHouseLords: List.unmodifiable(targetHouseLords),
      layers: List.unmodifiable(layers),
      structuralPolarity: structural.polarity,
      polarity: resolution.polarity,
      confidence: resolution.confidence,
      resolutionCode: resolution.code,
      directionalIndependentGroups: groupSignals.length,
      agreeingIndependentGroups: agreeingGroups,
      conflictDetected: conflictDetected,
      titleEn: resolution.titleEn,
      titleBn: resolution.titleBn,
      narrativeEn:
          'Conflict review for ${questionTiming.topic.name}: $layerSummaryEn. ${structural.explanationEn} ${resolution.explanationEn} The engine counts D1 and D1-D9 as one structural group and all Ashtakavarga checks as one Ashtakavarga group, so repeated correlated evidence cannot inflate confidence. High confidence is disabled in v2 because Moon-gochara and Ashtakavarga still share selected-date positional evidence.',
      narrativeBn:
          '${questionTiming.topic.name} conflict review: $layerSummaryBn। ${structural.explanationBn} ${resolution.explanationBn} D1 ও D1-D9-কে engine একই structural group এবং সব Ashtakavarga check-কে একটি Ashtakavarga group হিসেবে গণনা করে, তাই repeated correlated evidence দিয়ে confidence অযথা বাড়ে না। Moon-gochara ও Ashtakavarga একই selected-date positional evidence ব্যবহার করায় v2-তেও High confidence disabled।',
      evidence: List.unmodifiable(evidence),
      warningsEn: const [
        'This is a conflict-resolution and confidence-governance layer, not an event-prediction engine.',
        'D1 and D1-D9 dignity agreement share chart evidence and therefore count as one structural evidence group.',
        'All Ashtakavarga transit checks collapse to one group; individual planets do not create extra confidence votes.',
        'Any explicit directional conflict, including internal Ashtakavarga disagreement, is preserved as Mixed; a majority vote does not override contradiction.',
        'High confidence is disabled in v2. Ashtakavarga is now a governed evidence group, but it and Moon-gochara share selected-date transit-position evidence and therefore cannot justify a High rating by themselves.',
        'Do not use this output alone for medical, legal, financial, mortality or other high-stakes decisions.',
      ],
      warningsBn: const [
        'এটি conflict-resolution ও confidence-governance layer; event-prediction engine নয়।',
        'D1 ও D1-D9 dignity agreement একই chart evidence-এর অংশ, তাই এগুলো একটি structural evidence group হিসেবে গণনা হয়।',
        'সব Ashtakavarga transit check একটিমাত্র group হিসেবে গণনা হয়; আলাদা planet extra confidence vote তৈরি করে না।',
        'স্পষ্ট directional conflict, Ashtakavarga-এর internal disagreement-সহ, হলে ফল Mixed থাকে; majority vote দিয়ে contradiction override করা হয় না।',
        'v2-এ Ashtakavarga governed evidence group হিসেবে গণনা হয়, কিন্তু এটি ও Moon-gochara একই selected-date transit-position evidence ব্যবহার করে; তাই শুধু এই মিল দিয়ে High confidence দেওয়া হয় না।',
        'চিকিৎসা, আইন, অর্থ, মৃত্যু বা অন্য high-stakes সিদ্ধান্তে শুধু এই output ব্যবহার করা যাবে না।',
      ],
      professionalReviewRequired: true,
    );
  }

  void _validateInputs({
    required CalculationOutputSnapshot natalOutput,
    required KundliAnalysis kundliAnalysis,
    required VedicQuestionTiming questionTiming,
  }) {
    if (natalOutput.outputSchemaVersion != 'vedic-chart-v2' &&
        natalOutput.outputSchemaVersion != 'vedic-chart-v3' &&
        natalOutput.outputSchemaVersion != 'vedic-chart-v4' &&
        natalOutput.outputSchemaVersion != 'vedic-chart-v5' &&
        natalOutput.outputSchemaVersion != 'vedic-chart-v6' &&
        natalOutput.outputSchemaVersion != 'vedic-chart-v7' &&
        natalOutput.outputSchemaVersion != 'vedic-chart-v8' &&
        natalOutput.outputSchemaVersion != 'vedic-chart-v9' &&
        natalOutput.outputSchemaVersion != 'vedic-chart-v10') {
      throw ArgumentError(
        'Conflict confidence requires a Vedic output with explicit D9 fields',
      );
    }
    if (!questionTiming.asOfUtc.isUtc) {
      throw ArgumentError('Question timing instant must be UTC');
    }
    if (questionTiming.schemaVersion != 'vedic-question-timing-v1' &&
        questionTiming.schemaVersion != 'vedic-question-timing-v2' &&
        questionTiming.schemaVersion != 'vedic-question-timing-v3') {
      throw ArgumentError.value(
        questionTiming.schemaVersion,
        'questionTiming.schemaVersion',
      );
    }
    if (questionTiming.schemaVersion == 'vedic-question-timing-v2' ||
        questionTiming.schemaVersion == 'vedic-question-timing-v3') {
      if (questionTiming.schemaVersion == 'vedic-question-timing-v3') {
        const kakshaLords = <String>[
          'saturn', 'jupiter', 'mars', 'sun',
          'venus', 'mercury', 'moon', 'lagna',
        ];
        for (final check in questionTiming.ashtakavargaTransitChecks) {
          final kaksha = check.kaksha;
          if (kaksha == null ||
              kaksha.ruleVersion != 'ashtakavarga-kaksha-v1' ||
              !kaksha.degreeInSign.isFinite ||
              kaksha.degreeInSign < 0 ||
              kaksha.degreeInSign >= 30) {
            throw StateError('Question timing Kaksha metadata is invalid');
          }
          final expectedZeroBased = (kaksha.degreeInSign / 3.75).floor();
          final expectedNumber = expectedZeroBased + 1;
          final expectedStart = expectedZeroBased * 3.75;
          final expectedEnd = expectedStart + 3.75;
          if (kaksha.kakshaNumber != expectedNumber ||
              kaksha.kakshaLord != kakshaLords[expectedZeroBased] ||
              (kaksha.startDegree - expectedStart).abs() > 1e-9 ||
              (kaksha.endDegree - expectedEnd).abs() > 1e-9) {
            throw StateError('Question timing Kaksha geometry is inconsistent');
          }
          final expectedKakshaPolarity = kaksha.positiveMark
              ? AnalysisPolarity.supportive
              : AnalysisPolarity.challenging;
          if (kaksha.polarity != expectedKakshaPolarity) {
            throw StateError('Question timing Kaksha mark/polarity is inconsistent');
          }
          final wholeSign = check.bavPolarity != AnalysisPolarity.mixed &&
                  check.savPolarity != AnalysisPolarity.mixed &&
                  check.bavPolarity == check.savPolarity
              ? check.bavPolarity
              : AnalysisPolarity.mixed;
          if (check.wholeSignPolarity != wholeSign) {
            throw StateError('Question timing Kaksha whole-sign polarity is inconsistent');
          }
          final expectedFinal = wholeSign != AnalysisPolarity.mixed &&
                  wholeSign == kaksha.polarity
              ? wholeSign
              : AnalysisPolarity.mixed;
          if (check.polarity != expectedFinal) {
            throw StateError('Question timing Kaksha final polarity is inconsistent');
          }
        }
      }
      final directionalChecks = questionTiming.ashtakavargaTransitChecks
          .where((check) => check.polarity != AnalysisPolarity.mixed)
          .toList(growable: false);
      final directionalPlanets = directionalChecks
          .map((check) => check.planet)
          .toList(growable: false);
      final expectedPolarity =
          _aggregatePolarities(directionalChecks.map((check) => check.polarity));
      if (questionTiming.hasDirectionalAshtakavarga !=
          directionalChecks.isNotEmpty) {
        throw StateError(
          'Question timing Ashtakavarga directional flag is inconsistent',
        );
      }
      if (!_sameOrderedStrings(
        questionTiming.ashtakavargaTransitPlanets,
        directionalPlanets,
      )) {
        throw StateError(
          'Question timing Ashtakavarga directional planets are inconsistent',
        );
      }
      if (questionTiming.ashtakavargaPolarity != expectedPolarity) {
        throw StateError(
          'Question timing Ashtakavarga aggregate polarity is inconsistent',
        );
      }
    }
    if (questionTiming.targetHouses.isEmpty ||
        questionTiming.targetHouses.any((house) => house < 1 || house > 12)) {
      throw ArgumentError('Question timing target houses are invalid');
    }
    final expectedHouses = _expectedTopicHouses[questionTiming.topic]!;
    if (!_sameOrderedInts(questionTiming.targetHouses, expectedHouses)) {
      throw ArgumentError(
        'Question timing target houses do not match its versioned topic profile',
      );
    }
    if (!questionTiming.professionalReviewRequired) {
      throw StateError(
        'Conflict confidence requires professionally review-gated timing input',
      );
    }
    if (kundliAnalysis.findings.isEmpty) {
      throw StateError('Conflict confidence requires Kundli findings');
    }
  }

  List<ChartFinding> _targetNatalFindings(
    List<ChartFinding> findings,
    List<int> targetHouses,
  ) {
    final byHouse = <int, ChartFinding>{};
    for (final finding in findings) {
      for (final house in targetHouses) {
        if (finding.code == 'vedic.life_area.house_$house.synthesis') {
          byHouse[house] = finding;
        }
      }
    }
    if (byHouse.length != targetHouses.length) {
      throw StateError('Missing target-house Kundli synthesis for conflict review');
    }
    return [for (final house in targetHouses) byHouse[house]!];
  }

  List<ChartFinding> _targetDivisionalFindings(
    List<ChartFinding> findings,
    List<String> targetHouseLords,
  ) {
    final byLord = <String, ChartFinding>{};
    for (final finding in findings) {
      for (final lord in targetHouseLords) {
        if (finding.code == 'vedic.divisional.d1_d9.$lord') {
          byLord[lord] = finding;
        }
      }
    }
    return [
      for (final lord in targetHouseLords)
        if (byLord[lord] != null) byLord[lord]!,
    ];
  }

  _StructuralVerdict _structuralVerdict({
    required AnalysisPolarity natal,
    required AnalysisPolarity divisional,
    required bool divisionalAvailable,
  }) {
    if (!divisionalAvailable || divisional == AnalysisPolarity.mixed) {
      return const _StructuralVerdict(
        polarity: AnalysisPolarity.mixed,
        conflict: false,
        explanationEn:
            'The structural group is not directional because D1-D9 confirmation is incomplete or Mixed.',
        explanationBn:
            'D1-D9 confirmation অসম্পূর্ণ বা Mixed হওয়ায় structural group directional নয়।',
      );
    }
    if (natal == AnalysisPolarity.mixed) {
      return const _StructuralVerdict(
        polarity: AnalysisPolarity.mixed,
        conflict: false,
        explanationEn:
            'The structural group remains Mixed because the D1 target-house baseline is Mixed.',
        explanationBn:
            'D1 target-house baseline Mixed হওয়ায় structural group Mixed থাকে।',
      );
    }
    if (natal != divisional) {
      return const _StructuralVerdict(
        polarity: AnalysisPolarity.mixed,
        conflict: true,
        explanationEn:
            'D1 target-house direction and D1-D9 target-lord agreement point in opposite directions, so structural conflict is preserved.',
        explanationBn:
            'D1 target-house direction ও D1-D9 target-lord agreement বিপরীত হওয়ায় structural conflict সংরক্ষিত হয়েছে।',
      );
    }
    return _StructuralVerdict(
      polarity: natal,
      conflict: false,
      explanationEn:
          'D1 target-house direction and D1-D9 target-lord agreement reinforce the same ${natal.name} structural direction.',
      explanationBn:
          'D1 target-house direction ও D1-D9 target-lord agreement একই ${natal.name} structural direction সমর্থন করছে।',
    );
  }

  _Resolution _resolve({
    required Map<String, AnalysisPolarity> groupSignals,
    required bool structuralConflict,
    required bool ashtakavargaInternalConflict,
    required bool crossGroupConflict,
  }) {
    if (structuralConflict) {
      return const _Resolution(
        code: 'structural_d1_d9_conflict',
        polarity: AnalysisPolarity.mixed,
        confidence: AnalysisConfidence.low,
        titleEn: 'Structural D1-D9 conflict preserved',
        titleBn: 'D1-D9 structural conflict সংরক্ষিত',
        explanationEn:
            'A structural contradiction cannot be overridden by Dasha/transit agreement, so the final direction remains Mixed.',
        explanationBn:
            'Structural contradiction-কে Dasha/Transit agreement দিয়ে override করা হয় না; final direction Mixed থাকে।',
      );
    }
    if (ashtakavargaInternalConflict) {
      return const _Resolution(
        code: 'ashtakavarga_internal_directional_conflict',
        polarity: AnalysisPolarity.mixed,
        confidence: AnalysisConfidence.low,
        titleEn: 'Ashtakavarga internal conflict preserved',
        titleBn: 'Ashtakavarga internal conflict সংরক্ষিত',
        explanationEn:
            'Directional Ashtakavarga target-house checks disagree internally. The family is one governed group, so its contradiction is preserved instead of being majority-voted away.',
        explanationBn:
            'Directional Ashtakavarga target-house check-গুলোর মধ্যে internal disagreement আছে। Family-টি একটি governed group, তাই majority vote দিয়ে conflict মুছে ফেলা হয় না।',
      );
    }
    if (crossGroupConflict) {
      return const _Resolution(
        code: 'independent_group_directional_conflict',
        polarity: AnalysisPolarity.mixed,
        confidence: AnalysisConfidence.low,
        titleEn: 'Independent evidence groups conflict',
        titleBn: 'স্বতন্ত্র evidence group-এ দিকগত conflict',
        explanationEn:
            'At least two independent groups point in opposite directions. Majority voting is disabled, so the result remains Mixed.',
        explanationBn:
            'অন্তত দুটি independent group বিপরীত দিকে ইঙ্গিত করছে। Majority voting disabled, তাই ফল Mixed।',
      );
    }
    if (groupSignals.isEmpty) {
      return const _Resolution(
        code: 'insufficient_directional_groups',
        polarity: AnalysisPolarity.mixed,
        confidence: AnalysisConfidence.low,
        titleEn: 'Directional evidence insufficient',
        titleBn: 'Directional evidence অপর্যাপ্ত',
        explanationEn:
            'No independent group supplies a directional signal under the enabled rules.',
        explanationBn:
            'Enabled rule অনুযায়ী কোনো independent group directional signal দিচ্ছে না।',
      );
    }
    final direction = groupSignals.values.first;
    if (groupSignals.length >= 3) {
      final fourGroups = groupSignals.length == 4;
      return _Resolution(
        code: fourGroups
            ? 'four_group_governed_convergence'
            : 'three_group_governed_convergence',
        polarity: direction,
        confidence: AnalysisConfidence.medium,
        titleEn:
            '${groupSignals.length}-group ${direction.name} convergence',
        titleBn:
            '${groupSignals.length}-group ${direction.name} convergence',
        explanationEn: fourGroups
            ? 'Structure, topic Dasha, Moon-gochara transit and Ashtakavarga all converge in the same direction. Confidence remains capped at Medium because the two transit families share selected-date positional evidence.'
            : 'Three governed evidence groups converge in the same direction. v2 caps this at Medium confidence; the missing or non-directional fourth family prevents broader coverage.',
        explanationBn: fourGroups
            ? 'Structure, topic Dasha, Moon-gochara transit ও Ashtakavarga একই দিকে converge করেছে। দুই transit family একই selected-date positional evidence ব্যবহার করায় confidence Medium-এই capped থাকে।'
            : 'তিনটি governed evidence group একই দিকে converge করেছে। v2-এ confidence Medium-এ capped; চতুর্থ family unavailable বা non-directional।',
      );
    }
    if (groupSignals.length == 2) {
      return _Resolution(
        code: 'two_group_partial_convergence',
        polarity: direction,
        confidence: AnalysisConfidence.low,
        titleEn: 'Two-group ${direction.name} convergence',
        titleBn: 'দুই-group ${direction.name} convergence',
        explanationEn:
            'Two governed evidence groups agree, but broader independent coverage is missing or non-directional, so confidence remains Low.',
        explanationBn:
            'দুটি governed evidence group একমত, কিন্তু broader independent coverage unavailable বা non-directional; তাই confidence Low।',
      );
    }
    return const _Resolution(
      code: 'single_group_direction_only',
      polarity: AnalysisPolarity.mixed,
      confidence: AnalysisConfidence.low,
      titleEn: 'Single-group direction not enough',
      titleBn: 'একটি group-এর direction যথেষ্ট নয়',
      explanationEn:
          'Only one independent group is directional, so the engine does not publish a combined directional verdict.',
      explanationBn:
          'শুধু একটি independent group directional হওয়ায় engine combined directional verdict প্রকাশ করে না।',
    );
  }

  AnalysisPolarity _aggregatePolarities(Iterable<AnalysisPolarity> values) {
    final directional = values
        .where((value) => value != AnalysisPolarity.mixed)
        .toSet();
    if (directional.length != 1) return AnalysisPolarity.mixed;
    return directional.single;
  }

  Map<String, Object?> _requiredMap(Object? value, String path) {
    if (value is! Map) throw StateError('Missing or invalid $path');
    return Map<String, Object?>.from(value);
  }

  int _requiredSignIndex(Object? value, String path) {
    if (value is! int || value < 0 || value > 11) {
      throw StateError('Invalid $path');
    }
    return value;
  }


  bool _sameOrderedStrings(List<String> left, List<String> right) {
    if (left.length != right.length) return false;
    for (var index = 0; index < left.length; index += 1) {
      if (left[index] != right[index]) return false;
    }
    return true;
  }

  bool _sameOrderedInts(List<int> left, List<int> right) {
    if (left.length != right.length) return false;
    for (var index = 0; index < left.length; index += 1) {
      if (left[index] != right[index]) return false;
    }
    return true;
  }

  static const Map<VedicQuestionTopic, List<int>> _expectedTopicHouses = {
    VedicQuestionTopic.career: [10, 6, 11],
    VedicQuestionTopic.business: [10, 7, 11, 2],
    VedicQuestionTopic.marriage: [7, 2, 11],
    VedicQuestionTopic.finance: [2, 11],
    VedicQuestionTopic.education: [5, 9],
    VedicQuestionTopic.property: [4, 2, 11],
    VedicQuestionTopic.children: [5, 2, 11],
    VedicQuestionTopic.travelRelocation: [12, 4],
  };

  static const Map<int, String> _signLords = {
    0: 'mars',
    1: 'venus',
    2: 'mercury',
    3: 'moon',
    4: 'sun',
    5: 'mercury',
    6: 'venus',
    7: 'mars',
    8: 'jupiter',
    9: 'saturn',
    10: 'saturn',
    11: 'jupiter',
  };
}

class _StructuralVerdict {
  const _StructuralVerdict({
    required this.polarity,
    required this.conflict,
    required this.explanationEn,
    required this.explanationBn,
  });

  final AnalysisPolarity polarity;
  final bool conflict;
  final String explanationEn;
  final String explanationBn;
}

class _Resolution {
  const _Resolution({
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
