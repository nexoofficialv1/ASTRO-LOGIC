import 'package:astro_logic/src/models/calculation_output_snapshot.dart';
import 'package:astro_logic/src/models/kundli_analysis.dart';
import 'package:astro_logic/src/models/vedic_conflict_confidence.dart';
import 'package:astro_logic/src/models/vedic_question_timing.dart';
import 'package:astro_logic/src/vedic/vedic_conflict_confidence_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const engine = VedicConflictConfidenceEngine();
  final asOf = DateTime.utc(2026, 8, 7, 10);

  test('publishes Medium only when structure, Dasha and transit converge', () {
    final result = engine.resolve(
      natalOutput: _natal(),
      kundliAnalysis: _analysis(
        housePolarities: const {
          10: AnalysisPolarity.supportive,
          6: AnalysisPolarity.supportive,
          11: AnalysisPolarity.supportive,
        },
        divisionalPolarities: const {
          'saturn': AnalysisPolarity.supportive,
          'mercury': AnalysisPolarity.supportive,
        },
      ),
      questionTiming: _question(
        asOf,
        natal: AnalysisPolarity.supportive,
        dasha: AnalysisPolarity.supportive,
        transit: AnalysisPolarity.supportive,
        targetedTransitPlanets: const ['jupiter'],
      ),
    );

    expect(result.schemaVersion, 'vedic-conflict-confidence-v2');
    expect(result.targetHouseLords, ['saturn', 'mercury']);
    expect(result.structuralPolarity, AnalysisPolarity.supportive);
    expect(result.polarity, AnalysisPolarity.supportive);
    expect(result.confidence, AnalysisConfidence.medium);
    expect(result.resolutionCode, 'three_group_governed_convergence');
    expect(result.directionalIndependentGroups, 3);
    expect(result.agreeingIndependentGroups, 3);
    expect(result.conflictDetected, isFalse);
    expect(result.layers, hasLength(5));
    expect(
      result.layers
          .where((layer) => layer.independenceGroup == 'structure')
          .length,
      2,
    );
  });

  test('preserves D1 versus D1-D9 structural conflict despite timing agreement', () {
    final result = engine.resolve(
      natalOutput: _natal(),
      kundliAnalysis: _analysis(
        housePolarities: const {
          10: AnalysisPolarity.supportive,
          6: AnalysisPolarity.supportive,
          11: AnalysisPolarity.supportive,
        },
        divisionalPolarities: const {
          'saturn': AnalysisPolarity.challenging,
          'mercury': AnalysisPolarity.challenging,
        },
      ),
      questionTiming: _question(
        asOf,
        natal: AnalysisPolarity.supportive,
        dasha: AnalysisPolarity.supportive,
        transit: AnalysisPolarity.supportive,
        targetedTransitPlanets: const ['jupiter'],
      ),
    );

    expect(result.structuralPolarity, AnalysisPolarity.mixed);
    expect(result.polarity, AnalysisPolarity.mixed);
    expect(result.confidence, AnalysisConfidence.low);
    expect(result.resolutionCode, 'structural_d1_d9_conflict');
    expect(result.conflictDetected, isTrue);
  });

  test('preserves Dasha versus transit conflict without majority voting', () {
    final result = engine.resolve(
      natalOutput: _natal(),
      kundliAnalysis: _analysis(
        housePolarities: const {
          10: AnalysisPolarity.supportive,
          6: AnalysisPolarity.supportive,
          11: AnalysisPolarity.supportive,
        },
        divisionalPolarities: const {
          'saturn': AnalysisPolarity.supportive,
          'mercury': AnalysisPolarity.supportive,
        },
      ),
      questionTiming: _question(
        asOf,
        natal: AnalysisPolarity.supportive,
        dasha: AnalysisPolarity.supportive,
        transit: AnalysisPolarity.challenging,
        targetedTransitPlanets: const ['saturn'],
      ),
    );

    expect(result.polarity, AnalysisPolarity.mixed);
    expect(result.confidence, AnalysisConfidence.low);
    expect(
      result.resolutionCode,
      'independent_group_directional_conflict',
    );
    expect(result.conflictDetected, isTrue);
  });

  test('allows only Low two-group convergence when topical transit is absent', () {
    final result = engine.resolve(
      natalOutput: _natal(),
      kundliAnalysis: _analysis(
        housePolarities: const {
          10: AnalysisPolarity.supportive,
          6: AnalysisPolarity.supportive,
          11: AnalysisPolarity.supportive,
        },
        divisionalPolarities: const {
          'saturn': AnalysisPolarity.supportive,
          'mercury': AnalysisPolarity.supportive,
        },
      ),
      questionTiming: _question(
        asOf,
        natal: AnalysisPolarity.supportive,
        dasha: AnalysisPolarity.supportive,
        transit: AnalysisPolarity.mixed,
        targetedTransitPlanets: const [],
        confirmationCode: 'dasha_topic_review_without_transit_confirmation',
      ),
    );

    expect(result.polarity, AnalysisPolarity.supportive);
    expect(result.confidence, AnalysisConfidence.low);
    expect(result.resolutionCode, 'two_group_partial_convergence');
    expect(result.directionalIndependentGroups, 2);
  });

  test('does not count Mixed D1-D9 agreement as structural confirmation', () {
    final result = engine.resolve(
      natalOutput: _natal(),
      kundliAnalysis: _analysis(
        housePolarities: const {
          10: AnalysisPolarity.supportive,
          6: AnalysisPolarity.supportive,
          11: AnalysisPolarity.supportive,
        },
        divisionalPolarities: const {
          'saturn': AnalysisPolarity.mixed,
          'mercury': AnalysisPolarity.mixed,
        },
      ),
      questionTiming: _question(
        asOf,
        natal: AnalysisPolarity.supportive,
        dasha: AnalysisPolarity.supportive,
        transit: AnalysisPolarity.supportive,
        targetedTransitPlanets: const ['jupiter'],
      ),
    );

    expect(result.structuralPolarity, AnalysisPolarity.mixed);
    expect(result.directionalIndependentGroups, 2);
    expect(result.polarity, AnalysisPolarity.supportive);
    expect(result.confidence, AnalysisConfidence.low);
    expect(result.resolutionCode, 'two_group_partial_convergence');
  });

  test('rejects a question-timing natal polarity inconsistent with Kundli snapshot', () {
    expect(
      () => engine.resolve(
        natalOutput: _natal(),
        kundliAnalysis: _analysis(
          housePolarities: const {
            10: AnalysisPolarity.supportive,
            6: AnalysisPolarity.supportive,
            11: AnalysisPolarity.supportive,
          },
          divisionalPolarities: const {
            'saturn': AnalysisPolarity.supportive,
            'mercury': AnalysisPolarity.supportive,
          },
        ),
        questionTiming: _question(
          asOf,
          natal: AnalysisPolarity.challenging,
          dasha: AnalysisPolarity.supportive,
          transit: AnalysisPolarity.supportive,
          targetedTransitPlanets: const ['jupiter'],
        ),
      ),
      throwsStateError,
    );
  });

  test('requires explicit D9-capable Vedic calculation output', () {
    final invalid = CalculationOutputSnapshot(
      id: 1,
      consultationId: 1,
      inputSnapshotId: 1,
      engineId: 'fixture',
      engineVersion: '1',
      outputSchemaVersion: 'vedic-chart-v1',
      output: const {
        'ascendant': {'signIndex': 0},
      },
      outputHash: 'fixture',
      createdAt: asOf,
    );
    expect(
      () => engine.resolve(
        natalOutput: invalid,
        kundliAnalysis: _analysis(
          housePolarities: const {
            10: AnalysisPolarity.supportive,
            6: AnalysisPolarity.supportive,
            11: AnalysisPolarity.supportive,
          },
          divisionalPolarities: const {
            'saturn': AnalysisPolarity.supportive,
            'mercury': AnalysisPolarity.supportive,
          },
        ),
        questionTiming: _question(
          asOf,
          natal: AnalysisPolarity.supportive,
          dasha: AnalysisPolarity.supportive,
          transit: AnalysisPolarity.supportive,
          targetedTransitPlanets: const ['jupiter'],
        ),
      ),
      throwsArgumentError,
    );
  });

  test('rejects target houses that do not match the versioned topic profile', () {
    expect(
      () => engine.resolve(
        natalOutput: _natal(),
        kundliAnalysis: _analysis(
          housePolarities: const {
            10: AnalysisPolarity.supportive,
            6: AnalysisPolarity.supportive,
            11: AnalysisPolarity.supportive,
          },
          divisionalPolarities: const {
            'saturn': AnalysisPolarity.supportive,
            'mercury': AnalysisPolarity.supportive,
          },
        ),
        questionTiming: _question(
          asOf,
          natal: AnalysisPolarity.supportive,
          dasha: AnalysisPolarity.supportive,
          transit: AnalysisPolarity.supportive,
          targetedTransitPlanets: const ['jupiter'],
          targetHouses: const [10, 11],
        ),
      ),
      throwsArgumentError,
    );
  });

  test('counts multiple supportive Ashtakavarga checks as one fourth group', () {
    final checks = [
      _avCheck(
        planet: 'jupiter',
        house: 10,
        polarity: AnalysisPolarity.supportive,
      ),
      _avCheck(
        planet: 'venus',
        house: 11,
        polarity: AnalysisPolarity.supportive,
      ),
    ];
    final result = engine.resolve(
      natalOutput: _natal(),
      kundliAnalysis: _analysis(
        housePolarities: const {
          10: AnalysisPolarity.supportive,
          6: AnalysisPolarity.supportive,
          11: AnalysisPolarity.supportive,
        },
        divisionalPolarities: const {
          'saturn': AnalysisPolarity.supportive,
          'mercury': AnalysisPolarity.supportive,
        },
      ),
      questionTiming: _question(
        asOf,
        natal: AnalysisPolarity.supportive,
        dasha: AnalysisPolarity.supportive,
        transit: AnalysisPolarity.supportive,
        targetedTransitPlanets: const ['jupiter'],
        schemaVersion: 'vedic-question-timing-v2',
        ashtakavarga: AnalysisPolarity.supportive,
        hasDirectionalAshtakavarga: true,
        ashtakavargaTransitPlanets: const ['jupiter', 'venus'],
        ashtakavargaChecks: checks,
      ),
    );

    expect(result.polarity, AnalysisPolarity.supportive);
    expect(result.confidence, AnalysisConfidence.medium);
    expect(result.resolutionCode, 'four_group_governed_convergence');
    expect(result.directionalIndependentGroups, 4);
    expect(result.agreeingIndependentGroups, 4);
    expect(result.conflictDetected, isFalse);
    expect(result.layers, hasLength(5));
    final avLayer = result.layers.singleWhere(
      (layer) => layer.layer == VedicEvidenceLayer.ashtakavargaTransit,
    );
    expect(avLayer.available, isTrue);
    expect(avLayer.sourceCodes, hasLength(2));
    expect(avLayer.independenceGroup, 'ashtakavarga');
  });

  test('accepts timing v3 Kaksha-refined Ashtakavarga as one governed group', () {
    final result = engine.resolve(
      natalOutput: _natal(),
      kundliAnalysis: _analysis(
        housePolarities: const {
          10: AnalysisPolarity.supportive,
          6: AnalysisPolarity.supportive,
          11: AnalysisPolarity.supportive,
        },
        divisionalPolarities: const {
          'saturn': AnalysisPolarity.supportive,
          'mercury': AnalysisPolarity.supportive,
        },
      ),
      questionTiming: _question(
        asOf,
        natal: AnalysisPolarity.supportive,
        dasha: AnalysisPolarity.supportive,
        transit: AnalysisPolarity.supportive,
        targetedTransitPlanets: const ['jupiter'],
        schemaVersion: 'vedic-question-timing-v3',
        ashtakavarga: AnalysisPolarity.supportive,
        hasDirectionalAshtakavarga: true,
        ashtakavargaTransitPlanets: const ['jupiter'],
        ashtakavargaChecks: [
          _avCheckV3(
            planet: 'jupiter',
            house: 10,
            polarity: AnalysisPolarity.supportive,
          ),
        ],
      ),
    );

    expect(result.polarity, AnalysisPolarity.supportive);
    expect(result.directionalIndependentGroups, 4);
    expect(result.confidence, AnalysisConfidence.medium);
  });

  test('preserves Moon-gochara versus Ashtakavarga group conflict as Mixed', () {
    final result = engine.resolve(
      natalOutput: _natal(),
      kundliAnalysis: _analysis(
        housePolarities: const {
          10: AnalysisPolarity.supportive,
          6: AnalysisPolarity.supportive,
          11: AnalysisPolarity.supportive,
        },
        divisionalPolarities: const {
          'saturn': AnalysisPolarity.supportive,
          'mercury': AnalysisPolarity.supportive,
        },
      ),
      questionTiming: _question(
        asOf,
        natal: AnalysisPolarity.supportive,
        dasha: AnalysisPolarity.supportive,
        transit: AnalysisPolarity.supportive,
        targetedTransitPlanets: const ['jupiter'],
        schemaVersion: 'vedic-question-timing-v2',
        ashtakavarga: AnalysisPolarity.challenging,
        hasDirectionalAshtakavarga: true,
        ashtakavargaTransitPlanets: const ['saturn'],
        ashtakavargaChecks: [
          _avCheck(
            planet: 'saturn',
            house: 10,
            polarity: AnalysisPolarity.challenging,
          ),
        ],
      ),
    );

    expect(result.polarity, AnalysisPolarity.mixed);
    expect(result.confidence, AnalysisConfidence.low);
    expect(result.resolutionCode, 'independent_group_directional_conflict');
    expect(result.conflictDetected, isTrue);
  });

  test('preserves internal Ashtakavarga directional conflict even when other groups agree', () {
    final checks = [
      _avCheck(
        planet: 'jupiter',
        house: 10,
        polarity: AnalysisPolarity.supportive,
      ),
      _avCheck(
        planet: 'saturn',
        house: 11,
        polarity: AnalysisPolarity.challenging,
      ),
    ];
    final result = engine.resolve(
      natalOutput: _natal(),
      kundliAnalysis: _analysis(
        housePolarities: const {
          10: AnalysisPolarity.supportive,
          6: AnalysisPolarity.supportive,
          11: AnalysisPolarity.supportive,
        },
        divisionalPolarities: const {
          'saturn': AnalysisPolarity.supportive,
          'mercury': AnalysisPolarity.supportive,
        },
      ),
      questionTiming: _question(
        asOf,
        natal: AnalysisPolarity.supportive,
        dasha: AnalysisPolarity.supportive,
        transit: AnalysisPolarity.supportive,
        targetedTransitPlanets: const ['jupiter'],
        schemaVersion: 'vedic-question-timing-v2',
        ashtakavarga: AnalysisPolarity.mixed,
        hasDirectionalAshtakavarga: true,
        ashtakavargaTransitPlanets: const ['jupiter', 'saturn'],
        ashtakavargaChecks: checks,
      ),
    );

    expect(result.polarity, AnalysisPolarity.mixed);
    expect(result.confidence, AnalysisConfidence.low);
    expect(
      result.resolutionCode,
      'ashtakavarga_internal_directional_conflict',
    );
    expect(result.conflictDetected, isTrue);
  });

  test('rejects inconsistent Ashtakavarga directional metadata in timing v2', () {
    expect(
      () => engine.resolve(
        natalOutput: _natal(),
        kundliAnalysis: _analysis(
          housePolarities: const {
            10: AnalysisPolarity.supportive,
            6: AnalysisPolarity.supportive,
            11: AnalysisPolarity.supportive,
          },
          divisionalPolarities: const {
            'saturn': AnalysisPolarity.supportive,
            'mercury': AnalysisPolarity.supportive,
          },
        ),
        questionTiming: _question(
          asOf,
          natal: AnalysisPolarity.supportive,
          dasha: AnalysisPolarity.supportive,
          transit: AnalysisPolarity.supportive,
          targetedTransitPlanets: const ['jupiter'],
          schemaVersion: 'vedic-question-timing-v2',
          ashtakavarga: AnalysisPolarity.supportive,
          hasDirectionalAshtakavarga: false,
          ashtakavargaTransitPlanets: const [],
          ashtakavargaChecks: [
            _avCheck(
              planet: 'jupiter',
              house: 10,
              polarity: AnalysisPolarity.supportive,
            ),
          ],
        ),
      ),
      throwsStateError,
    );
  });

  test('v2 never emits High confidence', () {
    final result = engine.resolve(
      natalOutput: _natal(),
      kundliAnalysis: _analysis(
        housePolarities: const {
          10: AnalysisPolarity.challenging,
          6: AnalysisPolarity.challenging,
          11: AnalysisPolarity.challenging,
        },
        divisionalPolarities: const {
          'saturn': AnalysisPolarity.challenging,
          'mercury': AnalysisPolarity.challenging,
        },
      ),
      questionTiming: _question(
        asOf,
        natal: AnalysisPolarity.challenging,
        dasha: AnalysisPolarity.challenging,
        transit: AnalysisPolarity.challenging,
        targetedTransitPlanets: const ['saturn'],
      ),
    );

    expect(result.polarity, AnalysisPolarity.challenging);
    expect(result.confidence, isNot(AnalysisConfidence.high));
    expect(result.confidence, AnalysisConfidence.medium);
  });
}

