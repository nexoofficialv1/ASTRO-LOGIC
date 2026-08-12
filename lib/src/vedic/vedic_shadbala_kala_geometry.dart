part of 'vedic_shadbala_engine.dart';

_CheshtaResult _cheshtaBala(
  String planet,
  _Planet position, {
  required double ayanaBala,
  required double pakshaBala,
}) {
  final planetEn = _planetNamesEn[planet]!;
  final planetBn = _planetNamesBn[planet]!;
  if (planet == 'sun') {
    return _CheshtaResult(
      virupas: ayanaBala,
      method: 'sunAyanaBala',
      motionState: 'derivedFromAyana',
      outputPath:
          r'$.planets[?(@.body=="sun")].tropicalLongitude',
      descriptionEn:
          '$planetEn Cheshta Bala = ${_fmt(ayanaBala)} virupas because BPHS 27.18 equates the Sun\'s motional strength with its Ayana Bala.',
      descriptionBn:
          'BPHS 27.18 অনুযায়ী সূর্যের চেষ্টাবল অয়নবলের সমান; তাই $planetBn-এর চেষ্টাবল = ${_fmt(ayanaBala)} বিরূপ।',
      governanceEn:
          'Sun Cheshta uses the direct BPHS 27.18 Ayana equivalence.',
      governanceBn:
          'সূর্যের চেষ্টাবলে BPHS 27.18-এর সরাসরি অয়নবল-সমতা ব্যবহার করা হয়েছে।',
    );
  }
  if (planet == 'moon') {
    return _CheshtaResult(
      virupas: pakshaBala,
      method: 'moonPakshaBala',
      motionState: 'derivedFromPaksha',
      outputPath:
          r'$.planets[?(@.body=="moon")].siderealLongitude',
      descriptionEn:
          '$planetEn Cheshta Bala = ${_fmt(pakshaBala)} virupas because BPHS 27.18 equates the Moon\'s motional strength with its Paksha Bala.',
      descriptionBn:
          'BPHS 27.18 অনুযায়ী চন্দ্রের চেষ্টাবল পক্ষবলের সমান; তাই $planetBn-এর চেষ্টাবল = ${_fmt(pakshaBala)} বিরূপ।',
      governanceEn:
          'Moon Cheshta uses the direct BPHS 27.18 Paksha equivalence.',
      governanceBn:
          'চন্দ্রের চেষ্টাবলে BPHS 27.18-এর সরাসরি পক্ষবল-সমতা ব্যবহার করা হয়েছে।',
    );
  }

  final speed = position.longitudeSpeedPerDay;
  if (speed == null) {
    return _CheshtaResult(
      virupas: null,
      method: 'legacyOutputWithoutSpeed',
      motionState: null,
      outputPath:
          r'$.planets[?(@.body=="' + planet + r'")].longitudeSpeedPerDay',
      descriptionEn:
          '$planetEn Cheshta Bala is unavailable because this legacy calculation output does not persist exact longitudinal speed.',
      descriptionBn:
          'এই legacy calculation output-এ exact longitudinal speed সংরক্ষিত নেই, তাই $planetBn-এর চেষ্টাবল unavailable।',
      governanceEn:
          'This legacy record does not contribute a Mars-through-Saturn Cheshta value.',
      governanceBn:
          'এই legacy record থেকে মঙ্গল-থেকে-শনি চেষ্টাবলের মান যোগ করা হচ্ছে না।',
    );
  }

  final mean = _meanDailyMotionDegrees[planet]!;
  final ratio = speed.abs() / mean;
  final projected = _normalize(position.siderealLongitude + speed);
  final projectedSign = projected ~/ 30;
  final previousSign = (position.signIndex + 11) % 12;
  final nextSign = (position.signIndex + 1) % 12;

  late final String state;
  late final double virupas;
  if (speed < 0) {
    if (projectedSign == previousSign) {
      state = 'anuvakra';
      virupas = 30.0;
    } else {
      state = 'vakra';
      virupas = 60.0;
    }
  } else if (ratio < 0.10) {
    state = 'vikala';
    virupas = 15.0;
  } else if (ratio < 0.50) {
    state = 'mandatara';
    virupas = 15.0;
  } else if (ratio < 1.00) {
    state = 'manda';
    virupas = 30.0;
  } else if (ratio <= 1.50) {
    state = 'sama';
    virupas = 7.5;
  } else if (projectedSign == nextSign) {
    state = 'atichara';
    virupas = 30.0;
  } else {
    state = 'chara';
    virupas = 45.0;
  }

  return _CheshtaResult(
    virupas: virupas,
    method: 'bphsMotionStateSpeedProfileV1',
    motionState: state,
    outputPath:
        r'$.planets[?(@.body=="' + planet + r'")].longitudeSpeedPerDay',
    descriptionEn:
        '$planetEn Cheshta Bala = ${_fmt(virupas)} virupas in the versioned BPHS 27.21-23 motion-state profile: state=$state, exact speed=${_fmt(speed)}°/day, governed mean=${_fmt(mean)}°/day, speed ratio=${_fmt(ratio)}. Sign-entry states use a one-day speed projection.',
    descriptionBn:
        'versioned BPHS 27.21-23 motion-state profile-এ $planetBn-এর চেষ্টাবল = ${_fmt(virupas)} বিরূপ: state=$state, exact speed=${_fmt(speed)}°/দিন, governed mean=${_fmt(mean)}°/দিন, speed ratio=${_fmt(ratio)}। রাশি-প্রবেশ state নির্ণয়ে এক দিনের speed projection ব্যবহার করা হয়েছে।',
    governanceEn:
        'Mars-through-Saturn Cheshta uses an explicit speed-state operational profile for the eight BPHS motion labels. It is not presented as the alternative BPHS 27.24-25 mean/true-longitude Cheshta-kendra calculation.',
    governanceBn:
        'মঙ্গল-থেকে-শনি চেষ্টাবলে BPHS-এর আট motion label-এর জন্য একটি স্পষ্ট speed-state operational profile ব্যবহার করা হয়েছে; এটিকে BPHS 27.24-25-এর mean/true-longitude Cheshta-kendra গণনা হিসেবে দেখানো হচ্ছে না।',
  );
}

