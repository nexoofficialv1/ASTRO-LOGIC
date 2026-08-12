import '../data/client_store.dart';
import '../models/calculation_output_snapshot.dart';
import '../models/consultation.dart';
import '../models/kundli_analysis_snapshot.dart';
import 'kundli_judgment_engine.dart';

class KundliAnalysisOrchestrator {
  const KundliAnalysisOrchestrator(this._store);

  final ClientStore _store;

  Future<KundliAnalysisSnapshot> run({
    required Consultation consultation,
    required CalculationOutputSnapshot calculationOutput,
    required KundliJudgmentEngine engine,
  }) async {
    final analysis = await engine.analyze(calculationOutput);
    final id = await _store.createKundliAnalysisSnapshot(
      consultation: consultation,
      calculationOutput: calculationOutput,
      engineId: engine.engineId,
      engineVersion: engine.engineVersion,
      analysisSchemaVersion: engine.analysisSchemaVersion,
      analysis: analysis,
    );
    final saved = _store.findKundliAnalysisById(id);
    if (saved == null) throw StateError('Saved Kundli analysis not found');
    return saved;
  }
}
