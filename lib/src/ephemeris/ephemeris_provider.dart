import '../models/astrology_settings.dart';

enum CelestialBody {
  sun,
  moon,
  mars,
  mercury,
  jupiter,
  venus,
  saturn,
  rahu,
}

class EphemerisRequest {
  const EphemerisRequest({
    required this.utcDateTime,
    required this.latitude,
    required this.longitude,
    required this.ayanamsha,
    required this.lunarNodeMode,
  });

  final DateTime utcDateTime;
  final double latitude;
  final double longitude;
  final Ayanamsha ayanamsha;
  final LunarNodeMode lunarNodeMode;
}

class EphemerisPosition {
  const EphemerisPosition({
    required this.tropicalLongitude,
    required this.eclipticLatitude,
    required this.longitudeSpeed,
  });

  final double tropicalLongitude;
  final double eclipticLatitude;
  final double longitudeSpeed;
}

class EphemerisFrame {
  const EphemerisFrame({
    required this.positions,
    required this.tropicalAscendant,
    required this.ayanamshaDegrees,
    required this.sunHourAngleHours,
    this.tribhagaIsDay,
    this.tribhagaThird,
    this.tribhagaPeriodStartOffsetDays,
    this.tribhagaPeriodEndOffsetDays,
    this.astrologicalDayStartOffsetDays,
    this.varshaIngressOffsetDays,
    this.varshaDayStartOffsetDays,
    this.masaIngressOffsetDays,
    this.masaDayStartOffsetDays,
  });

  final Map<CelestialBody, EphemerisPosition> positions;
  final double tropicalAscendant;
  final double ayanamshaDegrees;

  /// Observer-specific apparent Sun hour angle in [0, 24).
  /// 0h is local apparent upper transit (noon); 12h is apparent midnight.
  final double sunHourAngleHours;

  /// True for the sunrise-to-sunset period, false for sunset-to-sunrise.
  /// Null when rise/set search is unavailable (for example polar day/night).
  final bool? tribhagaIsDay;

  /// One-based third (1..3) of the active day/night period.
  final int? tribhagaThird;

  /// Exact Astronomy Engine rise/set boundaries as day offsets from
  /// [EphemerisRequest.utcDateTime], retained so the derivation layer can
  /// persist auditable UTC timestamps without native string allocation.
  final double? tribhagaPeriodStartOffsetDays;
  final double? tribhagaPeriodEndOffsetDays;

  /// Previous sunrise that starts the astrological weekday containing the
  /// request instant. Null when rise/set search is unavailable.
  final double? astrologicalDayStartOffsetDays;

  /// Prior sidereal Aries ingress of the Sun and the sunrise that starts its
  /// astrological weekday. These are used by governed Varsha Bala.
  final double? varshaIngressOffsetDays;
  final double? varshaDayStartOffsetDays;

  /// Prior sidereal ingress of the Sun into the current sign and the sunrise
  /// that starts its astrological weekday. These are used by governed Masa Bala.
  final double? masaIngressOffsetDays;
  final double? masaDayStartOffsetDays;
}

abstract interface class EphemerisProvider {
  String get engineId;

  String get engineVersion;

  Future<EphemerisFrame> calculate(EphemerisRequest request);
}

