import 'package:astro_logic/src/models/kundli_analysis.dart';
import 'package:astro_logic/src/vedic/pratyantardasha_interpretation_engine.dart';
import 'package:astro_logic/src/vedic/vimshottari_dasha_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final vimshottari = VimshottariDashaEngine.calculate(
    moonSiderealLongitude: 354.0,
    birthUtc: DateTime.utc(1984, 3, 12, 18, 42),
  );

  test('builds exactly 729 chart-specific interpretations', () {
    final interpretations = PratyantardashaInterpretationEngine.build(
      rawVimshottari: vimshottari,
      profiles: _profiles(defaultScore: 3),
    );

    expect(interpretations, hasLength(729));
    expect(
      interpretations.map((value) => value.code).toSet(),
      hasLength(729),
    );
    expect(
      interpretations.every(
        (value) =>
            value.ruleVersion == 'pratyantardasha-interpretation-v1' &&
            value.endUtc.isAfter(value.startUtc) &&
            value.lifeAreas.isNotEmpty &&
            value.evidence.isNotEmpty,
      ),
      isTrue,
    );
  });

  test('preserves exact calendar boundaries and lord chain', () {
    final interpretations = PratyantardashaInterpretationEngine.build(
      rawVimshottari: vimshottari,
      profiles: _profiles(defaultScore: 3),
    );
    final firstMaha =
        Map<String, Object?>.from((vimshottari['mahadashas']! as List).first as Map);
    final firstAntar = Map<String, Object?>.from(
      (firstMaha['antardashas']! as List).first as Map,
    );
    final firstPd = Map<String, Object?>.from(
      (firstAntar['pratyantardashas']! as List).first as Map,
    );
    final first = interpretations.first;

    expect(first.mahadashaLord, firstMaha['lord']);
    expect(first.antardashaLord, firstAntar['antardashaLord']);
    expect(first.pratyantardashaLord, firstPd['pratyantardashaLord']);
    expect(first.startUtc, DateTime.parse(firstPd['startUtc']! as String).toUtc());
    expect(first.endUtc, DateTime.parse(firstPd['endUtc']! as String).toUtc());
  });

  test('uses governed 3:2:1 weighting and reinforcing trigger relation', () {
    final interpretations = PratyantardashaInterpretationEngine.build(
      rawVimshottari: vimshottari,
      profiles: _profiles(defaultScore: 3),
    );
    final period = interpretations.first;

    expect(period.weightedScore, 18);
    expect(period.polarity, AnalysisPolarity.supportive);
    expect(period.confidence, AnalysisConfidence.medium);
    expect(
      period.triggerRelation,
      PratyantardashaTriggerRelation.reinforcing,
    );
    expect(period.contradictorySignals, isFalse);
  });

  test('keeps opposed MD AD PD signals mixed and identifies countertrend', () {
    final lords = _firstDistinctLordChain(vimshottari);
    final interpretations = PratyantardashaInterpretationEngine.build(
      rawVimshottari: vimshottari,
      profiles: _profiles(
        scores: {
          lords.$1: 4,
          lords.$2: 4,
          lords.$3: -4,
        },
      ),
    );
    final period = interpretations.firstWhere(
      (value) =>
          value.mahadashaLord == lords.$1 &&
          value.antardashaLord == lords.$2 &&
          value.pratyantardashaLord == lords.$3,
    );

    expect(period.contradictorySignals, isTrue);
    expect(period.polarity, AnalysisPolarity.mixed);
    expect(period.confidence, AnalysisConfidence.low);
    expect(
      period.triggerRelation,
      PratyantardashaTriggerRelation.countertrend,
    );
    expect(period.narrativeEn, contains('remains Mixed'));
  });

  test('prioritizes life areas repeated across at least two Dasha levels', () {
    final lords = _firstDistinctLordChain(vimshottari);
    final profiles = _profiles(defaultScore: 3).map((profile) {
      if (profile.lord == lords.$1) {
        return _profile(
          profile.lord,
          3,
          const [LifeArea.career, LifeArea.finance],
        );
      }
      if (profile.lord == lords.$2) {
        return _profile(
          profile.lord,
          3,
          const [LifeArea.career, LifeArea.property],
        );
      }
      if (profile.lord == lords.$3) {
        return _profile(
          profile.lord,
          3,
          const [LifeArea.children, LifeArea.finance],
        );
      }
      return profile;
    }).toList(growable: false);
    final period = PratyantardashaInterpretationEngine.build(
      rawVimshottari: vimshottari,
      profiles: profiles,
    ).firstWhere(
      (value) =>
          value.mahadashaLord == lords.$1 &&
          value.antardashaLord == lords.$2 &&
          value.pratyantardashaLord == lords.$3,
    );

    expect(period.lifeAreas.toSet(), {LifeArea.career, LifeArea.finance});
  });

  test('uses Pratyantardasha areas as fallback when no area repeats', () {
    final lords = _firstDistinctLordChain(vimshottari);
    final profiles = _profiles(defaultScore: 3).map((profile) {
      if (profile.lord == lords.$1) {
        return _profile(profile.lord, 3, const [LifeArea.career]);
      }
      if (profile.lord == lords.$2) {
        return _profile(profile.lord, 3, const [LifeArea.property]);
      }
      if (profile.lord == lords.$3) {
        return _profile(profile.lord, 3, const [LifeArea.children]);
      }
      return profile;
    }).toList(growable: false);
    final period = PratyantardashaInterpretationEngine.build(
      rawVimshottari: vimshottari,
      profiles: profiles,
    ).firstWhere(
      (value) =>
          value.mahadashaLord == lords.$1 &&
          value.antardashaLord == lords.$2 &&
          value.pratyantardashaLord == lords.$3,
    );

    expect(period.lifeAreas, [LifeArea.children]);
  });
}

