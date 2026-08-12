import 'package:astro_logic/src/models/kundli_analysis_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('analysis snapshot retains engine, evidence payload and hash', () {
    final snapshot = KundliAnalysisSnapshot.fromDatabaseMap({
      'id': 2,
      'consultation_id': 3,
      'calculation_output_id': 4,
      'engine_id': 'vedic-judgment',
      'engine_version': '1.0.0',
      'analysis_schema_version': 'kundli-analysis-v1',
      'analysis_json': '{"findings":[{"code":"career.support"}]}',
      'analysis_hash': List.filled(64, 'b').join(),
      'created_at': '2026-08-05T12:00:00.000Z',
    });

    expect(snapshot.calculationOutputId, 4);
    expect(snapshot.analysisSchemaVersion, 'kundli-analysis-v1');
    expect(snapshot.analysis['findings'], isNotEmpty);
    expect(snapshot.analysisHash, hasLength(64));
  });
}
