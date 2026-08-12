import 'package:astro_logic/src/services/snapshot_integrity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('snapshot hash is deterministic and changes with governed input', () {
    final first = SnapshotIntegrity.sha256For(
      input: const {'utc': '1984-03-12T18:42:00.000Z', 'latitude': 23.22},
      settings: const {'ayanamsha': 'lahiri'},
      schemaVersion: 'input-schema-v1',
    );
    final repeated = SnapshotIntegrity.sha256For(
      input: const {'utc': '1984-03-12T18:42:00.000Z', 'latitude': 23.22},
      settings: const {'ayanamsha': 'lahiri'},
      schemaVersion: 'input-schema-v1',
    );
    final changed = SnapshotIntegrity.sha256For(
      input: const {'utc': '1984-03-12T18:43:00.000Z', 'latitude': 23.22},
      settings: const {'ayanamsha': 'lahiri'},
      schemaVersion: 'input-schema-v1',
    );

    expect(first, hasLength(64));
    expect(repeated, first);
    expect(changed, isNot(first));
  });

  test('output hash includes engine and schema versions', () {
    final first = SnapshotIntegrity.sha256ForOutput(
      output: const {'planets': <Object?>[]},
      engineId: 'fixture-engine',
      engineVersion: '1.0.0',
      outputSchemaVersion: 'chart-v1',
    );
    final changedEngine = SnapshotIntegrity.sha256ForOutput(
      output: const {'planets': <Object?>[]},
      engineId: 'fixture-engine',
      engineVersion: '1.0.1',
      outputSchemaVersion: 'chart-v1',
    );

    expect(first, hasLength(64));
    expect(changedEngine, isNot(first));
  });

  test('analysis hash is bound to its calculation output', () {
    final first = SnapshotIntegrity.sha256ForAnalysis(
      analysis: const {'findings': <Object?>[]},
      engineId: 'vedic-judgment',
      engineVersion: '1.0.0',
      analysisSchemaVersion: 'kundli-analysis-v1',
      calculationOutputId: 4,
    );
    final changedOutput = SnapshotIntegrity.sha256ForAnalysis(
      analysis: const {'findings': <Object?>[]},
      engineId: 'vedic-judgment',
      engineVersion: '1.0.0',
      analysisSchemaVersion: 'kundli-analysis-v1',
      calculationOutputId: 5,
    );

    expect(first, hasLength(64));
    expect(changedOutput, isNot(first));
  });

  test('professional report hash binds content, sources and report version', () {
    final first = SnapshotIntegrity.sha256ForProfessionalReport(
      report: const {'sections': <Object?>[]},
      sourceManifest: const [
        {
          'kind': 'kundliAnalysis',
          'id': 1,
          'hash': 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
          'schemaVersion': 'kundli-analysis-v28',
        },
      ],
      engineId: 'astro-logic-professional-report',
      engineVersion: '1.0.0',
      reportSchemaVersion: 'professional-consultation-report-v1',
    );
    final changedSource = SnapshotIntegrity.sha256ForProfessionalReport(
      report: const {'sections': <Object?>[]},
      sourceManifest: const [
        {
          'kind': 'kundliAnalysis',
          'id': 2,
          'hash': 'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
          'schemaVersion': 'kundli-analysis-v28',
        },
      ],
      engineId: 'astro-logic-professional-report',
      engineVersion: '1.0.0',
      reportSchemaVersion: 'professional-consultation-report-v1',
    );

    expect(first, hasLength(64));
    expect(changedSource, isNot(first));
  });

}
