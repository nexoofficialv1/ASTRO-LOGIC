import '../models/astrology_settings.dart';

enum WesternRulershipProfile { traditional, modern }

enum WesternAspectProfile { majorOnly, majorAndMinor }

class WesternGovernance {
  const WesternGovernance._();

  static const profileVersion = 'western-modern-aspect-v1';
  static const tropicalProfile = 'western-tropical-zodiac-v1';
  static const placidusProfile = 'western-placidus-native-v1';
  static const wholeSignProfile = 'western-whole-sign-v1';
  static const equalProfile = 'western-equal-ascendant-v1';
  static const majorAspectProfile = 'western-major-aspect-orb-v1';
  static const majorMinorAspectProfile = 'western-major-minor-aspect-orb-v1';
  static const patternProfile = 'western-aspect-pattern-v1';
  static const dignityProfile = 'western-essential-dignity-major-v1';
  static const traditionalRulershipProfile = 'western-rulership-traditional-v1';
  static const modernRulershipProfile = 'western-rulership-modern-v1';
  static const modernPlanetProfile = 'western-modern-planets-v1';

  static const validatedStartYear = 1800;
  static const validatedEndYear = 2200;

  static String houseProfile(WesternHouseSystem system) => switch (system) {
        WesternHouseSystem.placidus => placidusProfile,
        WesternHouseSystem.wholeSign => wholeSignProfile,
        WesternHouseSystem.equal => equalProfile,
      };

  static String aspectProfileId(WesternAspectProfile profile) => switch (profile) {
        WesternAspectProfile.majorOnly => majorAspectProfile,
        WesternAspectProfile.majorAndMinor => majorMinorAspectProfile,
      };

  static String rulershipProfileId(WesternRulershipProfile profile) => switch (profile) {
        WesternRulershipProfile.traditional => traditionalRulershipProfile,
        WesternRulershipProfile.modern => modernRulershipProfile,
      };

  static bool minorAspectsEnabled(WesternAspectProfile profile) =>
      profile == WesternAspectProfile.majorAndMinor;

  static String rulerNameForSign(int signIndex, WesternRulershipProfile profile) {
    if (signIndex < 0 || signIndex > 11) {
      throw RangeError.range(signIndex, 0, 11, 'signIndex');
    }
    const traditional = <String>[
      'mars', 'venus', 'mercury', 'moon', 'sun', 'mercury',
      'venus', 'mars', 'jupiter', 'saturn', 'saturn', 'jupiter',
    ];
    if (profile == WesternRulershipProfile.traditional) {
      return traditional[signIndex];
    }
    const modern = <String>[
      'mars', 'venus', 'mercury', 'moon', 'sun', 'mercury',
      'venus', 'pluto', 'jupiter', 'saturn', 'uranus', 'neptune',
    ];
    return modern[signIndex];
  }

  static const englishDisclosure =
      'Western v2 adds native Uranus, Neptune and Pluto, explicit traditional '
      'or modern sign-rulership profiles, optional governed minor aspects and '
      'deterministic aspect-pattern evidence. Traditional seven-planet '
      'essential dignity remains authoritative and separate. No automatic '
      'real-world prediction or cross-system confidence uplift is generated.';

  static const bengaliDisclosure =
      'Western v2-তে native Uranus, Neptune ও Pluto, স্পষ্ট Traditional/Modern '
      'sign-rulership profile, ঐচ্ছিক governed minor aspect এবং deterministic '
      'aspect-pattern evidence যোগ হয়েছে। সাতটি traditional planet-এর essential '
      'dignity আগের authoritative profile হিসেবেই আলাদা থাকে। কোনো automatic '
      'real-world prediction বা cross-system confidence uplift তৈরি হয় না।';
}