double _normalize(double value) {
  final normalized = value % 360.0;
  return normalized < 0 ? normalized + 360.0 : normalized;
}

double _nathonnataBala(String planet, double sunHourAngleHours) {
  if (!sunHourAngleHours.isFinite ||
      sunHourAngleHours < 0.0 ||
      sunHourAngleHours >= 24.0) {
    throw ArgumentError.value(sunHourAngleHours, 'sunHourAngleHours');
  }
  if (planet == 'mercury') return 60.0;
  final hoursFromApparentMidnight = (sunHourAngleHours - 12.0).abs();
  final unnataGhatis = hoursFromApparentMidnight * 2.5;
  final nataGhatis = 30.0 - unnataGhatis;
  final nightStrength = (2.0 * nataGhatis).clamp(0.0, 60.0).toDouble();
  if (planet == 'moon' || planet == 'mars' || planet == 'saturn') {
    return nightStrength;
  }
  return 60.0 - nightStrength;
}

double? _lordBala(String planet, String? lord, double virupas) {
  if (lord == null) return null;
  return planet == lord ? virupas : 0.0;
}

double _tribhagaBala(String planet, bool isDay, int third) {
  if (third < 1 || third > 3) {
    throw ArgumentError.value(third, 'third');
  }
  if (planet == 'jupiter') return 60.0;
  const dayLords = <int, String>{
    1: 'mercury',
    2: 'sun',
    3: 'saturn',
  };
  const nightLords = <int, String>{
    1: 'moon',
    2: 'venus',
    3: 'mars',
  };
  final lord = (isDay ? dayLords : nightLords)[third];
  return planet == lord ? 60.0 : 0.0;
}

