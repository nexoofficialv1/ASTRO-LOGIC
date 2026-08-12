part of 'vedic_shadbala_engine.dart';

Map<String, Object?> _requiredMap(Object? value, String path) {
  if (value is! Map) throw StateError('Missing or invalid $path');
  return Map<String, Object?>.from(value);
}

int _requiredSignIndex(Object? value, String path) {
  if (value is! int || value < 0 || value > 11) {
    throw StateError('Missing or invalid $path');
  }
  return value;
}

double _requiredLongitude(Object? value, String path) {
  if (value is! num ||
      !value.toDouble().isFinite ||
      value.toDouble() < 0 ||
      value.toDouble() >= 360) {
    throw StateError('Missing or invalid $path');
  }
  return value.toDouble();
}

double? _optionalFiniteDouble(
  Object? value,
  String path, {
  required bool required,
}) {
  if (value == null) {
    if (required) throw StateError('Missing $path');
    return null;
  }
  if (value is! num || !value.toDouble().isFinite) {
    throw StateError('Missing or invalid $path');
  }
  return value.toDouble();
}

double? _optionalEclipticLatitude(
  Object? value,
  String path, {
  required bool required,
}) {
  if (value == null) {
    if (required) throw StateError('Missing $path');
    return null;
  }
  if (value is! num ||
      !value.toDouble().isFinite ||
      value.toDouble() < -90.0 ||
      value.toDouble() > 90.0) {
    throw StateError('Missing or invalid $path');
  }
  return value.toDouble();
}

String _fmt(double value) {
  final fixed = value.toStringAsFixed(3);
  return fixed.replaceFirst(RegExp(r'\.?0+$'), '');
}

