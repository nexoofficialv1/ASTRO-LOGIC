import 'package:flutter_test/flutter_test.dart';

import 'package:astro_logic/src/kp/kp_event_judgment_engine.dart';
import 'package:astro_logic/src/kp/kp_horary_engine.dart';
import 'package:astro_logic/src/kp/kp_native_chart_engine.dart';
import 'package:astro_logic/src/models/astrology_settings.dart';

void main() {
  test('KP 1-249 table is exact, contiguous and sign-bounded', () {
    final segments = KpHoraryNumberTable.segments;
    expect(segments, hasLength(249));
    expect(segments.first.number, 1);
    expect(segments.first.startLongitude, 0);
    expect(segments.first.endLongitude, closeTo(0.7777777778, 1e-9));
    expect(segments.first.starLord, 'ketu');
    expect(segments.first.subLord, 'ketu');
    expect(segments[21].endLongitude, closeTo(30, 1e-12));
    expect(segments[22].startLongitude, closeTo(30, 1e-12));
    expect(segments[21].starLord, 'sun');
    expect(segments[22].starLord, 'sun');
    expect(segments[21].subLord, 'rahu');
    expect(segments[22].subLord, 'rahu');
    expect(segments.last.number, 249);
    expect(segments.last.startLongitude, closeTo(357.8888888889, 1e-9));
    expect(segments.last.endLongitude, closeTo(360, 1e-12));
    for (var i = 1; i < segments.length; i++) {
      expect(segments[i - 1].endLongitude,
          closeTo(segments[i].startLongitude, 1e-12));
      expect((segments[i].startLongitude / 30).floor(),
          ((segments[i].endLongitude - 1e-10) / 30).floor());
    }
  });

  test('horary cast binds cusp 1 to selected number without natal input', () async {
    final bridge = _LinearFakeBridge();
    final chart = await KpHoraryEngine(bridge).cast(
      KpHoraryInput(
        question: 'Will the proposed marriage proceed?',
        horaryNumber: 1,
        queryUtc: _LinearFakeBridge.epoch,
        latitude: 23.2,
        longitude: 88.3,
        nodeMode: LunarNodeMode.trueNode,
        topic: KpEventTopic.marriage,
      ),
    );
    expect(chart.segment.number, 1);
    expect(chart.horaryAscendant.siderealLongitude, closeTo(0, 1e-12));
    expect(chart.horaryCusps, hasLength(12));
    expect(chart.horaryCusps.first.siderealLongitude, closeTo(0, 2 / 3600));
    expect(chart.cuspSolutionErrorArcSeconds, lessThanOrEqualTo(2));
    expect(chart.queryMomentChart.planets, hasLength(9));
    expect(chart.toJson()['eventJudgment'], isNotNull);
    expect(chart.toJson()['timingConfirmation'], isNotNull);
    final governance = chart.toJson()['governance']! as Map;
    expect(governance['natalBirthDataUsed'], isFalse);
    expect(governance['automaticTiming'], isFalse);
    expect(governance['natalDashaUsed'], isFalse);
    expect(governance['automaticFutureTiming'], isFalse);
    expect(governance['practitionerReviewRequired'], isTrue);
  });
}

class _LinearFakeBridge implements KpNativeBridge {
  static final epoch = DateTime.utc(2026, 8, 11, 4, 49);
  static const _rate = 360.0 / 86164.0905;

  @override
  String get libraryVersion => 'fake-kp-horary-test';

  @override
  Future<KpNativeFrameData> calculateFrame({
    required DateTime utc,
    required double latitude,
    required double longitude,
  }) async {
    final seconds = utc.difference(epoch).inMilliseconds / 1000.0;
    final asc = _normalize(100 + seconds * _rate);
    final cusps = List<double>.generate(
      12,
      (index) => _normalize(asc + index * 30.0),
      growable: false,
    );
    return KpNativeFrameData(
      krishnamurtiAyanamsha: 0,
      tropicalAscendant: asc,
      tropicalMc: _normalize(asc + 90),
      siderealAscendant: asc,
      siderealMc: _normalize(asc + 90),
      trueNodeTropical: 210,
      meanNodeTropical: 209.5,
      tropicalCusps: cusps,
      siderealCusps: cusps,
    );
  }

  @override
  Future<KpNativePositionData> calculatePosition({
    required KpNativeBody body,
    required DateTime utc,
  }) async {
    final index = KpNativeBody.values.indexOf(body);
    return KpNativePositionData(
      tropicalLongitude: _normalize(15 + index * 37.0),
      eclipticLatitude: 0,
      longitudeSpeedPerDay: 1,
    );
  }

  static double _normalize(double value) {
    final result = value % 360.0;
    return result < 0 ? result + 360 : result;
  }
}
