import 'package:astro_logic/src/models/consultation.dart';
import 'package:astro_logic/src/models/kundli_analysis.dart';
import 'package:astro_logic/src/models/vedic_question_timing.dart';
import 'package:astro_logic/src/models/vedic_timing_synthesis.dart';
import 'package:astro_logic/src/models/vedic_transit_analysis.dart';
import 'package:astro_logic/src/vedic/vedic_question_timing_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const engine = VedicQuestionTimingEngine();
  final asOf = DateTime.utc(2026, 8, 7, 10);

  test('maps supported consultation categories and excludes general/health', () {
    expect(
      engine.topicForConsultationCategory(ConsultationCategory.business),
      VedicQuestionTopic.business,
    );
    expect(
      engine.topicForConsultationCategory(
        ConsultationCategory.travelRelocation,
      ),
      VedicQuestionTopic.travelRelocation,
    );
    expect(
      engine.topicForConsultationCategory(ConsultationCategory.general),
      isNull,
    );
    expect(
      engine.topicForConsultationCategory(ConsultationCategory.health),
      isNull,
    );
  });

  test('confirms a supportive career review only when Dasha and topical transit agree', () {
    final result = engine.analyze(
      topic: VedicQuestionTopic.career,
      kundliAnalysis: _analysis(
        housePolarities: const {
          10: AnalysisPolarity.supportive,
          6: AnalysisPolarity.supportive,
          11: AnalysisPolarity.mixed,
        },
        dashaScore: 3,
        dashaAreas: const [LifeArea.career, LifeArea.gains],
      ),
      timingSynthesis: _timing(asOf, AnalysisPolarity.supportive),
      transitAnalysis: _transit(
        asOf,
        planet: 'jupiter',
        houseFromAscendant: 10,
        polarity: AnalysisPolarity.supportive,
      ),
    );

    expect(result.schemaVersion, 'vedic-question-timing-v3');
    expect(result.confirmationCode, 'supportive_topic_convergence');
    expect(result.polarity, AnalysisPolarity.supportive);
    expect(result.confidence, AnalysisConfidence.medium);
    expect(result.dashaTopicScore, 18);
    expect(result.targetHouses, [10, 6, 11]);
    expect(result.targetedTransitPlanets, ['jupiter']);
    expect(result.professionalReviewRequired, isTrue);
  });

  test('preserves a natal target-house conflict as Mixed', () {
    final result = engine.analyze(
      topic: VedicQuestionTopic.finance,
      kundliAnalysis: _analysis(
        housePolarities: const {
          2: AnalysisPolarity.challenging,
          11: AnalysisPolarity.challenging,
        },
        dashaScore: 3,
        dashaAreas: const [LifeArea.finance, LifeArea.gains],
      ),
      timingSynthesis: _timing(asOf, AnalysisPolarity.supportive),
      transitAnalysis: _transit(
        asOf,
        planet: 'jupiter',
        houseFromAscendant: 11,
        polarity: AnalysisPolarity.supportive,
      ),
    );

    expect(result.confirmationCode, 'timing_layers_agree_natal_conflicts');
    expect(result.polarity, AnalysisPolarity.mixed);
    expect(result.confidence, AnalysisConfidence.low);
  });

  test('does not open a directional window without topic activation in active Dasha', () {
    final result = engine.analyze(
      topic: VedicQuestionTopic.education,
      kundliAnalysis: _analysis(
        housePolarities: const {
          5: AnalysisPolarity.supportive,
          9: AnalysisPolarity.supportive,
        },
        dashaScore: 4,
        dashaAreas: const [LifeArea.career],
      ),
      timingSynthesis: _timing(asOf, AnalysisPolarity.supportive),
      transitAnalysis: _transit(
        asOf,
        planet: 'jupiter',
        houseFromAscendant: 5,
        polarity: AnalysisPolarity.supportive,
      ),
    );

    expect(result.confirmationCode, 'insufficient_dasha_topic_activation');
    expect(result.polarity, AnalysisPolarity.mixed);
    expect(result.confidence, AnalysisConfidence.low);
    expect(result.dashaTopicScore, 0);
  });

  test('keeps Dasha-led topic review low confidence when transit misses target houses', () {
    final result = engine.analyze(
      topic: VedicQuestionTopic.marriage,
      kundliAnalysis: _analysis(
        housePolarities: const {
          7: AnalysisPolarity.supportive,
          2: AnalysisPolarity.supportive,
          11: AnalysisPolarity.mixed,
        },
        dashaScore: 2,
        dashaAreas: const [LifeArea.marriage, LifeArea.family],
      ),
      timingSynthesis: _timing(asOf, AnalysisPolarity.supportive),
      transitAnalysis: _transit(
        asOf,
        planet: 'jupiter',
        houseFromAscendant: 3,
        polarity: AnalysisPolarity.supportive,
      ),
    );

    expect(
      result.confirmationCode,
      'dasha_topic_review_without_transit_confirmation',
    );
    expect(result.polarity, AnalysisPolarity.supportive);
    expect(result.confidence, AnalysisConfidence.low);
    expect(result.targetedTransitPlanets, isEmpty);
  });

  test('keeps opposite Dasha and topical transit directions Mixed', () {
    final result = engine.analyze(
      topic: VedicQuestionTopic.property,
      kundliAnalysis: _analysis(
        housePolarities: const {
          4: AnalysisPolarity.mixed,
          2: AnalysisPolarity.supportive,
          11: AnalysisPolarity.supportive,
        },
        dashaScore: -3,
        dashaAreas: const [LifeArea.property, LifeArea.finance],
      ),
      timingSynthesis: _timing(asOf, AnalysisPolarity.challenging),
      transitAnalysis: _transit(
        asOf,
        planet: 'jupiter',
        houseFromAscendant: 4,
        polarity: AnalysisPolarity.supportive,
      ),
    );

    expect(result.confirmationCode, 'dasha_transit_topic_conflict');
    expect(result.polarity, AnalysisPolarity.mixed);
    expect(result.confidence, AnalysisConfidence.low);
  });

  test('Mixed transit remains non-directional even inside a target house', () {
    final result = engine.analyze(
      topic: VedicQuestionTopic.travelRelocation,
      kundliAnalysis: _analysis(
        housePolarities: const {
          12: AnalysisPolarity.supportive,
          4: AnalysisPolarity.mixed,
        },
        dashaScore: 2,
        dashaAreas: const [LifeArea.expenses, LifeArea.property],
      ),
      timingSynthesis: _timing(asOf, AnalysisPolarity.supportive),
      transitAnalysis: _transit(
        asOf,
        planet: 'saturn',
        houseFromAscendant: 12,
        polarity: AnalysisPolarity.mixed,
      ),
    );

    expect(
      result.confirmationCode,
      'dasha_topic_review_without_transit_confirmation',
    );
    expect(result.transitPolarity, AnalysisPolarity.mixed);
    expect(result.targetedTransitPlanets, isEmpty);
  });

  test('uses supportive Ashtakavarga as a governed transit confirmation when Moon-gochara is non-directional', () {
    final result = engine.analyze(
      topic: VedicQuestionTopic.career,
      kundliAnalysis: _analysis(
        housePolarities: const {
          10: AnalysisPolarity.supportive,
          6: AnalysisPolarity.supportive,
          11: AnalysisPolarity.mixed,
        },
        dashaScore: 3,
        dashaAreas: const [LifeArea.career, LifeArea.gains],
        ashtakavargaProfile: _ashtakavarga(
          planet: 'jupiter',
          bavMarks: 5,
          savMarks: 33,
        ),
      ),
      timingSynthesis: _timing(asOf, AnalysisPolarity.supportive),
      transitAnalysis: _transit(
        asOf,
        planet: 'jupiter',
        houseFromAscendant: 10,
        polarity: AnalysisPolarity.mixed,
      ),
    );

    expect(result.confirmationCode, 'supportive_topic_convergence_ashtakavarga');
    expect(result.polarity, AnalysisPolarity.supportive);
    expect(result.confidence, AnalysisConfidence.medium);
    expect(result.hasDirectionalAshtakavarga, isTrue);
    expect(result.ashtakavargaPolarity, AnalysisPolarity.supportive);
    expect(result.ashtakavargaTransitPlanets, ['jupiter']);
    expect(result.ashtakavargaTransitChecks.single.bavPositiveMarks, 5);
    expect(result.ashtakavargaTransitChecks.single.savPositiveMarks, 33);
    expect(result.ashtakavargaTransitChecks.single.wholeSignPolarity, AnalysisPolarity.supportive);
    expect(result.ashtakavargaTransitChecks.single.kaksha!.kakshaNumber, 1);
    expect(result.ashtakavargaTransitChecks.single.kaksha!.kakshaLord, 'saturn');
    expect(result.ashtakavargaTransitChecks.single.kaksha!.positiveMark, isTrue);
  });

  test('preserves Moon-gochara versus Ashtakavarga directional conflict as Mixed', () {
    final result = engine.analyze(
      topic: VedicQuestionTopic.career,
      kundliAnalysis: _analysis(
        housePolarities: const {
          10: AnalysisPolarity.supportive,
          6: AnalysisPolarity.supportive,
          11: AnalysisPolarity.mixed,
        },
        dashaScore: 3,
        dashaAreas: const [LifeArea.career],
        ashtakavargaProfile: _ashtakavarga(
          planet: 'jupiter',
          bavMarks: 2,
          savMarks: 23,
          activeKakshaPositive: false,
        ),
      ),
      timingSynthesis: _timing(asOf, AnalysisPolarity.supportive),
      transitAnalysis: _transit(
        asOf,
        planet: 'jupiter',
        houseFromAscendant: 10,
        polarity: AnalysisPolarity.supportive,
      ),
    );

    expect(result.confirmationCode, 'moon_gochara_ashtakavarga_conflict');
    expect(result.polarity, AnalysisPolarity.mixed);
    expect(result.confidence, AnalysisConfidence.low);
    expect(result.ashtakavargaPolarity, AnalysisPolarity.challenging);
  });

  test('keeps BAV 4 non-directional even when SAV is supportive', () {
    final result = engine.analyze(
      topic: VedicQuestionTopic.career,
      kundliAnalysis: _analysis(
        housePolarities: const {
          10: AnalysisPolarity.supportive,
          6: AnalysisPolarity.supportive,
          11: AnalysisPolarity.mixed,
        },
        dashaScore: 3,
        dashaAreas: const [LifeArea.career],
        ashtakavargaProfile: _ashtakavarga(
          planet: 'jupiter',
          bavMarks: 4,
          savMarks: 33,
        ),
      ),
      timingSynthesis: _timing(asOf, AnalysisPolarity.supportive),
      transitAnalysis: _transit(
        asOf,
        planet: 'jupiter',
        houseFromAscendant: 10,
        polarity: AnalysisPolarity.mixed,
      ),
    );

    expect(result.hasDirectionalAshtakavarga, isFalse);
    expect(result.ashtakavargaPolarity, AnalysisPolarity.mixed);
    expect(
      result.confirmationCode,
      'dasha_topic_review_without_transit_confirmation',
    );
  });

  test('does not let strong BAV override an adverse SAV context', () {
    final result = engine.analyze(
      topic: VedicQuestionTopic.career,
      kundliAnalysis: _analysis(
        housePolarities: const {
          10: AnalysisPolarity.supportive,
          6: AnalysisPolarity.supportive,
          11: AnalysisPolarity.mixed,
        },
        dashaScore: 3,
        dashaAreas: const [LifeArea.career],
        ashtakavargaProfile: _ashtakavarga(
          planet: 'jupiter',
          bavMarks: 6,
          savMarks: 23,
        ),
      ),
      timingSynthesis: _timing(asOf, AnalysisPolarity.supportive),
      transitAnalysis: _transit(
        asOf,
        planet: 'jupiter',
        houseFromAscendant: 10,
        polarity: AnalysisPolarity.mixed,
      ),
    );

    expect(result.ashtakavargaTransitChecks.single.bavPolarity, AnalysisPolarity.supportive);
    expect(result.ashtakavargaTransitChecks.single.savPolarity, AnalysisPolarity.challenging);
    expect(result.ashtakavargaTransitChecks.single.polarity, AnalysisPolarity.mixed);
    expect(result.hasDirectionalAshtakavarga, isFalse);
  });

  test('Kaksha disagreement downgrades supportive whole-sign Ashtakavarga to Mixed', () {
    final result = engine.analyze(
      topic: VedicQuestionTopic.career,
      kundliAnalysis: _analysis(
        housePolarities: const {
          10: AnalysisPolarity.supportive,
          6: AnalysisPolarity.supportive,
          11: AnalysisPolarity.mixed,
        },
        dashaScore: 3,
        dashaAreas: const [LifeArea.career],
        ashtakavargaProfile: _ashtakavarga(
          planet: 'jupiter',
          bavMarks: 6,
          savMarks: 33,
          activeKakshaPositive: false,
        ),
      ),
      timingSynthesis: _timing(asOf, AnalysisPolarity.supportive),
      transitAnalysis: _transit(
        asOf,
        planet: 'jupiter',
        houseFromAscendant: 10,
        polarity: AnalysisPolarity.mixed,
      ),
    );

    final check = result.ashtakavargaTransitChecks.single;
    expect(check.wholeSignPolarity, AnalysisPolarity.supportive);
    expect(check.kaksha!.polarity, AnalysisPolarity.challenging);
    expect(check.polarity, AnalysisPolarity.mixed);
    expect(result.hasDirectionalAshtakavarga, isFalse);
  });

  test('uses half-open Kaksha boundary so 3.75 degrees enters Jupiter Kaksha', () {
    final result = engine.analyze(
      topic: VedicQuestionTopic.career,
      kundliAnalysis: _analysis(
        housePolarities: const {
          10: AnalysisPolarity.supportive,
          6: AnalysisPolarity.supportive,
          11: AnalysisPolarity.mixed,
        },
        dashaScore: 3,
        dashaAreas: const [LifeArea.career],
        ashtakavargaProfile: _ashtakavarga(
          planet: 'jupiter',
          bavMarks: 5,
          savMarks: 33,
          activeKakshaPositive: true,
          activeKakshaLord: 'jupiter',
        ),
      ),
      timingSynthesis: _timing(asOf, AnalysisPolarity.supportive),
      transitAnalysis: _transit(
        asOf,
        planet: 'jupiter',
        houseFromAscendant: 10,
        polarity: AnalysisPolarity.mixed,
        degreeInSign: 3.75,
      ),
    );

    final kaksha = result.ashtakavargaTransitChecks.single.kaksha!;
    expect(kaksha.kakshaNumber, 2);
    expect(kaksha.kakshaLord, 'jupiter');
    expect(kaksha.startDegree, 3.75);
    expect(kaksha.endDegree, 7.5);
    expect(kaksha.positiveMark, isTrue);
  });

  test('rejects timing and transit layers calculated for different instants', () {
    expect(
      () => engine.analyze(
        topic: VedicQuestionTopic.children,
        kundliAnalysis: _analysis(
          housePolarities: const {
            5: AnalysisPolarity.supportive,
            2: AnalysisPolarity.supportive,
            11: AnalysisPolarity.supportive,
          },
          dashaScore: 2,
          dashaAreas: const [LifeArea.children],
        ),
        timingSynthesis: _timing(asOf, AnalysisPolarity.supportive),
        transitAnalysis: _transit(
          asOf.add(const Duration(minutes: 1)),
          planet: 'jupiter',
          houseFromAscendant: 5,
          polarity: AnalysisPolarity.supportive,
        ),
      ),
      throwsArgumentError,
    );
  });
}

