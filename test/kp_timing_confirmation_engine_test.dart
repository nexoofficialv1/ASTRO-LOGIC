import 'package:astro_logic/src/kp/kp_dasha_timing_engine.dart';
import 'package:astro_logic/src/kp/kp_event_judgment_engine.dart';
import 'package:astro_logic/src/kp/kp_foundation_engine.dart';
import 'package:astro_logic/src/kp/kp_house_evidence_engine.dart';
import 'package:astro_logic/src/kp/kp_timing_confirmation_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('supportive DBA plus transit and standard RP overlap caps at moderate', () {
    final matrix = _matrix(<String, List<int>>{
      for (final planet in KpFoundationEngine.vimshottariSequence)
        planet: const [2, 7, 11],
    });
    final judgment = _judgment(matrix, subLord: 'ketu');
    final reference = DateTime.utc(2000, 1, 2);
    final timing = _timing(matrix, judgment, reference);
    final result = KpTimingConfirmationEngine.build(
      topic: KpEventTopic.marriage,
      eventJudgment: judgment,
      timingSynthesis: timing,
      natalHouseEvidence: matrix,
      referenceTransitPoints: _transits('ketu'),
      referenceRulingPlanets: _ruling('ketu'),
      referenceUtc: reference,
    );

    expect(result.state,
        KpTimingConfirmationState.confirmedForPractitionerReview);
    expect(result.confidenceCeiling, KpTimingConfidenceCeiling.moderate);
    expect(result.allDbaTransitStarLordsFruitful, isTrue);
    expect(result.allLuminaryTransitStarLordsFruitful, isTrue);
    expect(result.fruitfulRulingPlanetOverlapCount, greaterThan(0));
    expect(result.toJson()['maximumConfidenceCeiling'], 'moderate');
    expect(result.toJson()['automaticExactEventDate'], isFalse);
  });

  test('detrimental-only transit star lord preserves contradiction', () {
    final matrix = _matrix(<String, List<int>>{
      for (final planet in KpFoundationEngine.vimshottariSequence)
        planet: planet == 'mars' ? const [1] : const [2, 7, 11],
    });
    final judgment = _judgment(matrix, subLord: 'ketu');
    final reference = DateTime.utc(2000, 1, 2);
    final timing = _timing(matrix, judgment, reference);
    final result = KpTimingConfirmationEngine.build(
      topic: KpEventTopic.marriage,
      eventJudgment: judgment,
      timingSynthesis: timing,
      natalHouseEvidence: matrix,
      referenceTransitPoints: _transits('mars'),
      referenceRulingPlanets: _ruling('ketu'),
      referenceUtc: reference,
    );

    expect(result.state, KpTimingConfirmationState.contradictory);
    expect(result.confidenceCeiling, KpTimingConfidenceCeiling.low);
    expect(result.contradictionPresent, isTrue);
  });

  test('partial confirmation does not upgrade to confirmed', () {
    final matrix = _matrix(<String, List<int>>{
      for (final planet in KpFoundationEngine.vimshottariSequence)
        planet: planet == 'ketu' ? const [2, 7, 11] : const <int>[],
    });
    final judgment = _judgment(matrix, subLord: 'ketu');
    final reference = DateTime.utc(2000, 1, 2);
    final timing = _timing(matrix, judgment, reference);
    final transits = _transits('ketu');
    transits['sun'] = _pointWithStarLord('venus');
    transits['moon'] = _pointWithStarLord('venus');
    final result = KpTimingConfirmationEngine.build(
      topic: KpEventTopic.marriage,
      eventJudgment: judgment,
      timingSynthesis: timing,
      natalHouseEvidence: matrix,
      referenceTransitPoints: transits,
      referenceRulingPlanets: _ruling('ketu'),
      referenceUtc: reference,
    );

    expect(result.state, KpTimingConfirmationState.partialConfirmation);
    expect(result.confidenceCeiling, KpTimingConfidenceCeiling.low);
    expect(result.allDbaTransitStarLordsFruitful, isTrue);
    expect(result.allLuminaryTransitStarLordsFruitful, isFalse);
  });

  test('denial gate prevents confirmation promotion', () {
    final matrix = _matrix(<String, List<int>>{
      for (final planet in KpFoundationEngine.vimshottariSequence)
        planet: const [1, 6, 10],
    });
    final judgment = _judgment(matrix, subLord: 'ketu');
    final reference = DateTime.utc(2000, 1, 2);
    final timing = _timing(matrix, judgment, reference);
    final result = KpTimingConfirmationEngine.build(
      topic: KpEventTopic.marriage,
      eventJudgment: judgment,
      timingSynthesis: timing,
      natalHouseEvidence: matrix,
      referenceTransitPoints: _transits('ketu'),
      referenceRulingPlanets: _ruling('ketu'),
      referenceUtc: reference,
    );

    expect(judgment.state, KpEventJudgmentState.denial);
    expect(result.state, KpTimingConfirmationState.notEligible);
    expect(result.confidenceCeiling, KpTimingConfidenceCeiling.none);
  });

  test('day lord and expanded sub-lord RP roles are audit-only', () {
    final matrix = _matrix(<String, List<int>>{
      for (final planet in KpFoundationEngine.vimshottariSequence)
        planet: const [2, 7, 11],
    });
    final judgment = _judgment(matrix, subLord: 'ketu');
    final reference = DateTime.utc(2000, 1, 2);
    final timing = _timing(matrix, judgment, reference);
    final result = KpTimingConfirmationEngine.build(
      topic: KpEventTopic.marriage,
      eventJudgment: judgment,
      timingSynthesis: timing,
      natalHouseEvidence: matrix,
      referenceTransitPoints: _transits('ketu'),
      referenceRulingPlanets: _ruling('ketu'),
      referenceUtc: reference,
    );

    final excluded = result.rulingPlanetEvidence
        .where((value) => !value.usedForConfirmation)
        .map((value) => value.role)
        .toSet();
    expect(excluded, contains('dayLord'));
    expect(excluded, contains('ascendantSubLord'));
    expect(excluded, contains('moonSubLord'));
  });
}

