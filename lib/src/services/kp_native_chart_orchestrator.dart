import '../data/client_store.dart';
import '../kp/kp_native_chart_engine.dart';
import '../kp/kp_timing_confirmation_engine.dart';
import '../kp/kp_event_judgment_engine.dart';
import '../kp/kp_dasha_timing_engine.dart';
import '../kp/kp_foundation_engine.dart';
import '../models/calculation_output_snapshot.dart';
import '../models/consultation.dart';

class KpNativeChartOrchestrator {
  const KpNativeChartOrchestrator(this.clientStore);

  final ClientStore clientStore;

  Future<CalculationOutputSnapshot> run({
    required Consultation consultation,
    required KpNativeChartEngine engine,
  }) async {
    if (consultation.id == null) {
      throw ArgumentError('Saved consultation is required');
    }
    if (consultation.status == ConsultationStatus.finalized) {
      throw StateError('Finalized consultation cannot accept KP output');
    }
    if (!consultation.systems.contains(AstrologySystem.kp)) {
      throw StateError('KP must be selected for this consultation');
    }

    final client = clientStore.findById(consultation.clientId);
    if (client == null) throw StateError('Consultation client not found');
    final birthMatches = client.birthRecords
        .where((record) => record.id == consultation.birthRecordId)
        .toList(growable: false);
    if (birthMatches.isEmpty) throw StateError('Birth record not found');
    final birth = birthMatches.first;

    final inputId = await clientStore.createKpInputSnapshot(
      client: client,
      birthRecord: birth,
      nodeMode: clientStore.settings.lunarNodeMode,
    );
    final inputSnapshot = clientStore.findSnapshotById(inputId);
    if (inputSnapshot == null) {
      throw StateError('KP input snapshot could not be reloaded');
    }

    final chart = await engine.cast(
      KpNativeChartInput(
        utc: birth.utcDateTime,
        latitude: birth.latitude,
        longitude: birth.longitude,
        nodeMode: clientStore.settings.lunarNodeMode,
      ),
    );
    final eventTopic = _eventTopicForCategory(consultation.category);
    final eventJudgment = eventTopic == null
        ? null
        : KpEventJudgmentEngine.judge(
            topic: eventTopic,
            cusps: chart.cusps
                .map((cusp) => KpCuspClassification(
                      house: cusp.house,
                      point: cusp.classification,
                    ))
                .toList(growable: false),
            houseEvidence: chart.houseEvidence,
          );
    final referenceUtc = DateTime.now().toUtc();
    final timingSynthesis = eventTopic == null || eventJudgment == null
        ? null
        : KpDashaTimingEngine.build(
            topic: eventTopic,
            eventJudgment: eventJudgment,
            houseEvidence: chart.houseEvidence,
            moonSiderealLongitude: chart.planets
                .firstWhere((planet) => planet.name == 'moon')
                .siderealLongitude,
            birthUtc: birth.utcDateTime,
            referenceUtc: referenceUtc,
          );
    final referenceChart = timingSynthesis == null
        ? null
        : await engine.cast(
            KpNativeChartInput(
              utc: referenceUtc,
              latitude: birth.latitude,
              longitude: birth.longitude,
              nodeMode: clientStore.settings.lunarNodeMode,
            ),
          );
    final timingConfirmation = timingSynthesis == null ||
            eventTopic == null ||
            eventJudgment == null ||
            referenceChart == null
        ? null
        : KpTimingConfirmationEngine.build(
            topic: eventTopic,
            eventJudgment: eventJudgment,
            timingSynthesis: timingSynthesis,
            natalHouseEvidence: chart.houseEvidence,
            referenceTransitPoints: <String, KpPointClassification>{
              for (final planet in referenceChart.planets)
                planet.name: planet.classification,
            },
            referenceRulingPlanets: referenceChart.rulingPlanets,
            referenceUtc: referenceUtc,
          );
    final outputMap = Map<String, Object?>.from(chart.toJson());
    outputMap['eventJudgment'] = eventJudgment?.toJson();
    outputMap['eventTiming'] = timingSynthesis?.toJson();
    outputMap['timingConfirmation'] = timingConfirmation?.toJson();
    outputMap['eventJudgmentAvailability'] = <String, Object?>{
      'supportedForConsultationCategory': eventTopic != null,
      'supportedTopics': KpEventJudgmentEngine.profiles.keys
          .map((topic) => topic.name)
          .toList(growable: false),
      'automaticTiming': eventTopic != null,
      'timingProfile': eventTopic == null
          ? null
          : KpDashaTimingEngine.profileVersion,
      'transitConfirmationIncluded': timingConfirmation != null,
      'rulingPlanetConfirmationIncluded': timingConfirmation != null,
      'timingConfirmationProfile': timingConfirmation == null
          ? null
          : KpTimingConfirmationEngine.profileVersion,
    };

    final outputId = await clientStore.createCalculationOutputSnapshot(
      consultation: consultation,
      inputSnapshot: inputSnapshot,
      engineId: KpNativeChartEngine.engineId,
      engineVersion: KpNativeChartEngine.engineVersion,
      outputSchemaVersion: KpNativeChartEngine.outputSchemaVersion,
      output: outputMap,
    );
    final output = clientStore.findOutputById(outputId);
    if (output == null) throw StateError('KP output could not be reloaded');
    return output;
  }

  KpEventTopic? _eventTopicForCategory(ConsultationCategory category) {
    return switch (category) {
      ConsultationCategory.marriage => KpEventTopic.marriage,
      ConsultationCategory.children => KpEventTopic.children,
      _ => null,
    };
  }
}
