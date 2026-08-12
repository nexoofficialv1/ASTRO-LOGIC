import 'package:astro_logic/src/models/calculation_output_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('engine identity and version survive output snapshot decoding', () {
    final snapshot = CalculationOutputSnapshot.fromDatabaseMap({
      'id': 3,
      'consultation_id': 7,
      'input_snapshot_id': 9,
      'engine_id': 'fixture-engine',
      'engine_version': '1.2.0',
      'output_schema_version': 'chart-v1',
      'output_json': '{"planets":[]}',
      'output_hash': List.filled(64, 'a').join(),
      'created_at': '2026-08-05T10:00:00.000Z',
    });

    expect(snapshot.engineId, 'fixture-engine');
    expect(snapshot.engineVersion, '1.2.0');
    expect(snapshot.outputSchemaVersion, 'chart-v1');
    expect(snapshot.output['planets'], isEmpty);
  });
}
