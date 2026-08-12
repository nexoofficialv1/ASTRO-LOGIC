import '../ephemeris/ephemeris_provider.dart';
import '../models/astrology_settings.dart';
import '../models/calculation_snapshot.dart';
import '../models/consultation.dart';
import '../services/calculation_engine_adapter.dart';
import 'vedic_math.dart';
import 'vimshottari_dasha_engine.dart';

class VedicDerivationEngine implements CalculationEngineAdapter {
  const VedicDerivationEngine(this._ephemeris);

  final EphemerisProvider _ephemeris;

  @override
  AstrologySystem get system => AstrologySystem.vedic;

  @override
  String get engineId => 'astro-logic-vedic/${_ephemeris.engineId}';

  @override
  String get engineVersion => '1.0.0+${_ephemeris.engineVersion}';

  @override
  String get outputSchemaVersion => 'vedic-chart-v10';

  @override
  Future<Map<String, Object?>> calculate(
    CalculationSnapshot inputSnapshot,
  ) async {
    final input = inputSnapshot.input;
    final settings = inputSnapshot.settings;
    final request = EphemerisRequest(
      utcDateTime: DateTime.parse(input['utcDateTime'] as String).toUtc(),
      latitude: (input['latitude'] as num).toDouble(),
      longitude: (input['longitude'] as num).toDouble(),
      ayanamsha: Ayanamsha.values.byName(settings['ayanamsha'] as String),
      lunarNodeMode:
          LunarNodeMode.values.byName(settings['lunarNodeMode'] as String),
    );
    final frame = await _ephemeris.calculate(request);
    _validateFrame(frame);
    final utcOffsetMinutes = (input['utcOffsetMinutes'] as num).toInt();
    final varshaMasaDinaHora = _varshaMasaDinaHoraMetadata(
      request.utcDateTime,
      utcOffsetMinutes,
      frame,
    );

    final positions = <Map<String, Object?>>[];
    for (final body in CelestialBody.values) {
      final position = frame.positions[body]!;
      final sidereal = VedicMath.siderealLongitude(
        position.tropicalLongitude,
        frame.ayanamshaDegrees,
      );
      positions.add(_positionMap(
        body.name,
        position.tropicalLongitude,
        sidereal,
        position.longitudeSpeed < 0,
        position.longitudeSpeed,
        position.eclipticLatitude,
      ));
    }

    final rahu = positions.firstWhere((value) => value['body'] == 'rahu');
    final ketuSidereal = VedicMath.normalize(
      (rahu['siderealLongitude'] as double) + 180.0,
    );
    positions.add(_positionMap(
      'ketu',
      VedicMath.normalize(
        (rahu['tropicalLongitude'] as double) + 180.0,
      ),
      ketuSidereal,
      rahu['retrograde'] as bool,
      rahu['longitudeSpeedPerDay'] as double,
      -(rahu['eclipticLatitude'] as double),
    ));

    final sun = positions.firstWhere((value) => value['body'] == 'sun');
    final moon = positions.firstWhere((value) => value['body'] == 'moon');
    final siderealAscendant = VedicMath.siderealLongitude(
      frame.tropicalAscendant,
      frame.ayanamshaDegrees,
    );
    final tithi = VedicMath.tithiNumber(
      sun['tropicalLongitude'] as double,
      moon['tropicalLongitude'] as double,
    );

    final ascendant = _derivedPointMap(siderealAscendant);
    final d9Planets = positions
        .map(
          (position) => <String, Object?>{
            'body': position['body'],
            'signIndex': position['navamsaSignIndex'],
            'sign': position['navamsaSign'],
          },
        )
        .toList(growable: false);
    final d10Planets = positions
        .map(
          (position) => <String, Object?>{
            'body': position['body'],
            'signIndex': position['dashamsaSignIndex'],
            'sign': position['dashamsaSign'],
          },
        )
        .toList(growable: false);

    return {
      'metadata': {
        'ephemerisEngine': _ephemeris.engineId,
        'ephemerisVersion': _ephemeris.engineVersion,
        'ayanamsha': request.ayanamsha.name,
        'ayanamshaDegrees': frame.ayanamshaDegrees,
        'lunarNodeMode': request.lunarNodeMode.name,
        'utcDateTime': request.utcDateTime.toIso8601String(),
        'sunHourAngleHours': frame.sunHourAngleHours,
        if (frame.tribhagaThird != null) ...{
          'tribhagaIsDay': frame.tribhagaIsDay,
          'tribhagaThird': frame.tribhagaThird,
          'tribhagaPeriodStartUtc': _offsetUtc(
            request.utcDateTime,
            frame.tribhagaPeriodStartOffsetDays!,
          ).toIso8601String(),
          'tribhagaPeriodEndUtc': _offsetUtc(
            request.utcDateTime,
            frame.tribhagaPeriodEndOffsetDays!,
          ).toIso8601String(),
        },
        ...varshaMasaDinaHora,
      },
      'ascendant': ascendant,
      'planets': positions,
      'divisionalCharts': {
        'd9': {
          'division': 9,
          'ascendant': {
            'signIndex': ascendant['navamsaSignIndex'],
            'sign': ascendant['navamsaSign'],
          },
          'planets': d9Planets,
        },
        'd10': {
          'division': 10,
          'calculationProfile': 'bphs-dashamsa-odd-self-even-ninth-v1',
          'ascendant': {
            'signIndex': ascendant['dashamsaSignIndex'],
            'sign': ascendant['dashamsaSign'],
          },
          'planets': d10Planets,
        },
      },
      'vimshottari': VimshottariDashaEngine.calculate(
        moonSiderealLongitude: moon['siderealLongitude'] as double,
        birthUtc: request.utcDateTime,
      ),
      'panchanga': {
        'tithiNumber': tithi,
        'paksha': tithi <= 15 ? 'shukla' : 'krishna',
        'yogaNumber': VedicMath.yogaNumber(
          sun['siderealLongitude'] as double,
          moon['siderealLongitude'] as double,
        ),
      },
    };
  }

