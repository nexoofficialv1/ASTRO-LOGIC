part of 'vedic_lagna_judgment_engine.dart';

Map<String, Object?> _requiredMap(Object? value, String path) {
  if (value is! Map) throw StateError('Missing or invalid $path');
  return Map<String, Object?>.from(value);
}

int _requiredSignIndex(Object? value, String path) {
  if (value is! num || value.toInt() < 0 || value.toInt() > 11) {
    throw StateError('Missing or invalid $path');
  }
  return value.toInt();
}

Map<String, _ChartPlanet> _requiredPlanets(Object? value) {
  if (value is! List) throw StateError('Missing or invalid planets');
  final planets = <String, _ChartPlanet>{};
  for (var index = 0; index < value.length; index += 1) {
    final map = _requiredMap(value[index], 'planets[$index]');
    final body = map['body'];
    if (body is! String || body.trim().isEmpty) {
      throw StateError('Missing planet body at index $index');
    }
    final signIndex = _requiredSignIndex(
      map['signIndex'],
      'planets[$index].signIndex',
    );
    final siderealLongitude = _requiredLongitude(
      map['siderealLongitude'],
      'planets[$index].siderealLongitude',
    );
    if ((siderealLongitude ~/ 30) != signIndex) {
      throw StateError(
        'Planet sign and sidereal longitude disagree at index $index',
      );
    }
    final calculatedNavamsa = _navamsaSignIndex(siderealLongitude);
    final suppliedNavamsa = map['navamsaSignIndex'];
    final navamsaSignIndex = suppliedNavamsa == null
        ? calculatedNavamsa
        : _requiredSignIndex(
            suppliedNavamsa,
            'planets[$index].navamsaSignIndex',
          );
    if (navamsaSignIndex != calculatedNavamsa) {
      throw StateError(
        'Planet Navamsha and sidereal longitude disagree at index $index',
      );
    }
    final latitudeValue = map['eclipticLatitude'];
    final eclipticLatitude = latitudeValue == null
        ? null
        : _requiredLatitude(
            latitudeValue,
            'planets[$index].eclipticLatitude',
          );
    planets[body] = _ChartPlanet(
      signIndex: signIndex,
      siderealLongitude: siderealLongitude,
      navamsaSignIndex: navamsaSignIndex,
      retrograde: _requiredBoolean(
        map['retrograde'],
        'planets[$index].retrograde',
      ),
      eclipticLatitude: eclipticLatitude,
    );
  }
  return planets;
}

double _requiredLatitude(Object? value, String path) {
  if (value is! num ||
      !value.toDouble().isFinite ||
      value.toDouble() < -90.0 ||
      value.toDouble() > 90.0) {
    throw StateError('Missing or invalid $path');
  }
  return value.toDouble();
}

double _requiredLongitude(Object? value, String path) {
  if (value is! num ||
      !value.toDouble().isFinite ||
      value.toDouble() < 0 ||
      value.toDouble() >= 360) {
    throw StateError('Missing or invalid $path');
  }
  return value.toDouble();
}

int _navamsaSignIndex(double longitude) =>
    ((longitude * 9.0) ~/ 30.0) % 12;

bool _requiredBoolean(Object? value, String path) {
  if (value is! bool) throw StateError('Missing or invalid $path');
  return value;
}

_Dignity _dignity(String planet, int signIndex) {
  if (_exaltationSigns[planet] == signIndex) return _Dignity.exalted;
  if (_debilitationSigns[planet] == signIndex) {
    return _Dignity.debilitated;
  }
  if (_ownSigns[planet]!.contains(signIndex)) return _Dignity.ownSign;
  return _Dignity.neutral;
}

