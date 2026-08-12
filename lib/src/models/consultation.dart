import 'dart:convert';

enum ConsultationStatus { draft, reviewed, finalized }

enum ConsultationCategory {
  general,
  career,
  business,
  marriage,
  finance,
  education,
  health,
  property,
  children,
  travelRelocation,
}

enum AstrologySystem { vedic, kp, western, numerology, vastu, palmistry }

class Consultation {
  const Consultation({
    this.id,
    required this.clientId,
    required this.birthRecordId,
    required this.subject,
    required this.category,
    required this.systems,
    required this.status,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  final int? id;
  final int clientId;
  final int birthRecordId;
  final String subject;
  final ConsultationCategory category;
  final List<AstrologySystem> systems;
  final ConsultationStatus status;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, Object?> toDatabaseMap() => {
        'client_id': clientId,
        'birth_record_id': birthRecordId,
        'subject': subject,
        'category': category.name,
        'systems_json': jsonEncode(systems.map((value) => value.name).toList()),
        'status': status.name,
        'notes': notes,
        'created_at': createdAt.toUtc().toIso8601String(),
        'updated_at': updatedAt.toUtc().toIso8601String(),
      };

  factory Consultation.fromDatabaseMap(Map<String, Object?> map) => Consultation(
        id: map['id'] as int,
        clientId: map['client_id'] as int,
        birthRecordId: map['birth_record_id'] as int,
        subject: map['subject'] as String,
        category: ConsultationCategory.values.byName(map['category'] as String),
        systems: (jsonDecode(map['systems_json'] as String) as List)
            .cast<String>()
            .map((name) => AstrologySystem.values.byName(name))
            .toList(growable: false),
        status: ConsultationStatus.values.byName(map['status'] as String),
        notes: map['notes'] as String,
        createdAt: DateTime.parse(map['created_at'] as String),
        updatedAt: DateTime.parse(map['updated_at'] as String),
      );
}
