import 'package:astro_logic/src/kp/kp_foundation_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('KP star/sub arithmetic', () {
    test('Ashwini starts with Ketu sub and then Venus', () {
      final first = KpFoundationEngine.classify(0.5);
      final second = KpFoundationEngine.classify(1.0);

      expect(first.nakshatra, 'Ashwini');
      expect(first.starLord, 'ketu');
      expect(first.subLord, 'ketu');
      expect(second.starLord, 'ketu');
      expect(second.subLord, 'venus');
    });

    test('exact Bharani boundary starts Venus star and Venus sub', () {
      final point = KpFoundationEngine.classify(13 + 20 / 60);
      expect(point.nakshatra, 'Bharani');
      expect(point.starLord, 'venus');
      expect(point.subLord, 'venus');
    });

    test('sub boundaries are exact Vimshottari proportions', () {
      final point = KpFoundationEngine.classify(0.1);
      expect(point.subStartLongitude, closeTo(0, 1e-12));
      expect(point.subEndLongitude, closeTo(7 / 9, 1e-12));
    });

    test('normalizes longitudes but rejects non-finite input', () {
      expect(KpFoundationEngine.classify(-1).siderealLongitude, 359);
      expect(
        () => KpFoundationEngine.classify(double.nan),
        throwsArgumentError,
      );
    });
  });

  test('cusp framework requires exactly twelve supplied cusps', () {
    final cusps = KpFoundationEngine.classifyCusps(
      List<double>.generate(12, (index) => index * 30.0),
    );
    expect(cusps, hasLength(12));
    expect(cusps.first.house, 1);
    expect(cusps.last.house, 12);
    expect(
      () => KpFoundationEngine.classifyCusps(const [0, 30]),
      throwsArgumentError,
    );
  });

  test('ruling-planet panel preserves roles and collapses duplicate planets', () {
    final panel = KpFoundationEngine.rulingPlanets(
      ascendantSiderealLongitude: 0.5,
      moonSiderealLongitude: 13 + 20 / 60,
      weekday: DateTime.friday,
    );
    expect(panel.roles, hasLength(7));
    expect(panel.roles.first.role, 'ascendantSubLord');
    expect(panel.roles.first.planet, 'ketu');
    expect(panel.uniquePlanets.toSet().length, panel.uniquePlanets.length);
  });

  test('four-level significator keeps evidence hierarchy without judgment', () {
    final profile = KpFoundationEngine.buildSignificator(
      planet: 'Mars',
      occupiedHouse: 11,
      ownedHouses: const [1, 8],
      starLord: 'Venus',
      starLordOccupiedHouse: 2,
      starLordOwnedHouses: const [3, 7],
    );
    expect(profile.levels.map((level) => level.level), [1, 2, 3, 4]);
    expect(profile.combinedHouses, [2, 11, 3, 7, 1, 8]);
  });
}