  Map<String, Object?> _varshaMasaDinaHoraMetadata(
    DateTime birthUtc,
    int utcOffsetMinutes,
    EphemerisFrame frame,
  ) {
    DateTime? instant(double? offsetDays) =>
        offsetDays == null ? null : _offsetUtc(birthUtc, offsetDays);

    final astrologicalDayStart = instant(frame.astrologicalDayStartOffsetDays);
    final varshaIngress = instant(frame.varshaIngressOffsetDays);
    final varshaDayStart = instant(frame.varshaDayStartOffsetDays);
    final masaIngress = instant(frame.masaIngressOffsetDays);
    final masaDayStart = instant(frame.masaDayStartOffsetDays);
    final dinaLord = astrologicalDayStart == null
        ? null
        : _weekdayLordForUtc(
            astrologicalDayStart,
            utcOffsetMinutes,
          );
    final varshaLord = varshaDayStart == null
        ? null
        : _weekdayLordForUtc(varshaDayStart, utcOffsetMinutes);
    final masaLord = masaDayStart == null
        ? null
        : _weekdayLordForUtc(masaDayStart, utcOffsetMinutes);

    String? horaLord;
    int? horaNumber;
    String? horaPeriod;
    if (dinaLord != null &&
        frame.tribhagaIsDay != null &&
        frame.tribhagaPeriodStartOffsetDays != null &&
        frame.tribhagaPeriodEndOffsetDays != null) {
      final start = _offsetUtc(
        birthUtc,
        frame.tribhagaPeriodStartOffsetDays!,
      );
      final end = _offsetUtc(
        birthUtc,
        frame.tribhagaPeriodEndOffsetDays!,
      );
      final spanMicros = end.microsecondsSinceEpoch - start.microsecondsSinceEpoch;
      final elapsedMicros =
          birthUtc.microsecondsSinceEpoch - start.microsecondsSinceEpoch;
      if (spanMicros > 0 && elapsedMicros >= 0 && elapsedMicros <= spanMicros) {
        var segment = (12.0 * elapsedMicros / spanMicros).floor();
        if (segment < 0) segment = 0;
        if (segment > 11) segment = 11;
        final base = frame.tribhagaIsDay! ? 0 : 12;
        horaNumber = base + segment + 1;
        horaPeriod = frame.tribhagaIsDay! ? 'day' : 'night';
        horaLord = _horaLordFor(dinaLord, horaNumber);
      }
    }

    return <String, Object?>{
      'varshaMasaDinaHoraProfile': 'siderealSolarIngressAstrologicalDayV1',
      'varshaMasaDinaHoraUtcOffsetMinutes': utcOffsetMinutes,
      if (astrologicalDayStart != null)
        'astrologicalDayStartUtc': astrologicalDayStart.toIso8601String(),
      if (varshaIngress != null)
        'varshaIngressUtc': varshaIngress.toIso8601String(),
      if (varshaDayStart != null)
        'varshaAstrologicalDayStartUtc': varshaDayStart.toIso8601String(),
      if (masaIngress != null)
        'masaIngressUtc': masaIngress.toIso8601String(),
      if (masaDayStart != null)
        'masaAstrologicalDayStartUtc': masaDayStart.toIso8601String(),
      if (varshaLord != null) 'varshaLord': varshaLord,
      if (masaLord != null) 'masaLord': masaLord,
      if (dinaLord != null) 'dinaLord': dinaLord,
      if (horaLord != null) 'horaLord': horaLord,
      if (horaNumber != null) 'horaNumber': horaNumber,
      if (horaPeriod != null) 'horaPeriod': horaPeriod,
    };
  }

