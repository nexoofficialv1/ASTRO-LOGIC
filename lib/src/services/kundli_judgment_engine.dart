import '../models/calculation_output_snapshot.dart';
import '../models/kundli_analysis.dart';

abstract interface class KundliJudgmentEngine {
  String get engineId;

  String get engineVersion;

  String get analysisSchemaVersion;

  Future<KundliAnalysis> analyze(CalculationOutputSnapshot calculationOutput);
}