const _supportedSchemas = {
  'vedic-chart-v1',
  'vedic-chart-v2',
  'vedic-chart-v3',
  'vedic-chart-v4',
  'vedic-chart-v5',
  'vedic-chart-v6',
  'vedic-chart-v7',
  'vedic-chart-v8',
  'vedic-chart-v9',
  'vedic-chart-v10',
};
const _planetaryWarBodies = <String>[
  'mars',
  'mercury',
  'jupiter',
  'venus',
  'saturn',
];
const double _planetaryWarThresholdDegrees = 1.0;
const double _latitudeTieToleranceDegrees = 1e-9;
const _classicalPlanets = [
  'sun',
  'moon',
  'mars',
  'mercury',
  'jupiter',
  'venus',
  'saturn',
];
const _pakshaBenefics = <String>{
  'moon',
  'mercury',
  'jupiter',
  'venus',
};
// Versioned geocentric mean daily motion constants in degrees/day used
// only to operationalize the BPHS 27.21-23 speed-state labels.
const _meanDailyMotionDegrees = <String, double>{
  'mars': 31.0 / 60.0,
  'mercury': 1.0 + 23.0 / 60.0,
  'jupiter': 5.0 / 60.0,
  'venus': 1.0 + 12.0 / 60.0,
  'saturn': 2.0 / 60.0,
};
const _deepDebilitationLongitude = <String, double>{
  'sun': 190.0,
  'moon': 213.0,
  'mars': 118.0,
  'mercury': 345.0,
  'jupiter': 275.0,
  'venus': 177.0,
  'saturn': 20.0,
};
// BPHS 27.7 zero-strength directional points measured from Lagna:
// Sun/Mars -> 4th; Jupiter/Mercury -> 7th; Moon/Venus -> 10th;
// Saturn -> Lagna. The exact angular separation (folded to <= 180°) / 3
// yields 0..60 virupas. The opposite points are the full-strength angles.
const _digBalaPowerlessOffset = <String, double>{
  'sun': 90.0,
  'moon': 270.0,
  'mars': 90.0,
  'mercury': 180.0,
  'jupiter': 180.0,
  'venus': 270.0,
  'saturn': 0.0,
};
// BPHS 27.32-33 required Shadbala Pinda totals, in virupas.
// These are used only as quantitative strength sufficiency thresholds.
const _requiredShadbalaVirupas = <String, double>{
  'sun': 390.0,
  'moon': 360.0,
  'mars': 300.0,
  'mercury': 420.0,
  'jupiter': 390.0,
  'venus': 330.0,
  'saturn': 300.0,
};
const _naisargikaBala = <String, double>{
  'sun': 60.0,
  'moon': 360.0 / 7.0,
  'venus': 300.0 / 7.0,
  'jupiter': 240.0 / 7.0,
  'mercury': 180.0 / 7.0,
  'mars': 120.0 / 7.0,
  'saturn': 60.0 / 7.0,
};
const _temporaryFriendHouses = <int>{2, 3, 4, 10, 11, 12};
const _signLords = <int, String>{
  0: 'mars',
  1: 'venus',
  2: 'mercury',
  3: 'moon',
  4: 'sun',
  5: 'mercury',
  6: 'venus',
  7: 'mars',
  8: 'jupiter',
  9: 'saturn',
  10: 'saturn',
  11: 'jupiter',
};
const _naturalFriends = <String, Set<String>>{
  'sun': {'moon', 'mars', 'jupiter'},
  'moon': {'sun', 'mercury'},
  'mars': {'sun', 'moon', 'jupiter'},
  'mercury': {'sun', 'venus'},
  'jupiter': {'sun', 'moon', 'mars'},
  'venus': {'mercury', 'saturn'},
  'saturn': {'mercury', 'venus'},
};
const _naturalEnemies = <String, Set<String>>{
  'sun': {'venus', 'saturn'},
  'moon': <String>{},
  'mars': {'mercury'},
  'mercury': {'moon'},
  'jupiter': {'mercury', 'venus'},
  'venus': {'sun', 'moon'},
  'saturn': {'sun', 'moon', 'mars'},
};
const _moolatrikonaRanges = <String, _DegreeRange>{
  'sun': _DegreeRange(4, 0, 20),
  'moon': _DegreeRange(1, 3, 30),
  'mars': _DegreeRange(0, 0, 12),
  'mercury': _DegreeRange(5, 15, 20),
  'jupiter': _DegreeRange(8, 0, 10),
  'venus': _DegreeRange(6, 0, 15),
  'saturn': _DegreeRange(10, 0, 20),
};
const _planetNamesEn = <String, String>{
  'sun': 'Sun',
  'moon': 'Moon',
  'mars': 'Mars',
  'mercury': 'Mercury',
  'jupiter': 'Jupiter',
  'venus': 'Venus',
  'saturn': 'Saturn',
};
const _planetNamesBn = <String, String>{
  'sun': 'সূর্য',
  'moon': 'চন্দ্র',
  'mars': 'মঙ্গল',
  'mercury': 'বুধ',
  'jupiter': 'বৃহস্পতি',
  'venus': 'শুক্র',
  'saturn': 'শনি',
};
_DrikResult _drikBala(
  String targetPlanet,
  _Planet target,
  Map<String, _Planet> planets,
) {
  final contributions = <DrikBalaContribution>[];
  for (final aspector in _classicalPlanets) {
    if (aspector == targetPlanet) continue;
    final source = planets[aspector]!;
    final angle = _normalize(target.siderealLongitude - source.siderealLongitude);
    final aspect = _sphutaDrishtiVirupas(aspector, angle);
    if (aspect <= 1e-12) continue;
    final nature = _drikNature(aspector, planets);
    final baseQuarter = aspect * (nature == 'benefic' ? 0.25 : -0.25);
    final superAdded = (aspector == 'mercury' || aspector == 'jupiter')
        ? aspect
        : 0.0;
    contributions.add(
      DrikBalaContribution(
        aspector: aspector,
        aspectAngleDegrees: angle,
        aspectVirupas: aspect,
        nature: nature,
        baseQuarterContributionVirupas: baseQuarter,
        superAddedVirupas: superAdded,
        netContributionVirupas: baseQuarter + superAdded,
      ),
    );
  }
  return _DrikResult(
    virupas: contributions.fold<double>(
      0.0,
      (sum, value) => sum + value.netContributionVirupas,
    ),
    contributions: contributions,
  );
}