CalculationOutputSnapshot _natal() => CalculationOutputSnapshot(
      id: 1,
      consultationId: 1,
      inputSnapshotId: 1,
      engineId: 'fixture-vedic',
      engineVersion: '1',
      outputSchemaVersion: 'vedic-chart-v4',
      output: const {
        'ascendant': {'signIndex': 0},
      },
      outputHash: 'fixture',
      createdAt: DateTime.utc(2026, 8, 7),
    );

KundliAnalysis _analysis({
  required Map<int, AnalysisPolarity> housePolarities,
  required Map<String, AnalysisPolarity> divisionalPolarities,
}) {
  return KundliAnalysis(
    findings: [
      for (final entry in housePolarities.entries)
        _finding(
          code: 'vedic.life_area.house_${entry.key}.synthesis',
          polarity: entry.value,
          kind: EvidenceKind.lordship,
        ),
      for (final entry in divisionalPolarities.entries)
        _finding(
          code: 'vedic.divisional.d1_d9.${entry.key}',
          polarity: entry.value,
          kind: EvidenceKind.divisional,
        ),
    ],
    timingWindows: const [],
    remedyCandidates: const [],
    warningsEn: const ['fixture'],
    warningsBn: const ['fixture'],
    professionalReviewRequired: true,
  );
}

