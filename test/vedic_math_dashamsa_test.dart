import 'package:astro_logic/src/vedic/vedic_math.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('BPHS D10 odd signs count from self', () {
    expect(VedicMath.dashamsaSignIndex(7.0), 2); // Aries 3rd part -> Gemini
    expect(VedicMath.dashamsaSignIndex(125.0 + 10 / 60), 5); // Leo 2nd -> Virgo
    expect(VedicMath.dashamsaSignIndex(194.0 + 20 / 60), 10); // Libra 5th -> Aquarius
  });

  test('BPHS D10 even signs count from ninth sign', () {
    expect(VedicMath.dashamsaSignIndex(30.0), 9); // Taurus 1st -> Capricorn
    expect(VedicMath.dashamsaSignIndex(117.0 + 40 / 60), 8); // Cancer 10th -> Sagittarius
    expect(VedicMath.dashamsaSignIndex(232.0), 10); // Scorpio 8th -> Aquarius
  });

  test('D10 uses half-open 3 degree boundaries', () {
    expect(VedicMath.dashamsaSignIndex(2.999999), 0);
    expect(VedicMath.dashamsaSignIndex(3.0), 1);
    expect(VedicMath.dashamsaSignIndex(29.999999), 9);
  });
}
