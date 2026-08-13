import 'package:astro_logic/src/models/calculation_output_snapshot.dart';
import 'package:astro_logic/src/models/kundli_analysis.dart';
import 'package:astro_logic/src/models/vedic_transit_analysis.dart';
import 'package:astro_logic/src/vedic/vedic_timing_synthesis_engine.dart';
import 'package:astro_logic/src/vedic/vimshottari_dasha_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final birth = DateTime.utc(2000, 1, 1);
  final vimshottari = VimshottariDashaEngine.calculate(
    moonSiderealLongitude: 0,
    birthUtc: birth,
  );
  final selected = _firstPeriodWithDistinctLords(vimshottari, birth);

  test('confirms supportive Dasha when enabled transit direction agrees', () {
    final asOf = selected.midpoint;
    final analysis = const VedicTimingSynthesisEngine().synthesize(
      natalOutput: _natalOutput(vimshottari),
      kundliAnalysis: _kundliAnalysis(_profiles(defaultScore: 3)),
      transitAnalysis: _transit(
        asOf,
        jupiterPolarity: AnalysisPolarity.supportive,
        saturnPolarity: AnalysisPolarity.mixed,
      ),
      asOfUtc: asOf,
    );

    expect(analysis.schemaVersion, 'vedic-timing-synthesis-v1');
    expect(analysis.confirmationCode, 'supportive_convergence');
    expect(analysis.polarity, AnalysisPolarity.supportive);
    expect(analysis.confidence, AnalysisConfidence.medium);
    expect(analysis.activeDasha.weightedScore, 18);
    expect(analysis.activeDasha.mahadashaLord, selected.mahaLord);
    expect(analysis.activeDasha.antardashaLord, selected.antarLord);
    expect(
      analysis.activeDasha.pratyantardashaLord,
      selected.pratyantarLord,
    );
    expect(analysis.professionalReviewRequired, isTrue);
  });

  test('keeps opposite Dasha and transit directions mixed', () {
    final asOf = selected.midpoint;
    final analysis = const VedicTimingSynthesisEngine().synthesize(
      natalOutput: _natalOutput(vimshottari),
      kundliAnalysis: _kundliAnalysis(_profiles(defaultScore: -3)),
      transitAnalysis: _transit(
        asOf,
        jupiterPolarity: AnalysisPolarity.supportive,
        saturnPolarity: AnalysisPolarity.mixed,
      ),
      asOfUtc: asOf,
    );

    expect(analysis.activeDasha.polarity, AnalysisPolarity.challenging);
    expect(analysis.transitPolarity, AnalysisPolarity.supportive);
    expect(analysis.confirmationCode, 'directional_conflict');
    expect(analysis.polarity, AnalysisPolarity.mixed);
    expect(analysis.confidence, AnalysisConfidence.medium);
  });

  test('preserves contradictory three-level Dasha as mixed', () {
    final asOf = selected.midpoint;
    final scores = <String, int>{
      selected.mahaLord: 3,
      selected.antarLord: 3,
      selected.pratyantarLord: -3,
    };
    final analysis = const VedicTimingSynthesisEngine().synthesize(
      natalOutput: _natalOutput(vimshottari),
      kundliAnalysis: _kundliAnalysis(_profiles(scores: scores)),
      transitAnalysis: _transit(
        asOf,
        jupiterPolarity: AnalysisPolarity.supportive,
        saturnPolarity: AnalysisPolarity.mixed,
      ),
      asOfUtc: asOf,
    );

    expect(analysis.activeDasha.contradictorySignals, isTrue);
    expect(analysis.activeDasha.polarity, AnalysisPolarity.mixed);
    expect(
      analysis.confirmationCode,
      'insufficient_directional_confirmation',
    );
    expect(analysis.polarity, AnalysisPolarity.mixed);
    expect(analysis.confidence, AnalysisConfidence.low);
  });

  test('does not convert absence of directional transit into adverse signal', () {
    final asOf = selected.midpoint;
    final analysis = const VedicTimingSynthesisEngine().synthesize(
      natalOutput: _natalOutput(vimshottari),
      kundliAnalysis: _kundliAnalysis(_profiles(defaultScore: 3)),
      transitAnalysis: _transit(
        asOf,
        jupiterPolarity: AnalysisPolarity.mixed,
        saturnPolarity: AnalysisPolarity.mixed,
      ),
      asOfUtc: asOf,
    );

    expect(analysis.transitPolarity, AnalysisPolarity.mixed);
    expect(analysis.polarity, AnalysisPolarity.mixed);
    expect(analysis.confidence, AnalysisConfidence.low);
    expect(
      analysis.narrativeEn,
      contains('provides no directional confirmation on this date'),
    );
  });

  test('uses half-open Dasha boundaries and moves to the next period', () {
    final next = _nextPratyantar(vimshottari, selected);
    final asOf = selected.end;
    final analysis = const VedicTimingSynthesisEngine().synthesize(
      natalOutput: _natalOutput(vimshottari),
      kundliAnalysis: _kundliAnalysis(_profiles(defaultScore: 3)),
      transitAnalysis: _transit(
        asOf,
        jupiterPolarity: AnalysisPolarity.supportive,
        saturnPolarity: AnalysisPolarity.mixed,
      ),
      asOfUtc: asOf,
    );

    expect(analysis.activeDasha.startUtc, next.start);
    expect(analysis.activeDasha.pratyantardashaLord, next.pratyantarLord);
  });

  test('rejects a transit result calculated for another instant', () {
    final asOf = selected.midpoint;
    expect(
      () => const VedicTimingSynthesisEngine().synthesize(
        natalOutput: _natalOutput(vimshottari),
        kundliAnalysis: _kundliAnalysis(_profiles(defaultScore: 3)),
        transitAnalysis: _transit(
          asOf.add(const Duration(hours: 1)),
          jupiterPolarity: AnalysisPolarity.supportive,
          saturnPolarity: AnalysisPolarity.mixed,
        ),
        asOfUtc: asOf,
      ),
      throwsArgumentError,
    );
  });
}