_TribhagaContext? _optionalTribhagaContext(Object? rawMetadata) {
  final metadata = _requiredMap(rawMetadata, 'metadata');
  final rawIsDay = metadata['tribhagaIsDay'];
  final rawThird = metadata['tribhagaThird'];
  final rawStart = metadata['tribhagaPeriodStartUtc'];
  final rawEnd = metadata['tribhagaPeriodEndUtc'];
  final present = <Object?>[rawIsDay, rawThird, rawStart, rawEnd]
      .where((value) => value != null)
      .length;
  if (present == 0) return null;
  if (present != 4 ||
      rawIsDay is! bool ||
      rawThird is! int ||
      rawThird < 1 ||
      rawThird > 3 ||
      rawStart is! String ||
      rawEnd is! String) {
    throw StateError('metadata Tribhaga solar-period contract is invalid');
  }
  final rawBirth = metadata['utcDateTime'];
  if (rawBirth is! String) {
    throw StateError('metadata.utcDateTime is required for Tribhaga audit');
  }
  final start = DateTime.tryParse(rawStart)?.toUtc();
  final end = DateTime.tryParse(rawEnd)?.toUtc();
  final birth = DateTime.tryParse(rawBirth)?.toUtc();
  if (start == null || end == null || birth == null ||
      !end.isAfter(start) || birth.isBefore(start) || birth.isAfter(end)) {
    throw StateError('metadata Tribhaga UTC boundaries are invalid');
  }
  return _TribhagaContext(
    isDay: rawIsDay,
    third: rawThird,
    startUtc: start.toIso8601String(),
    endUtc: end.toIso8601String(),
  );
}

_VarshaMasaDinaHoraContext _varshaMasaDinaHoraContext(
  Object? rawMetadata,
) {
  final metadata = _requiredMap(rawMetadata, 'metadata');
  final profile = metadata['varshaMasaDinaHoraProfile'];
  if (profile != 'siderealSolarIngressAstrologicalDayV1') {
    throw StateError('Current Vedic output has an invalid Varsha-Masa-Dina-Hora profile');
  }

  String? lord(String key) {
    final value = metadata[key];
    if (value == null) return null;
    if (value is! String || !_classicalPlanets.contains(value)) {
      throw StateError('metadata.$key is invalid');
    }
    return value;
  }

  String? utc(String key) {
    final value = metadata[key];
    if (value == null) return null;
    if (value is! String || DateTime.tryParse(value)?.isUtc != true) {
      throw StateError('metadata.$key must be an ISO UTC timestamp');
    }
    return DateTime.parse(value).toUtc().toIso8601String();
  }

  final varshaLord = lord('varshaLord');
  final masaLord = lord('masaLord');
  final dinaLord = lord('dinaLord');
  final horaLord = lord('horaLord');
  final rawHoraNumber = metadata['horaNumber'];
  final rawHoraPeriod = metadata['horaPeriod'];
  int? horaNumber;
  String? horaPeriod;
  if (rawHoraNumber != null || rawHoraPeriod != null || horaLord != null) {
    if (rawHoraNumber is! int ||
        rawHoraNumber < 1 ||
        rawHoraNumber > 24 ||
        rawHoraPeriod is! String ||
        (rawHoraPeriod != 'day' && rawHoraPeriod != 'night') ||
        horaLord == null) {
      throw StateError('metadata Hora contract is invalid');
    }
    horaNumber = rawHoraNumber;
    horaPeriod = rawHoraPeriod;
  }

  final astrologicalDayStartUtc = utc('astrologicalDayStartUtc');
  final varshaIngressUtc = utc('varshaIngressUtc');
  final varshaDayStartUtc = utc('varshaAstrologicalDayStartUtc');
  final masaIngressUtc = utc('masaIngressUtc');
  final masaDayStartUtc = utc('masaAstrologicalDayStartUtc');
  final hasDinaAudit = dinaLord != null || astrologicalDayStartUtc != null;
  final hasVarshaAudit =
      varshaLord != null || varshaIngressUtc != null || varshaDayStartUtc != null;
  final hasMasaAudit =
      masaLord != null || masaIngressUtc != null || masaDayStartUtc != null;
  if ((hasDinaAudit && (dinaLord == null || astrologicalDayStartUtc == null)) ||
      (hasVarshaAudit &&
          (varshaLord == null ||
              varshaIngressUtc == null ||
              varshaDayStartUtc == null)) ||
      (hasMasaAudit &&
          (masaLord == null || masaIngressUtc == null || masaDayStartUtc == null))) {
    throw StateError('metadata Varsha-Masa-Dina audit contract is incomplete');
  }

  return _VarshaMasaDinaHoraContext(
    profile: profile as String,
    varshaLord: varshaLord,
    masaLord: masaLord,
    dinaLord: dinaLord,
    horaLord: horaLord,
    horaNumber: horaNumber,
    horaPeriod: horaPeriod,
    astrologicalDayStartUtc: astrologicalDayStartUtc,
    varshaIngressUtc: varshaIngressUtc,
    varshaDayStartUtc: varshaDayStartUtc,
    masaIngressUtc: masaIngressUtc,
    masaDayStartUtc: masaDayStartUtc,
  );
}

