enum WesternNativeBody {
  sun,
  moon,
  mars,
  mercury,
  jupiter,
  venus,
  saturn,
  uranus,
  neptune,
  pluto,
}

class WesternNativePositionData {
  const WesternNativePositionData({
    required this.tropicalLongitude,
    required this.eclipticLatitude,
    required this.longitudeSpeedPerDay,
  });

  final double tropicalLongitude;
  final double eclipticLatitude;
  final double longitudeSpeedPerDay;
}

class WesternNativeFrameData {
  const WesternNativeFrameData({
    required this.tropicalAscendant,
    required this.tropicalMc,
    required this.trueNodeTropical,
    required this.meanNodeTropical,
    required this.placidusAvailable,
    required this.tropicalCusps,
  });

  final double tropicalAscendant;
  final double tropicalMc;
  final double trueNodeTropical;
  final double meanNodeTropical;
  final bool placidusAvailable;
  final List<double> tropicalCusps;
}

abstract interface class WesternNativeBridge {
  String get libraryVersion;

  Future<WesternNativeFrameData> calculateFrame({
    required DateTime utc,
    required double latitude,
    required double longitude,
  });

  Future<WesternNativePositionData> calculatePosition({
    required WesternNativeBody body,
    required DateTime utc,
  });
}