  static String _weekdayLordForUtc(DateTime utc, int utcOffsetMinutes) {
    final local = utc.add(Duration(minutes: utcOffsetMinutes));
    return _weekdayLords[local.weekday]!;
  }

  static String _horaLordFor(String dinaLord, int horaNumber) {
    final start = _horaOrder.indexOf(dinaLord);
    if (start < 0) throw StateError('Unknown Dina lord: $dinaLord');
    return _horaOrder[(start + horaNumber - 1) % _horaOrder.length];
  }

  static const Map<int, String> _weekdayLords = <int, String>{
    DateTime.monday: 'moon',
    DateTime.tuesday: 'mars',
    DateTime.wednesday: 'mercury',
    DateTime.thursday: 'jupiter',
    DateTime.friday: 'venus',
    DateTime.saturday: 'saturn',
    DateTime.sunday: 'sun',
  };

  static const List<String> _horaOrder = <String>[
    'saturn',
    'jupiter',
    'mars',
    'sun',
    'venus',
    'mercury',
    'moon',
  ];

  Map<String, Object?> _positionMap(
    String body,
    double tropical,
    double sidereal,
    bool retrograde,
    double longitudeSpeedPerDay,
    double eclipticLatitude,
  ) => {
        'body': body,
        'tropicalLongitude': VedicMath.normalize(tropical),
        'siderealLongitude': sidereal,
        'signIndex': VedicMath.signIndex(sidereal),
        'sign': VedicMath.rashiNames[VedicMath.signIndex(sidereal)],
        'degreeInSign': VedicMath.degreeInSign(sidereal),
        'nakshatraIndex': VedicMath.nakshatraIndex(sidereal),
        'nakshatra': VedicMath.nakshatraNames[
            VedicMath.nakshatraIndex(sidereal)],
        'pada': VedicMath.nakshatraPada(sidereal),
        'navamsaSignIndex': VedicMath.navamsaSignIndex(sidereal),
        'navamsaSign':
            VedicMath.rashiNames[VedicMath.navamsaSignIndex(sidereal)],
        'dashamsaSignIndex': VedicMath.dashamsaSignIndex(sidereal),
        'dashamsaSign':
            VedicMath.rashiNames[VedicMath.dashamsaSignIndex(sidereal)],
        'retrograde': retrograde,
        'longitudeSpeedPerDay': longitudeSpeedPerDay,
        'eclipticLatitude': eclipticLatitude,
      };

  Map<String, Object?> _derivedPointMap(double sidereal) => {
        'siderealLongitude': sidereal,
        'signIndex': VedicMath.signIndex(sidereal),
        'sign': VedicMath.rashiNames[VedicMath.signIndex(sidereal)],
        'degreeInSign': VedicMath.degreeInSign(sidereal),
        'nakshatraIndex': VedicMath.nakshatraIndex(sidereal),
        'nakshatra':
            VedicMath.nakshatraNames[VedicMath.nakshatraIndex(sidereal)],
        'pada': VedicMath.nakshatraPada(sidereal),
        'navamsaSignIndex': VedicMath.navamsaSignIndex(sidereal),
        'navamsaSign':
            VedicMath.rashiNames[VedicMath.navamsaSignIndex(sidereal)],
        'dashamsaSignIndex': VedicMath.dashamsaSignIndex(sidereal),
        'dashamsaSign':
            VedicMath.rashiNames[VedicMath.dashamsaSignIndex(sidereal)],
      };