double _requiredSunHourAngle(Object? rawMetadata) {
  final metadata = _requiredMap(rawMetadata, 'metadata');
  final raw = metadata['sunHourAngleHours'];
  if (raw is! num) {
    throw StateError('Current Vedic output is missing metadata.sunHourAngleHours');
  }
  final value = raw.toDouble();
  if (!value.isFinite || value < 0.0 || value >= 24.0) {
    throw StateError('metadata.sunHourAngleHours must be finite in [0, 24)');
  }
  return value;
}

double _pakshaBala(
  String planet,
  double sunLongitude,
  double moonLongitude,
) {
  final raw = (moonLongitude - sunLongitude + 360.0) % 360.0;
  final folded = raw <= 180.0 ? raw : 360.0 - raw;
  final beneficStrength = folded / 3.0;
  if (_pakshaBenefics.contains(planet)) return beneficStrength;
  return 60.0 - beneficStrength;
}

double _ayanaBala(String planet, double tropicalLongitude) {
  final halfCircle = tropicalLongitude % 180.0;
  final equinoxDistance =
      halfCircle <= 90.0 ? halfCircle : 180.0 - halfCircle;
  final khanda = equinoxDistance <= 30.0
      ? (equinoxDistance / 30.0) * 45.0
      : equinoxDistance <= 60.0
          ? 45.0 + ((equinoxDistance - 30.0) / 30.0) * 33.0
          : 78.0 + ((equinoxDistance - 60.0) / 30.0) * 12.0;
  final ariesToVirgo = tropicalLongitude < 180.0;
  final double adjusted;
  if (planet == 'moon' || planet == 'saturn') {
    adjusted = ariesToVirgo ? 90.0 - khanda : 90.0 + khanda;
  } else if (planet == 'mercury') {
    adjusted = 90.0 + khanda;
  } else {
    adjusted = ariesToVirgo ? 90.0 + khanda : 90.0 - khanda;
  }
  final virupas = adjusted / 3.0;
  if (!virupas.isFinite || virupas < 0.0 || virupas > 60.0) {
    throw StateError('Computed Ayana Bala is outside 0..60 virupas');
  }
  return virupas;
}

double _digBala(
  String planet,
  double planetLongitude,
  double ascendantLongitude,
) {
  final powerlessOffset = _digBalaPowerlessOffset[planet]!;
  final powerlessLongitude =
      (ascendantLongitude + powerlessOffset) % 360.0;
  final forward =
      (planetLongitude - powerlessLongitude + 360.0) % 360.0;
  final distance = forward <= 180.0 ? forward : 360.0 - forward;
  return distance / 3.0;
}

double _ucchaBala(String planet, double longitude) {
  final debilitationPoint = _deepDebilitationLongitude[planet]!;
  final forward = (longitude - debilitationPoint + 360.0) % 360.0;
  final distance = forward <= 180.0 ? forward : 360.0 - forward;
  return distance / 3.0;
}