const _supportiveHouses = {1, 4, 5, 7, 9, 10};
const _challengingHouses = {6, 8, 12};
const _mahapurushaKendras = {1, 4, 7, 10};
const _rajaYogaKendraTrikona = {1, 4, 5, 7, 9, 10};
const _gajakesariBeneficSupporters = {'mercury', 'venus'};
const _kujaCoreHouses = {1, 4, 7, 8, 12};
const _mahapurushaProfiles = <_MahapurushaProfile>[
  _MahapurushaProfile('ruchaka', 'Ruchaka', 'রুচক', 'mars'),
  _MahapurushaProfile('bhadra', 'Bhadra', 'ভদ্র', 'mercury'),
  _MahapurushaProfile('hamsa', 'Hamsa', 'হংস', 'jupiter'),
  _MahapurushaProfile('malavya', 'Malavya', 'মালব্য', 'venus'),
  _MahapurushaProfile('shasha', 'Shasha', 'শশ', 'saturn'),
];
const _kendraForYoga = {4, 7, 10};
const _trikonaForYoga = {5, 9};
const _ownershipScores = <int, int>{
  1: 2,
  2: 0,
  3: -1,
  4: 1,
  5: 2,
  6: -2,
  7: 0,
  8: -2,
  9: 2,
  10: 1,
  11: -1,
  12: -1,
};
const _houseLifeAreas = <LifeArea>[
  LifeArea.self,
  LifeArea.family,
  LifeArea.communication,
  LifeArea.property,
  LifeArea.education,
  LifeArea.obstacles,
  LifeArea.marriage,
  LifeArea.longevity,
  LifeArea.fortune,
  LifeArea.career,
  LifeArea.gains,
  LifeArea.expenses,
];
const _houseDomainsEn = <String>[
  'self, vitality and direction',
  'family, speech and accumulated wealth',
  'courage, siblings and communication',
  'home, mother, property and contentment',
  'intelligence, education, children and creativity',
  'health obstacles, debt, conflict and service',
  'marriage and partnership',
  'longevity, transformation and shared assets',
  'dharma, fortune, father and higher learning',
  'career, status and action',
  'gains, networks and ambitions',
  'expenditure, foreign stay, withdrawal and liberation',
];
const _houseDomainsBn = <String>[
  'স্বভাব, প্রাণশক্তি ও জীবনদিশা',
  'পরিবার, বাকশক্তি ও সঞ্চিত অর্থ',
  'সাহস, ভাইবোন ও যোগাযোগ',
  'গৃহ, মাতা, সম্পত্তি ও মানসিক স্বস্তি',
  'বুদ্ধি, শিক্ষা, সন্তান ও সৃজনশীলতা',
  'স্বাস্থ্যগত বাধা, ঋণ, বিরোধ ও সেবা',
  'বিবাহ ও অংশীদারিত্ব',
  'আয়ু, রূপান্তর ও যৌথ সম্পদ',
  'ধর্ম, ভাগ্য, পিতা ও উচ্চশিক্ষা',
  'পেশা, মর্যাদা ও কর্ম',
  'লাভ, যোগাযোগবৃত্ত ও আকাঙ্ক্ষা',
  'ব্যয়, বিদেশবাস, নির্জনতা ও মোক্ষ',
];
const _aspectRules = <String, List<_AspectRule>>{
  'sun': [_AspectRule(7, '7th', 'সপ্তম')],
  'moon': [_AspectRule(7, '7th', 'সপ্তম')],
  'mercury': [_AspectRule(7, '7th', 'সপ্তম')],
  'venus': [_AspectRule(7, '7th', 'সপ্তম')],
  'mars': [
    _AspectRule(7, '7th', 'সপ্তম'),
    _AspectRule(4, 'special 4th', 'বিশেষ চতুর্থ'),
    _AspectRule(8, 'special 8th', 'বিশেষ অষ্টম'),
  ],
  'jupiter': [
    _AspectRule(7, '7th', 'সপ্তম'),
    _AspectRule(5, 'special 5th', 'বিশেষ পঞ্চম'),
    _AspectRule(9, 'special 9th', 'বিশেষ নবম'),
  ],
  'saturn': [
    _AspectRule(7, '7th', 'সপ্তম'),
    _AspectRule(3, 'special 3rd', 'বিশেষ তৃতীয়'),
    _AspectRule(10, 'special 10th', 'বিশেষ দশম'),
  ],
};
const _combustionBodies = <String>[
  'moon',
  'mars',
  'mercury',
  'jupiter',
  'venus',
  'saturn',
];
const _retrogradeBodies = <String>[
  'mars',
  'mercury',
  'jupiter',
  'venus',
  'saturn',
];
const _planetaryWarBodies = <String>[
  'mars',
  'mercury',
  'jupiter',
  'venus',
  'saturn',
];
const _planetaryWarReviewThreshold = 1.0;
const _vimshottariSequence = <String>[
  'ketu',
  'venus',
  'sun',
  'moon',
  'mars',
  'rahu',
  'jupiter',
  'saturn',
  'mercury',
];
const _temporaryFriendHouses = <int>{2, 3, 4, 10, 11, 12};
const _signLords = <int, String>{
  0: 'mars', 1: 'venus', 2: 'mercury', 3: 'moon',
  4: 'sun', 5: 'mercury', 6: 'venus', 7: 'mars',
  8: 'jupiter', 9: 'saturn', 10: 'saturn', 11: 'jupiter',
};
const _exaltationSigns = <String, int>{
  'sun': 0, 'moon': 1, 'mars': 9, 'mercury': 5,
  'jupiter': 3, 'venus': 11, 'saturn': 6,
};
const _debilitationSigns = <String, int>{
  'sun': 6, 'moon': 7, 'mars': 3, 'mercury': 11,
  'jupiter': 9, 'venus': 5, 'saturn': 0,
};
const _ownSigns = <String, Set<int>>{
  'sun': {4}, 'moon': {3}, 'mars': {0, 7}, 'mercury': {2, 5},
  'jupiter': {8, 11}, 'venus': {1, 6}, 'saturn': {9, 10},
};
const _naturalFriends = <String, Set<String>>{
  'sun': {'moon', 'mars', 'jupiter'},
  'moon': {'sun', 'mercury'},
  'mars': {'sun', 'moon', 'jupiter'},
  'mercury': {'sun', 'venus'},
  'jupiter': {'sun', 'moon', 'mars'},
  'venus': {'mercury', 'saturn'},
  'saturn': {'mercury', 'venus'},
};
const _naturalEnemies = <String, Set<String>>{
  'sun': {'venus', 'saturn'},
  'moon': <String>{},
  'mars': {'mercury'},
  'mercury': {'moon'},
  'jupiter': {'mercury', 'venus'},
  'venus': {'sun', 'moon'},
  'saturn': {'sun', 'moon', 'mars'},
};
const _naturalRelationshipEn =
    <_NaturalRelationship, String>{
  _NaturalRelationship.own: 'own',
  _NaturalRelationship.friend: 'friendly',
  _NaturalRelationship.neutral: 'neutral',
  _NaturalRelationship.enemy: 'enemy',
};
const _naturalRelationshipBn =
    <_NaturalRelationship, String>{
  _NaturalRelationship.own: 'নিজ',
  _NaturalRelationship.friend: 'মিত্র',
  _NaturalRelationship.neutral: 'সম',
  _NaturalRelationship.enemy: 'শত্রু',
};
const _compoundRelationshipEn =
    <_CompoundRelationship, String>{
  _CompoundRelationship.greatFriend: 'great friend',
  _CompoundRelationship.friend: 'friend',
  _CompoundRelationship.neutral: 'neutral',
  _CompoundRelationship.enemy: 'enemy',
  _CompoundRelationship.greatEnemy: 'great enemy',
};
const _compoundRelationshipBn =
    <_CompoundRelationship, String>{
  _CompoundRelationship.greatFriend: 'অধিমিত্র',
  _CompoundRelationship.friend: 'মিত্র',
  _CompoundRelationship.neutral: 'সম',
  _CompoundRelationship.enemy: 'শত্রু',
  _CompoundRelationship.greatEnemy: 'অধিশত্রু',
};
const _moolatrikonaRanges = <String, _DegreeRange>{
  'sun': _DegreeRange(4, 0, 20),
  'moon': _DegreeRange(1, 3, 30),
  'mars': _DegreeRange(0, 0, 12),
  'mercury': _DegreeRange(5, 15, 20),
  'jupiter': _DegreeRange(8, 0, 10),
  'venus': _DegreeRange(6, 0, 15),
  'saturn': _DegreeRange(10, 0, 20),
};
const _signNamesEn = [
  'Aries', 'Taurus', 'Gemini', 'Cancer', 'Leo', 'Virgo',
  'Libra', 'Scorpio', 'Sagittarius', 'Capricorn', 'Aquarius', 'Pisces',
];
const _signNamesBn = [
  'মেষ', 'বৃষ', 'মিথুন', 'কর্কট', 'সিংহ', 'কন্যা',
  'তুলা', 'বৃশ্চিক', 'ধনু', 'মকর', 'কুম্ভ', 'মীন',
];
const _planetNamesEn = <String, String>{
  'sun': 'Sun', 'moon': 'Moon', 'mars': 'Mars',
  'mercury': 'Mercury', 'jupiter': 'Jupiter',
  'venus': 'Venus', 'saturn': 'Saturn',
};
const _planetNamesBn = <String, String>{
  'sun': 'সূর্য', 'moon': 'চন্দ্র', 'mars': 'মঙ্গল',
  'mercury': 'বুধ', 'jupiter': 'বৃহস্পতি',
  'venus': 'শুক্র', 'saturn': 'শনি',
};
const _nodeNamesEn = <String, String>{
  'rahu': 'Rahu',
  'ketu': 'Ketu',
};
const _nodeNamesBn = <String, String>{
  'rahu': 'রাহু',
  'ketu': 'কেতু',
};
const _dignityEn = <_Dignity, String>{
  _Dignity.exalted: 'exalted', _Dignity.ownSign: 'own-sign',
  _Dignity.debilitated: 'debilitated', _Dignity.neutral: 'neutral',
};
const _dignityBn = <_Dignity, String>{
  _Dignity.exalted: 'তুঙ্গ', _Dignity.ownSign: 'স্বক্ষেত্র',
  _Dignity.debilitated: 'নীচ', _Dignity.neutral: 'নিরপেক্ষ',
};
const _polarityEn = <AnalysisPolarity, String>{
  AnalysisPolarity.supportive: 'Supportive',
  AnalysisPolarity.challenging: 'Challenging',
  AnalysisPolarity.mixed: 'Mixed',
};
const _polarityBn = <AnalysisPolarity, String>{
  AnalysisPolarity.supportive: 'সহায়ক',
  AnalysisPolarity.challenging: 'চ্যালেঞ্জিং',
  AnalysisPolarity.mixed: 'মিশ্র',
};
const _dashaHouseLifeAreas = <int, List<LifeArea>>{
  1: [LifeArea.self, LifeArea.health],
  2: [LifeArea.family, LifeArea.finance],
  3: [LifeArea.communication, LifeArea.siblings],
  4: [LifeArea.property, LifeArea.family],
  5: [LifeArea.education, LifeArea.children],
  6: [LifeArea.health, LifeArea.obstacles],
  7: [LifeArea.marriage],
  8: [LifeArea.longevity, LifeArea.finance],
  9: [LifeArea.fortune, LifeArea.education, LifeArea.spirituality],
  10: [LifeArea.career],
  11: [LifeArea.gains, LifeArea.finance],
  12: [LifeArea.expenses, LifeArea.spirituality],
};

