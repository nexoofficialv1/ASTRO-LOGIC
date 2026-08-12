import 'package:astro_logic/src/ephemeris/ephemeris_provider.dart';
import 'package:astro_logic/src/models/calculation_output_snapshot.dart';
import 'package:astro_logic/src/models/kundli_analysis.dart';
import 'package:astro_logic/src/models/vedic_transit_analysis.dart';
import 'package:astro_logic/src/vedic/vedic_transit_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('derives all sidereal positions plus seven classical and Rahu Moon-gochara findings',
      () async {
    final provider = _FixedTransitEphemeris();
    final analysis = await VedicTransitEngine(provider).analyze(
      natalOutput: _natalOutput(ascendantSign: 0, moonSign: 0),
      asOfUtc: DateTime.utc(2026, 8, 7, 8, 0),
      latitude: 23.22,
      longitude: 88.37,
    );

    expect(provider.lastRequest?.utcDateTime, DateTime.utc(2026, 8, 7, 8));
    expect(analysis.positions, hasLength(9));
    expect(analysis.findings, hasLength(8));
    expect(analysis.schemaVersion, 'vedic-transit-analysis-v3');
    expect(analysis.engineVersion, startsWith('3.0.0+'));
    expect(analysis.professionalReviewRequired, isTrue);
    expect(
      analysis.findings.map((value) => value.planet).toList(),
      ['sun', 'moon', 'mars', 'mercury', 'jupiter', 'venus', 'saturn', 'rahu'],
    );

    final rahu = analysis.positions.firstWhere((value) => value.body == 'rahu');
    final ketu = analysis.positions.firstWhere((value) => value.body == 'ketu');
    expect(ketu.siderealLongitude, (rahu.siderealLongitude + 180) % 360);
    expect(analysis.findings.any((value) => value.planet == 'rahu'), isTrue);
    expect(analysis.findings.any((value) => value.planet == 'ketu'), isFalse);
  });

  test('classifies governed classical profile without converting Sade Sati adverse',
      () async {
    final analysis = await VedicTransitEngine(_FixedTransitEphemeris()).analyze(
      natalOutput: _natalOutput(ascendantSign: 0, moonSign: 0),
      asOfUtc: DateTime.utc(2026, 8, 7, 8, 0),
      latitude: 23.22,
      longitude: 88.37,
    );

    expect(_finding(analysis, 'sun').houseFromMoon, 3);
    expect(_finding(analysis, 'sun').polarity, AnalysisPolarity.supportive);
    expect(_finding(analysis, 'moon').houseFromMoon, 1);
    expect(_finding(analysis, 'moon').polarity, AnalysisPolarity.supportive);
    expect(_finding(analysis, 'mars').houseFromMoon, 6);
    expect(_finding(analysis, 'mars').polarity, AnalysisPolarity.supportive);
    expect(_finding(analysis, 'mercury').houseFromMoon, 2);
    expect(
      _finding(analysis, 'mercury').polarity,
      AnalysisPolarity.supportive,
    );
    expect(_finding(analysis, 'jupiter').houseFromMoon, 5);
    expect(
      _finding(analysis, 'jupiter').polarity,
      AnalysisPolarity.supportive,
    );
    expect(_finding(analysis, 'venus').houseFromMoon, 7);
    expect(_finding(analysis, 'venus').polarity, AnalysisPolarity.challenging);

    final saturn = _finding(analysis, 'saturn');
    expect(saturn.houseFromMoon, 12);
    expect(saturn.code, 'vedic.transit.saturn.sade_sati.rising');
    expect(saturn.polarity, AnalysisPolarity.mixed);
    expect(saturn.confidence, AnalysisConfidence.medium);
    expect(saturn.narrativeEn, contains('automatic adverse prediction'));

    final rahu = _finding(analysis, 'rahu');
    expect(rahu.houseFromMoon, 2);
    expect(rahu.polarity, AnalysisPolarity.challenging);
    expect(rahu.evidence.single.ruleId, contains('phaladeepika26.24'));
  });

  test('treats the eleventh from natal Moon as supportive for all classical planets',
      () async {
    final analysis = await VedicTransitEngine(
      _FixedTransitEphemeris.allAtSidereal(300.0),
    ).analyze(
      natalOutput: _natalOutput(ascendantSign: 0, moonSign: 0),
      asOfUtc: DateTime.utc(2026, 8, 7, 8, 0),
      latitude: 23.22,
      longitude: 88.37,
    );

    for (final finding in analysis.findings) {
      expect(finding.houseFromMoon, 11, reason: finding.planet);
      expect(
        finding.polarity,
        AnalysisPolarity.supportive,
        reason: finding.planet,
      );
      expect(finding.confidence, AnalysisConfidence.medium);
      expect(finding.evidence.single.kind, EvidenceKind.transit);
      if (finding.planet == 'rahu') {
        expect(finding.evidence.single.ruleId, contains('phaladeepika26.24'));
      } else {
        expect(finding.evidence.single.ruleId, contains('brihat_samhita.v2'));
      }
    }
  });

  test('keeps intentionally ambiguous classical houses mixed', () async {
    final analysis = await VedicTransitEngine(
      _FixedTransitEphemeris(
        siderealByBody: const {
          CelestialBody.sun: 60.0,
          CelestialBody.moon: 90.0,
          CelestialBody.mars: 150.0,
          CelestialBody.mercury: 60.0,
          CelestialBody.jupiter: 120.0,
          CelestialBody.venus: 330.0,
          CelestialBody.saturn: 90.0,
          CelestialBody.rahu: 30.0,
        },
      ),
    ).analyze(
      natalOutput: _natalOutput(ascendantSign: 0, moonSign: 0),
      asOfUtc: DateTime.utc(2026, 8, 7, 8, 0),
      latitude: 23.22,
      longitude: 88.37,
    );

    expect(_finding(analysis, 'moon').houseFromMoon, 4);
    expect(_finding(analysis, 'moon').polarity, AnalysisPolarity.mixed);
    expect(_finding(analysis, 'mercury').houseFromMoon, 3);
    expect(_finding(analysis, 'mercury').polarity, AnalysisPolarity.mixed);
    expect(_finding(analysis, 'venus').houseFromMoon, 12);
    expect(_finding(analysis, 'venus').polarity, AnalysisPolarity.mixed);
    expect(_finding(analysis, 'saturn').houseFromMoon, 4);
    expect(_finding(analysis, 'saturn').polarity, AnalysisPolarity.challenging);
  });

  test('emits directional challenging signals without high-stakes event claims',
      () async {
    final analysis = await VedicTransitEngine(
      _FixedTransitEphemeris(
        siderealByBody: const {
          CelestialBody.sun: 0.0,
          CelestialBody.moon: 30.0,
          CelestialBody.mars: 90.0,
          CelestialBody.mercury: 120.0,
          CelestialBody.jupiter: 150.0,
          CelestialBody.venus: 180.0,
          CelestialBody.saturn: 90.0,
          CelestialBody.rahu: 30.0,
        },
      ),
    ).analyze(
      natalOutput: _natalOutput(ascendantSign: 0, moonSign: 0),
      asOfUtc: DateTime.utc(2026, 8, 7, 8, 0),
      latitude: 23.22,
      longitude: 88.37,
    );

    expect(_finding(analysis, 'sun').polarity, AnalysisPolarity.challenging);
    expect(_finding(analysis, 'moon').polarity, AnalysisPolarity.challenging);
    expect(_finding(analysis, 'mars').polarity, AnalysisPolarity.challenging);
    expect(
      _finding(analysis, 'mercury').polarity,
      AnalysisPolarity.challenging,
    );
    expect(
      _finding(analysis, 'jupiter').polarity,
      AnalysisPolarity.challenging,
    );
    expect(_finding(analysis, 'venus').polarity, AnalysisPolarity.challenging);
    expect(_finding(analysis, 'saturn').polarity, AnalysisPolarity.challenging);
    expect(_finding(analysis, 'rahu').polarity, AnalysisPolarity.challenging);
    expect(
      analysis.warningsEn.any((value) => value.contains('high-stakes')),
      isTrue,
    );
  });

  test('rejects local DateTime before calling ephemeris', () async {
    final provider = _FixedTransitEphemeris();
    final local = DateTime(2026, 8, 7, 13, 30);

    await expectLater(
      VedicTransitEngine(provider).analyze(
        natalOutput: _natalOutput(ascendantSign: 0, moonSign: 0),
        asOfUtc: local,
        latitude: 23.22,
        longitude: 88.37,
      ),
      throwsArgumentError,
    );
    expect(provider.lastRequest, isNull);
  });

  test('rejects non-Vedic natal output', () async {
    final output = _natalOutput(ascendantSign: 0, moonSign: 0);
    final invalid = CalculationOutputSnapshot(
      id: output.id,
      consultationId: output.consultationId,
      inputSnapshotId: output.inputSnapshotId,
      engineId: output.engineId,
      engineVersion: output.engineVersion,
      outputSchemaVersion: 'western-chart-v1',
      output: output.output,
      outputHash: output.outputHash,
      createdAt: output.createdAt,
    );

    await expectLater(
      VedicTransitEngine(_FixedTransitEphemeris()).analyze(
        natalOutput: invalid,
        asOfUtc: DateTime.utc(2026, 8, 7, 8, 0),
        latitude: 23.22,
        longitude: 88.37,
      ),
      throwsArgumentError,
    );
  });
}

