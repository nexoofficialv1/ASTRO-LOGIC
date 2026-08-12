import 'package:astro_logic/src/models/calculation_output_snapshot.dart';
import 'package:astro_logic/src/vedic/vedic_shadbala_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const engine = VedicShadbalaEngine();

  test('publishes seven classical-planet foundation profiles only', () {
    final results = engine.build(_output());

    expect(results, hasLength(7));
    expect(
      results.map((value) => value.planet).toSet(),
      {'sun', 'moon', 'mars', 'mercury', 'jupiter', 'venus', 'saturn'},
    );
    expect(results.any((value) => value.planet == 'rahu'), isFalse);
    expect(results.any((value) => value.planet == 'ketu'), isFalse);
    expect(
      results.every((value) => value.ruleVersion == 'shadbala-foundation-v10'),
      isTrue,
    );
  });

  test('publishes sixfold aggregate and BPHS required-strength ratio when complete', () {
    final results = engine.build(_output());

    for (final value in results) {
      expect(value.computedComponents, [
        'sthana',
        'dig',
        'kala',
        'cheshta',
        'naisargika',
        'drik',
        'aggregateThresholdEvaluation',
      ]);
      expect(value.missingComponents, isEmpty);
      expect(value.kalaComputedSubcomponents, [
        'nathonnata',
        'paksha',
        'tribhaga',
        'varsha',
        'masa',
        'dina',
        'hora',
        'yuddha',
        'ayana',
      ]);
      expect(value.kalaMissingSubcomponents, isEmpty);
      expect(value.kalaBalaComplete, isTrue);
      expect(value.kalaBalaVirupas,
          closeTo(value.kalaBalaPartialVirupas + value.yuddhaBalaVirupas!, 1e-9));
      expect(value.aggregateAvailable, isTrue);
      expect(
        value.totalShadbalaVirupas,
        closeTo(
          value.sthanaBalaVirupas +
              value.digBalaVirupas +
              value.kalaBalaVirupas! +
              value.cheshtaBalaVirupas! +
              value.naisargikaBalaVirupas +
              value.drikBalaVirupas,
          1e-9,
        ),
      );
      expect(value.totalShadbalaRupas,
          closeTo(value.totalShadbalaVirupas! / 60.0, 1e-9));
      expect(value.requiredStrengthRatio,
          closeTo(value.totalShadbalaVirupas! / value.requiredShadbalaVirupas, 1e-9));
      expect(value.surplusDeficitVirupas,
          closeTo(value.totalShadbalaVirupas! - value.requiredShadbalaVirupas, 1e-9));
      expect(
        value.thresholdStatus,
        value.totalShadbalaVirupas! + 1e-9 >= value.requiredShadbalaVirupas
            ? 'meetsRequired'
            : 'belowRequired',
      );
      expect(value.thresholdProfile, 'bphs27_32_33RequiredTotalV1');
      expect(value.narrativeEn, contains('strength sufficiency'));

    }
  });


  test('uses BPHS 27.32-33 planet-specific required totals', () {
    final results = engine.build(_output());
    double required(String planet) =>
        results.firstWhere((value) => value.planet == planet).requiredShadbalaVirupas;

    expect(required('sun'), 390.0);
    expect(required('moon'), 360.0);
    expect(required('mars'), 300.0);
    expect(required('mercury'), 420.0);
    expect(required('jupiter'), 390.0);
    expect(required('venus'), 330.0);
    expect(required('saturn'), 300.0);
    for (final value in results) {
      expect(value.requiredShadbalaRupas,
          closeTo(value.requiredShadbalaVirupas / 60.0, 1e-9));
    }
  });

  test('Sthana Bala equals its five auditable subcomponents', () {
    final results = engine.build(_output());

    for (final value in results) {
      expect(
        value.sthanaBalaVirupas,
        closeTo(
          value.ucchaBalaVirupas +
              value.saptavargajaBalaVirupas +
              value.ojayugmaBalaVirupas +
              value.kendradiBalaVirupas +
              value.drekkanaBalaVirupas,
          1e-9,
        ),
      );
      expect(value.vargaContributions.map((item) => item.division).toSet(),
          {1, 2, 3, 7, 9, 12, 30});
    }
  });

  test('Sun at exact deep exaltation receives 60 Uccha virupas', () {
    final sun = engine.build(_output()).firstWhere((value) => value.planet == 'sun');

    expect(sun.ucchaBalaVirupas, closeTo(60.0, 1e-9));
    expect(sun.kendradiBalaVirupas, 60.0);
  });

  test('Drekkana and Ojhayugma rules remain transparent', () {
    final results = engine.build(_output());
    final moon = results.firstWhere((value) => value.planet == 'moon');
    final mars = results.firstWhere((value) => value.planet == 'mars');
    final mercury = results.firstWhere((value) => value.planet == 'mercury');

    expect(moon.drekkanaBalaVirupas, 15.0);
    expect(mars.drekkanaBalaVirupas, 15.0);
    expect(mercury.drekkanaBalaVirupas, 15.0);
    expect(moon.ojayugmaBalaVirupas, greaterThanOrEqualTo(15.0));
  });

  test('D1 Moolatrikona contributes 45 virupas in Saptavargaja', () {
    final mars = engine.build(_output()).firstWhere((value) => value.planet == 'mars');
    final d1 = mars.vargaContributions.firstWhere((value) => value.division == 1);

    expect(d1.signIndex, 0);
    expect(d1.relationship, 'moolatrikona');
    expect(d1.virupas, 45.0);
  });

  test('Dig Bala reaches 60 at classical strong angles and 0 opposite them', () {
    final strong = engine.build(_output(
      ascendantLongitude: 0.0,
      overrides: const {
        'sun': 270.0,
        'moon': 90.0,
        'mars': 270.0,
        'mercury': 0.0,
        'jupiter': 0.0,
        'venus': 90.0,
        'saturn': 180.0,
      },
    ));
    for (final value in strong) {
      expect(value.digBalaVirupas, closeTo(60.0, 1e-9),
          reason: value.planet);
    }

    final powerless = engine.build(_output(
      ascendantLongitude: 0.0,
      overrides: const {
        'sun': 90.0,
        'moon': 270.0,
        'mars': 90.0,
        'mercury': 180.0,
        'jupiter': 180.0,
        'venus': 270.0,
        'saturn': 0.0,
      },
    ));
    for (final value in powerless) {
      expect(value.digBalaVirupas, closeTo(0.0, 1e-9),
          reason: value.planet);
    }
  });

  test('Dig Bala uses exact Ascendant longitude rather than whole-sign cusp', () {
    final result = engine.build(_output(
      ascendantLongitude: 15.0,
      overrides: const {'sun': 285.0},
    ));
    final sun = result.firstWhere((value) => value.planet == 'sun');
    expect(sun.digBalaVirupas, closeTo(60.0, 1e-9));
  });

  test('Nathonnata Bala reaches classical midnight/noon extrema', () {
    final midnight = engine.build(_output(sunHourAngleHours: 12.0));
    double midnightValue(String planet) => midnight
        .firstWhere((value) => value.planet == planet)
        .nathonnataBalaVirupas!;
    for (final planet in ['moon', 'mars', 'saturn', 'mercury']) {
      expect(midnightValue(planet), closeTo(60.0, 1e-9), reason: planet);
    }
    for (final planet in ['sun', 'jupiter', 'venus']) {
      expect(midnightValue(planet), closeTo(0.0, 1e-9), reason: planet);
    }

    final noon = engine.build(_output(sunHourAngleHours: 0.0));
    double noonValue(String planet) => noon
        .firstWhere((value) => value.planet == planet)
        .nathonnataBalaVirupas!;
    for (final planet in ['sun', 'jupiter', 'venus', 'mercury']) {
      expect(noonValue(planet), closeTo(60.0, 1e-9), reason: planet);
    }
    for (final planet in ['moon', 'mars', 'saturn']) {
      expect(noonValue(planet), closeTo(0.0, 1e-9), reason: planet);
    }
  });

  test('Nathonnata Bala is symmetric around apparent noon and midnight', () {
    final morning = engine.build(_output(sunHourAngleHours: 18.0));
    final evening = engine.build(_output(sunHourAngleHours: 6.0));
    for (final planet in ['sun', 'moon', 'mars', 'mercury', 'jupiter', 'venus', 'saturn']) {
      final a = morning.firstWhere((value) => value.planet == planet);
      final b = evening.firstWhere((value) => value.planet == planet);
      expect(a.nathonnataBalaVirupas, closeTo(b.nathonnataBalaVirupas!, 1e-9));
    }
  });

  test('legacy v5 leaves Nathonnata unavailable instead of approximating apparent time', () {
    final results = engine.build(_output(schema: 'vedic-chart-v5'));
    for (final value in results) {
      expect(value.nathonnataBalaVirupas, isNull);
      expect(value.sunHourAngleHours, isNull);
      expect(
        value.kalaComputedSubcomponents,
        value.planet == 'sun' || value.planet == 'moon'
            ? ['paksha', 'yuddha', 'ayana']
            : ['paksha', 'ayana'],
      );
      expect(value.kalaMissingSubcomponents.first, 'nathonnata');
      if (!{'sun', 'moon'}.contains(value.planet)) {
        expect(value.kalaMissingSubcomponents, contains('yuddha'));
      }
    }
  });

  test('Paksha Bala follows BPHS benefic/malefic complement at new and full Moon', () {
    final newMoon = engine.build(_output(
      overrides: const {'sun': 0.0, 'moon': 0.0},
      tropicalOverrides: const {'sun': 0.0, 'moon': 0.0},
    ));
    double newValue(String planet) => newMoon
        .firstWhere((value) => value.planet == planet)
        .pakshaBalaVirupas;
    expect(newValue('moon'), closeTo(0.0, 1e-9));
    expect(newValue('mercury'), closeTo(0.0, 1e-9));
    expect(newValue('jupiter'), closeTo(0.0, 1e-9));
    expect(newValue('venus'), closeTo(0.0, 1e-9));
    expect(newValue('sun'), closeTo(60.0, 1e-9));
    expect(newValue('mars'), closeTo(60.0, 1e-9));
    expect(newValue('saturn'), closeTo(60.0, 1e-9));

    final fullMoon = engine.build(_output(
      overrides: const {'sun': 0.0, 'moon': 180.0},
      tropicalOverrides: const {'sun': 0.0, 'moon': 180.0},
    ));
    double fullValue(String planet) => fullMoon
        .firstWhere((value) => value.planet == planet)
        .pakshaBalaVirupas;
    expect(fullValue('moon'), closeTo(60.0, 1e-9));
    expect(fullValue('mercury'), closeTo(60.0, 1e-9));
    expect(fullValue('jupiter'), closeTo(60.0, 1e-9));
    expect(fullValue('venus'), closeTo(60.0, 1e-9));
    expect(fullValue('sun'), closeTo(0.0, 1e-9));
    expect(fullValue('mars'), closeTo(0.0, 1e-9));
    expect(fullValue('saturn'), closeTo(0.0, 1e-9));
  });

  test('Tribhaga day thirds assign Mercury Sun Saturn and keep Jupiter full', () {
    const lords = {1: 'mercury', 2: 'sun', 3: 'saturn'};
    for (final third in [1, 2, 3]) {
      final results = engine.build(_output(tribhagaIsDay: true, tribhagaThird: third));
      for (final value in results) {
        final expected = value.planet == 'jupiter' || value.planet == lords[third]
            ? 60.0
            : 0.0;
        expect(value.tribhagaBalaVirupas, expected, reason: '${value.planet}/$third');
        expect(value.tribhagaPeriod, 'day');
        expect(value.tribhagaThird, third);
      }
    }
  });

  test('Tribhaga night thirds assign Moon Venus Mars and keep Jupiter full', () {
    const lords = {1: 'moon', 2: 'venus', 3: 'mars'};
    for (final third in [1, 2, 3]) {
      final results = engine.build(_output(tribhagaIsDay: false, tribhagaThird: third));
      for (final value in results) {
        final expected = value.planet == 'jupiter' || value.planet == lords[third]
            ? 60.0
            : 0.0;
        expect(value.tribhagaBalaVirupas, expected, reason: '${value.planet}/$third');
        expect(value.tribhagaPeriod, 'night');
        expect(value.tribhagaThird, third);
      }
    }
  });

  test('legacy v6 leaves Tribhaga unavailable rather than inventing sunrise thirds', () {
    final results = engine.build(_output(schema: 'vedic-chart-v6'));
    for (final value in results) {
      expect(value.tribhagaBalaVirupas, isNull);
      expect(value.tribhagaPeriod, isNull);
      expect(value.kalaMissingSubcomponents, contains('tribhaga'));
    }
  });

  test('Ayana Bala uses BPHS 45/33/12 tropical-longitude khanda profile', () {
    final cancer = engine.build(_output(
      tropicalOverrides: const {
        'sun': 90.0,
        'moon': 90.0,
        'mars': 90.0,
        'mercury': 90.0,
        'jupiter': 90.0,
        'venus': 90.0,
        'saturn': 90.0,
      },
    ));
    double cancerValue(String planet) => cancer
        .firstWhere((value) => value.planet == planet)
        .ayanaBalaVirupas;
    for (final planet in ['sun', 'mars', 'mercury', 'jupiter', 'venus']) {
      expect(cancerValue(planet), closeTo(60.0, 1e-9), reason: planet);
    }
    for (final planet in ['moon', 'saturn']) {
      expect(cancerValue(planet), closeTo(0.0, 1e-9), reason: planet);
    }

    final capricorn = engine.build(_output(
      tropicalOverrides: const {
        'sun': 270.0,
        'moon': 270.0,
        'mars': 270.0,
        'mercury': 270.0,
        'jupiter': 270.0,
        'venus': 270.0,
        'saturn': 270.0,
      },
    ));
    double capricornValue(String planet) => capricorn
        .firstWhere((value) => value.planet == planet)
        .ayanaBalaVirupas;
    for (final planet in ['moon', 'mercury', 'saturn']) {
      expect(capricornValue(planet), closeTo(60.0, 1e-9), reason: planet);
    }
    for (final planet in ['sun', 'mars', 'jupiter', 'venus']) {
      expect(capricornValue(planet), closeTo(0.0, 1e-9), reason: planet);
    }
  });

  test('Ayana Bala matches published Parashara khanda example within rounding', () {
    final result = engine.build(_output(
      tropicalOverrides: const {'sun': 40.3666666667},
    ));
    final sun = result.firstWhere((value) => value.planet == 'sun');
    expect(sun.ayanaBalaVirupas, closeTo(48.8, 0.05));
  });

  test('pre-war Kala subtotal includes all governed non-Yuddha temporal components', () {
    final results = engine.build(_output());
    for (final value in results) {
      expect(value.nathonnataBalaVirupas, isNotNull);
      expect(
        value.kalaBalaPartialVirupas,
        closeTo(
          value.nathonnataBalaVirupas! +
              value.pakshaBalaVirupas +
              value.tribhagaBalaVirupas! +
              value.varshaBalaVirupas! +
              value.masaBalaVirupas! +
              value.dinaBalaVirupas! +
              value.horaBalaVirupas! +
              value.ayanaBalaVirupas,
          1e-9,
        ),
      );
      expect(value.kalaBalaComplete, isTrue);
      expect(value.kalaBalaVirupas,
          closeTo(value.kalaBalaPartialVirupas + value.yuddhaBalaVirupas!, 1e-9));
      expect(value.totalShadbalaVirupas, isNotNull);
    }
  });

  test('Varsha Masa Dina Hora allocate 15 30 45 60 virupas to their lords', () {
    final results = engine.build(_output(
      varshaLord: 'sun',
      masaLord: 'mercury',
      dinaLord: 'moon',
      horaLord: 'saturn',
      horaNumber: 17,
      horaPeriod: 'night',
    ));

    dynamic p(String planet) =>
        results.firstWhere((value) => value.planet == planet);
    expect(p('sun').varshaBalaVirupas, 15.0);
    expect(p('mercury').masaBalaVirupas, 30.0);
    expect(p('moon').dinaBalaVirupas, 45.0);
    expect(p('saturn').horaBalaVirupas, 60.0);
    expect(p('jupiter').varshaBalaVirupas, 0.0);
    expect(p('jupiter').masaBalaVirupas, 0.0);
    expect(p('jupiter').dinaBalaVirupas, 0.0);
    expect(p('jupiter').horaBalaVirupas, 0.0);
    expect(p('saturn').horaNumber, 17);
    expect(
      p('saturn').varshaMasaDinaHoraProfile,
      'siderealSolarIngressAstrologicalDayV1',
    );
  });

  test('time-lord strengths accumulate when one planet rules multiple periods', () {
    final jupiter = engine.build(_output(
      varshaLord: 'jupiter',
      masaLord: 'jupiter',
      dinaLord: 'jupiter',
      horaLord: 'jupiter',
    )).firstWhere((value) => value.planet == 'jupiter');

    expect(jupiter.varshaBalaVirupas, 15.0);
    expect(jupiter.masaBalaVirupas, 30.0);
    expect(jupiter.dinaBalaVirupas, 45.0);
    expect(jupiter.horaBalaVirupas, 60.0);
    expect(
      jupiter.varshaBalaVirupas! +
          jupiter.masaBalaVirupas! +
          jupiter.dinaBalaVirupas! +
          jupiter.horaBalaVirupas!,
      150.0,
    );
  });

  test('legacy v7 leaves Varsha Masa Dina Hora unavailable rather than inventing lords', () {
    final results = engine.build(_output(schema: 'vedic-chart-v7'));
    for (final value in results) {
      expect(value.varshaBalaVirupas, isNull);
      expect(value.masaBalaVirupas, isNull);
      expect(value.dinaBalaVirupas, isNull);
      expect(value.horaBalaVirupas, isNull);
      expect(value.kalaMissingSubcomponents, containsAll(['varsha', 'masa', 'dina', 'hora']));
    }
  });

  test('Sun and Moon Cheshta follow direct BPHS 27.18 equivalences', () {
    final results = engine.build(_output());
    final sun = results.firstWhere((value) => value.planet == 'sun');
    final moon = results.firstWhere((value) => value.planet == 'moon');

    expect(sun.cheshtaMethod, 'sunAyanaBala');
    expect(sun.cheshtaMotionState, 'derivedFromAyana');
    expect(sun.cheshtaBalaVirupas, closeTo(sun.ayanaBalaVirupas, 1e-9));
    expect(moon.cheshtaMethod, 'moonPakshaBala');
    expect(moon.cheshtaMotionState, 'derivedFromPaksha');
    expect(moon.cheshtaBalaVirupas, closeTo(moon.pakshaBalaVirupas, 1e-9));
  });

  test('Mars-through-Saturn Cheshta classifies BPHS motion states from exact speed', () {
    final results = engine.build(_output(
      overrides: const {
        'mars': 5.0,
        'mercury': 60.05,
        'jupiter': 125.0,
        'venus': 205.0,
        'saturn': 315.0,
      },
      speedOverrides: const {
        'mars': -0.20,
        'mercury': -0.20,
        'jupiter': 0.004,
        'venus': 0.30,
        'saturn': 0.025,
      },
    ));

    dynamic p(String planet) =>
        results.firstWhere((value) => value.planet == planet);
    expect(p('mars').cheshtaMotionState, 'vakra');
    expect(p('mars').cheshtaBalaVirupas, 60.0);
    expect(p('mercury').cheshtaMotionState, 'anuvakra');
    expect(p('mercury').cheshtaBalaVirupas, 30.0);
    expect(p('jupiter').cheshtaMotionState, 'vikala');
    expect(p('jupiter').cheshtaBalaVirupas, 15.0);
    expect(p('venus').cheshtaMotionState, 'mandatara');
    expect(p('venus').cheshtaBalaVirupas, 15.0);
    expect(p('saturn').cheshtaMotionState, 'manda');
    expect(p('saturn').cheshtaBalaVirupas, 30.0);
  });

  test('direct Sama, Chara and Atichara boundaries remain explicit', () {
    final sama = engine.build(_output(
      speedOverrides: const {'mars': 0.60},
    )).firstWhere((value) => value.planet == 'mars');
    expect(sama.cheshtaMotionState, 'sama');
    expect(sama.cheshtaBalaVirupas, 7.5);

    final chara = engine.build(_output(
      overrides: const {'mars': 5.0},
      speedOverrides: const {'mars': 0.90},
    )).firstWhere((value) => value.planet == 'mars');
    expect(chara.cheshtaMotionState, 'chara');
    expect(chara.cheshtaBalaVirupas, 45.0);

    final atichara = engine.build(_output(
      overrides: const {'mars': 29.6},
      speedOverrides: const {'mars': 0.90},
    )).firstWhere((value) => value.planet == 'mars');
    expect(atichara.cheshtaMotionState, 'atichara');
    expect(atichara.cheshtaBalaVirupas, 30.0);
  });

  test('legacy v4 keeps Mars-through-Saturn Cheshta explicitly unavailable', () {
    final results = engine.build(_output(
      schema: 'vedic-chart-v4',
      includeSpeeds: false,
    ));
    final mars = results.firstWhere((value) => value.planet == 'mars');
    final sun = results.firstWhere((value) => value.planet == 'sun');

    expect(mars.cheshtaBalaVirupas, isNull);
    expect(mars.cheshtaMethod, 'legacyOutputWithoutSpeed');
    expect(mars.missingComponents,
        ['kalaRemaining', 'cheshta', 'aggregateThresholdEvaluation']);
    expect(mars.aggregateAvailable, isFalse);
    expect(mars.totalShadbalaVirupas, isNull);
    expect(mars.requiredStrengthRatio, isNull);
    expect(mars.thresholdStatus, 'unavailable');
    expect(sun.cheshtaBalaVirupas, isNotNull);
  });

  test('vedic-chart-v9 requires speed, Sun hour angle and latitude while polar temporal metadata may be absent', () {
    expect(
      () => engine.build(_output(includeSpeeds: false)),
      throwsStateError,
    );
    expect(
      () => engine.build(_output(includeLatitudes: false)),
      throwsStateError,
    );
    expect(
      () => engine.build(_output(includeSunHourAngle: false)),
      throwsStateError,
    );
    final polar = engine.build(_output(
      includeTribhaga: false,
      includeVarshaMasaDinaHora: false,
    ));
    for (final value in polar) {
      expect(value.tribhagaBalaVirupas, isNull);
      expect(value.varshaBalaVirupas, isNull);
      expect(value.masaBalaVirupas, isNull);
      expect(value.dinaBalaVirupas, isNull);
      expect(value.horaBalaVirupas, isNull);
      expect(value.kalaComputedSubcomponents,
          ['nathonnata', 'paksha', 'yuddha', 'ayana']);
      expect(value.kalaMissingSubcomponents, containsAll([
        'tribhaga',
        'varsha',
        'masa',
        'dina',
        'hora',
      ]));
    }
  });

  test('Yuddha is zero when no eligible same-sign pair is within one degree', () {
    final results = engine.build(_output());
    final mars = results.firstWhere((value) => value.planet == 'mars');
    final sun = results.firstWhere((value) => value.planet == 'sun');

    expect(mars.yuddhaRole, 'noWar');
    expect(mars.yuddhaBalaVirupas, 0.0);
    expect(mars.yuddhaWarPartner, isNull);
    expect(sun.yuddhaRole, 'notEligible');
    expect(sun.yuddhaBalaVirupas, 0.0);
  });

  test('isolated planetary war uses northern ecliptic latitude and symmetric BPHS correction', () {
    final results = engine.build(_output(
      overrides: const {'mars': 10.0, 'mercury': 10.5},
      latitudeOverrides: const {'mars': 2.0, 'mercury': 1.0},
    ));
    final mars = results.firstWhere((value) => value.planet == 'mars');
    final mercury = results.firstWhere((value) => value.planet == 'mercury');

    expect(mars.yuddhaRole, 'winner');
    expect(mercury.yuddhaRole, 'loser');
    expect(mars.yuddhaWarPartner, 'mercury');
    expect(mercury.yuddhaWarPartner, 'mars');
    expect(mars.yuddhaSeparationDegrees, closeTo(0.5, 1e-9));
    expect(mars.yuddhaLatitudeDegrees, 2.0);
    expect(mars.yuddhaPartnerLatitudeDegrees, 1.0);
    expect(mars.yuddhaBalaVirupas, greaterThanOrEqualTo(0.0));
    expect(mercury.yuddhaBalaVirupas, closeTo(-mars.yuddhaBalaVirupas!, 1e-9));
    expect(mars.yuddhaPreWarStrengthDifferenceVirupas,
        closeTo(mars.yuddhaBalaVirupas!.abs(), 1e-9));
    expect(mars.kalaBalaComplete, isTrue);
    expect(mercury.kalaBalaComplete, isTrue);
  });

  test('latitude tie keeps Yuddha and Kala unresolved rather than inventing a victor', () {
    final results = engine.build(_output(
      overrides: const {'mars': 10.0, 'mercury': 10.5},
      latitudeOverrides: const {'mars': 1.25, 'mercury': 1.25},
    ));
    final mars = results.firstWhere((value) => value.planet == 'mars');
    final mercury = results.firstWhere((value) => value.planet == 'mercury');

    expect(mars.yuddhaRole, 'latitudeTie');
    expect(mercury.yuddhaRole, 'latitudeTie');
    expect(mars.yuddhaBalaVirupas, isNull);
    expect(mercury.yuddhaBalaVirupas, isNull);
    expect(mars.kalaBalaComplete, isFalse);
    expect(mars.kalaMissingSubcomponents, contains('yuddha'));
  });

  test('multi-planet war cluster is gated instead of imposing pair order', () {
    final results = engine.build(_output(
      overrides: const {'mars': 10.0, 'mercury': 10.4, 'jupiter': 10.8},
      latitudeOverrides: const {'mars': 2.0, 'mercury': 1.0, 'jupiter': 0.5},
    ));
    for (final planet in ['mars', 'mercury', 'jupiter']) {
      final value = results.firstWhere((item) => item.planet == planet);
      expect(value.yuddhaRole, 'ambiguousMultiplePartners');
      expect(value.yuddhaBalaVirupas, isNull);
      expect(value.kalaBalaComplete, isFalse);
    }
  });

  test('legacy v8 keeps five-planet Yuddha unavailable without latitude evidence', () {
    final results = engine.build(_output(
      schema: 'vedic-chart-v8',
      includeLatitudes: false,
    ));
    final mars = results.firstWhere((value) => value.planet == 'mars');
    final sun = results.firstWhere((value) => value.planet == 'sun');

    expect(mars.yuddhaRole, 'legacyOutputWithoutLatitude');
    expect(mars.yuddhaBalaVirupas, isNull);
    expect(mars.kalaBalaComplete, isFalse);
    expect(sun.yuddhaRole, 'notEligible');
    expect(sun.yuddhaBalaVirupas, 0.0);
  });

  test('Drik Bala persists exact received contributions and signed sum', () {
    final results = engine.build(_output());

    for (final value in results) {
      expect(value.drikProfile, 'bphsSphutaDrishtiDrikV1');
      expect(value.drikBalaVirupas.isFinite, isTrue);
      expect(
        value.drikBalaVirupas,
        closeTo(
          value.drikContributions.fold<double>(
            0.0,
            (sum, item) => sum + item.netContributionVirupas,
          ),
          1e-9,
        ),
      );
      expect(
        value.drikContributions.every(
          (item) => item.aspector != value.planet &&
              item.aspectVirupas > 0 &&
              item.aspectVirupas <= 60,
        ),
        isTrue,
      );
    }
  });

  test('Sphuta Drishti special peaks reach 60 virupas for Mars Jupiter and Saturn', () {
    dynamic contributionFor({
      required String aspector,
      required double targetLongitude,
      required double aspectorLongitude,
    }) {
      final profile = engine.build(_output(
        overrides: {
          'sun': targetLongitude,
          aspector: aspectorLongitude,
        },
      )).firstWhere((value) => value.planet == 'sun');
      return profile.drikContributions
          .firstWhere((value) => value.aspector == aspector);
    }

    expect(
      contributionFor(
        aspector: 'mars',
        targetLongitude: 120.0,
        aspectorLongitude: 0.0,
      ).aspectVirupas,
      closeTo(60.0, 1e-9),
    );
    expect(
      contributionFor(
        aspector: 'jupiter',
        targetLongitude: 240.0,
        aspectorLongitude: 0.0,
      ).aspectVirupas,
      closeTo(60.0, 1e-9),
    );
    expect(
      contributionFor(
        aspector: 'saturn',
        targetLongitude: 60.0,
        aspectorLongitude: 0.0,
      ).aspectVirupas,
      closeTo(60.0, 1e-9),
    );
  });

  test('BPHS 27.19 quarter weighting and Mercury/Jupiter super-add remain auditable', () {
    final jupiterTarget = engine.build(_output(
      overrides: const {'jupiter': 0.0, 'sun': 240.0},
    )).firstWhere((value) => value.planet == 'sun');
    final jupiter = jupiterTarget.drikContributions
        .firstWhere((value) => value.aspector == 'jupiter');
    expect(jupiter.nature, 'benefic');
    expect(jupiter.aspectVirupas, closeTo(60.0, 1e-9));
    expect(jupiter.baseQuarterContributionVirupas, closeTo(15.0, 1e-9));
    expect(jupiter.superAddedVirupas, closeTo(60.0, 1e-9));
    expect(jupiter.netContributionVirupas, closeTo(75.0, 1e-9));

    final saturnTarget = engine.build(_output(
      overrides: const {'saturn': 0.0, 'sun': 60.0},
    )).firstWhere((value) => value.planet == 'sun');
    final saturn = saturnTarget.drikContributions
        .firstWhere((value) => value.aspector == 'saturn');
    expect(saturn.nature, 'malefic');
    expect(saturn.aspectVirupas, closeTo(60.0, 1e-9));
    expect(saturn.baseQuarterContributionVirupas, closeTo(-15.0, 1e-9));
    expect(saturn.superAddedVirupas, closeTo(0.0, 1e-9));
    expect(saturn.netContributionVirupas, closeTo(-15.0, 1e-9));
  });

  test('Moon Drik nature follows waxing versus waning phase', () {
    final waxing = engine.build(_output(
      overrides: const {'sun': 350.0, 'moon': 0.0, 'venus': 180.0},
    )).firstWhere((value) => value.planet == 'venus');
    final waxingMoon = waxing.drikContributions
        .firstWhere((value) => value.aspector == 'moon');
    expect(waxingMoon.nature, 'benefic');
    expect(waxingMoon.netContributionVirupas, closeTo(15.0, 1e-9));

    final waning = engine.build(_output(
      overrides: const {'sun': 10.0, 'moon': 0.0, 'venus': 180.0},
    )).firstWhere((value) => value.planet == 'venus');
    final waningMoon = waning.drikContributions
        .firstWhere((value) => value.aspector == 'moon');
    expect(waningMoon.nature, 'malefic');
    expect(waningMoon.netContributionVirupas, closeTo(-15.0, 1e-9));
  });

  test('Mercury joined to a classical malefic keeps the full super-add but flips quarter weight', () {
    final target = engine.build(_output(
      overrides: const {
        'mercury': 0.0,
        'mars': 5.0,
        'jupiter': 180.0,
      },
    )).firstWhere((value) => value.planet == 'jupiter');
    final mercury = target.drikContributions
        .firstWhere((value) => value.aspector == 'mercury');

    expect(mercury.nature, 'malefic');
    expect(mercury.aspectVirupas, closeTo(60.0, 1e-9));
    expect(mercury.baseQuarterContributionVirupas, closeTo(-15.0, 1e-9));
    expect(mercury.superAddedVirupas, closeTo(60.0, 1e-9));
    expect(mercury.netContributionVirupas, closeTo(45.0, 1e-9));
  });

  test('uses fixed Naisargika scale without converting it to outcome polarity', () {
    final results = engine.build(_output());
    double strength(String planet) => results
        .firstWhere((value) => value.planet == planet)
        .naisargikaBalaVirupas;

    expect(strength('sun'), 60.0);
    expect(strength('moon'), closeTo(360.0 / 7.0, 1e-9));
    expect(strength('venus'), closeTo(300.0 / 7.0, 1e-9));
    expect(strength('jupiter'), closeTo(240.0 / 7.0, 1e-9));
    expect(strength('mercury'), closeTo(180.0 / 7.0, 1e-9));
    expect(strength('mars'), closeTo(120.0 / 7.0, 1e-9));
    expect(strength('saturn'), closeTo(60.0 / 7.0, 1e-9));
  });

  test('rejects unsupported calculation schemas', () {
    final v10 = engine.build(_output(schema: 'vedic-chart-v10'));
    expect(v10, hasLength(7));
    expect(v10.every((value) => value.ruleVersion == 'shadbala-foundation-v10'), isTrue);

    expect(
      () => engine.build(_output(schema: 'vedic-chart-v99')),
      throwsArgumentError,
    );
  });
}