List<ShadbalaVargaContribution> _saptavargajaContributions(
  String planet,
  _Planet position,
  Map<String, _Planet> planets,
) {
  final signs = <int, int>{
    1: position.signIndex,
    2: _horaSign(position.signIndex, position.degreeInSign),
    3: _drekkanaSign(position.signIndex, position.degreeInSign),
    7: _saptamsaSign(position.signIndex, position.degreeInSign),
    9: position.navamsaSignIndex,
    12: _dwadasamsaSign(position.signIndex, position.degreeInSign),
    30: _trimsamsaSign(position.signIndex, position.degreeInSign),
  };

  return [
    for (final entry in signs.entries)
      _vargaContribution(
        planet,
        division: entry.key,
        signIndex: entry.value,
        natalPosition: position,
        planets: planets,
      ),
  ];
}

ShadbalaVargaContribution _vargaContribution(
  String planet, {
  required int division,
  required int signIndex,
  required _Planet natalPosition,
  required Map<String, _Planet> planets,
}) {
  final moolatrikona = division == 1
      ? _isMoolatrikona(planet, natalPosition)
      : signIndex == _moolatrikonaRanges[planet]!.signIndex;
  if (moolatrikona) {
    return ShadbalaVargaContribution(
      division: division,
      signIndex: signIndex,
      hostPlanet: _signLords[signIndex]!,
      relationship: 'moolatrikona',
      virupas: 45.0,
    );
  }
  final host = _signLords[signIndex]!;
  if (host == planet) {
    return ShadbalaVargaContribution(
      division: division,
      signIndex: signIndex,
      hostPlanet: host,
      relationship: 'own',
      virupas: 30.0,
    );
  }

  final hostPosition = planets[host];
  if (hostPosition == null) {
    throw StateError('Missing sign-lord position for $host');
  }
  // v1 resolves Tatkalika Maitri from the natal Rasi positions for all
  // seven varga contributions. This choice is explicit because traditions
  // differ on whether temporary friendship should be recalculated inside
  // each derived varga.
  final houseToHost =
      ((hostPosition.signIndex - natalPosition.signIndex + 12) % 12) + 1;
  final temporaryFriend = _temporaryFriendHouses.contains(houseToHost);
  final naturalFriend = _naturalFriends[planet]!.contains(host);
  final naturalEnemy = _naturalEnemies[planet]!.contains(host);
  late final String relationship;
  late final double virupas;

  if (naturalFriend && temporaryFriend) {
    relationship = 'greatFriend';
    virupas = 20.0;
  } else if (naturalFriend && !temporaryFriend) {
    relationship = 'neutral';
    virupas = 10.0;
  } else if (naturalEnemy && temporaryFriend) {
    relationship = 'neutral';
    virupas = 10.0;
  } else if (naturalEnemy && !temporaryFriend) {
    relationship = 'greatEnemy';
    virupas = 2.0;
  } else if (temporaryFriend) {
    relationship = 'friend';
    virupas = 15.0;
  } else {
    relationship = 'enemy';
    virupas = 4.0;
  }

  return ShadbalaVargaContribution(
    division: division,
    signIndex: signIndex,
    hostPlanet: host,
    relationship: relationship,
    virupas: virupas,
  );
}

bool _isMoolatrikona(String planet, _Planet position) {
  final range = _moolatrikonaRanges[planet]!;
  return position.signIndex == range.signIndex &&
      position.degreeInSign >= range.startDegree &&
      position.degreeInSign < range.endDegree;
}

double _ojayugmaBala(String planet, int d1Sign, int d9Sign) {
  final needsEven = planet == 'moon' || planet == 'venus';
  double score = 0;
  final d1Matches = needsEven ? d1Sign.isOdd : d1Sign.isEven;
  final d9Matches = needsEven ? d9Sign.isOdd : d9Sign.isEven;
  if (d1Matches) score += 15.0;
  if (d9Matches) score += 15.0;
  return score;
}

double _kendradiBala(int house) {
  if ({1, 4, 7, 10}.contains(house)) return 60.0;
  if ({2, 5, 8, 11}.contains(house)) return 30.0;
  return 15.0;
}

double _drekkanaBala(String planet, double degree) {
  final segment = degree < 10.0 ? 1 : (degree < 20.0 ? 2 : 3);
  if ({'sun', 'mars', 'jupiter'}.contains(planet) && segment == 1) {
    return 15.0;
  }
  // BPHS 27.6 profile: female planets receive the second Drekkana and
  // hermaphrodite planets the third. Some later/common implementations use
  // a different ordering; that variant is not mixed into this rule version.
  if ({'moon', 'venus'}.contains(planet) && segment == 2) {
    return 15.0;
  }
  if ({'mercury', 'saturn'}.contains(planet) && segment == 3) {
    return 15.0;
  }
  return 0.0;
}

