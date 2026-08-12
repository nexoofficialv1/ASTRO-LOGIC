import '../models/astrology_settings.dart';
import 'kp_event_judgment_engine.dart';
import 'kp_foundation_engine.dart';
import 'kp_house_evidence_engine.dart';
import 'kp_horary_confirmation_engine.dart';
import 'kp_native_chart_engine.dart';

class KpHoraryNumberSegment {
  const KpHoraryNumberSegment({
    required this.number,
    required this.startLongitude,
    required this.endLongitude,
    required this.sign,
    required this.signLord,
    required this.starLord,
    required this.subLord,
  });

  final int number;
  final double startLongitude;
  final double endLongitude;
  final String sign;
  final String signLord;
  final String starLord;
  final String subLord;

  double get ascendantLongitude => startLongitude;

  Map<String, Object?> toJson() => {
        'number': number,
        'startLongitude': startLongitude,
        'endLongitude': endLongitude,
        'ascendantLongitude': ascendantLongitude,
        'sign': sign,
        'signLord': signLord,
        'starLord': starLord,
        'subLord': subLord,
      };
}

class KpHoraryNumberTable {
  const KpHoraryNumberTable._();

  static const profileVersion = 'kp-horary-249-table-v1';
  static const _arcSecondsPerSign = 30 * 3600;
  static const _arcSecondsPerNakshatra = 13 * 3600 + 20 * 60;
  static const _arcSecondsPerVimshottariYear = 400;

  static final List<KpHoraryNumberSegment> segments = _buildSegments();

  static KpHoraryNumberSegment forNumber(int number) {
    if (number < 1 || number > 249) {
      throw RangeError.range(number, 1, 249, 'horaryNumber');
    }
    return segments[number - 1];
  }

  static List<KpHoraryNumberSegment> _buildSegments() {
    final result = <KpHoraryNumberSegment>[];
    for (var nakshatraIndex = 0; nakshatraIndex < 27; nakshatraIndex++) {
      final starLord = KpFoundationEngine.vimshottariSequence[nakshatraIndex % 9];
      final starSequenceIndex =
          KpFoundationEngine.vimshottariSequence.indexOf(starLord);
      var cursor = nakshatraIndex * _arcSecondsPerNakshatra;
      for (var offset = 0; offset < 9; offset++) {
        final subLord = KpFoundationEngine
            .vimshottariSequence[(starSequenceIndex + offset) % 9];
        final span = _arcSecondsPerVimshottariYear *
            KpFoundationEngine.vimshottariYears[subLord]!;
        final intervalEnd = cursor + span;
        var pieceStart = cursor;
        while (pieceStart < intervalEnd) {
          final signIndex = pieceStart ~/ _arcSecondsPerSign;
          final signBoundary = (signIndex + 1) * _arcSecondsPerSign;
          final pieceEnd = intervalEnd < signBoundary ? intervalEnd : signBoundary;
          result.add(
            KpHoraryNumberSegment(
              number: result.length + 1,
              startLongitude: pieceStart / 3600.0,
              endLongitude: pieceEnd / 3600.0,
              sign: KpFoundationEngine.signNames[signIndex],
              signLord: KpFoundationEngine.signLords[signIndex],
              starLord: starLord,
              subLord: subLord,
            ),
          );
          pieceStart = pieceEnd;
        }
        cursor = intervalEnd;
      }
    }
    if (result.length != 249 ||
        result.first.startLongitude != 0 ||
        (result.last.endLongitude - 360).abs() > 1e-12) {
      throw StateError('KP 1-249 table construction failed its invariant.');
    }
    return List.unmodifiable(result);
  }
}

class KpHoraryInput {
  const KpHoraryInput({
    required this.question,
    required this.horaryNumber,
    required this.queryUtc,
    required this.latitude,
    required this.longitude,
    required this.nodeMode,
    this.topic,
  });

  final String question;
  final int horaryNumber;
  final DateTime queryUtc;
  final double latitude;
  final double longitude;
  final LunarNodeMode nodeMode;
  final KpEventTopic? topic;

  Map<String, Object?> toJson() => {
        'question': question.trim(),
        'horaryNumber': horaryNumber,
        'queryUtc': queryUtc.toUtc().toIso8601String(),
        'latitude': latitude,
        'longitude': longitude,
        'nodeMode': nodeMode.name,
        'topic': topic?.name,
        'natalBirthDataUsed': false,
      };
}

class KpHoraryChart {
  const KpHoraryChart({
    required this.input,
    required this.segment,
    required this.queryMomentChart,
    required this.horaryAscendant,
    required this.horaryCusps,
    required this.houseEvidence,
    required this.eventJudgment,
    required this.timingConfirmation,
    required this.cuspSolutionUtc,
    required this.cuspSolutionErrorArcSeconds,
  });

