import 'package:astro_logic/src/models/birth_record.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('converts India local birth time to UTC without device-timezone leakage', () {
    final record = BirthRecord(
      label: 'Primary',
      localDateTime: DateTime(1984, 3, 13, 0, 12),
      utcOffsetMinutes: 330,
      placeName: 'Kalna',
      latitude: 23.22,
      longitude: 88.37,
      confidence: BirthTimeConfidence.exact,
      sourceNote: 'Recorded',
    );

    expect(record.utcDateTime, DateTime.utc(1984, 3, 12, 18, 42));
  });
}

