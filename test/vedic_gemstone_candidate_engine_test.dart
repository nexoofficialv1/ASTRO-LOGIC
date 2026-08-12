import 'package:astro_logic/src/models/calculation_output_snapshot.dart';
import 'package:astro_logic/src/models/kundli_analysis.dart';
import 'package:astro_logic/src/vedic/vedic_gemstone_candidate_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const engine = VedicGemstoneCandidateEngine();

  test('marks functionally challenging planet contraindicated', () {
    final reviews = engine.build(
      _output(ascendantSign: 0),
      shadbalaProfiles: [_shadbala('mercury', ratio: 0.80)],
      timingWindows: [_window('mercury', 'mercury')],
    );
    final mercury = reviews.singleWhere((value) => value.planet == 'mercury');
    expect(mercury.functionalScore, lessThanOrEqualTo(-2));
    expect(mercury.status, GemstoneCandidateStatus.contraindicated);
  });

  test('eligible requires supportive functional role, Shadbala deficit and active Dasha', () {
    final output = _output(ascendantSign: 1);
    final reviews = engine.build(
      output,
      shadbalaProfiles: [_shadbala('saturn', ratio: 0.80)],
      timingWindows: [_window('saturn', 'saturn')],
    );
    final saturn = reviews.singleWhere((value) => value.planet == 'saturn');
    expect(saturn.functionalScore, greaterThanOrEqualTo(2));
    expect(saturn.shadbalaThresholdStatus, 'belowRequired');
    expect(saturn.activeDashaRole, 'mahadasha+antardasha');
    expect(saturn.status, GemstoneCandidateStatus.eligible);
    expect(saturn.primaryGemstone, 'Blue Sapphire');
  });

  test('node contact blocks automatic eligible status', () {
    final output = _output(ascendantSign: 1, rahuSign: 6);
    final reviews = engine.build(
      output,
      shadbalaProfiles: [_shadbala('saturn', ratio: 0.80)],
      timingWindows: [_window('saturn', 'saturn')],
    );
    final saturn = reviews.singleWhere((value) => value.planet == 'saturn');
    expect(saturn.nodeContacts, contains('rahu'));
    expect(saturn.status, GemstoneCandidateStatus.insufficientEvidence);
  });

  test('meeting Shadbala threshold does not create a strengthening candidate', () {
    final reviews = engine.build(
      _output(ascendantSign: 1),
      shadbalaProfiles: [_shadbala('saturn', ratio: 1.10, below: false)],
      timingWindows: [_window('saturn', 'saturn')],
    );
    final saturn = reviews.singleWhere((value) => value.planet == 'saturn');
    expect(saturn.status, GemstoneCandidateStatus.insufficientEvidence);
  });

  test('returns seven classical reviews and never invents Rahu/Ketu gemstone review', () {
    final reviews = engine.build(
      _output(ascendantSign: 0),
      shadbalaProfiles: const [],
      timingWindows: const [],
    );
    expect(reviews, hasLength(7));
    expect(reviews.map((value) => value.planet), isNot(contains('rahu')));
    expect(reviews.map((value) => value.planet), isNot(contains('ketu')));
    expect(reviews.every((value) => value.status != GemstoneCandidateStatus.eligible), isTrue);
  });
}

CalculationOutputSnapshot _output({
  required int ascendantSign,
  int rahuSign = 5,
}) {
  final longitudes = <String, double>{
    'sun': 40.0,
    'moon': 70.0,
    'mars': 10.0,
    'mercury': 100.0,
    'jupiter': 130.0,
    'venus': 160.0,
    'saturn': 190.0,
    'rahu': rahuSign * 30.0 + 10.0,
    'ketu': ((rahuSign + 6) % 12) * 30.0 + 10.0,
  };
  return CalculationOutputSnapshot(
    id: 1,
    consultationId: 1,
    inputSnapshotId: 1,
    engineId: 'fixture',
    engineVersion: '1',
    outputSchemaVersion: 'vedic-chart-v10',
    output: {
      'ascendant': {'signIndex': ascendantSign},
      'planets': [
        for (final entry in longitudes.entries)
          {
            'body': entry.key,
            'signIndex': entry.value ~/ 30,
            'siderealLongitude': entry.value,
            'navamsaSignIndex': (((entry.value * 9.0) / 30.0).floor()) % 12,
            'retrograde': false,
          },
      ],
    },
    outputHash: 'fixture',
    createdAt: DateTime.utc(2026, 8, 10, 0, 0),
  );
}