class _DashaActivation {
  const _DashaActivation({
    required this.score,
    required this.internalConflict,
    required this.lifeAreas,
    required this.summaryEn,
    required this.summaryBn,
    required this.evidence,
  });

  final int score;
  final bool internalConflict;
  final List<LifeArea> lifeAreas;
  final String summaryEn;
  final String summaryBn;
  final List<ChartEvidence> evidence;
}

enum _Dignity { exalted, ownSign, debilitated, neutral }

enum _NaturalRelationship { own, friend, neutral, enemy }

enum _CompoundRelationship { greatFriend, friend, neutral, enemy, greatEnemy }

class _DegreeRange {
  const _DegreeRange(this.signIndex, this.startDegree, this.endDegree);

  final int signIndex;
  final double startDegree;
  final double endDegree;
}

class _ChartPlanet {
  const _ChartPlanet({
    required this.signIndex,
    required this.siderealLongitude,
    required this.navamsaSignIndex,
    required this.retrograde,
    required this.eclipticLatitude,
  });

  final int signIndex;
  final double siderealLongitude;
  final int navamsaSignIndex;
  final bool retrograde;
  final double? eclipticLatitude;
}

class _FunctionalRole {
  const _FunctionalRole({
    required this.ownedHouses,
    required this.score,
    required this.yogaKaraka,
    required this.polarity,
  });

  final List<int> ownedHouses;
  final int score;
  final bool yogaKaraka;
  final AnalysisPolarity polarity;
}

class _MahapurushaProfile {
  const _MahapurushaProfile(
    this.code,
    this.nameEn,
    this.nameBn,
    this.planet,
  );

  final String code;
  final String nameEn;
  final String nameBn;
  final String planet;
}

class _StrengthReview {
  const _StrengthReview({
    required this.hasChallenge,
    required this.textEn,
    required this.textBn,
  });

  final bool hasChallenge;
  final String textEn;
  final String textBn;
}

class _AspectRule {
  const _AspectRule(this.houseCount, this.labelEn, this.labelBn);

  final int houseCount;
  final String labelEn;
  final String labelBn;
}
