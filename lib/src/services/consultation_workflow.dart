import '../models/consultation.dart';

class ConsultationWorkflow {
  const ConsultationWorkflow._();

  static bool canTransition({
    required ConsultationStatus from,
    required ConsultationStatus to,
    required bool outputsExist,
  }) =>
      switch (from) {
        ConsultationStatus.draft =>
          to == ConsultationStatus.reviewed && outputsExist,
        ConsultationStatus.reviewed =>
          to == ConsultationStatus.draft ||
              (to == ConsultationStatus.finalized && outputsExist),
        ConsultationStatus.finalized => false,
      };
}