ChartFinding _finding({
  required String code,
  required AnalysisPolarity polarity,
  required EvidenceKind kind,
}) =>
    ChartFinding(
      code: code,
      area: LifeArea.overall,
      polarity: polarity,
      confidence: AnalysisConfidence.medium,
      titleEn: code,
      titleBn: code,
      narrativeEn: 'fixture',
      narrativeBn: 'fixture',
      evidence: [
        ChartEvidence(
          ruleId: 'fixture.$code',
          outputPath: r'$.fixture',
          kind: kind,
          descriptionEn: 'fixture evidence',
          descriptionBn: 'fixture evidence',
        ),
      ],
    );

VedicQuestionTiming _question(
  DateTime asOf, {
  required AnalysisPolarity natal,
  required AnalysisPolarity dasha,
  required AnalysisPolarity transit,
  required List<String> targetedTransitPlanets,
  String confirmationCode = 'supportive_topic_convergence',
  List<int> targetHouses = const [10, 6, 11],
  String schemaVersion = 'vedic-question-timing-v1',
  AnalysisPolarity ashtakavarga = AnalysisPolarity.mixed,
  bool hasDirectionalAshtakavarga = false,
  List<String> ashtakavargaTransitPlanets = const [],
  List<VedicAshtakavargaTransitCheck> ashtakavargaChecks = const [],
}) =>
    VedicQuestionTiming(
      asOfUtc: asOf,
      engineId: 'fixture-question',
      engineVersion: schemaVersion == 'vedic-question-timing-v3'
          ? '3.0.0'
          : schemaVersion == 'vedic-question-timing-v2'
              ? '2.0.0'
              : '1.0.0',
      schemaVersion: schemaVersion,
      topic: VedicQuestionTopic.career,
      targetHouses: targetHouses,
      targetLifeAreas: const [LifeArea.career, LifeArea.gains],
      natalPolarity: natal,
      dashaPolarity: dasha,
      transitPolarity: transit,
      polarity: dasha == transit ? dasha : AnalysisPolarity.mixed,
      confidence: AnalysisConfidence.low,
      confirmationCode: confirmationCode,
      dashaTopicScore: dasha == AnalysisPolarity.challenging ? -12 : 12,
      targetedTransitPlanets: targetedTransitPlanets,
      ashtakavargaPolarity: ashtakavarga,
      hasDirectionalAshtakavarga: hasDirectionalAshtakavarga,
      ashtakavargaTransitPlanets: ashtakavargaTransitPlanets,
      ashtakavargaTransitChecks: ashtakavargaChecks,
      titleEn: 'fixture',
      titleBn: 'fixture',
      narrativeEn: 'fixture',
      narrativeBn: 'fixture',
      evidence: const [
        ChartEvidence(
          ruleId: 'fixture.dasha',
          outputPath: r'$.fixture',
          kind: EvidenceKind.dasha,
          descriptionEn: 'dasha fixture',
          descriptionBn: 'dasha fixture',
        ),
        ChartEvidence(
          ruleId: 'fixture.transit',
          outputPath: r'$.fixture',
          kind: EvidenceKind.transit,
          descriptionEn: 'transit fixture',
          descriptionBn: 'transit fixture',
        ),
      ],
      warningsEn: const ['fixture'],
      warningsBn: const ['fixture'],
      professionalReviewRequired: true,
    );

