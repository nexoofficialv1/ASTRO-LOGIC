import 'package:astro_logic/src/vedic/vimshottari_dasha_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('builds a complete Revati Mercury Vimshottari cycle', () {
    final birth = DateTime.utc(1984, 3, 12, 18, 42);
    final result = VimshottariDashaEngine.calculate(
      moonSiderealLongitude: 354.0,
      birthUtc: birth,
    );
    final mahadashas =
        (result['mahadashas']! as List).cast<Map<String, Object?>>();

    expect(result['ruleVersion'], 'vimshottari-calendar-v2');
    expect(result['birthNakshatra'], 'Revati');
    expect(result['startingMahadashaLord'], 'mercury');
    expect(result['balanceAtBirthYears'] as double, closeTo(7.65, 0.000001));
    expect(mahadashas, hasLength(9));
    expect(mahadashas.expand(
      (value) => value['antardashas']! as List,
    ), hasLength(81));
    final allAntardashas = mahadashas
        .expand((value) => value['antardashas']! as List)
        .cast<Map<String, Object?>>();
    expect(
      allAntardashas.expand(
        (value) => value['pratyantardashas']! as List,
      ),
      hasLength(729),
    );
    expect(
      mahadashas.where((value) => value['activeAtBirth'] == true),
      hasLength(1),
    );
    final firstAntardashas =
        (mahadashas.first['antardashas']! as List)
            .cast<Map<String, Object?>>();
    expect(
      firstAntardashas.where((value) => value['activeAtBirth'] == true),
      hasLength(1),
    );
    expect(firstAntardashas.first['mahadashaLord'], 'mercury');
    expect(firstAntardashas.first['antardashaLord'], 'mercury');
    expect(
      firstAntardashas.last['endUtc'],
      mahadashas.first['endUtc'],
    );
    final firstPratyantardashas =
        (firstAntardashas.first['pratyantardashas']! as List)
            .cast<Map<String, Object?>>();
    expect(firstPratyantardashas, hasLength(9));
    expect(firstPratyantardashas.first['pratyantardashaLord'], 'mercury');
    expect(
      firstPratyantardashas.last['endUtc'],
      firstAntardashas.first['endUtc'],
    );
    expect(
      allAntardashas
          .expand((value) => value['pratyantardashas']! as List)
          .cast<Map<String, Object?>>()
          .where((value) => value['activeAtBirth'] == true),
      hasLength(1),
    );
  });

  test('normalizes Moon longitude before selecting the starting lord', () {
    final result = VimshottariDashaEngine.calculate(
      moonSiderealLongitude: -6.0,
      birthUtc: DateTime.utc(2000),
    );

    expect(result['moonSiderealLongitude'], 354.0);
    expect(result['startingMahadashaLord'], 'mercury');
  });

  test('rejects a non-finite Moon longitude', () {
    expect(
      () => VimshottariDashaEngine.calculate(
        moonSiderealLongitude: double.nan,
        birthUtc: DateTime.utc(2000),
      ),
      throwsArgumentError,
    );
  });
}