KundliAnalysis _analysis({
  required Map<int, AnalysisPolarity> housePolarities,
  required int dashaScore,
  required List<LifeArea> dashaAreas,
  AshtakavargaAnalysisProfile? ashtakavargaProfile,
}) {
  final findings = <ChartFinding>[
    for (final entry in housePolarities.entries)
      ChartFinding(
        code: 'vedic.life_area.house_${entry.key}.synthesis',
        area: LifeArea.overall,
        polarity: entry.value,
        confidence: AnalysisConfidence.medium,
        titleEn: 'House ${entry.key}',
        titleBn: 'House ${entry.key}',
        narrativeEn: 'fixture',
        narrativeBn: 'fixture',
        evidence: [
          ChartEvidence(
            ruleId: 'fixture.house.${entry.key}',
            outputPath: r'$.fixture',
            kind: EvidenceKind.lordship,
            descriptionEn: 'house fixture',
            descriptionBn: 'house fixture',
          ),
        ],
      ),
  ];
  return KundliAnalysis(
    findings: findings,
    timingWindows: const [],
    ashtakavargaProfile: ashtakavargaProfile,
    dashaActivationProfiles: [
      for (final lord in const ['sun', 'moon', 'mars'])
        DashaActivationProfile(
          lord: lord,
          score: dashaScore,
          polarity: dashaScore > 0
              ? AnalysisPolarity.supportive
              : dashaScore < 0
                  ? AnalysisPolarity.challenging
                  : AnalysisPolarity.mixed,
          lifeAreas: dashaAreas,
          summaryEn: '$lord fixture',
          summaryBn: '$lord fixture',
          evidence: [
            ChartEvidence(
              ruleId: 'fixture.dasha.$lord',
              outputPath: r'$.fixture',
              kind: EvidenceKind.dasha,
              descriptionEn: '$lord fixture',
              descriptionBn: '$lord fixture',
            ),
          ],
        ),
    ],
    remedyCandidates: const [],
    warningsEn: const [],
    warningsBn: const [],
    professionalReviewRequired: true,
  );
}