KpEventJudgment _judgment(
  KpHouseEvidenceMatrix matrix, {
  required String subLord,
}) =>
    KpEventJudgmentEngine.judge(
      topic: KpEventTopic.marriage,
      cusps: _cusps(primaryHouse: 7, subLord: subLord),
      houseEvidence: matrix,
    );

KpDashaTimingSynthesis _timing(
  KpHouseEvidenceMatrix matrix,
  KpEventJudgment judgment,
  DateTime reference,
) =>
    KpDashaTimingEngine.build(
      topic: KpEventTopic.marriage,
      eventJudgment: judgment,
      houseEvidence: matrix,
      moonSiderealLongitude: 0,
      birthUtc: DateTime.utc(2000, 1, 1),
      referenceUtc: reference,
    );

Map<String, KpPointClassification> _transits(String starLord) =>
    <String, KpPointClassification>{
      for (final planet in KpFoundationEngine.vimshottariSequence)
        planet: _pointWithStarLord(starLord),
    };

KpRulingPlanetPanel _ruling(String planet) => KpRulingPlanetPanel(
      ruleVersion: KpFoundationEngine.rulingPlanetRuleVersion,
      roles: <KpRulingPlanetRole>[
        KpRulingPlanetRole(rank: 1, role: 'ascendantSubLord', planet: planet),
        KpRulingPlanetRole(rank: 2, role: 'ascendantStarLord', planet: planet),
        KpRulingPlanetRole(rank: 3, role: 'moonStarLord', planet: planet),
        KpRulingPlanetRole(rank: 4, role: 'ascendantSignLord', planet: planet),
        KpRulingPlanetRole(rank: 5, role: 'moonSignLord', planet: planet),
        KpRulingPlanetRole(rank: 6, role: 'moonSubLord', planet: planet),
        KpRulingPlanetRole(rank: 7, role: 'dayLord', planet: planet),
      ],
      uniquePlanets: <String>[planet],
    );

KpPointClassification _pointWithStarLord(String lord) {
  final index = KpFoundationEngine.vimshottariSequence.indexOf(lord);
  if (index < 0) throw ArgumentError.value(lord, 'lord');
  return KpFoundationEngine.classify(index * (360 / 27) + 0.1);
}

KpHouseEvidenceMatrix _matrix(Map<String, List<int>> housesByPlanet) {
  final planets = <String, KpPlanetHouseEvidence>{};
  for (final planet in KpFoundationEngine.vimshottariSequence) {
    final houses = housesByPlanet[planet] ?? const <int>[];
    final profile = KpSignificatorProfile(
      ruleVersion: KpFoundationEngine.significatorRuleVersion,
      planet: planet,
      starLord: planet,
      levels: <KpSignificatorLevel>[
        KpSignificatorLevel(
          level: 1,
          source: 'starLordOccupancy',
          houses: houses,
        ),
        const KpSignificatorLevel(
          level: 2,
          source: 'planetOccupancy',
          houses: [],
        ),
        const KpSignificatorLevel(
          level: 3,
          source: 'starLordOwnership',
          houses: [],
        ),
        const KpSignificatorLevel(
          level: 4,
          source: 'planetOwnership',
          houses: [],
        ),
      ],
    );
    planets[planet] = KpPlanetHouseEvidence(
      planet: planet,
      occupiedHouse: 1,
      ownedHouses: const <int>[],
      starLord: planet,
      starLordOccupiedHouse: 1,
      starLordOwnedHouses: const <int>[],
      significator: profile,
    );
  }
  return KpHouseEvidenceMatrix(
    profileVersion: KpHouseEvidenceEngine.profileVersion,
    cuspLords: const <int, String>{},
    occupantsByHouse: const <int, List<String>>{},
    planets: planets,
  );
}

List<KpCuspClassification> _cusps({
  required int primaryHouse,
  required String subLord,
}) =>
    List<KpCuspClassification>.generate(
      12,
      (index) {
        final house = index + 1;
        final point = house == primaryHouse
            ? _pointWithSubLord(subLord)
            : KpFoundationEngine.classify(index * 30 + 0.5);
        return KpCuspClassification(house: house, point: point);
      },
      growable: false,
    );

KpPointClassification _pointWithSubLord(String lord) {
  for (var micro = 0; micro < 360000; micro += 5) {
    final point = KpFoundationEngine.classify(micro / 1000.0);
    if (point.subLord == lord) return point;
  }
  throw StateError('No sub-lord longitude found for $lord');
}
