import 'package:astro_logic/src/models/consultation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('consultation systems and workflow status round-trip', () {
    final now = DateTime.utc(2026, 8, 5, 10);
    final consultation = Consultation(
      id: 7,
      clientId: 1,
      birthRecordId: 2,
      subject: 'Career timing',
      category: ConsultationCategory.career,
      systems: const [AstrologySystem.vedic, AstrologySystem.kp],
      status: ConsultationStatus.draft,
      notes: 'Review after calculation.',
      createdAt: now,
      updatedAt: now,
    );
    final restored = Consultation.fromDatabaseMap({
      'id': 7,
      ...consultation.toDatabaseMap(),
    });

    expect(restored.category, ConsultationCategory.career);
    expect(restored.systems, [AstrologySystem.vedic, AstrologySystem.kp]);
    expect(restored.status, ConsultationStatus.draft);
  });
}

