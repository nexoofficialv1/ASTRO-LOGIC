import 'vedic_math.dart';

/// Deterministic Vimshottari Mahadasha/Antardasha/Pratyantardasha calendar.
class VimshottariDashaEngine {
  const VimshottariDashaEngine._();

  static const ruleVersion = 'vimshottari-calendar-v2';
  static const cycleYears = 120;
  static const yearLengthDays = 365.25636;
  static const yearMode = 'siderealSolarYear';

  static const sequence = <String>[
    'ketu',
    'venus',
    'sun',
    'moon',
    'mars',
    'rahu',
    'jupiter',
    'saturn',
    'mercury',
  ];

  static const yearsByLord = <String, int>{
    'ketu': 7,
    'venus': 20,
    'sun': 6,
    'moon': 10,
    'mars': 7,
    'rahu': 18,
    'jupiter': 16,
    'saturn': 19,
    'mercury': 17,
  };

  static Map<String, Object?> calculate({
    required double moonSiderealLongitude,
    required DateTime birthUtc,
  }) {
    if (!moonSiderealLongitude.isFinite) {
      throw ArgumentError.value(
        moonSiderealLongitude,
        'moonSiderealLongitude',
      );
    }
    final normalizedMoon = VedicMath.normalize(moonSiderealLongitude);
    final normalizedBirth = birthUtc.toUtc();
    final nakshatraIndex = VedicMath.nakshatraIndex(normalizedMoon);
    final nakshatraSpan = 360.0 / 27.0;
    final elapsedFraction =
        (normalizedMoon - nakshatraIndex * nakshatraSpan) / nakshatraSpan;
    final startingSequenceIndex = nakshatraIndex % sequence.length;
    final startingLord = sequence[startingSequenceIndex];
    final startingYears = yearsByLord[startingLord]!;
    final fullStartingDays = startingYears * yearLengthDays;
    final firstStart = _addDays(
      normalizedBirth,
      -(elapsedFraction * fullStartingDays),
    );

    final mahadashas = <Map<String, Object?>>[];
    var mahaStart = firstStart;
    for (var offset = 0; offset < sequence.length; offset += 1) {
      final lord = sequence[(startingSequenceIndex + offset) % sequence.length];
      final nominalYears = yearsByLord[lord]!;
      final mahaEnd = _addDays(
        mahaStart,
        nominalYears * yearLengthDays,
      );
      final antardashas = _buildAntardashas(
        mahaLord: lord,
        mahaYears: nominalYears,
        mahaStart: mahaStart,
        mahaEnd: mahaEnd,
        birthUtc: normalizedBirth,
      );
      mahadashas.add({
        'lord': lord,
        'nominalYears': nominalYears,
        'startUtc': mahaStart.toIso8601String(),
        'endUtc': mahaEnd.toIso8601String(),
        'activeAtBirth': _contains(mahaStart, mahaEnd, normalizedBirth),
        'antardashas': antardashas,
      });
      mahaStart = mahaEnd;
    }

    final firstEnd = DateTime.parse(
      mahadashas.first['endUtc']! as String,
    ).toUtc();
    final balanceDays = firstEnd.difference(normalizedBirth).inMicroseconds /
        Duration.microsecondsPerDay;

    return {
      'ruleVersion': ruleVersion,
      'cycleYears': cycleYears,
      'yearMode': yearMode,
      'yearLengthDays': yearLengthDays,
      'birthUtc': normalizedBirth.toIso8601String(),
      'moonSiderealLongitude': normalizedMoon,
      'birthNakshatraIndex': nakshatraIndex,
      'birthNakshatra': VedicMath.nakshatraNames[nakshatraIndex],
      'startingMahadashaLord': startingLord,
      'elapsedNakshatraFraction': elapsedFraction,
      'balanceAtBirthDays': balanceDays,
      'balanceAtBirthYears': balanceDays / yearLengthDays,
      'mahadashas': mahadashas,
    };
  }

  static List<Map<String, Object?>> _buildAntardashas({
    required String mahaLord,
    required int mahaYears,
    required DateTime mahaStart,
    required DateTime mahaEnd,
    required DateTime birthUtc,
  }) {
    final periods = <Map<String, Object?>>[];
    final mahaSequenceIndex = sequence.indexOf(mahaLord);
    var antarStart = mahaStart;
    for (var offset = 0; offset < sequence.length; offset += 1) {
      final antarLord =
          sequence[(mahaSequenceIndex + offset) % sequence.length];
      final antarDays = mahaYears *
          yearsByLord[antarLord]! /
          cycleYears *
          yearLengthDays;
      final antarEnd = offset == sequence.length - 1
          ? mahaEnd
          : _addDays(antarStart, antarDays);
      final pratyantardashas = _buildPratyantardashas(
        mahaLord: mahaLord,
        antarLord: antarLord,
        antarStart: antarStart,
        antarEnd: antarEnd,
        birthUtc: birthUtc,
      );
      periods.add({
        'mahadashaLord': mahaLord,
        'antardashaLord': antarLord,
        'startUtc': antarStart.toIso8601String(),
        'endUtc': antarEnd.toIso8601String(),
        'activeAtBirth': _contains(antarStart, antarEnd, birthUtc),
        'pratyantardashas': pratyantardashas,
      });
      antarStart = antarEnd;
    }
    return periods;
  }

  static List<Map<String, Object?>> _buildPratyantardashas({
    required String mahaLord,
    required String antarLord,
    required DateTime antarStart,
    required DateTime antarEnd,
    required DateTime birthUtc,
  }) {
    final periods = <Map<String, Object?>>[];
    final antarSequenceIndex = sequence.indexOf(antarLord);
    final parentMicroseconds =
        antarEnd.difference(antarStart).inMicroseconds;
    var pratyantarStart = antarStart;
    for (var offset = 0; offset < sequence.length; offset += 1) {
      final pratyantarLord =
          sequence[(antarSequenceIndex + offset) % sequence.length];
      final pratyantarEnd = offset == sequence.length - 1
          ? antarEnd
          : pratyantarStart.add(
              Duration(
                microseconds: (parentMicroseconds *
                        yearsByLord[pratyantarLord]! /
                        cycleYears)
                    .round(),
              ),
            );
      periods.add({
        'mahadashaLord': mahaLord,
        'antardashaLord': antarLord,
        'pratyantardashaLord': pratyantarLord,
        'startUtc': pratyantarStart.toIso8601String(),
        'endUtc': pratyantarEnd.toIso8601String(),
        'activeAtBirth':
            _contains(pratyantarStart, pratyantarEnd, birthUtc),
      });
      pratyantarStart = pratyantarEnd;
    }
    return periods;
  }

  static bool _contains(DateTime start, DateTime end, DateTime instant) =>
      !instant.isBefore(start) && instant.isBefore(end);

  static DateTime _addDays(DateTime start, double days) => start.add(
        Duration(
          microseconds:
              (days * Duration.microsecondsPerDay).round(),
        ),
      );
}
