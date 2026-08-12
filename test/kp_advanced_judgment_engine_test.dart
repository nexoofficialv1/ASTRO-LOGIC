import 'package:astro_logic/src/kp/kp_event_judgment_engine.dart';
import 'package:astro_logic/src/kp/kp_foundation_engine.dart';
import 'package:astro_logic/src/kp/kp_house_evidence_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('house topology handles zodiac wrap without equal-house assumptions', () {
    final cusps = <double>[
      350, 20, 50, 80, 110, 140, 170, 200, 230, 260, 290, 320,
    ];
    expect(
      KpHouseEvidenceEngine.houseForLongitude(
        longitude: 355,
        cuspLongitudes: cusps,
      ),
      1,
    );
    expect(
      KpHouseEvidenceEngine.houseForLongitude(
        longitude: 5,
        cuspLongitudes: cusps,
      ),
      1,
    );
    expect(
      KpHouseEvidenceEngine.houseForLongitude(
        longitude: 25,
        cuspLongitudes: cusps,
      ),
      2,
    );
  });

  test('native-style evidence derives occupancy, ownership and four levels', () {
    final cuspValues = List<double>.generate(12, (index) => index * 30.0);
    final cusps = KpFoundationEngine.classifyCusps(cuspValues);
    final planetValues = <String, double>{
      'ketu': 5,
      'venus': 35,
      'sun': 65,
      'moon': 95,
      'mars': 125,
      'rahu': 155,
      'jupiter': 185,
      'saturn': 215,
      'mercury': 245,
    };
    final evidence = KpHouseEvidenceEngine.build(
      planetClassifications: <String, KpPointClassification>{
        for (final entry in planetValues.entries)
          entry.key: KpFoundationEngine.classify(entry.value),
      },
      cusps: cusps,
    );

    expect(evidence.planet('venus').occupiedHouse, 2);
    expect(evidence.planet('rahu').ownedHouses, isEmpty);
    expect(evidence.planet('ketu').significator.levels, hasLength(4));
    expect(evidence.cuspLords, hasLength(12));
  });

  test('marriage cusp sub-lord produces source-bounded promise', () {
    final result = KpEventJudgmentEngine.judge(
      topic: KpEventTopic.marriage,
      cusps: _cusps(primaryHouse: 7, subLord: 'venus'),
      houseEvidence: _matrix('venus', const [7]),
    );
    expect(result.state, KpEventJudgmentState.promise);
    expect(result.ruleProfile.conductiveHouses, [2, 7, 11]);
    expect(result.evidenceClarity, 'Medium');
    expect(result.toJson()['realWorldGuarantee'], isFalse);
  });

  test('detrimental-only marriage evidence is denial review', () {
    final result = KpEventJudgmentEngine.judge(
      topic: KpEventTopic.marriage,
      cusps: _cusps(primaryHouse: 7, subLord: 'venus'),
      houseEvidence: _matrix('venus', const [6]),
    );
    expect(result.state, KpEventJudgmentState.denial);
  });

  test('mixed conductive and detrimental evidence stays insufficient', () {
    final result = KpEventJudgmentEngine.judge(
      topic: KpEventTopic.marriage,
      cusps: _cusps(primaryHouse: 7, subLord: 'venus'),
      houseEvidence: _matrix('venus', const [7, 6]),
    );
    expect(result.state, KpEventJudgmentState.insufficientEvidence);
    expect(result.evidenceClarity, 'Low');
  });

  test('children profile uses fifth cusp and 2/5/11 group', () {
    final result = KpEventJudgmentEngine.judge(
      topic: KpEventTopic.children,
      cusps: _cusps(primaryHouse: 5, subLord: 'jupiter'),
      houseEvidence: _matrix('jupiter', const [2]),
    );
    expect(result.state, KpEventJudgmentState.promise);
    expect(result.ruleProfile.primaryCusp, 5);
    expect(result.ruleProfile.conductiveHouses, [2, 5, 11]);
  });
}

KpHouseEvidenceMatrix _matrix(String planet, List<int> houses) {
  final profile = KpSignificatorProfile(
    ruleVersion: KpFoundationEngine.significatorRuleVersion,
    planet: planet,
    starLord: planet,
    levels: <KpSignificatorLevel>[
      KpSignificatorLevel(level: 1, source: 'starLordOccupancy', houses: houses),
      const KpSignificatorLevel(level: 2, source: 'planetOccupancy', houses: []),
      const KpSignificatorLevel(level: 3, source: 'starLordOwnership', houses: []),
      const KpSignificatorLevel(level: 4, source: 'planetOwnership', houses: []),
    ],
  );
  return KpHouseEvidenceMatrix(
    profileVersion: KpHouseEvidenceEngine.profileVersion,
    cuspLords: const <int, String>{},
    occupantsByHouse: const <int, List<String>>{},
    planets: <String, KpPlanetHouseEvidence>{
      planet: KpPlanetHouseEvidence(
        planet: planet,
        occupiedHouse: 1,
        ownedHouses: const [],
        starLord: planet,
        starLordOccupiedHouse: 1,
        starLordOwnedHouses: const [],
        significator: profile,
      ),
    },
  );
}

List<KpCuspClassification> _cusps({
  required int primaryHouse,
  required String subLord,
}) {
  return List<KpCuspClassification>.generate(12, (index) {
    final base = KpFoundationEngine.classify(index * 30.0);
    final point = KpPointClassification(
      siderealLongitude: base.siderealLongitude,
      signIndex: base.signIndex,
      sign: base.sign,
      signLord: base.signLord,
      nakshatraIndex: base.nakshatraIndex,
      nakshatra: base.nakshatra,
      starLord: base.starLord,
      subLord: index + 1 == primaryHouse ? subLord : base.subLord,
      subIndexWithinStar: base.subIndexWithinStar,
      starStartLongitude: base.starStartLongitude,
      starEndLongitude: base.starEndLongitude,
      subStartLongitude: base.subStartLongitude,
      subEndLongitude: base.subEndLongitude,
    );
    return KpCuspClassification(house: index + 1, point: point);
  }, growable: false);
}
