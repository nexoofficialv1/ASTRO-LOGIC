import '../data/client_store.dart';
import '../models/calculation_output_snapshot.dart';
import '../models/consultation.dart';
import '../western/western_chart_engine.dart';
import '../western/western_governance.dart';

class WesternChartOrchestrator {
  const WesternChartOrchestrator(this.clientStore);

  final ClientStore clientStore;

  Future<CalculationOutputSnapshot> run({
    required Consultation consultation,
    required WesternChartEngine engine,
    WesternRulershipProfile rulershipProfile = WesternRulershipProfile.traditional,
    WesternAspectProfile aspectProfile = WesternAspectProfile.majorOnly,
    bool includeModernPlanets = true,
  }) async {
    if (consultation.id == null) {
      throw ArgumentError('Saved consultation is required');
    }
    if (consultation.status == ConsultationStatus.finalized) {
      throw StateError('Finalized consultation cannot accept Western output');
    }
    if (!consultation.systems.contains(AstrologySystem.western)) {
      throw StateError('Western Astrology must be selected for this consultation');
    }

    final client = clientStore.findById(consultation.clientId);
    if (client == null) throw StateError('Consultation client not found');
    final matches = client.birthRecords
        .where((record) => record.id == consultation.birthRecordId)
        .toList(growable: false);
    if (matches.isEmpty) throw StateError('Birth record not found');
    final birth = matches.first;
    final settings = clientStore.settings;

    final inputId = await clientStore.createWesternInputSnapshot(
      client: client,
      birthRecord: birth,
      houseSystem: settings.westernHouseSystem,
      nodeMode: settings.lunarNodeMode,
      rulershipProfile: rulershipProfile,
      aspectProfile: aspectProfile,
      includeModernPlanets: includeModernPlanets,
    );
    final inputSnapshot = clientStore.findSnapshotById(inputId);
    if (inputSnapshot == null) {
      throw StateError('Western input snapshot could not be reloaded');
    }

    final chart = await engine.cast(
      WesternChartInput(
        utc: birth.utcDateTime,
        latitude: birth.latitude,
        longitude: birth.longitude,
        houseSystem: settings.westernHouseSystem,
        nodeMode: settings.lunarNodeMode,
        rulershipProfile: rulershipProfile,
        aspectProfile: aspectProfile,
        includeModernPlanets: includeModernPlanets,
      ),
    );
    final outputId = await clientStore.createCalculationOutputSnapshot(
      consultation: consultation,
      inputSnapshot: inputSnapshot,
      engineId: WesternChartEngine.engineId,
      engineVersion: WesternChartEngine.engineVersion,
      outputSchemaVersion: WesternChartEngine.outputSchemaVersion,
      output: chart.toJson(),
    );
    final output = clientStore.findOutputById(outputId);
    if (output == null) throw StateError('Western output could not be reloaded');
    return output;
  }
}