int _horaSign(int sign, double degree) {
  final oddZodiacSign = sign.isEven;
  final firstHalf = degree < 15.0;
  if (oddZodiacSign) return firstHalf ? 4 : 3;
  return firstHalf ? 3 : 4;
}

int _drekkanaSign(int sign, double degree) {
  final segment = degree < 10.0 ? 0 : (degree < 20.0 ? 1 : 2);
  return (sign + segment * 4) % 12;
}

int _saptamsaSign(int sign, double degree) {
  final segment = (degree / (30.0 / 7.0)).floor();
  final start = sign.isEven ? sign : (sign + 6) % 12;
  return (start + segment) % 12;
}

int _dwadasamsaSign(int sign, double degree) {
  final segment = (degree / 2.5).floor();
  return (sign + segment) % 12;
}

int _trimsamsaSign(int sign, double degree) {
  final oddZodiacSign = sign.isEven;
  if (oddZodiacSign) {
    if (degree < 5.0) return 0; // Mars / Aries
    if (degree < 10.0) return 10; // Saturn / Aquarius
    if (degree < 18.0) return 8; // Jupiter / Sagittarius
    if (degree < 25.0) return 2; // Mercury / Gemini
    return 6; // Venus / Libra
  }
  if (degree < 5.0) return 1; // Venus / Taurus
  if (degree < 12.0) return 5; // Mercury / Virgo
  if (degree < 20.0) return 11; // Jupiter / Pisces
  if (degree < 25.0) return 9; // Saturn / Capricorn
  return 7; // Mars / Scorpio
}

Map<String, _Planet> _requiredPlanets(
  Object? value, {
  required bool requireLongitudeSpeed,
  required bool requireEclipticLatitude,
}) {
  if (value is! List) throw StateError('Missing or invalid planets');
  final result = <String, _Planet>{};
  for (var index = 0; index < value.length; index += 1) {
    final map = _requiredMap(value[index], 'planets[$index]');
    final body = map['body'];
    if (body is! String || body.trim().isEmpty) {
      throw StateError('Missing planet body at index $index');
    }
    final sign = _requiredSignIndex(map['signIndex'], 'planets[$index].signIndex');
    final longitude = _requiredLongitude(
      map['siderealLongitude'],
      'planets[$index].siderealLongitude',
    );
    final tropicalLongitude = _requiredLongitude(
      map['tropicalLongitude'],
      'planets[$index].tropicalLongitude',
    );
    if ((longitude ~/ 30) != sign) {
      throw StateError('Planet sign and longitude disagree at index $index');
    }
    final navamsaCalculated = ((longitude * 9.0) ~/ 30.0) % 12;
    final suppliedNavamsa = map['navamsaSignIndex'];
    final navamsa = suppliedNavamsa == null
        ? navamsaCalculated
        : _requiredSignIndex(
            suppliedNavamsa,
            'planets[$index].navamsaSignIndex',
          );
    if (navamsa != navamsaCalculated) {
      throw StateError('Planet Navamsha and longitude disagree at index $index');
    }
    final speed = _optionalFiniteDouble(
      map['longitudeSpeedPerDay'],
      'planets[$index].longitudeSpeedPerDay',
      required: requireLongitudeSpeed && _classicalPlanets.contains(body),
    );
    final eclipticLatitude = _optionalEclipticLatitude(
      map['eclipticLatitude'],
      'planets[$index].eclipticLatitude',
      required: requireEclipticLatitude && _classicalPlanets.contains(body),
    );
    result[body] = _Planet(
      signIndex: sign,
      siderealLongitude: longitude,
      tropicalLongitude: tropicalLongitude,
      navamsaSignIndex: navamsa,
      longitudeSpeedPerDay: speed,
      eclipticLatitude: eclipticLatitude,
    );
  }
  return result;
}