  final KpHoraryInput input;
  final KpHoraryNumberSegment segment;
  final KpNativeChart queryMomentChart;
  final KpPointClassification horaryAscendant;
  final List<KpNativeCuspPoint> horaryCusps;
  final KpHouseEvidenceMatrix houseEvidence;
  final KpEventJudgment? eventJudgment;
  final KpHoraryTimingConfirmationSynthesis? timingConfirmation;
  final DateTime cuspSolutionUtc;
  final double cuspSolutionErrorArcSeconds;

  Map<String, Object?> toJson() => {
        'engineId': KpHoraryEngine.engineId,
        'engineVersion': KpHoraryEngine.engineVersion,
        'inputSchemaVersion': KpHoraryEngine.inputSchemaVersion,
        'outputSchemaVersion': KpHoraryEngine.outputSchemaVersion,
        'profileVersion': KpHoraryEngine.profileVersion,
        'numberTableProfile': KpHoraryNumberTable.profileVersion,
        'input': input.toJson(),
        'numberSegment': segment.toJson(),
        'horaryAscendant': horaryAscendant.toJson(),
        'horaryCusps': horaryCusps.map((c) => c.toJson()).toList(growable: false),
        'queryMomentPlanets': queryMomentChart.planets
            .map((planet) => planet.toJson())
            .toList(growable: false),
        'queryMomentRulingPlanets': {
          'ruleVersion': queryMomentChart.rulingPlanets.ruleVersion,
          'roles': queryMomentChart.rulingPlanets.roles
              .map((r) => {'rank': r.rank, 'role': r.role, 'planet': r.planet})
              .toList(growable: false),
          'uniquePlanets': queryMomentChart.rulingPlanets.uniquePlanets,
        },
        'houseEvidence': houseEvidence.toJson(),
        'eventJudgment': eventJudgment?.toJson(),
        'timingConfirmation': timingConfirmation?.toJson(),
        'cuspGeometry': {
          'houseSystem': 'Placidus',
          'technicalSolutionUtc': cuspSolutionUtc.toIso8601String(),
          'ascendantErrorArcSeconds': cuspSolutionErrorArcSeconds,
          'technicalSolutionUtcIsEventTime': false,
        },
        'governance': {
          'natalBirthDataUsed': false,
          'queryMomentUsedForPlanets': true,
          'horaryNumberSetsAscendant': true,
          'queryMomentRulingPlanetConfirmation': timingConfirmation != null,
          'natalDashaUsed': false,
          'automaticTiming': false,
          'automaticFutureTiming': false,
          'realWorldGuarantee': false,
          'practitionerReviewRequired': true,
        },
      };
}

class KpHoraryEngine {
  const KpHoraryEngine(this.bridge);

  static const engineId = 'astro-logic-kp-horary';
  static const engineVersion = '1.1.0';
  static const inputSchemaVersion = 'kp-horary-input-v1';
  static const outputSchemaVersion = 'kp-horary-chart-v2';
  static const profileVersion = 'kp-horary-249-placidus-rp-v2';

  final KpNativeBridge bridge;