CalculationOutputSnapshot _output({
  String schema = 'vedic-chart-v9',
  double ascendantLongitude = 0.0,
  Map<String, double> overrides = const {},
  Map<String, double> tropicalOverrides = const {},
  Map<String, double> speedOverrides = const {},
  Map<String, double> latitudeOverrides = const {},
  bool includeSpeeds = true,
  bool includeLatitudes = true,
  bool includeSunHourAngle = true,
  double sunHourAngleHours = 6.0,
  bool includeTribhaga = true,
  bool tribhagaIsDay = false,
  int tribhagaThird = 2,
  bool includeVarshaMasaDinaHora = true,
  String varshaLord = 'sun',
  String masaLord = 'mercury',
  String dinaLord = 'moon',
  String horaLord = 'saturn',
  int horaNumber = 17,
  String horaPeriod = 'night',
}) {
  final longitudes = <String, double>{
    'sun': 10.0,
    'moon': 45.0,
    'mars': 5.0,
    'mercury': 85.0,
    'jupiter': 125.0,
    'venus': 205.0,
    'saturn': 315.0,
    'rahu': 250.0,
    'ketu': 70.0,
    ...overrides,
  };
  final speeds = <String, double>{
    'sun': 1.0,
    'moon': 13.0,
    'mars': 0.5,
    'mercury': 1.2,
    'jupiter': 0.08,
    'venus': 1.1,
    'saturn': 0.03,
    'rahu': -0.05,
    'ketu': -0.05,
    ...speedOverrides,
  };
  final latitudes = <String, double>{
    'sun': 0.0,
    'moon': 3.0,
    'mars': 1.5,
    'mercury': -1.0,
    'jupiter': 0.2,
    'venus': -0.9,
    'saturn': 2.5,
    'rahu': 0.0,
    'ketu': 0.0,
    ...latitudeOverrides,
  };
  return CalculationOutputSnapshot(
    id: 1,
    consultationId: 1,
    inputSnapshotId: 1,
    engineId: 'fixture-vedic',
    engineVersion: '1',
    outputSchemaVersion: schema,
    output: {
      'metadata': {
        'utcDateTime': '1984-03-12T18:42:00.000Z',
        if (includeSunHourAngle) 'sunHourAngleHours': sunHourAngleHours,
        if (includeTribhaga) ...{
          'tribhagaIsDay': tribhagaIsDay,
          'tribhagaThird': tribhagaThird,
          'tribhagaPeriodStartUtc': '1984-03-12T13:54:00.000Z',
          'tribhagaPeriodEndUtc': '1984-03-13T01:54:00.000Z',
        },
        if (schema == 'vedic-chart-v8' ||
            schema == 'vedic-chart-v9' ||
            schema == 'vedic-chart-v10') ...{
          'varshaMasaDinaHoraProfile': 'siderealSolarIngressAstrologicalDayV1',
          'varshaMasaDinaHoraUtcOffsetMinutes': 330,
          if (includeVarshaMasaDinaHora) ...{
            'astrologicalDayStartUtc': '1984-03-12T00:42:00.000Z',
            'varshaIngressUtc': '1983-04-14T10:00:00.000Z',
            'varshaAstrologicalDayStartUtc': '1983-04-14T00:30:00.000Z',
            'masaIngressUtc': '1984-02-13T12:00:00.000Z',
            'masaAstrologicalDayStartUtc': '1984-02-13T00:30:00.000Z',
            'varshaLord': varshaLord,
            'masaLord': masaLord,
            'dinaLord': dinaLord,
            'horaLord': horaLord,
            'horaNumber': horaNumber,
            'horaPeriod': horaPeriod,
          },
        },
      },
      'ascendant': {
        'signIndex': ascendantLongitude ~/ 30,
        'siderealLongitude': ascendantLongitude,
      },
      'planets': [
        for (final entry in longitudes.entries)
          {
            'body': entry.key,
            'signIndex': entry.value ~/ 30,
            'siderealLongitude': entry.value,
            'tropicalLongitude': tropicalOverrides[entry.key] ?? entry.value,
            'navamsaSignIndex': ((entry.value * 9.0) ~/ 30.0) % 12,
            'retrograde': (speeds[entry.key] ?? 0) < 0,
            if (includeSpeeds)
              'longitudeSpeedPerDay': speeds[entry.key] ?? 0.0,
            if (includeLatitudes)
              'eclipticLatitude': latitudes[entry.key] ?? 0.0,
          },
      ],
    },
    outputHash: List.filled(64, 'a').join(),
    createdAt: DateTime.utc(2026, 8, 7),
  );
}