  static DateTime _offsetUtc(DateTime base, double offsetDays) =>
      base.add(
        Duration(
          microseconds: (offsetDays * 86400000000.0).round(),
        ),
      ).toUtc();

  void _validateFrame(EphemerisFrame frame) {
    final missing = CelestialBody.values
        .where((body) => !frame.positions.containsKey(body))
        .map((body) => body.name)
        .toList();
    if (missing.isNotEmpty) {
      throw StateError('Ephemeris frame is missing: ${missing.join(', ')}');
    }
    final values = <double>[
      frame.tropicalAscendant,
      frame.ayanamshaDegrees,
      frame.sunHourAngleHours,
      for (final position in frame.positions.values)
        position.tropicalLongitude,
      for (final position in frame.positions.values) position.longitudeSpeed,
      for (final position in frame.positions.values) position.eclipticLatitude,
    ];
    if (values.any((value) => !value.isFinite)) {
      throw StateError('Ephemeris returned a non-finite value');
    }
    if (frame.ayanamshaDegrees.abs() > 60.0) {
      throw StateError('Ephemeris returned an invalid ayanamsha');
    }
    if (frame.sunHourAngleHours < 0.0 || frame.sunHourAngleHours >= 24.0) {
      throw StateError('Ephemeris returned an invalid Sun hour angle');
    }
    final tribhagaValues = <Object?>[
      frame.tribhagaIsDay,
      frame.tribhagaThird,
      frame.tribhagaPeriodStartOffsetDays,
      frame.tribhagaPeriodEndOffsetDays,
    ];
    final hasAnyTribhaga = tribhagaValues.any((value) => value != null);
    final hasAllTribhaga = tribhagaValues.every((value) => value != null);
    if (hasAnyTribhaga != hasAllTribhaga) {
      throw StateError('Ephemeris returned a partial Tribhaga solar-period frame');
    }
    if (hasAllTribhaga) {
      if (frame.tribhagaThird! < 1 ||
          frame.tribhagaThird! > 3 ||
          !frame.tribhagaPeriodStartOffsetDays!.isFinite ||
          !frame.tribhagaPeriodEndOffsetDays!.isFinite ||
          frame.tribhagaPeriodStartOffsetDays! > 0 ||
          frame.tribhagaPeriodEndOffsetDays! < 0 ||
          frame.tribhagaPeriodEndOffsetDays! <=
              frame.tribhagaPeriodStartOffsetDays!) {
        throw StateError('Ephemeris returned an invalid Tribhaga solar period');
      }
    }

    final astrologicalDayStart = frame.astrologicalDayStartOffsetDays;
    if (astrologicalDayStart != null &&
        (!astrologicalDayStart.isFinite || astrologicalDayStart > 0.0)) {
      throw StateError('Ephemeris returned an invalid astrological-day start');
    }
    final ingressValues = <double?>[
      frame.varshaIngressOffsetDays,
      frame.varshaDayStartOffsetDays,
      frame.masaIngressOffsetDays,
      frame.masaDayStartOffsetDays,
    ];
    final hasAnyIngress = ingressValues.any((value) => value != null);
    final hasAllIngress = ingressValues.every((value) => value != null);
    if (hasAnyIngress != hasAllIngress) {
      throw StateError('Ephemeris returned a partial solar-ingress frame');
    }
    if (hasAllIngress) {
      if (ingressValues.any((value) => !value!.isFinite || value > 0.0) ||
          frame.varshaDayStartOffsetDays! > frame.varshaIngressOffsetDays! ||
          frame.masaDayStartOffsetDays! > frame.masaIngressOffsetDays!) {
        throw StateError('Ephemeris returned invalid solar-ingress metadata');
      }
    }
  }
}