VedicAshtakavargaTransitCheck _avCheckV3({
  required String planet,
  required int house,
  required AnalysisPolarity polarity,
}) {
  final supportive = polarity == AnalysisPolarity.supportive;
  final challenging = polarity == AnalysisPolarity.challenging;
  final finalPolarity = supportive
      ? AnalysisPolarity.supportive
      : challenging
          ? AnalysisPolarity.challenging
          : AnalysisPolarity.mixed;
  return VedicAshtakavargaTransitCheck(
    planet: planet,
    signIndex: (house - 1) % 12,
    houseFromAscendant: house,
    bavPositiveMarks: supportive ? 5 : challenging ? 3 : 4,
    savPositiveMarks: supportive ? 31 : challenging ? 24 : 27,
    bavPolarity: finalPolarity,
    savPolarity: finalPolarity,
    wholeSignPolarity: finalPolarity,
    kaksha: VedicAshtakavargaKakshaProfile(
      ruleVersion: 'ashtakavarga-kaksha-v1',
      kakshaNumber: 1,
      kakshaLord: 'saturn',
      startDegree: 0,
      endDegree: 3.75,
      degreeInSign: 0,
      positiveMark: supportive,
      polarity: finalPolarity,
      evidence: const [],
    ),
    polarity: finalPolarity,
    evidence: const [],
  );
}

VedicAshtakavargaTransitCheck _avCheck({
  required String planet,
  required int house,
  required AnalysisPolarity polarity,
}) =>
    VedicAshtakavargaTransitCheck(
      planet: planet,
      signIndex: (house - 1) % 12,
      houseFromAscendant: house,
      bavPositiveMarks: polarity == AnalysisPolarity.supportive
          ? 5
          : polarity == AnalysisPolarity.challenging
              ? 3
              : 4,
      savPositiveMarks: polarity == AnalysisPolarity.supportive
          ? 31
          : polarity == AnalysisPolarity.challenging
              ? 24
              : 27,
      bavPolarity: polarity,
      savPolarity: polarity,
      polarity: polarity,
      evidence: [
        ChartEvidence(
          ruleId: 'fixture.ashtakavarga.$planet.$house',
          outputPath: r'$.fixture.ashtakavarga',
          kind: EvidenceKind.ashtakavarga,
          descriptionEn: 'ashtakavarga fixture',
          descriptionBn: 'ashtakavarga fixture',
        ),
      ],
    );
