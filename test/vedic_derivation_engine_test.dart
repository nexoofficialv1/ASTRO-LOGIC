import 'package:astro_logic/src/ephemeris/ephemeris_provider.dart';
import 'package:astro_logic/src/models/calculation_snapshot.dart';
import 'package:astro_logic/src/vedic/vedic_derivation_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('derives D1, D9, D10, Nakshatra, Tithi and Ketu from fixed evidence',
      () async {
    final snapshot = CalculationSnapshot(
      id: 1,
      clientId: 1,
      birthRecordId: 1,
      label: 'Golden fixture',
      snapshotKind: 'input',
      schemaVersion: 'input-schema-v1',
      inputHash: 'fixture',
      input: const {
        'utcDateTime': '1984-03-12T18:42:00.000Z',
        'utcOffsetMinutes': 330,
        'latitude': 23.22,
        'longitude': 88.37,
      },
      settings: const {
        'ayanamsha': 'lahiri',
        'lunarNodeMode': 'trueNode',
      },
      createdAt: DateTime.utc(2026, 8, 5),
    );
    final engine = VedicDerivationEngine(_FixedEphemeris());
    expect(engine.outputSchemaVersion, 'vedic-chart-v10');
    final result = await engine.calculate(snapshot);
    final metadata = result['metadata']! as Map<String, Object?>;
    final ascendant = result['ascendant']! as Map<String, Object?>;
    final panchanga = result['panchanga']! as Map<String, Object?>;
    final divisionalCharts =
        result['divisionalCharts']! as Map<String, Object?>;
    final d9 = divisionalCharts['d9']! as Map<String, Object?>;
    final d9Planets = (d9['planets']! as List).cast<Map<String, Object?>>();
    final d10 = divisionalCharts['d10']! as Map<String, Object?>;
    final d10Planets = (d10['planets']! as List).cast<Map<String, Object?>>();
    final vimshottari = result['vimshottari']! as Map<String, Object?>;
    final mahadashas =
        (vimshottari['mahadashas']! as List).cast<Map<String, Object?>>();
    final planets =
        (result['planets']! as List).cast<Map<String, Object?>>();
    final sun = planets.firstWhere((value) => value['body'] == 'sun');
    final mercury =
        planets.firstWhere((value) => value['body'] == 'mercury');
    final ketu = planets.firstWhere((value) => value['body'] == 'ketu');

    expect(metadata['sunHourAngleHours'], closeTo(6.0, 1e-12));
    expect(metadata['tribhagaIsDay'], isFalse);
    expect(metadata['tribhagaThird'], 2);
    expect(metadata['tribhagaPeriodStartUtc'], '1984-03-12T13:54:00.000Z');
    expect(metadata['tribhagaPeriodEndUtc'], '1984-03-13T01:54:00.000Z');
    expect(metadata['varshaMasaDinaHoraProfile'], 'siderealSolarIngressAstrologicalDayV1');
    expect(metadata['dinaLord'], 'moon');
    expect(metadata['varshaLord'], 'sun');
    expect(metadata['masaLord'], 'moon');
    expect(metadata['horaLord'], 'jupiter');
    expect(metadata['horaNumber'], 17);
    expect(metadata['horaPeriod'], 'night');
    expect(metadata['astrologicalDayStartUtc'], '1984-03-12T00:42:00.000Z');
    expect(metadata['varshaIngressUtc'], '1984-03-11T18:42:00.000Z');
    expect(metadata['varshaAstrologicalDayStartUtc'], '1984-03-11T06:42:00.000Z');
    expect(metadata['masaIngressUtc'], '1984-03-12T06:42:00.000Z');
    expect(metadata['masaAstrologicalDayStartUtc'], '1984-03-12T00:42:00.000Z');
    expect(ascendant['siderealLongitude'], 220.0);
    expect(ascendant['signIndex'], 7);
    expect(sun['siderealLongitude'], 330.0);
    expect(sun['signIndex'], 11);
    expect(sun['nakshatra'], 'Purva Bhadrapada');
    expect(sun['pada'], 4);
    expect(sun['navamsaSignIndex'], 3);
    expect(sun['dashamsaSignIndex'], 7);
    expect(mercury['retrograde'], isTrue);
    expect(mercury['longitudeSpeedPerDay'], closeTo(-0.1, 1e-12));
    expect(sun['longitudeSpeedPerDay'], closeTo(1.0, 1e-12));
    expect(sun['eclipticLatitude'], closeTo(0.0, 1e-12));
    expect(mercury['eclipticLatitude'], closeTo(0.0, 1e-12));
    expect(ketu['siderealLongitude'], 256.0);
    expect(panchanga['tithiNumber'], 3);
    expect(panchanga['paksha'], 'shukla');
    expect(panchanga['yogaNumber'], 25);
    expect(d9['division'], 9);
    expect((d9['ascendant']! as Map)['signIndex'], 6);
    expect(
      d9Planets.firstWhere((value) => value['body'] == 'sun')['signIndex'],
      3,
    );
    expect(d10['division'], 10);
    expect(d10['calculationProfile'], 'bphs-dashamsa-odd-self-even-ninth-v1');
    expect((d10['ascendant']! as Map)['signIndex'], 6);
    expect(
      d10Planets.firstWhere((value) => value['body'] == 'sun')['signIndex'],
      7,
    );
    expect(vimshottari['birthNakshatra'], 'Revati');
    expect(vimshottari['startingMahadashaLord'], 'mercury');
    expect(mahadashas, hasLength(9));
    expect(
      mahadashas.expand((value) => value['antardashas']! as List),
      hasLength(81),
    );
    expect(
      mahadashas
          .expand((value) => value['antardashas']! as List)
          .cast<Map<String, Object?>>()
          .expand((value) => value['pratyantardashas']! as List),
      hasLength(729),
    );
  });
}

