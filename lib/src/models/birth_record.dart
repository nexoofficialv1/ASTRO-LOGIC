enum BirthTimeConfidence { exact, recorded, approximate, unknown }

class BirthRecord {
  const BirthRecord({
    this.id,
    this.clientId,
    required this.label,
    required this.localDateTime,
    required this.utcOffsetMinutes,
    required this.placeName,
    required this.latitude,
    required this.longitude,
    required this.confidence,
    required this.sourceNote,
  });

  final int? id;
  final int? clientId;
  final String label;
  final DateTime localDateTime;
  final int utcOffsetMinutes;
  final String placeName;
  final double latitude;
  final double longitude;
  final BirthTimeConfidence confidence;
  final String sourceNote;

  DateTime get utcDateTime => DateTime.utc(
        localDateTime.year,
        localDateTime.month,
        localDateTime.day,
        localDateTime.hour,
        localDateTime.minute,
        localDateTime.second,
        localDateTime.millisecond,
        localDateTime.microsecond,
      ).subtract(Duration(minutes: utcOffsetMinutes));

  Map<String, Object?> toDatabaseMap({required int ownerId}) => {
        'client_id': ownerId,
        'label': label,
        'local_datetime': localDateTime.toIso8601String(),
        'utc_datetime': utcDateTime.toIso8601String(),
        'utc_offset_minutes': utcOffsetMinutes,
        'place_name': placeName,
        'latitude': latitude,
        'longitude': longitude,
        'confidence': confidence.name,
        'source_note': sourceNote,
      };

  factory BirthRecord.fromDatabaseMap(Map<String, Object?> map) => BirthRecord(
        id: map['id'] as int,
        clientId: map['client_id'] as int,
        label: map['label'] as String,
        localDateTime: DateTime.parse(map['local_datetime'] as String),
        utcOffsetMinutes: map['utc_offset_minutes'] as int,
        placeName: map['place_name'] as String,
        latitude: (map['latitude'] as num).toDouble(),
        longitude: (map['longitude'] as num).toDouble(),
        confidence: BirthTimeConfidence.values.byName(map['confidence'] as String),
        sourceNote: map['source_note'] as String,
      );
}