  Future<KpHoraryChart> cast(KpHoraryInput input) async {
    if (input.question.trim().isEmpty) {
      throw ArgumentError('A single explicit horary question is required.');
    }
    if (!input.latitude.isFinite ||
        input.latitude < -89 ||
        input.latitude > 89 ||
        !input.longitude.isFinite ||
        input.longitude < -180 ||
        input.longitude > 180) {
      throw ArgumentError('Supported horary coordinates are required.');
    }
    final queryUtc = input.queryUtc.toUtc();
    final segment = KpHoraryNumberTable.forNumber(input.horaryNumber);
    final nativeEngine = KpNativeChartEngine(bridge);
    final queryChart = await nativeEngine.cast(
      KpNativeChartInput(
        utc: queryUtc,
        latitude: input.latitude,
        longitude: input.longitude,
        nodeMode: input.nodeMode,
      ),
    );

    final solved = await _solvePlacidusFrame(
      queryUtc: queryUtc,
      latitude: input.latitude,
      longitude: input.longitude,
      targetSiderealAscendant: segment.ascendantLongitude,
      initialSiderealAscendant: queryChart.ascendant.siderealLongitude,
    );
    final cusps = List<KpNativeCuspPoint>.generate(
      12,
      (index) => KpNativeCuspPoint(
        house: index + 1,
        tropicalLongitude: solved.frame.tropicalCusps[index],
        siderealLongitude: solved.frame.siderealCusps[index],
        classification: KpFoundationEngine.classify(solved.frame.siderealCusps[index]),
      ),
      growable: false,
    );
    final houseEvidence = KpHouseEvidenceEngine.build(
      planetClassifications: <String, KpPointClassification>{
        for (final planet in queryChart.planets) planet.name: planet.classification,
      },
      cusps: cusps
          .map((cusp) => KpCuspClassification(
                house: cusp.house,
                point: cusp.classification,
              ))
          .toList(growable: false),
    );
    final eventJudgment = input.topic == null
        ? null
        : KpEventJudgmentEngine.judge(
            topic: input.topic!,
            cusps: cusps
                .map((cusp) => KpCuspClassification(
                      house: cusp.house,
                      point: cusp.classification,
                    ))
                .toList(growable: false),
            houseEvidence: houseEvidence,
          );
    final timingConfirmation = input.topic == null || eventJudgment == null
        ? null
        : KpHoraryTimingConfirmationEngine.build(
            topic: input.topic!,
            eventJudgment: eventJudgment,
            horaryHouseEvidence: houseEvidence,
            queryMomentRulingPlanets: queryChart.rulingPlanets,
            queryUtc: queryUtc,
          );

    return KpHoraryChart(
      input: input,
      segment: segment,
      queryMomentChart: queryChart,
      horaryAscendant: KpFoundationEngine.classify(segment.ascendantLongitude),
      horaryCusps: List.unmodifiable(cusps),
      houseEvidence: houseEvidence,
      eventJudgment: eventJudgment,
      timingConfirmation: timingConfirmation,
      cuspSolutionUtc: solved.utc,
      cuspSolutionErrorArcSeconds: solved.errorDegrees.abs() * 3600.0,
    );
  }

  Future<_HoraryFrameSolution> _solvePlacidusFrame({
    required DateTime queryUtc,
    required double latitude,
    required double longitude,
    required double targetSiderealAscendant,
    required double initialSiderealAscendant,
  }) async {
    const siderealRateDegreesPerSecond = 360.0 / 86164.0905;
    var delta = _signedDelta(targetSiderealAscendant, initialSiderealAscendant) /
        siderealRateDegreesPerSecond;
    var guess = queryUtc.add(Duration(milliseconds: (delta * 1000).round()));
    final minUtc = queryUtc.subtract(const Duration(hours: 13));
    final maxUtc = queryUtc.add(const Duration(hours: 13));

    KpNativeFrameData? bestFrame;
    DateTime? bestUtc;
    var bestError = 999.0;
    for (var iteration = 0; iteration < 8; iteration++) {
      if (guess.isBefore(minUtc)) guess = minUtc;
      if (guess.isAfter(maxUtc)) guess = maxUtc;
      final frame = await bridge.calculateFrame(
        utc: guess,
        latitude: latitude,
        longitude: longitude,
      );
      final error = _signedDelta(
        targetSiderealAscendant,
        frame.siderealAscendant,
      );
      if (error.abs() < bestError.abs()) {
        bestError = error;
        bestFrame = frame;
        bestUtc = guess;
      }
      if (error.abs() * 3600.0 <= 0.25) break;

      final probeUtc = guess.add(const Duration(seconds: 30));
      final probe = await bridge.calculateFrame(
        utc: probeUtc,
        latitude: latitude,
        longitude: longitude,
      );
      final moved = _signedDelta(
        probe.siderealAscendant,
        frame.siderealAscendant,
      );
      final derivative = moved / 30.0;
      if (!derivative.isFinite || derivative.abs() < 0.0001) break;
      var seconds = error / derivative;
      if (seconds > 1800) seconds = 1800;
      if (seconds < -1800) seconds = -1800;
      guess = guess.add(Duration(milliseconds: (seconds * 1000).round()));
    }
    if (bestFrame == null || bestUtc == null || bestError.abs() * 3600.0 > 2.0) {
      throw StateError(
        'Horary Placidus cusp solver could not bind cusp 1 to the selected 1-249 ascendant within 2 arcseconds.',
      );
    }
    return _HoraryFrameSolution(
      frame: bestFrame,
      utc: bestUtc,
      errorDegrees: bestError,
    );
  }

  static double _signedDelta(double target, double current) {
    var delta = (target - current) % 360.0;
    if (delta > 180) delta -= 360;
    if (delta < -180) delta += 360;
    return delta;
  }
}

class _HoraryFrameSolution {
  const _HoraryFrameSolution({
    required this.frame,
    required this.utc,
    required this.errorDegrees,
  });

  final KpNativeFrameData frame;
  final DateTime utc;
  final double errorDegrees;
}