/// Exact aspect strength in virupas for the governed Sphuta-Drishti profile.
///
/// The common six BPHS Chapter-26 intervals are used for all planets. Mars,
/// Jupiter and Saturn then use the versioned special-aspect curves that keep
/// the classical full-strength peaks at 120/210, 120/240 and 60/270 degrees
/// respectively. The Jupiter 240..270 segment uses the continuity-preserving
/// corrected envelope (60 at 240 -> 15 at 270) rather than the visibly
/// corrupt literal branch found in some translations.
double _sphutaDrishtiVirupas(String aspector, double angle) {
  final a = _normalize(angle);
  if (a < 30.0 || a >= 300.0) return 0.0;

  if (aspector == 'mars') {
    if (a >= 90.0 && a < 120.0) return 45.0 + (a - 90.0) / 2.0;
    if (a >= 120.0 && a < 150.0) return 2.0 * (150.0 - a);
    if (a >= 180.0 && a < 210.0) return 60.0;
    if (a >= 210.0 && a < 240.0) return 270.0 - a;
  } else if (aspector == 'jupiter') {
    if (a >= 90.0 && a < 120.0) return 45.0 + (a - 90.0) / 2.0;
    if (a >= 120.0 && a < 150.0) return 2.0 * (150.0 - a);
    if (a >= 210.0 && a < 240.0) return 45.0 + (a - 210.0) / 2.0;
    if (a >= 240.0 && a < 270.0) return 15.0 + 1.5 * (270.0 - a);
  } else if (aspector == 'saturn') {
    if (a >= 30.0 && a < 60.0) return 2.0 * (a - 30.0);
    if (a >= 60.0 && a < 90.0) return 45.0 + (90.0 - a) / 2.0;
    if (a >= 240.0 && a < 270.0) return a - 210.0;
    if (a >= 270.0 && a < 300.0) return 2.0 * (300.0 - a);
  }

  if (a < 60.0) return (a - 30.0) / 2.0;
  if (a < 90.0) return a - 45.0;
  if (a < 120.0) return 30.0 + (120.0 - a) / 2.0;
  if (a < 150.0) return 150.0 - a;
  if (a < 180.0) return 2.0 * (a - 150.0);
  return (300.0 - a) / 2.0;
}

String _drikNature(String planet, Map<String, _Planet> planets) {
  if (planet == 'jupiter' || planet == 'venus') return 'benefic';
  if (planet == 'sun' || planet == 'mars' || planet == 'saturn') {
    return 'malefic';
  }
  if (planet == 'moon') {
    return _moonIsWaxing(planets) ? 'benefic' : 'malefic';
  }
  if (planet == 'mercury') {
    final mercury = planets['mercury']!;
    final maleficCompanions = <String>{'sun', 'mars', 'saturn'};
    if (!_moonIsWaxing(planets)) maleficCompanions.add('moon');
    final joinedMalefic = maleficCompanions.any(
      (name) => planets[name]!.signIndex == mercury.signIndex,
    );
    return joinedMalefic ? 'malefic' : 'benefic';
  }
  throw StateError('Unsupported Drik nature planet: $planet');
}

bool _moonIsWaxing(Map<String, _Planet> planets) {
  final elongation = _normalize(
    planets['moon']!.siderealLongitude - planets['sun']!.siderealLongitude,
  );
  return elongation > 0.0 && elongation <= 180.0;
}

class _DrikResult {
  const _DrikResult({required this.virupas, required this.contributions});

  final double virupas;
  final List<DrikBalaContribution> contributions;
}

class _TribhagaContext {
  const _TribhagaContext({
    required this.isDay,
    required this.third,
    required this.startUtc,
    required this.endUtc,
  });

  final bool isDay;
  final int third;
  final String startUtc;
  final String endUtc;
  String get period => isDay ? 'day' : 'night';
}

class _VarshaMasaDinaHoraContext {
  const _VarshaMasaDinaHoraContext({
    required this.profile,
    required this.varshaLord,
    required this.masaLord,
    required this.dinaLord,
    required this.horaLord,
    required this.horaNumber,
    required this.horaPeriod,
    required this.astrologicalDayStartUtc,
    required this.varshaIngressUtc,
    required this.varshaDayStartUtc,
    required this.masaIngressUtc,
    required this.masaDayStartUtc,
  });

  final String profile;
  final String? varshaLord;
  final String? masaLord;
  final String? dinaLord;
  final String? horaLord;
  final int? horaNumber;
  final String? horaPeriod;
  final String? astrologicalDayStartUtc;
  final String? varshaIngressUtc;
  final String? varshaDayStartUtc;
  final String? masaIngressUtc;
  final String? masaDayStartUtc;
}

