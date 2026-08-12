import '../models/calculation_snapshot.dart';
import '../models/consultation.dart';

abstract interface class CalculationEngineAdapter {
  AstrologySystem get system;

  String get engineId;

  String get engineVersion;

  String get outputSchemaVersion;

  Future<Map<String, Object?>> calculate(CalculationSnapshot inputSnapshot);
}
