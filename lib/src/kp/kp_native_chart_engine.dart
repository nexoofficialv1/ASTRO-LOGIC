import '../models/astrology_settings.dart';
import 'kp_foundation_engine.dart';
import 'kp_governance.dart';
import 'kp_house_evidence_engine.dart';

enum KpNativeBody { sun, moon, mars, mercury, jupiter, venus, saturn }

class KpNativePositionData {
  const KpNativePositionData({
    required this.tropicalLongitude,
    required this.eclipticLatitude,
    required this.longitudeSpeedPerDay,
  });
  final double tropicalLongitude;
  final double eclipticLatitude;
  final double longitudeSpeedPerDay;
}

class KpNativeFrameData {
  const KpNativeFrameData({
    required this.krishnamurtiAyanamsha,
    required this.tropicalAscendant,
    required this.tropicalMc,
    required this.siderealAscendant,
    required this.siderealMc,
    required this.trueNodeTropical,
    required this.meanNodeTropical,
    required this.tropicalCusps,
    required this.siderealCusps,
  });
  final double krishnamurtiAyanamsha;
  final double tropicalAscendant;
  final double tropicalMc;
  final double siderealAscendant;
  final double siderealMc;
  final double trueNodeTropical;
  final double meanNodeTropical;
  final List<double> tropicalCusps;
  final List<double> siderealCusps;
}

abstract interface class KpNativeBridge {
  String get libraryVersion;
  Future<KpNativeFrameData> calculateFrame({
    required DateTime utc,
    required double latitude,
    required double longitude,
  });
  Future<KpNativePositionData> calculatePosition({
    required KpNativeBody body,
    required DateTime utc,
  });
}

class KpNativeChartInput {
  const KpNativeChartInput({
    required this.utc,
    required this.latitude,
    required this.longitude,
    required this.nodeMode,
  });
  final DateTime utc;
  final double latitude;
  final double longitude;
  final LunarNodeMode nodeMode;

  Map<String, Object?> toJson() => {
        'utc': utc.toUtc().toIso8601String(),
        'latitude': latitude,
        'longitude': longitude,
        'nodeMode': nodeMode.name,
        'ayanamshaProfile': KpGovernance.ayanamshaProfile,
        'houseProfile': KpGovernance.houseProfile,
      };
}

class KpNativeChartPoint {
  const KpNativeChartPoint({
    required this.name,
    required this.tropicalLongitude,
    required this.siderealLongitude,
    required this.eclipticLatitude,
    required this.longitudeSpeedPerDay,
    required this.classification,
  });
  final String name;
  final double tropicalLongitude;
  final double siderealLongitude;
  final double eclipticLatitude;
  final double? longitudeSpeedPerDay;
  final KpPointClassification classification;

  Map<String, Object?> toJson() => {
        'name': name,
        'tropicalLongitude': tropicalLongitude,
        'siderealLongitude': siderealLongitude,
        'eclipticLatitude': eclipticLatitude,
        'longitudeSpeedPerDay': longitudeSpeedPerDay,
        'classification': classification.toJson(),
      };
}

class KpNativeCuspPoint {
  const KpNativeCuspPoint({
    required this.house,
    required this.tropicalLongitude,
    required this.siderealLongitude,
    required this.classification,
  });
  final int house;
  final double tropicalLongitude;
  final double siderealLongitude;
  final KpPointClassification classification;

  Map<String, Object?> toJson() => {
        'house': house,
        'tropicalLongitude': tropicalLongitude,
        'siderealLongitude': siderealLongitude,
        'classification': classification.toJson(),
      };
}

class KpNativeChart {
  const KpNativeChart({
    required this.nativeLibraryVersion,
    required this.input,
    required this.krishnamurtiAyanamsha,
    required this.ascendant,
    required this.mc,
    required this.planets,
    required this.cusps,
    required this.rulingPlanets,
    required this.houseEvidence,
  });
  final String nativeLibraryVersion;
  final KpNativeChartInput input;
  final double krishnamurtiAyanamsha;
  final KpPointClassification ascendant;
  final KpPointClassification mc;
  final List<KpNativeChartPoint> planets;
  final List<KpNativeCuspPoint> cusps;
  final KpRulingPlanetPanel rulingPlanets;
  final KpHouseEvidenceMatrix houseEvidence;

  Map<String, Object?> toJson() => {
        'engineId': KpNativeChartEngine.engineId,
        'engineVersion': KpNativeChartEngine.engineVersion,
        'outputSchemaVersion': KpNativeChartEngine.outputSchemaVersion,
        'nativeLibraryVersion': nativeLibraryVersion,
        'input': input.toJson(),
        'governance': {
          'profileVersion': KpGovernance.profileVersion,
          'ayanamshaProfile': KpGovernance.ayanamshaProfile,
          'houseProfile': KpGovernance.houseProfile,
          'automaticEventPrediction': false,
          'automaticEventTiming': false,
          'crossSystemConfidenceUplift': false,
        },
        'krishnamurtiAyanamsha': krishnamurtiAyanamsha,
        'ascendant': ascendant.toJson(),
        'mc': mc.toJson(),
        'planets': planets.map((v) => v.toJson()).toList(growable: false),
        'cusps': cusps.map((v) => v.toJson()).toList(growable: false),
        'houseEvidence': houseEvidence.toJson(),
        'eventJudgment': null,
        'eventTiming': null,
        'timingConfirmation': null,
        'rulingPlanets': {
          'ruleVersion': rulingPlanets.ruleVersion,
          'roles': rulingPlanets.roles
              .map((r) => {'rank': r.rank, 'role': r.role, 'planet': r.planet})
              .toList(growable: false),
          'uniquePlanets': rulingPlanets.uniquePlanets,
        },
        'disclosures': const [
          'Classic Krishnamurti Reader-1 reconstruction is versioned and is not represented as the only historically possible KP ayanamsha definition.',
          'Placidus is solved natively without silent Porphyry fallback; unsupported polar geometry is rejected.',
          'Star/Sub, house-significator and ruling-planet output is evidence for practitioner review; event judgment is a separate source-bounded layer and never a real-world guarantee.',
        ],
      };
}

