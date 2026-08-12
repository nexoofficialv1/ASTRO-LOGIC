import '../data/client_store.dart';
import '../models/calculation_output_snapshot.dart';
import '../models/calculation_snapshot.dart';
import '../models/consultation.dart';
import 'calculation_engine_adapter.dart';

class CalculationOrchestrator {
  const CalculationOrchestrator(this._store);

  final ClientStore _store;

  Future<CalculationSnapshot> prepareInput(Consultation consultation) async {
    final client = _store.findById(consultation.clientId);
    if (client == null) throw StateError('Client not found');
    final matchingRecords = client.birthRecords
        .where((record) => record.id == consultation.birthRecordId);
    final birthRecord = matchingRecords.isEmpty ? null : matchingRecords.first;
    if (birthRecord == null) throw StateError('Birth record not found');
    final snapshotId = await _store.createInputSnapshot(
      client: client,
      birthRecord: birthRecord,
    );
    final snapshot = _store.findSnapshotById(snapshotId);
    if (snapshot == null) throw StateError('Prepared snapshot not found');
    return snapshot;
  }

  Future<CalculationOutputSnapshot> run({
    required Consultation consultation,
    required CalculationEngineAdapter engine,
  }) async {
    if (!consultation.systems.contains(engine.system)) {
      throw StateError('Engine system was not selected for this consultation');
    }
    final inputSnapshot = await prepareInput(consultation);
    final output = await engine.calculate(inputSnapshot);
    final outputId = await _store.createCalculationOutputSnapshot(
      consultation: consultation,
      inputSnapshot: inputSnapshot,
      engineId: engine.engineId,
      engineVersion: engine.engineVersion,
      outputSchemaVersion: engine.outputSchemaVersion,
      output: output,
    );
    final saved = _store.findOutputById(outputId);
    if (saved == null) throw StateError('Saved calculation output not found');
    return saved;
  }
}
