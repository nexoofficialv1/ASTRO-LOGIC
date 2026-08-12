import 'package:astro_logic/src/models/professional_report_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('professional report snapshot restores immutable JSON payload', () {
    final snapshot = ProfessionalReportSnapshot.fromDatabaseMap({
      'id': 3,
      'consultation_id': 7,
      'engine_id': 'astro-logic-professional-report',
      'engine_version': '1.0.0',
      'report_schema_version': 'professional-consultation-report-v1',
      'source_manifest_json':
          '[{"kind":"kundliAnalysis","id":11,"hash":"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa","schemaVersion":"kundli-analysis-v28"}]',
      'report_json': '{"sections":[],"professionalReviewRequired":true}',
      'report_hash':
          'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc',
      'created_at': '2026-08-09T00:00:00.000Z',
    });

    expect(snapshot.id, 3);
    expect(snapshot.sourceManifest.single['id'], 11);
    expect(snapshot.report['professionalReviewRequired'], isTrue);
    expect(snapshot.reportHash, hasLength(64));
  });
}
