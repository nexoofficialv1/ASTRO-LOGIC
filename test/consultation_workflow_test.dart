import 'package:astro_logic/src/models/consultation.dart';
import 'package:astro_logic/src/services/consultation_workflow.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('review and finalization require verified output', () {
    expect(
      ConsultationWorkflow.canTransition(
        from: ConsultationStatus.draft,
        to: ConsultationStatus.reviewed,
        outputsExist: false,
      ),
      isFalse,
    );
    expect(
      ConsultationWorkflow.canTransition(
        from: ConsultationStatus.draft,
        to: ConsultationStatus.reviewed,
        outputsExist: true,
      ),
      isTrue,
    );
    expect(
      ConsultationWorkflow.canTransition(
        from: ConsultationStatus.reviewed,
        to: ConsultationStatus.finalized,
        outputsExist: true,
      ),
      isTrue,
    );
  });

  test('finalized consultation cannot transition', () {
    for (final target in ConsultationStatus.values) {
      expect(
        ConsultationWorkflow.canTransition(
          from: ConsultationStatus.finalized,
          to: target,
          outputsExist: true,
        ),
        isFalse,
      );
    }
  });
}