class _FixedEphemeris implements EphemerisProvider {
  @override
  String get engineId => 'fixed-test-evidence';

  @override
  String get engineVersion => '1';

  @override
  Future<EphemerisFrame> calculate(EphemerisRequest request) async =>
      const EphemerisFrame(
        ayanamshaDegrees: 24.0,
        tropicalAscendant: 244.0,
        sunHourAngleHours: 6.0,
        tribhagaIsDay: false,
        tribhagaThird: 2,
        tribhagaPeriodStartOffsetDays: -0.2,
        tribhagaPeriodEndOffsetDays: 0.3,
        astrologicalDayStartOffsetDays: -0.75,
        varshaIngressOffsetDays: -1.0,
        varshaDayStartOffsetDays: -1.5,
        masaIngressOffsetDays: -0.5,
        masaDayStartOffsetDays: -0.75,
        positions: {
          CelestialBody.sun: EphemerisPosition(
            tropicalLongitude: 354.0,
            eclipticLatitude: 0.0,
            longitudeSpeed: 1.0,
          ),
          CelestialBody.moon: EphemerisPosition(
            tropicalLongitude: 18.0,
            eclipticLatitude: 0.0,
            longitudeSpeed: 13.0,
          ),
          CelestialBody.mars: EphemerisPosition(
            tropicalLongitude: 250.0,
            eclipticLatitude: 0.0,
            longitudeSpeed: 0.5,
          ),
          CelestialBody.mercury: EphemerisPosition(
            tropicalLongitude: 10.0,
            eclipticLatitude: 0.0,
            longitudeSpeed: -0.1,
          ),
          CelestialBody.jupiter: EphemerisPosition(
            tropicalLongitude: 280.0,
            eclipticLatitude: 0.0,
            longitudeSpeed: 0.1,
          ),
          CelestialBody.venus: EphemerisPosition(
            tropicalLongitude: 320.0,
            eclipticLatitude: 0.0,
            longitudeSpeed: 1.0,
          ),
          CelestialBody.saturn: EphemerisPosition(
            tropicalLongitude: 220.0,
            eclipticLatitude: 0.0,
            longitudeSpeed: 0.05,
          ),
          CelestialBody.rahu: EphemerisPosition(
            tropicalLongitude: 100.0,
            eclipticLatitude: 0.0,
            longitudeSpeed: -0.05,
          ),
        },
      );
}
