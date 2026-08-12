import 'birth_record.dart';

enum ClientGender { male, female, other }

class Client {
  const Client({
    this.id,
    required this.fullName,
    required this.mobile,
    required this.email,
    required this.gender,
    required this.notes,
    required this.createdAt,
    required this.birthRecords,
  });

  final int? id;
  final String fullName;
  final String mobile;
  final String email;
  final ClientGender gender;
  final String notes;
  final DateTime createdAt;
  final List<BirthRecord> birthRecords;

  Map<String, Object?> toDatabaseMap() => {
        'full_name': fullName,
        'mobile': mobile,
        'email': email,
        'gender': gender.name,
        'notes': notes,
        'created_at': createdAt.toUtc().toIso8601String(),
      };

  factory Client.fromDatabaseMap(
    Map<String, Object?> map,
    List<BirthRecord> birthRecords,
  ) => Client(
        id: map['id'] as int,
        fullName: map['full_name'] as String,
        mobile: map['mobile'] as String,
        email: map['email'] as String,
        gender: ClientGender.values.byName(map['gender'] as String),
        notes: map['notes'] as String,
        createdAt: DateTime.parse(map['created_at'] as String),
        birthRecords: birthRecords,
      );
}

