import 'dart:convert';

class AuditEvent {
  const AuditEvent({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.action,
    required this.summary,
    required this.createdAt,
  });

  final int id;
  final String entityType;
  final int? entityId;
  final String action;
  final Map<String, Object?> summary;
  final DateTime createdAt;

  factory AuditEvent.fromDatabaseMap(Map<String, Object?> map) => AuditEvent(
        id: map['id'] as int,
        entityType: map['entity_type'] as String,
        entityId: map['entity_id'] as int?,
        action: map['action'] as String,
        summary: Map<String, Object?>.from(
          jsonDecode(map['summary_json'] as String) as Map,
        ),
        createdAt: DateTime.parse(map['created_at'] as String),
      );
}

