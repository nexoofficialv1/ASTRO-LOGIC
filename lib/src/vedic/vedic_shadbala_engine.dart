import '../models/calculation_output_snapshot.dart';
import '../models/kundli_analysis.dart';

part 'vedic_shadbala_profile_rules.dart';
part 'vedic_shadbala_kala_geometry.dart';
part 'vedic_shadbala_support.dart';

/// Auditable Shadbala foundation.
///
/// Version 10 publishes governed Sthana, Dig, complete-when-evidence-is-present
/// Kala Bala (including Yuddha), Cheshta, Naisargika and exact-longitude Drik
/// Bala for the seven classical planets, then exposes the sixfold aggregate
/// whenever all six families are available. The aggregate is compared only
/// with the BPHS 27.32-33 planet-specific required Shadbala total. This
/// strength threshold is not converted into benefic/malefic outcome polarity.
class VedicShadbalaEngine {
  const VedicShadbalaEngine();

  static const String ruleVersion = 'shadbala-foundation-v10';

  List<ShadbalaPlanetProfile> build(CalculationOutputSnapshot output) {
    if (!_supportedSchemas.contains(output.outputSchemaVersion)) {
      throw ArgumentError(
        'Shadbala foundation requires vedic-chart-v1 through vedic-chart-v10 output',
      );
    }
    final ascendant = _requiredMap(output.output['ascendant'], 'ascendant');
    final ascendantSign = _requiredSignIndex(
      ascendant['signIndex'],
      'ascendant.signIndex',
    );
    final ascendantLongitude = _requiredLongitude(
      ascendant['siderealLongitude'],
      'ascendant.siderealLongitude',
    );
    if ((ascendantLongitude ~/ 30) != ascendantSign) {
      throw StateError('Ascendant sign and longitude disagree');
    }
    final planets = _requiredPlanets(
      output.output['planets'],
      requireEclipticLatitude: output.outputSchemaVersion == 'vedic-chart-v9' ||
          output.outputSchemaVersion == 'vedic-chart-v10',
      requireLongitudeSpeed: output.outputSchemaVersion == 'vedic-chart-v5' ||
          output.outputSchemaVersion == 'vedic-chart-v6' ||
          output.outputSchemaVersion == 'vedic-chart-v7' ||
          output.outputSchemaVersion == 'vedic-chart-v8' ||
          output.outputSchemaVersion == 'vedic-chart-v9' ||
          output.outputSchemaVersion == 'vedic-chart-v10',
    );
    final hasApparentTime = output.outputSchemaVersion == 'vedic-chart-v6' ||
        output.outputSchemaVersion == 'vedic-chart-v7' ||
        output.outputSchemaVersion == 'vedic-chart-v8' ||
        output.outputSchemaVersion == 'vedic-chart-v9' ||
        output.outputSchemaVersion == 'vedic-chart-v10';
    final sunHourAngleHours = hasApparentTime
        ? _requiredSunHourAngle(output.output['metadata'])
        : null;
    final tribhaga = output.outputSchemaVersion == 'vedic-chart-v7' ||
            output.outputSchemaVersion == 'vedic-chart-v8' ||
            output.outputSchemaVersion == 'vedic-chart-v9' ||
            output.outputSchemaVersion == 'vedic-chart-v10'
        ? _optionalTribhagaContext(output.output['metadata'])
        : null;
    final varshaMasaDinaHora = output.outputSchemaVersion == 'vedic-chart-v8' ||
            output.outputSchemaVersion == 'vedic-chart-v9' ||
            output.outputSchemaVersion == 'vedic-chart-v10'
        ? _varshaMasaDinaHoraContext(output.output['metadata'])
        : null;
    for (final planet in _classicalPlanets) {
      if (!planets.containsKey(planet)) {
        throw StateError('Vedic output is missing required planet $planet');
      }
    }

    final preWarStrengths = <String, double?>{
      for (final planet in _classicalPlanets)
        planet: _preWarShadbala(
          planet,
          planets[planet]!,
          ascendantSign,
          ascendantLongitude,
          planets,
          sunHourAngleHours,
          tribhaga,
          varshaMasaDinaHora,
        ),
    };
    final yuddha = _yuddhaResults(
      planets,
      preWarStrengths,
      latitudeEvidenceAvailable: output.outputSchemaVersion == 'vedic-chart-v9' ||
          output.outputSchemaVersion == 'vedic-chart-v10',
    );

    return [
      for (final planet in _classicalPlanets)
        _profile(
          planet,
          planets[planet]!,
          ascendantSign,
          ascendantLongitude,
          planets,
          sunHourAngleHours,
          tribhaga,
          varshaMasaDinaHora,
          yuddha[planet]!,
        ),
    ];
  }

}
