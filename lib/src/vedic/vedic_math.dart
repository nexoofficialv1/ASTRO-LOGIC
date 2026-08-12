class VedicMath {
  const VedicMath._();

  static const rashiNames = <String>[
    'Aries',
    'Taurus',
    'Gemini',
    'Cancer',
    'Leo',
    'Virgo',
    'Libra',
    'Scorpio',
    'Sagittarius',
    'Capricorn',
    'Aquarius',
    'Pisces',
  ];

  static const nakshatraNames = <String>[
    'Ashwini',
    'Bharani',
    'Krittika',
    'Rohini',
    'Mrigashira',
    'Ardra',
    'Punarvasu',
    'Pushya',
    'Ashlesha',
    'Magha',
    'Purva Phalguni',
    'Uttara Phalguni',
    'Hasta',
    'Chitra',
    'Swati',
    'Vishakha',
    'Anuradha',
    'Jyeshtha',
    'Mula',
    'Purva Ashadha',
    'Uttara Ashadha',
    'Shravana',
    'Dhanishta',
    'Shatabhisha',
    'Purva Bhadrapada',
    'Uttara Bhadrapada',
    'Revati',
  ];

  static double normalize(double degrees) {
    final value = degrees % 360.0;
    return value < 0 ? value + 360.0 : value;
  }

  static double siderealLongitude(double tropical, double ayanamsha) =>
      normalize(tropical - ayanamsha);

  static int signIndex(double longitude) =>
      (normalize(longitude) * 12.0) ~/ 360.0;

  static double degreeInSign(double longitude) => normalize(longitude) % 30.0;

  static int nakshatraIndex(double longitude) =>
      (normalize(longitude) * 27.0) ~/ 360.0;

  static int nakshatraPada(double longitude) =>
      (((normalize(longitude) * 108.0) ~/ 360.0) % 4) + 1;

  static int navamsaSignIndex(double longitude) =>
      ((normalize(longitude) * 9.0) ~/ 30.0) % 12;

  /// Classical Parashari Dashamsa (D10): each sign is divided into ten
  /// 3-degree parts. Odd signs count from themselves; even signs count
  /// from the ninth sign from the natal sign.
  static int dashamsaSignIndex(double longitude) {
    final normalized = normalize(longitude);
    final natalSign = signIndex(normalized);
    final segment = (degreeInSign(normalized) ~/ 3.0).clamp(0, 9).toInt();
    final start = natalSign.isEven ? natalSign : (natalSign + 8) % 12;
    return (start + segment) % 12;
  }

  static int tithiNumber(double sunLongitude, double moonLongitude) =>
      ((normalize(moonLongitude - sunLongitude) * 30.0) ~/ 360.0) + 1;

  static int yogaNumber(double siderealSun, double siderealMoon) =>
      ((normalize(siderealSun + siderealMoon) * 27.0) ~/ 360.0) + 1;
}
