import 'package:astro_logic/src/kp/kp_dasha_timing_engine.dart';
import 'package:astro_logic/src/kp/kp_event_judgment_engine.dart';
import 'package:astro_logic/src/kp/kp_foundation_engine.dart';
import 'package:astro_logic/src/kp/kp_house_evidence_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('supportive profile builds 729 DBA windows at exact nakshatra start', () {
    final matrix = _matrix(const [2, 7, 11]);
    final judgment = KpEventJudgmentEngine.judge(
      topic: KpEventTopic.marriage,
      cusps: _cusps(primaryHouse: 7, subLord: 'ketu'),
      houseEvidence: matrix,
    );
    final result = KpDashaTimingEngine.build(
      topic: KpEventTopic.marriage,
      eventJudgment: judgment,
      houseEvidence: matrix,
      moonSiderealLongitude: 0,
      birthUtc: DateTime.utc(2000, 1, 1),
      referenceUtc: DateTime.utc(2026, 8, 11),
    );

    expect(result.windows, hasLength(729));
    expect(result.gateState,
        KpDashaTimingGateState.openForPractitionerReview);
    expect(result.supportiveWindowCount, 729);
    expect(result.conflictingWindowCount, 0);
    expect(result.windows.first.dashaLord, 'ketu');
    expect(result.windows.first.bhuktiLord, 'ketu');
    expect(result.windows.first.antaraLord, 'ketu');
    expect(result.windows.first.conductiveCoverage, [2, 7, 11]);
    expect(result.nextSupportiveWindows(), isNotEmpty);
    expect(result.toJson()['transitConfirmationIncluded'], isFalse);
    expect(result.toJson()['rulingPlanetConfirmationIncluded'], isFalse);
  });

  test('detrimental chart blocks timing promotion but preserves period evidence', () {
    final matrix = _matrix(const [1, 6, 10]);
    final judgment = KpEventJudgmentEngine.judge(
      topic: KpEventTopic.marriage,
      cusps: _cusps(primaryHouse: 7, subLord: 'ketu'),
      houseEvidence: matrix,
    );
    final result = KpDashaTimingEngine.build(
      topic: KpEventTopic.marriage,
      eventJudgment: judgment,
      houseEvidence: matrix,
      moonSiderealLongitude: 0,
      birthUtc: DateTime.utc(2000, 1, 1),
      referenceUtc: DateTime.utc(2026, 8, 11),
    );

    expect(judgment.state, KpEventJudgmentState.denial);
    expect(result.gateState, KpDashaTimingGateState.blockedByDenial);
    expect(result.windows, hasLength(729));
    expect(result.conflictingWindowCount, 729);
    expect(result.nextSupportiveWindows(), isEmpty);
    expect(result.windows.first.detrimentalCoverage, [1, 6, 10]);
  });

  test('mixed conductive and detrimental evidence stays conflicting', () {
    final matrix = _matrix(const [2, 7, 11, 1]);
    final judgment = KpEventJudgmentEngine.judge(
      topic: KpEventTopic.marriage,
      cusps: _cusps(primaryHouse: 7, subLord: 'ketu'),
      houseEvidence: matrix,
    );
    final result = KpDashaTimingEngine.build(
      topic: KpEventTopic.marriage,
      eventJudgment: judgment,
      houseEvidence: matrix,
      moonSiderealLongitude: 0,
      birthUtc: DateTime.utc(2000, 1, 1),
      referenceUtc: DateTime.utc(2026, 8, 11),
    );

    expect(judgment.state, KpEventJudgmentState.insufficientEvidence);
    expect(
      result.gateState,
      KpDashaTimingGateState.blockedByInsufficientChartEvidence,
    );
    expect(result.supportiveWindowCount, 0);
    expect(result.conflictingWindowCount, 729);
    expect(result.windows.first.conductiveCoverage, [2, 7, 11]);
    expect(result.windows.first.detrimentalCoverage, [1]);
  });

  test('incomplete three-lord house coverage never becomes supportive', () {
    final matrix = _matrixByPlanet(<String, List<int>>{
      'ketu': const [2],
      'venus': const [7],
      'sun': const [2],
      'moon': const [2],
      'mars': const [2],
      'rahu': const [2],
      'jupiter': const [2],
      'saturn': const [2],
      'mercury': const [2],
    });
    final judgment = KpEventJudgmentEngine.judge(
      topic: KpEventTopic.marriage,
      cusps: _cusps(primaryHouse: 7, subLord: 'ketu'),
      houseEvidence: matrix,
    );
    final result = KpDashaTimingEngine.build(
      topic: KpEventTopic.marriage,
      eventJudgment: judgment,
      houseEvidence: matrix,
      moonSiderealLongitude: 0,
      birthUtc: DateTime.utc(2000, 1, 1),
      referenceUtc: DateTime.utc(2000, 1, 2),
    );

    expect(result.windows.first.state,
        KpDashaTimingWindowState.conflicting);
    expect(result.windows.first.conductiveCoverage, [2]);
    expect(result.supportiveWindowCount, 0);
  });
}

KpHouseEvidenceMatrix _matrix(List<int> houses) => _matrixByPlanet(
      <String, List<int>>{
        for (final planet in KpFoundationEngine.vimshottariSequence)
          planet: houses,
      },
    );

KpHouseEvidenceMatrix _matrixByPlanet(Map<String, List<int>> housesByPlanet) {
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
