import 'package:astro_logic/src/kp/kp_event_judgment_engine.dart';
import 'package:astro_logic/src/kp/kp_foundation_engine.dart';
import 'package:astro_logic/src/kp/kp_horary_confirmation_engine.dart';
import 'package:astro_logic/src/kp/kp_house_evidence_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('promise plus primary cusp sub-lord standard RP overlap caps at moderate', () {
    final matrix = _matrix(<String, List<int>>{
      for (final planet in KpFoundationEngine.vimshottariSequence)
        planet: planet == 'ketu' ? const [2, 7, 11] : const <int>[],
    });
    final judgment = _judgment(matrix, subLord: 'ketu');
    final result = KpHoraryTimingConfirmationEngine.build(
      topic: KpEventTopic.marriage,
      eventJudgment: judgment,
      horaryHouseEvidence: matrix,
      queryMomentRulingPlanets: _ruling(
        ascStar: 'ketu',
        ascSign: 'venus',
        moonStar: 'sun',
        moonSign: 'moon',
      ),
      queryUtc: DateTime.utc(2026, 8, 11, 10),
    );

    expect(judgment.state, KpEventJudgmentState.promise);
    expect(
      result.state,
      KpHoraryTimingConfirmationState.corroboratedForPractitionerReview,
    );
    expect(result.confidenceCeiling, KpHoraryConfidenceCeiling.moderate);
    expect(result.primaryCuspSubLordFruitfulOverlap, isTrue);
    expect(result.toJson()['natalDashaUsed'], isFalse);
    expect(result.toJson()['exactEventDateClaimed'], isFalse);
  });

  test('detrimental-only standard RP preserves contradiction', () {
    final matrix = _matrix(<String, List<int>>{
      for (final planet in KpFoundationEngine.vimshottariSequence)
        planet: planet == 'ketu'
            ? const [2, 7, 11]
            : planet == 'mars'
                ? const [1, 6, 10]
                : const <int>[],
    });
    final judgment = _judgment(matrix, subLord: 'ketu');
    final result = KpHoraryTimingConfirmationEngine.build(
      topic: KpEventTopic.marriage,
      eventJudgment: judgment,
      horaryHouseEvidence: matrix,
      queryMomentRulingPlanets: _ruling(
        ascStar: 'ketu',
        ascSign: 'mars',
        moonStar: 'sun',
        moonSign: 'moon',
      ),
      queryUtc: DateTime.utc(2026, 8, 11, 10),
    );

    expect(result.state, KpHoraryTimingConfirmationState.contradictory);
    expect(result.confidenceCeiling, KpHoraryConfidenceCeiling.low);
    expect(result.detrimentalStandardPlanets, contains('mars'));
  });

  test('fruitful RP without primary cusp sub-lord overlap remains partial', () {
    final matrix = _matrix(<String, List<int>>{
      for (final planet in KpFoundationEngine.vimshottariSequence)
        planet: planet == 'ketu' || planet == 'venus'
            ? const [2, 7, 11]
            : const <int>[],
    });
    final judgment = _judgment(matrix, subLord: 'ketu');
    final result = KpHoraryTimingConfirmationEngine.build(
      topic: KpEventTopic.marriage,
      eventJudgment: judgment,
      horaryHouseEvidence: matrix,
      queryMomentRulingPlanets: _ruling(
        ascStar: 'venus',
        ascSign: 'sun',
        moonStar: 'moon',
        moonSign: 'mercury',
      ),
      queryUtc: DateTime.utc(2026, 8, 11, 10),
    );

    expect(result.state, KpHoraryTimingConfirmationState.partialCorroboration);
    expect(result.confidenceCeiling, KpHoraryConfidenceCeiling.low);
    expect(result.primaryCuspSubLordRpOverlap, isFalse);
    expect(result.fruitfulStandardPlanets, contains('venus'));
  });

  test('denial is not eligible for RP timing promotion', () {
    final matrix = _matrix(<String, List<int>>{
      for (final planet in KpFoundationEngine.vimshottariSequence)
        planet: const [1, 6, 10],
    });
    final judgment = _judgment(matrix, subLord: 'ketu');
    final result = KpHoraryTimingConfirmationEngine.build(
      topic: KpEventTopic.marriage,
      eventJudgment: judgment,
      horaryHouseEvidence: matrix,
      queryMomentRulingPlanets: _ruling(
        ascStar: 'ketu',
        ascSign: 'ketu',
        moonStar: 'ketu',
        moonSign: 'ketu',
      ),
      queryUtc: DateTime.utc(2026, 8, 11, 10),
    );

    expect(judgment.state, KpEventJudgmentState.denial);
    expect(result.state, KpHoraryTimingConfirmationState.notEligible);
    expect(result.confidenceCeiling, KpHoraryConfidenceCeiling.none);
  });

  test('day lord and sub-lord RP roles stay audit-only', () {
    final matrix = _matrix(<String, List<int>>{
      for (final planet in KpFoundationEngine.vimshottariSequence)
        planet: const [2, 7, 11],
    });
    final judgment = _judgment(matrix, subLord: 'ketu');
    final result = KpHoraryTimingConfirmationEngine.build(
      topic: KpEventTopic.marriage,
      eventJudgment: judgment,
      horaryHouseEvidence: matrix,
      queryMomentRulingPlanets: _ruling(
        ascStar: 'ketu',
        ascSign: 'venus',
        moonStar: 'moon',
        moonSign: 'sun',
      ),
      queryUtc: DateTime.utc(2026, 8, 11, 10),
    );

    final excluded = result.rulingPlanetEvidence
        .where((value) => !value.usedForConfirmation)
        .map((value) => value.role)
        .toSet();
    expect(excluded, contains('ascendantSubLord'));
    expect(excluded, contains('moonSubLord'));
    expect(excluded, contains('dayLord'));
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

KpRulingPlanetPanel _ruling({
  required String ascStar,
  required String ascSign,
  required String moonStar,
  required String moonSign,
}) =>
    KpRulingPlanetPanel(
      ruleVersion: KpFoundationEngine.rulingPlanetRuleVersion,
      roles: <KpRulingPlanetRole>[
        const KpRulingPlanetRole(
          rank: 1,
          role: 'ascendantSubLord',
          planet: 'rahu',
        ),
        KpRulingPlanetRole(rank: 2, role: 'ascendantStarLord', planet: ascStar),
        KpRulingPlanetRole(rank: 3, role: 'moonStarLord', planet: moonStar),
        KpRulingPlanetRole(rank: 4, role: 'ascendantSignLord', planet: ascSign),
        KpRulingPlanetRole(rank: 5, role: 'moonSignLord', planet: moonSign),
        const KpRulingPlanetRole(
          rank: 6,
          role: 'moonSubLord',
          planet: 'rahu',
        ),
        const KpRulingPlanetRole(rank: 7, role: 'dayLord', planet: 'mars'),
      ],
      uniquePlanets: <String>{
        'rahu',
        ascStar,
        moonStar,
        ascSign,
        moonSign,
        'mars',
      }.toList(growable: false),
    );

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