VedicTransitFinding _finding(VedicTransitAnalysis analysis, String planet) =>
    analysis.findings.firstWhere((value) => value.planet == planet);

CalculationOutputSnapshot _natalOutput({
  required int ascendantSign,
  required int moonSign,
}) =>
    CalculationOutputSnapshot(
      id: 1,
      consultationId: 1,
      inputSnapshotId: 1,
      engineId: 'fixture',
      engineVersion: '1',
      outputSchemaVersion: 'vedic-chart-v4',
      output: {
        'metadata': const {
          'ayanamsha': 'lahiri',
          'lunarNodeMode': 'trueNode',
        },
        'ascendant': {'signIndex': ascendantSign},
        'planets': [
          {'body': 'moon', 'signIndex': moonSign},
        ],
      },
      outputHash: 'fixture',
      createdAt: DateTime.utc(2026, 8, 7),
    );

class _FixedTransitEphemeris implements EphemerisProvider {
  _FixedTransitEphemeris({
    Map<CelestialBody, double>? siderealByBody,
  }) : siderealByBody = siderealByBody ?? _defaultSidereal;

  _FixedTransitEphemeris.allAtSidereal(double longitude)
      : siderealByBody = {
          for (final body in CelestialBody.values) body: longitude,
        };

  static const _defaultSidereal = <CelestialBody, double>{
    CelestialBody.sun: 60.0,
    CelestialBody.moon: 0.0,
    CelestialBody.mars: 150.0,
    CelestialBody.mercury: 30.0,
    CelestialBody.jupiter: 120.0,
    CelestialBody.venus: 180.0,
    CelestialBody.saturn: 330.0,
    CelestialBody.rahu: 36.0,
  };

  final Map<CelestialBody, double> siderealByBody;
  EphemerisRequest? lastRequest;

  @override
  String get engineId => 'fixed-transit-evidence';

  @override
  String get engineVersion => '1';

  @override
  Future<EphemerisFrame> calculate(EphemerisRequest request) async {
    lastRequest = request;
    return EphemerisFrame(
      ayanamshaDegrees: 24.0,
      sunHourAngleHours: 6.0,
      tropicalAscendant: 0.0,
      positions: {
        for (final body in CelestialBody.values)
          body: EphemerisPosition(
            tropicalLongitude: (siderealByBody[body]! + 24.0) % 360.0,
            eclipticLatitude: 0.0,
            longitudeSpeed: body == CelestialBody.mercury ||
                    body == CelestialBody.rahu
                ? -0.1
                : 0.1,
          ),
      },
    );
  }
}
