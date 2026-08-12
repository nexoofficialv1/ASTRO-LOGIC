import 'kp_foundation_engine.dart';

/// Derives KP house occupancy, cusp-sign ownership and the frozen four-level
/// significator hierarchy from an already-cast sidereal Placidus chart.
class KpHouseEvidenceEngine {
  const KpHouseEvidenceEngine._();

  static const engineVersion = '1.0.0';
  static const profileVersion = 'kp-house-significator-synthesis-v1';

  static KpHouseEvidenceMatrix build({
    required Map<String, KpPointClassification> planetClassifications,
    required List<KpCuspClassification> cusps,
  }) {
    if (cusps.length != 12) {
      throw ArgumentError.value(cusps.length, 'cusps', 'Requires 12 cusps');
    }
    for (final lord in KpFoundationEngine.vimshottariSequence) {
      if (!planetClassifications.containsKey(lord)) {
        throw ArgumentError('Missing KP planet classification: $lord');
      }
    }

    final cuspLongitudes = cusps
        .map((cusp) => cusp.point.siderealLongitude)
        .toList(growable: false);
    _validateCuspCycle(cuspLongitudes);

    final occupiedHouseByPlanet = <String, int>{};
    for (final entry in planetClassifications.entries) {
      occupiedHouseByPlanet[entry.key] = houseForLongitude(
        longitude: entry.value.siderealLongitude,
        cuspLongitudes: cuspLongitudes,
      );
    }

    final ownedHousesByPlanet = <String, List<int>>{};
    for (final planet in KpFoundationEngine.vimshottariSequence) {
      // Rahu and Ketu have no sign ownership in this frozen KP profile.
      ownedHousesByPlanet[planet] = planet == 'rahu' || planet == 'ketu'
          ? const <int>[]
          : List<int>.unmodifiable(
              cusps
                  .where((cusp) => cusp.point.signLord == planet)
                  .map((cusp) => cusp.house),
            );
    }

    final profiles = <String, KpPlanetHouseEvidence>{};
    for (final planet in KpFoundationEngine.vimshottariSequence) {
      final point = planetClassifications[planet]!;
      final starLord = point.starLord;
      final profile = KpFoundationEngine.buildSignificator(
        planet: planet,
        occupiedHouse: occupiedHouseByPlanet[planet]!,
        ownedHouses: ownedHousesByPlanet[planet]!,
        starLord: starLord,
        starLordOccupiedHouse: occupiedHouseByPlanet[starLord]!,
        starLordOwnedHouses: ownedHousesByPlanet[starLord]!,
      );
      profiles[planet] = KpPlanetHouseEvidence(
        planet: planet,
        occupiedHouse: occupiedHouseByPlanet[planet]!,
        ownedHouses: ownedHousesByPlanet[planet]!,
        starLord: starLord,
        starLordOccupiedHouse: occupiedHouseByPlanet[starLord]!,
        starLordOwnedHouses: ownedHousesByPlanet[starLord]!,
        significator: profile,
      );
    }

    final occupantsByHouse = <int, List<String>>{
      for (var house = 1; house <= 12; house++) house: <String>[],
    };
    for (final entry in occupiedHouseByPlanet.entries) {
      occupantsByHouse[entry.value]!.add(entry.key);
    }

    return KpHouseEvidenceMatrix(
      profileVersion: profileVersion,
      cuspLords: <int, String>{
        for (final cusp in cusps) cusp.house: cusp.point.signLord,
      },
      occupantsByHouse: <int, List<String>>{
        for (final entry in occupantsByHouse.entries)
          entry.key: List<String>.unmodifiable(entry.value),
      },
      planets: Map<String, KpPlanetHouseEvidence>.unmodifiable(profiles),
    );
  }

  static int houseForLongitude({
    required double longitude,
    required List<double> cuspLongitudes,
  }) {
    if (!longitude.isFinite || cuspLongitudes.length != 12) {
      throw ArgumentError('Valid longitude and exactly 12 cusps are required');
    }
    _validateCuspCycle(cuspLongitudes);
    final point = _normalize(longitude);
    for (var index = 0; index < 12; index++) {
      final start = _normalize(cuspLongitudes[index]);
      final end = _normalize(cuspLongitudes[(index + 1) % 12]);
      final span = _forwardDistance(start, end);
      final distance = _forwardDistance(start, point);
      if (distance < span) return index + 1;
    }
    // The only unassigned location is an exact 360° normalization boundary;
    // that boundary belongs to the cusp that starts there.
    return 1;
  }

  static void _validateCuspCycle(List<double> values) {
    if (values.length != 12 || values.any((value) => !value.isFinite)) {
      throw ArgumentError('Exactly 12 finite cusp longitudes are required');
    }
    var total = 0.0;
    for (var index = 0; index < 12; index++) {
      final span = _forwardDistance(
        _normalize(values[index]),
        _normalize(values[(index + 1) % 12]),
      );
      if (span <= 1e-9 || span >= 180.0) {
        throw StateError('Invalid Placidus cusp order at house ${index + 1}');
      }
      total += span;
    }
    if ((total - 360.0).abs() > 1e-6) {
      throw StateError('Cusp cycle does not cover exactly 360 degrees');
    }
  }

  static double _forwardDistance(double from, double to) {
    final value = (to - from) % 360.0;
    return value < 0 ? value + 360.0 : value;
  }

  static double _normalize(double value) {
    final normalized = value % 360.0;
    return normalized < 0 ? normalized + 360.0 : normalized;
  }
}

class KpPlanetHouseEvidence {
  const KpPlanetHouseEvidence({
    required this.planet,
    required this.occupiedHouse,
    required this.ownedHouses,
    required this.starLord,
    required this.starLordOccupiedHouse,
    required this.starLordOwnedHouses,
    required this.significator,
  });

  final String planet;
  final int occupiedHouse;
  final List<int> ownedHouses;
  final String starLord;
  final int starLordOccupiedHouse;
  final List<int> starLordOwnedHouses;
  final KpSignificatorProfile significator;

  Map<String, Object?> toJson() => <String, Object?>{
        'planet': planet,
        'occupiedHouse': occupiedHouse,
        'ownedHouses': ownedHouses,
        'starLord': starLord,
        'starLordOccupiedHouse': starLordOccupiedHouse,
        'starLordOwnedHouses': starLordOwnedHouses,
        'significator': significator.toJson(),
      };
}

class KpHouseEvidenceMatrix {
  const KpHouseEvidenceMatrix({
    required this.profileVersion,
    required this.cuspLords,
    required this.occupantsByHouse,
    required this.planets,
  });

  final String profileVersion;
  final Map<int, String> cuspLords;
  final Map<int, List<String>> occupantsByHouse;
  final Map<String, KpPlanetHouseEvidence> planets;

  KpPlanetHouseEvidence planet(String name) {
    final value = planets[name.toLowerCase()];
    if (value == null) throw ArgumentError('Unknown KP planet: $name');
    return value;
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'engineVersion': KpHouseEvidenceEngine.engineVersion,
        'profileVersion': profileVersion,
        'cuspLords': <String, String>{
          for (final entry in cuspLords.entries) '${entry.key}': entry.value,
        },
        'occupantsByHouse': <String, List<String>>{
          for (final entry in occupantsByHouse.entries)
            '${entry.key}': entry.value,
        },
        'planets': <String, Object?>{
          for (final entry in planets.entries) entry.key: entry.value.toJson(),
        },
      };
}