List<DashaActivationProfile> _profiles({
  int defaultScore = 0,
  Map<String, int> scores = const {},
}) =>
    VimshottariDashaEngine.sequence
        .map(
          (lord) => _profile(
            lord,
            scores[lord] ?? defaultScore,
            const [LifeArea.overall, LifeArea.career],
          ),
        )
        .toList(growable: false);

DashaActivationProfile _profile(
  String lord,
  int score,
  List<LifeArea> areas,
) =>
    DashaActivationProfile(
      lord: lord,
      score: score,
      polarity: score >= 2
          ? AnalysisPolarity.supportive
          : score <= -2
              ? AnalysisPolarity.challenging
              : AnalysisPolarity.mixed,
      lifeAreas: areas,
      summaryEn: '$lord chart-specific activation.',
      summaryBn: '$lord চার্টভিত্তিক সক্রিয়তা।',
      evidence: [
        ChartEvidence(
          ruleId: 'fixture.dasha.$lord',
          outputPath: r'$.fixture',
          kind: EvidenceKind.dasha,
          descriptionEn: '$lord activation fixture.',
          descriptionBn: '$lord সক্রিয়তার fixture।',
        ),
      ],
    );

(String, String, String) _firstDistinctLordChain(
  Map<String, Object?> vimshottari,
) {
  for (final rawMaha in (vimshottari['mahadashas']! as List).whereType<Map>()) {
    final maha = Map<String, Object?>.from(rawMaha);
    final mahaLord = maha['lord']! as String;
    for (final rawAntar in (maha['antardashas']! as List).whereType<Map>()) {
      final antar = Map<String, Object?>.from(rawAntar);
      final antarLord = antar['antardashaLord']! as String;
      for (final rawPd in
          (antar['pratyantardashas']! as List).whereType<Map>()) {
        final pd = Map<String, Object?>.from(rawPd);
        final pdLord = pd['pratyantardashaLord']! as String;
        if ({mahaLord, antarLord, pdLord}.length == 3) {
          return (mahaLord, antarLord, pdLord);
        }
      }
    }
  }
  throw StateError('No distinct three-lord chain found');
}
