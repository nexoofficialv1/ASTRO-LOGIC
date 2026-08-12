import '../data/client_store.dart';
import '../models/consultation.dart';
import '../models/kundli_analysis_snapshot.dart';
import '../models/numerology_snapshot.dart';
import '../numerology/numerology_analysis_policy.dart';
import '../numerology/numerology_engine.dart';
import '../numerology/numerology_judgment_engine.dart';

class NumerologySnapshotOrchestrator {
  const NumerologySnapshotOrchestrator(this._store);

  final ClientStore _store;

  Future<NumerologySnapshot> run({
    required Consultation consultation,
    required String nameLatin,
    required int targetYear,
    List<String> alternateNamesLatin = const [],
    String? professionalSelectedNameLatin,
  }) async {
    if (!consultation.systems.contains(AstrologySystem.numerology)) {
      throw StateError('Numerology was not selected for this consultation');
    }
    final client = _store.findById(consultation.clientId);
    if (client == null) throw StateError('Client not found');
    final matches = client.birthRecords
        .where((record) => record.id == consultation.birthRecordId);
    if (matches.isEmpty) throw StateError('Birth record not found');
    final birthRecord = matches.first;
    final profile = const NumerologyEngine().calculate(
      NumerologyInput(
        fullNameLatin: nameLatin,
        birthDate: birthRecord.localDateTime,
        personalYear: targetYear,
        alternateNamesLatin: alternateNamesLatin,
        professionalSelectedNameLatin: professionalSelectedNameLatin,
      ),
    );
    final vedicSnapshots = consultation.id == null
        ? const <KundliAnalysisSnapshot>[]
        : _store.kundliAnalysesForConsultation(consultation.id!);
    final vedicSnapshot = vedicSnapshots.isEmpty ? null : vedicSnapshots.first;
    final analysis = const NumerologyJudgmentEngine().analyze(
      profile,
      vedicSnapshot: vedicSnapshot,
    );
    NumerologyAnalysisPolicy.validate(analysis);
    final id = await _store.createNumerologySnapshot(
      consultation: consultation,
      birthRecord: birthRecord,
      profile: profile,
      analysis: analysis,
    );
    final saved = _store.findNumerologySnapshotById(id);
    if (saved == null) throw StateError('Saved Numerology snapshot not found');
    return saved;
  }
}