class _CheshtaResult {
  const _CheshtaResult({
    required this.virupas,
    required this.method,
    required this.motionState,
    required this.outputPath,
    required this.descriptionEn,
    required this.descriptionBn,
    required this.governanceEn,
    required this.governanceBn,
  });

  final double? virupas;
  final String method;
  final String? motionState;
  final String outputPath;
  final String descriptionEn;
  final String descriptionBn;
  final String governanceEn;
  final String governanceBn;
}

class _Planet {
  const _Planet({
    required this.signIndex,
    required this.siderealLongitude,
    required this.tropicalLongitude,
    required this.navamsaSignIndex,
    required this.longitudeSpeedPerDay,
    required this.eclipticLatitude,
  });

  final int signIndex;
  final double siderealLongitude;
  final double tropicalLongitude;
  final int navamsaSignIndex;
  final double? longitudeSpeedPerDay;
  final double? eclipticLatitude;
  double get degreeInSign => siderealLongitude % 30.0;
}

class _YuddhaResult {
  const _YuddhaResult._({
    required this.virupas,
    required this.profile,
    required this.role,
    required this.partner,
    required this.separationDegrees,
    required this.latitudeDegrees,
    required this.partnerLatitudeDegrees,
    required this.preWarStrengthDifference,
    required this.outputPath,
    required this.descriptionEn,
    required this.descriptionBn,
  });

  factory _YuddhaResult.noWar({
    required String role,
    double? latitudeDegrees,
    required String descriptionEn,
    required String descriptionBn,
  }) =>
      _YuddhaResult._(
        virupas: 0.0,
        profile: 'bphs27_20NorthernLatitudeYuddhaV1',
        role: role,
        partner: null,
        separationDegrees: null,
        latitudeDegrees: latitudeDegrees,
        partnerLatitudeDegrees: null,
        preWarStrengthDifference: 0.0,
        outputPath: r'$.planets',
        descriptionEn: descriptionEn,
        descriptionBn: descriptionBn,
      );

  factory _YuddhaResult.unavailable({
    required String role,
    String? partner,
    double? separationDegrees,
    double? latitudeDegrees,
    double? partnerLatitudeDegrees,
    required String descriptionEn,
    required String descriptionBn,
  }) =>
      _YuddhaResult._(
        virupas: null,
        profile: 'bphs27_20NorthernLatitudeYuddhaV1',
        role: role,
        partner: partner,
        separationDegrees: separationDegrees,
        latitudeDegrees: latitudeDegrees,
        partnerLatitudeDegrees: partnerLatitudeDegrees,
        preWarStrengthDifference: null,
        outputPath: r'$.planets',
        descriptionEn: descriptionEn,
        descriptionBn: descriptionBn,
      );

  factory _YuddhaResult.computed({
    required double virupas,
    required String role,
    required String partner,
    required double separationDegrees,
    required double latitudeDegrees,
    required double partnerLatitudeDegrees,
    required double preWarStrengthDifference,
    required String descriptionEn,
    required String descriptionBn,
  }) =>
      _YuddhaResult._(
        virupas: virupas,
        profile: 'bphs27_20NorthernLatitudeYuddhaV1',
        role: role,
        partner: partner,
        separationDegrees: separationDegrees,
        latitudeDegrees: latitudeDegrees,
        partnerLatitudeDegrees: partnerLatitudeDegrees,
        preWarStrengthDifference: preWarStrengthDifference,
        outputPath: r'$.planets[*].eclipticLatitude',
        descriptionEn: descriptionEn,
        descriptionBn: descriptionBn,
      );

  final double? virupas;
  final String profile;
  final String role;
  final String? partner;
  final double? separationDegrees;
  final double? latitudeDegrees;
  final double? partnerLatitudeDegrees;
  final double? preWarStrengthDifference;
  final String outputPath;
  final String descriptionEn;
  final String descriptionBn;
}

class _DegreeRange {
  const _DegreeRange(this.signIndex, this.startDegree, this.endDegree);

  final int signIndex;
  final double startDegree;
  final double endDegree;
}
