import 'dart:convert';

import 'package:astro_logic/src/models/numerology_snapshot.dart';
import 'package:astro_logic/src/services/snapshot_integrity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('deserializes an immutable Numerology snapshot row', () {
    final snapshot = NumerologySnapshot.fromDatabaseMap({
      'id': 4,
      'consultation_id': 3,
      'client_id': 2,
      'birth_record_id': 1,
      'target_year': 2026,
      'name_latin': 'BAPPA RAY',
      'calculation_engine_id': 'astro-logic-numerology',
      'calculation_engine_version': '2.1.0',
      'calculation_schema_version': 'numerology-profile-v3',
      'calculation_json': jsonEncode({
        'driver': {'compound': 13, 'reduced': 4},
      }),
      'analysis_engine_id': 'astro-logic-numerology-judgment',
      'analysis_engine_version': '2.1.0',
      'analysis_schema_version': 'numerology-analysis-v3',
      'analysis_json': jsonEncode({'professionalReviewRequired': true}),
      'snapshot_hash': List.filled(64, 'a').join(),
      'created_at': '2026-08-06T00:00:00.000Z',
    });

    expect(snapshot.consultationId, 3);
    expect(snapshot.nameLatin, 'BAPPA RAY');
    expect(snapshot.targetYear, 2026);
    expect(
      (snapshot.calculation['driver'] as Map)['reduced'],
      4,
    );
    expect(snapshot.analysis['professionalReviewRequired'], isTrue);
  });

  test('snapshot hash changes when alternate candidates or professional focus changes', () {
    String hash({
      List<String> candidates = const ['BAPPA ROY'],
      String? selected,
    }) =>
        SnapshotIntegrity.sha256ForNumerology(
          input: {
            'nameLatin': 'BAPPA RAY',
            'targetYear': 2026,
            'alternateNamesLatin': candidates,
            'professionalSelectedNameLatin': selected,
          },
          calculation: {
            'nameCandidateComparisons': candidates,
            'professionalSelectedNameLatin': selected,
          },
          analysis: {
            'nameCandidateReviews': candidates,
          },
          calculationEngineId: 'astro-logic-numerology',
          calculationEngineVersion: '2.1.0',
          calculationSchemaVersion: 'numerology-profile-v3',
          analysisEngineId: 'astro-logic-numerology-judgment',
          analysisEngineVersion: '2.1.0',
          analysisSchemaVersion: 'numerology-analysis-v3',
        );

    expect(hash(), isNot(hash(candidates: const ['BAPPA RAI'])));
    expect(hash(), isNot(hash(selected: 'BAPPA ROY')));
  });

  test('hash binds input, both payloads and both versioned engines', () {
    String hash({String calculationVersion = '1.0.0'}) =>
        SnapshotIntegrity.sha256ForNumerology(
          input: const {'nameLatin': 'BAPPA RAY', 'targetYear': 2026},
          calculation: const {'driver': 4},
          analysis: const {'review': true},
          calculationEngineId: 'calculation-engine',
          calculationEngineVersion: calculationVersion,
          calculationSchemaVersion: 'profile-v1',
          analysisEngineId: 'analysis-engine',
          analysisEngineVersion: '1.0.0',
          analysisSchemaVersion: 'analysis-v1',
        );

    expect(hash(), hasLength(64));
    expect(hash(), hash());
    expect(hash(), isNot(hash(calculationVersion: '1.0.1')));
  });
}