CalculationOutputSnapshot _natalOutput(Map<String, Object?> vimshottari) =>
    CalculationOutputSnapshot(
      id: 1,
      consultationId: 1,
      inputSnapshotId: 1,
      engineId: 'fixture',
      engineVersion: '1',
      outputSchemaVersion: 'vedic-chart-v4',
      output: {'vimshottari': vimshottari},
      outputHash: 'fixture',
      createdAt: DateTime.utc(2000, 1, 1),
    );

KundliAnalysis _kundliAnalysis(List<DashaActivationProfile> profiles) =>
    KundliAnalysis(
      findings: const [],
      timingWindows: const [],
      dashaActivationProfiles: profiles,
      remedyCandidates: const [],
      warningsEn: const [],
      warningsBn: const [],
      professionalReviewRequired: true,
    );

List<DashaActivationProfile> _profiles({
  int defaultScore = 0,
  Map<String, int> scores = const {},
}) =>
    VimshottariDashaEngine.sequence
        .map(
          (lord) => DashaActivationProfile(
            lord: lord,
            score: scores[lord] ?? defaultScore,
            polarity: _scorePolarity(scores[lord] ?? defaultScore),
            lifeAreas: const [LifeArea.overall, LifeArea.career],
            summaryEn: '$lord activation fixture',
            summaryBn: '$lord activation fixture',
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
        )
        .toList(growable: false);

AnalysisPolarity _scorePolarity(int score) => score > 0
    ? AnalysisPolarity.supportive
    : score < 0
        ? AnalysisPolarity.challenging
        : AnalysisPolarity.mixed;

VedicTransitAnalysis _transit(
  DateTime asOf, {
  required AnalysisPolarity jupiterPolarity,
  required AnalysisPolarity saturnPolarity,
}) =>
    VedicTransitAnalysis(
      asOfUtc: asOf,
      engineId: 'fixture-transit',
      engineVersion: '1',
      schemaVersion: 'vedic-transit-analysis-v2',
      ayanamsha: 'lahiri',
      lunarNodeMode: 'trueNode',
      positions: const [],
      findings: [
        _transitFinding('jupiter', jupiterPolarity),
        _transitFinding('saturn', saturnPolarity),
      ],
      warningsEn: const [],
      warningsBn: const [],
      professionalReviewRequired: true,
    );

VedicTransitFinding _transitFinding(
  String planet,
  AnalysisPolarity polarity,
) =>
    VedicTransitFinding(
      code: 'fixture.transit.$planet.${polarity.name}',
      planet: planet,
      houseFromMoon: 5,
      polarity: polarity,
      confidence: AnalysisConfidence.medium,
      titleEn: '$planet transit',
      titleBn: '$planet transit',
      narrativeEn: '$planet transit fixture',
      narrativeBn: '$planet transit fixture',
      evidence: [
        ChartEvidence(
          ruleId: 'fixture.transit.$planet',
          outputPath: r'$.transit',
          kind: EvidenceKind.transit,
          descriptionEn: '$planet transit fixture',
          descriptionBn: '$planet transit fixture',
        ),
      ],
    );

_SelectedPeriod _firstPeriodWithDistinctLords(
  Map<String, Object?> vimshottari,
  DateTime birth,
) {
  final mahadashas = vimshottari['mahadashas']! as List;
  for (final rawMaha in mahadashas.whereType<Map>()) {
    final maha = Map<String, Object?>.from(rawMaha);
    final mahaLord = maha['lord']! as String;
    final antardashas = maha['antardashas']! as List;
    for (final rawAntar in antardashas.whereType<Map>()) {
      final antar = Map<String, Object?>.from(rawAntar);
      final antarLord = antar['antardashaLord']! as String;
      final periods = antar['pratyantardashas']! as List;
      for (final rawPeriod in periods.whereType<Map>()) {
        final period = Map<String, Object?>.from(rawPeriod);
        final pratyantarLord = period['pratyantardashaLord']! as String;
        final start = DateTime.parse(period['startUtc']! as String).toUtc();
        final end = DateTime.parse(period['endUtc']! as String).toUtc();
        if (!end.isAfter(birth)) continue;
        if ({mahaLord, antarLord, pratyantarLord}.length == 3) {
          return _SelectedPeriod(
            mahaLord: mahaLord,
            antarLord: antarLord,
            pratyantarLord: pratyantarLord,
            start: start,
            end: end,
          );
        }
      }
    }
  }
  throw StateError('Fixture did not produce a distinct MD/AD/PD chain');
}

_SelectedPeriod _nextPratyantar(
  Map<String, Object?> vimshottari,
  _SelectedPeriod selected,
) {
  final all = <_SelectedPeriod>[];
  final mahadashas = vimshottari['mahadashas']! as List;
  for (final rawMaha in mahadashas.whereType<Map>()) {
    final maha = Map<String, Object?>.from(rawMaha);
    final mahaLord = maha['lord']! as String;
    for (final rawAntar in (maha['antardashas']! as List).whereType<Map>()) {
      final antar = Map<String, Object?>.from(rawAntar);
      final antarLord = antar['antardashaLord']! as String;
      for (final rawPeriod
          in (antar['pratyantardashas']! as List).whereType<Map>()) {
        final period = Map<String, Object?>.from(rawPeriod);
        all.add(
          _SelectedPeriod(
            mahaLord: mahaLord,
            antarLord: antarLord,
            pratyantarLord: period['pratyantardashaLord']! as String,
            start: DateTime.parse(period['startUtc']! as String).toUtc(),
            end: DateTime.parse(period['endUtc']! as String).toUtc(),
          ),
        );
      }
    }
  }
  final index = all.indexWhere(
    (period) =>
        period.start == selected.start &&
        period.end == selected.end &&
        period.pratyantarLord == selected.pratyantarLord,
  );
  if (index < 0 || index + 1 >= all.length) {
    throw StateError('Selected fixture period has no next period');
  }
  return all[index + 1];
}

class _SelectedPeriod {
  const _SelectedPeriod({
    required this.mahaLord,
    required this.antarLord,
    required this.pratyantarLord,
    required this.start,
    required this.end,
  });

  final String mahaLord;
  final String antarLord;
  final String pratyantarLord;
  final DateTime start;
  final DateTime end;

  DateTime get midpoint => start.add(
        Duration(
          microseconds: end.difference(start).inMicroseconds ~/ 2,
        ),
      );
}