class KpNativeChartEngine {
  const KpNativeChartEngine(this.bridge);

  static const engineId = 'astro-logic-kp-native';
  static const engineVersion = '1.3.0';
  static const outputSchemaVersion = 'kp-native-chart-v4';

  final KpNativeBridge bridge;

  Future<KpNativeChart> cast(KpNativeChartInput input) async {
    final utc = input.utc.toUtc();
    if (!input.latitude.isFinite ||
        input.latitude < -90 ||
        input.latitude > 90 ||
        !input.longitude.isFinite ||
        input.longitude < -180 ||
        input.longitude > 180) {
      throw ArgumentError('Valid geographic coordinates are required');
    }
    if (utc.year < KpGovernance.validatedStartYear ||
        utc.year > KpGovernance.validatedEndYear) {
      throw RangeError(
        'KP native profile is validated only for '
        '${KpGovernance.validatedStartYear}–${KpGovernance.validatedEndYear}',
      );
    }

    final frame = await bridge.calculateFrame(
      utc: utc,
      latitude: input.latitude,
      longitude: input.longitude,
    );
    if (frame.tropicalCusps.length != 12 || frame.siderealCusps.length != 12) {
      throw StateError('Native Placidus engine did not return 12 cusps');
    }

    final planets = <KpNativeChartPoint>[];
    for (final body in KpNativeBody.values) {
      final raw = await bridge.calculatePosition(body: body, utc: utc);
      final sidereal =
          _normalize(raw.tropicalLongitude - frame.krishnamurtiAyanamsha);
      planets.add(
        KpNativeChartPoint(
          name: body.name,
          tropicalLongitude: raw.tropicalLongitude,
          siderealLongitude: sidereal,
          eclipticLatitude: raw.eclipticLatitude,
          longitudeSpeedPerDay: raw.longitudeSpeedPerDay,
          classification: KpFoundationEngine.classify(sidereal),
        ),
      );
    }

    final nodeTropical = input.nodeMode == LunarNodeMode.trueNode
        ? frame.trueNodeTropical
        : frame.meanNodeTropical;
    final rahuSidereal =
        _normalize(nodeTropical - frame.krishnamurtiAyanamsha);
    planets.add(
      KpNativeChartPoint(
        name: 'rahu',
        tropicalLongitude: nodeTropical,
        siderealLongitude: rahuSidereal,
        eclipticLatitude: 0,
        longitudeSpeedPerDay: null,
        classification: KpFoundationEngine.classify(rahuSidereal),
      ),
    );
    final ketuTropical = _normalize(nodeTropical + 180);
    final ketuSidereal = _normalize(rahuSidereal + 180);
    planets.add(
      KpNativeChartPoint(
        name: 'ketu',
        tropicalLongitude: ketuTropical,
        siderealLongitude: ketuSidereal,
        eclipticLatitude: 0,
        longitudeSpeedPerDay: null,
        classification: KpFoundationEngine.classify(ketuSidereal),
      ),
    );

    final cusps = List<KpNativeCuspPoint>.generate(
      12,
      (index) => KpNativeCuspPoint(
        house: index + 1,
        tropicalLongitude: frame.tropicalCusps[index],
        siderealLongitude: frame.siderealCusps[index],
        classification: KpFoundationEngine.classify(frame.siderealCusps[index]),
      ),
      growable: false,
    );
    final houseEvidence = KpHouseEvidenceEngine.build(
      planetClassifications: <String, KpPointClassification>{
        for (final planet in planets) planet.name: planet.classification,
      },
      cusps: cusps
          .map((cusp) => KpCuspClassification(
                house: cusp.house,
                point: cusp.classification,
              ))
          .toList(growable: false),
    );
    final moon = planets.firstWhere((planet) => planet.name == 'moon');
    final ruling = KpFoundationEngine.rulingPlanets(
      ascendantSiderealLongitude: frame.siderealAscendant,
      moonSiderealLongitude: moon.siderealLongitude,
      weekday: utc.weekday,
    );

    return KpNativeChart(
      nativeLibraryVersion: bridge.libraryVersion,
      input: input,
      krishnamurtiAyanamsha: frame.krishnamurtiAyanamsha,
      ascendant: KpFoundationEngine.classify(frame.siderealAscendant),
      mc: KpFoundationEngine.classify(frame.siderealMc),
      planets: List.unmodifiable(planets),
      cusps: List.unmodifiable(cusps),
      rulingPlanets: ruling,
      houseEvidence: houseEvidence,
    );
  }

  static double _normalize(double value) {
    final result = value % 360.0;
    return result < 0 ? result + 360.0 : result;
  }
}