AnalysisTimingWindow _window(String maha, String antar) => AnalysisTimingWindow(
      code: 'vedic.dasha.vimshottari.$maha.$antar.0.0',
      area: LifeArea.overall,
      start: DateTime.utc(2026, 1, 1),
      end: DateTime.utc(2027, 1, 1),
      polarity: AnalysisPolarity.mixed,
      confidence: AnalysisConfidence.medium,
      narrativeEn: 'fixture',
      narrativeBn: 'fixture',
      evidence: const [
        ChartEvidence(
          ruleId: 'fixture.dasha',
          outputPath: r'$.vimshottari',
          kind: EvidenceKind.dasha,
          descriptionEn: 'fixture',
          descriptionBn: 'fixture',
        ),
      ],
    );

ShadbalaPlanetProfile _shadbala(
  String planet, {
  required double ratio,
  bool below = true,
}) =>
    ShadbalaPlanetProfile(
      code: 'fixture.$planet',
      ruleVersion: 'shadbala-foundation-v10',
      planet: planet,
      ucchaBalaVirupas: 0,
      saptavargajaBalaVirupas: 0,
      ojayugmaBalaVirupas: 0,
      kendradiBalaVirupas: 0,
      drekkanaBalaVirupas: 0,
      sthanaBalaVirupas: 0,
      digBalaVirupas: 0,
      nathonnataBalaVirupas: 0,
      sunHourAngleHours: 0,
      tribhagaBalaVirupas: 0,
      tribhagaPeriod: 'day',
      tribhagaThird: 1,
      tribhagaPeriodStartUtc: '2026-08-10T00:00:00.000Z',
      tribhagaPeriodEndUtc: '2026-08-10T01:00:00.000Z',
      pakshaBalaVirupas: 0,
      varshaBalaVirupas: 0,
      masaBalaVirupas: 0,
      dinaBalaVirupas: 0,
      horaBalaVirupas: 0,
      varshaLord: 'sun',
      masaLord: 'sun',
      dinaLord: 'sun',
      horaLord: 'sun',
      horaNumber: 1,
      varshaMasaDinaHoraProfile: 'fixture',
      ayanaBalaVirupas: 0,
      yuddhaBalaVirupas: 0,
      yuddhaProfile: 'fixture',
      yuddhaRole: 'noWar',
      yuddhaWarPartner: null,
      yuddhaSeparationDegrees: null,
      yuddhaLatitudeDegrees: null,
      yuddhaPartnerLatitudeDegrees: null,
      yuddhaPreWarStrengthDifferenceVirupas: null,
      kalaBalaPartialVirupas: 0,
      kalaBalaVirupas: 0,
      kalaComputedSubcomponents: const [],
      kalaMissingSubcomponents: const [],
      kalaBalaComplete: true,
      cheshtaBalaVirupas: 0,
      cheshtaMethod: 'fixture',
      cheshtaMotionState: 'fixture',
      longitudeSpeedPerDay: 1,
      naisargikaBalaVirupas: 0,
      drikBalaVirupas: 0,
      drikProfile: 'fixture',
      drikContributions: const [],
      vargaContributions: const [],
      computedComponents: const [],
      missingComponents: const [],
      aggregateAvailable: true,
      totalShadbalaVirupas: ratio * 300,
      totalShadbalaRupas: ratio * 5,
      requiredShadbalaVirupas: 300,
      requiredShadbalaRupas: 5,
      requiredStrengthRatio: ratio,
      surplusDeficitVirupas: ratio * 300 - 300,
      thresholdStatus: below ? 'belowRequired' : 'meetsRequired',
      thresholdProfile: 'fixture',
      narrativeEn: 'fixture',
      narrativeBn: 'fixture',
      evidence: const [
        ChartEvidence(
          ruleId: 'fixture.shadbala',
          outputPath: r'$.fixture',
          kind: EvidenceKind.strength,
          descriptionEn: 'fixture',
          descriptionBn: 'fixture',
        ),
      ],
    );