AshtakavargaAnalysisProfile _ashtakavarga({
  required String planet,
  required int bavMarks,
  required int savMarks,
  bool activeKakshaPositive = true,
  String activeKakshaLord = 'saturn',
}) {
  AnalysisPolarity savPolarity;
  String savBand;
  if (savMarks > 30) {
    savPolarity = AnalysisPolarity.supportive;
    savBand = 'favourable';
  } else if (savMarks >= 25) {
    savPolarity = AnalysisPolarity.mixed;
    savBand = 'medium';
  } else {
    savPolarity = AnalysisPolarity.challenging;
    savBand = 'adverse';
  }
  const refs = <String>[
    'saturn', 'jupiter', 'mars', 'sun',
    'venus', 'mercury', 'moon', 'lagna',
  ];
  final selected = <String>[];
  if (activeKakshaPositive && bavMarks > 0) {
    selected.add(activeKakshaLord);
  }
  for (final ref in refs) {
    if (selected.length >= bavMarks) break;
    if (ref == activeKakshaLord) continue;
    selected.add(ref);
  }
  final signs = <BhinnashtakavargaSignProfile>[
    for (var sign = 0; sign < 12; sign += 1)
      BhinnashtakavargaSignProfile(
        signIndex: sign,
        positiveMarks: sign == 0 ? bavMarks : 0,
        contributors: sign == 0
            ? [
                for (final ref in selected.take(bavMarks))
                  AshtakavargaContribution(
                    reference: ref,
                    referenceSignIndex: 0,
                    relativeHouse: 1,
                  ),
              ]
            : const [],
      ),
  ];
  return AshtakavargaAnalysisProfile(
    code: 'vedic.ashtakavarga.foundation',
    ruleVersion: 'ashtakavarga-foundation-v1',
    rulesetProfile: 'receivedStandardParashariPositivePlacesV1',
    notationConvention: 'positiveMark1 fixture',
    bhinnashtakavarga: [
      BhinnashtakavargaPlanetProfile(
        planet: planet,
        fixedTotalPositiveMarks: bavMarks,
        signs: signs,
      ),
    ],
    sarvashtakavarga: [
      for (var sign = 0; sign < 12; sign += 1)
        SarvashtakavargaSignProfile(
          signIndex: sign,
          houseNumber: sign + 1,
          positiveMarks: sign == 0 ? savMarks : 28,
          band: sign == 0 ? savBand : 'medium',
          polarity: sign == 0 ? savPolarity : AnalysisPolarity.mixed,
          confidence: AnalysisConfidence.medium,
          narrativeEn: 'fixture',
          narrativeBn: 'fixture',
          evidence: const [],
        ),
    ],
    totalPositiveMarks: 337,
    averagePositiveMarks: 337 / 12.0,
    evidence: const [],
  );
}

