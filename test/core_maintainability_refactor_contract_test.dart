import 'package:flutter_test/flutter_test.dart';
import 'package:astro_logic/src/data/app_database.dart';
import 'package:astro_logic/src/services/encrypted_backup_service.dart';
import 'package:astro_logic/src/vedic/vedic_lagna_judgment_engine.dart';
import 'package:astro_logic/src/vedic/vedic_shadbala_engine.dart';

void main() {
  test('v072 refactor preserves governed contract versions', () {
    const vedic = VedicLagnaJudgmentEngine();
    expect(vedic.engineVersion, '32.0.0');
    expect(vedic.analysisSchemaVersion, 'kundli-analysis-v32');
    expect(VedicShadbalaEngine.ruleVersion, 'shadbala-foundation-v10');
    expect(EncryptedBackupService.engineVersion, '1.4.0');
    expect(
      EncryptedBackupService.contractVersion,
      'astro-logic-encrypted-backup-v1',
    );
    expect(
      EncryptedBackupService.mergeReceiptContractVersion,
      'astro-logic-backup-merge-receipt-v1',
    );
    expect(AppDatabase.schemaVersion, 12);
  });
}