VedicTimingSynthesis _timing(DateTime asOf, AnalysisPolarity polarity) =>
    VedicTimingSynthesis(
      asOfUtc: asOf,
      engineId: 'fixture-timing',
      engineVersion: '1.1.0',
      schemaVersion: 'vedic-timing-synthesis-v1',
      activeDasha: VedicActiveDashaChain(
        mahadashaLord: 'sun',
        antardashaLord: 'moon',
        pratyantardashaLord: 'mars',
        startUtc: asOf.subtract(const Duration(days: 10)),
        endUtc: asOf.add(const Duration(days: 10)),
        weightedScore: polarity == AnalysisPolarity.challenging ? -18 : 18,
        polarity: polarity,
        contradictorySignals: false,
        reinforcedLifeAreas: const [],
      ),
      transitPolarity: AnalysisPolarity.mixed,
      polarity: polarity,
      confidence: AnalysisConfidence.medium,
      confirmationCode: 'fixture',
      titleEn: 'fixture',
      titleBn: 'fixture',
      narrativeEn: 'fixture',
      narrativeBn: 'fixture',
      transitFindingCodes: const [],
      evidence: const [],
      warningsEn: const [],
      warningsBn: const [],
      professionalReviewRequired: true,
    );

VedicTransitAnalysis _transit(
  DateTime asOf, {
  required String planet,
  required int houseFromAscendant,
  required AnalysisPolarity polarity,
  double degreeInSign = 0,
}) =>
    VedicTransitAnalysis(
      asOfUtc: asOf,
      engineId: 'fixture-transit',
      engineVersion: '2.0.0',
      schemaVersion: 'vedic-transit-analysis-v2',
      ayanamsha: 'lahiri',
      lunarNodeMode: 'trueNode',
      positions: [
        VedicTransitPosition(
          body: planet,
          siderealLongitude: degreeInSign,
          signIndex: 0,
          sign: 'Aries',
          degreeInSign: degreeInSign,
          retrograde: false,
          houseFromAscendant: houseFromAscendant,
          houseFromMoon: 5,
        ),
      ],
      findings: [
        VedicTransitFinding(
          code: 'fixture.transit.$planet.${polarity.name}',
          planet: planet,
          houseFromMoon: 5,
          polarity: polarity,
          confidence: AnalysisConfidence.medium,
          titleEn: '$planet transit',
          titleBn: '$planet transit',
          narrativeEn: 'fixture',
          narrativeBn: 'fixture',
          evidence: [
            ChartEvidence(
              ruleId: 'fixture.transit.$planet',
              outputPath: r'$.fixture',
              kind: EvidenceKind.transit,
              descriptionEn: '$planet transit fixture',
              descriptionBn: '$planet transit fixture',
            ),
          ],
        ),
      ],
      warningsEn: const [],
      warningsBn: const [],
      professionalReviewRequired: true,
    );
