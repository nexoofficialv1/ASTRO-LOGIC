part of 'vedic_shadbala_engine.dart';

const String _shadbalaRuleVersion = VedicShadbalaEngine.ruleVersion;

ShadbalaPlanetProfile _profile(
  String planet,
  _Planet position,
  int ascendantSign,
  double ascendantLongitude,
  Map<String, _Planet> planets,
  double? sunHourAngleHours,
  _TribhagaContext? tribhaga,
  _VarshaMasaDinaHoraContext? varshaMasaDinaHora,
  _YuddhaResult yuddha,
) {
  final uccha = _ucchaBala(planet, position.siderealLongitude);
  final vargaContributions = _saptavargajaContributions(
    planet,
    position,
    planets,
  );
  final saptavargaja = vargaContributions.fold<double>(
    0,
    (sum, value) => sum + value.virupas,
  );
  final ojayugma = _ojayugmaBala(
    planet,
    position.signIndex,
    position.navamsaSignIndex,
  );
  final house = ((position.signIndex - ascendantSign + 12) % 12) + 1;
  final kendradi = _kendradiBala(house);
  final drekkana = _drekkanaBala(planet, position.degreeInSign);
  final sthana = uccha + saptavargaja + ojayugma + kendradi + drekkana;
  final dig = _digBala(
    planet,
    position.siderealLongitude,
    ascendantLongitude,
  );
  final nathonnata = sunHourAngleHours == null
      ? null
      : _nathonnataBala(planet, sunHourAngleHours);
  final tribhagaBala = tribhaga == null
      ? null
      : _tribhagaBala(planet, tribhaga.isDay, tribhaga.third);
  final paksha = _pakshaBala(
    planet,
    planets['sun']!.siderealLongitude,
    planets['moon']!.siderealLongitude,
  );
  final varsha = _lordBala(planet, varshaMasaDinaHora?.varshaLord, 15.0);
  final masa = _lordBala(planet, varshaMasaDinaHora?.masaLord, 30.0);
  final dina = _lordBala(planet, varshaMasaDinaHora?.dinaLord, 45.0);
  final hora = _lordBala(planet, varshaMasaDinaHora?.horaLord, 60.0);
  final ayana = _ayanaBala(planet, position.tropicalLongitude);
  final kalaPartial = (nathonnata ?? 0.0) +
      (tribhagaBala ?? 0.0) +
      paksha +
      (varsha ?? 0.0) +
      (masa ?? 0.0) +
      (dina ?? 0.0) +
      (hora ?? 0.0) +
      ayana;
  final cheshta = _cheshtaBala(
    planet,
    position,
    ayanaBala: ayana,
    pakshaBala: paksha,
  );
  final drik = _drikBala(planet, position, planets);
  final naisargika = _naisargikaBala[planet]!;
  final planetEn = _planetNamesEn[planet]!;
  final planetBn = _planetNamesBn[planet]!;
  final kalaComplete = nathonnata != null &&
      tribhagaBala != null &&
      varsha != null &&
      masa != null &&
      dina != null &&
      hora != null &&
      yuddha.virupas != null;
  final kalaTotal = kalaComplete ? kalaPartial + yuddha.virupas! : null;
  final aggregateAvailable = kalaComplete && cheshta.virupas != null;
  final totalShadbala = aggregateAvailable
      ? sthana +
          dig +
          kalaTotal! +
          cheshta.virupas! +
          naisargika +
          drik.virupas
      : null;
  final totalShadbalaRupas =
      totalShadbala == null ? null : totalShadbala / 60.0;
  final requiredShadbala = _requiredShadbalaVirupas[planet]!;
  final requiredShadbalaRupas = requiredShadbala / 60.0;
  final requiredStrengthRatio =
      totalShadbala == null ? null : totalShadbala / requiredShadbala;
  final surplusDeficit =
      totalShadbala == null ? null : totalShadbala - requiredShadbala;
  final thresholdStatus = totalShadbala == null
      ? 'unavailable'
      : totalShadbala + 1e-9 >= requiredShadbala
          ? 'meetsRequired'
          : 'belowRequired';
  final kalaComputed = <String>[
    if (nathonnata != null) 'nathonnata',
    'paksha',
    if (tribhagaBala != null) 'tribhaga',
    if (varsha != null) 'varsha',
    if (masa != null) 'masa',
    if (dina != null) 'dina',
    if (hora != null) 'hora',
    if (yuddha.virupas != null) 'yuddha',
    'ayana',
  ];
  final kalaMissing = <String>[
    if (nathonnata == null) 'nathonnata',
    if (tribhagaBala == null) 'tribhaga',
    if (varsha == null) 'varsha',
    if (masa == null) 'masa',
    if (dina == null) 'dina',
    if (hora == null) 'hora',
    if (yuddha.virupas == null) 'yuddha',
  ];

  final evidence = <ChartEvidence>[
    ChartEvidence(
      ruleId: '$_shadbalaRuleVersion.uccha.$planet',
      outputPath: r'$.planets[?(@.body=="' + planet + r'")].siderealLongitude',
      kind: EvidenceKind.strength,
      descriptionEn:
          '$planetEn Uccha Bala = ${_fmt(uccha)} virupas from the governed deep-debilitation distance formula.',
      descriptionBn:
          '$planetBn-এর উচ্চবল = ${_fmt(uccha)} বিরূপ; versioned গভীর-নীচ বিন্দু থেকে কৌণিক দূরত্বের সূত্রে গণনা করা হয়েছে।',
    ),
    ChartEvidence(
      ruleId: '$_shadbalaRuleVersion.saptavargaja.$planet',
      outputPath: r'$.planets[?(@.body=="' + planet + r'")].siderealLongitude',
      kind: EvidenceKind.strength,
      descriptionEn:
          '$planetEn Saptavargaja Bala = ${_fmt(saptavargaja)} virupas across D1, D2, D3, D7, D9, D12 and D30.',
      descriptionBn:
          'D1, D2, D3, D7, D9, D12 ও D30 মিলিয়ে $planetBn-এর সপ্তবর্গজ বল = ${_fmt(saptavargaja)} বিরূপ।',
    ),
    ChartEvidence(
      ruleId: '$_shadbalaRuleVersion.ojayugma.$planet',
      outputPath: r'$.planets[?(@.body=="' + planet + r'")].navamsaSignIndex',
      kind: EvidenceKind.strength,
      descriptionEn:
          '$planetEn Ojhayugma Bala = ${_fmt(ojayugma)} virupas from D1/D9 odd-even placement.',
      descriptionBn:
          'D1/D9-এর বিজোড়-জোড় অবস্থান থেকে $planetBn-এর ওজযুগ্ম বল = ${_fmt(ojayugma)} বিরূপ।',
    ),
    ChartEvidence(
      ruleId: '$_shadbalaRuleVersion.kendradi.$planet',
      outputPath: r'$.planets[?(@.body=="' + planet + r'")].signIndex',
      kind: EvidenceKind.strength,
      descriptionEn:
          '$planetEn Kendradi Bala = ${_fmt(kendradi)} virupas from whole-sign house $house in the app\'s governed house frame.',
      descriptionBn:
          'অ্যাপের governed whole-sign ভাব কাঠামোতে $house নম্বর ভাব থেকে $planetBn-এর কেন্দ্রাদি বল = ${_fmt(kendradi)} বিরূপ।',
    ),
    ChartEvidence(
      ruleId: '$_shadbalaRuleVersion.drekkana.$planet',
      outputPath: r'$.planets[?(@.body=="' + planet + r'")].siderealLongitude',
      kind: EvidenceKind.strength,
      descriptionEn:
          '$planetEn Drekkana Bala = ${_fmt(drekkana)} virupas from its 10-degree Drekkana segment.',
      descriptionBn:
          'রাশির ১০° দ্রেক্কাণ অংশ থেকে $planetBn-এর দ্রেক্কাণ বল = ${_fmt(drekkana)} বিরূপ।',
    ),
    ChartEvidence(
      ruleId: '$_shadbalaRuleVersion.dig.$planet',
      outputPath: r'$.planets[?(@.body=="' + planet + r'")].siderealLongitude',
      kind: EvidenceKind.strength,
      descriptionEn:
          '$planetEn Dig Bala = ${_fmt(dig)} virupas from exact sidereal longitude versus its BPHS 27.7 zero-strength directional point, using the sidereal Ascendant ${_fmt(ascendantLongitude)}°.',
      descriptionBn:
          'BPHS 27.7-এর শূন্য-দিকবল বিন্দুর সঙ্গে exact sidereal longitude এবং sidereal Lagna ${_fmt(ascendantLongitude)}° ব্যবহার করে $planetBn-এর দিকবল = ${_fmt(dig)} বিরূপ।',
    ),
    if (nathonnata != null)
      ChartEvidence(
        ruleId: '$_shadbalaRuleVersion.nathonnata.$planet',
        outputPath: r'$.metadata.sunHourAngleHours',
        kind: EvidenceKind.strength,
        descriptionEn:
            '$planetEn Nathonnata Bala = ${_fmt(nathonnata)} virupas from apparent Sun hour angle ${_fmt(sunHourAngleHours!)}h under BPHS 27.9. Apparent noon is 0h and apparent midnight 12h.',
        descriptionBn:
            'BPHS 27.9 অনুযায়ী apparent Sun hour angle ${_fmt(sunHourAngleHours!)}h থেকে $planetBn-এর নতোন্নত বল = ${_fmt(nathonnata)} বিরূপ। apparent noon = 0h এবং apparent midnight = 12h ধরা হয়েছে।',
      ),
    if (tribhagaBala != null)
      ChartEvidence(
        ruleId: '$_shadbalaRuleVersion.tribhaga.$planet',
        outputPath: r'$.metadata.tribhagaThird',
        kind: EvidenceKind.strength,
        descriptionEn:
            '$planetEn Tribhaga Bala = ${_fmt(tribhagaBala)} virupas for ${tribhaga!.period} third ${tribhaga!.third}, using the actual Astronomy Engine rise/set interval ${tribhaga!.startUtc} to ${tribhaga!.endUtc}. The governed BPHS 27.12 ordering is day: Mercury/Sun/Saturn, night: Moon/Venus/Mars; Jupiter is always full.',
        descriptionBn:
            'actual Astronomy Engine rise/set interval ${tribhaga!.startUtc} থেকে ${tribhaga!.endUtc}-এর ${tribhaga!.period == 'day' ? 'দিন' : 'রাত'}-এর ${tribhaga!.third} নম্বর তৃতীয়াংশে BPHS 27.12 governed ক্রম অনুযায়ী $planetBn-এর ত্রিভাগ বল = ${_fmt(tribhagaBala)} বিরূপ। দিনের ক্রম বুধ/সূর্য/শনি, রাতের ক্রম চন্দ্র/শুক্র/মঙ্গল; বৃহস্পতি সর্বদা পূর্ণ বল পায়।',
      ),
    ChartEvidence(
      ruleId: '$_shadbalaRuleVersion.paksha.$planet',
      outputPath: r'$.planets[?(@.body=="moon")].siderealLongitude',
      kind: EvidenceKind.strength,
      descriptionEn:
          '$planetEn Paksha Bala = ${_fmt(paksha)} virupas from the governed BPHS 27.10-11 Sun-Moon separation rule; this is a temporal-strength component, not an event prediction.',
      descriptionBn:
          'BPHS 27.10-11-এর governed সূর্য-চন্দ্র কৌণিক দূরত্বের সূত্রে $planetBn-এর পক্ষবল = ${_fmt(paksha)} বিরূপ; এটি কালবলের একটি অংশ, কোনো নিশ্চিত ঘটনার ভবিষ্যদ্বাণী নয়।',
    ),
    if (varsha != null)
      ChartEvidence(
        ruleId: '$_shadbalaRuleVersion.varsha.$planet',
        outputPath: r'$.metadata.varshaLord',
        kind: EvidenceKind.strength,
        descriptionEn:
            '$planetEn Varsha Bala = ${_fmt(varsha)} virupas; the governed year lord is ${_planetNamesEn[varshaMasaDinaHora!.varshaLord!]}, derived from the astrological weekday that begins at sunrise ${varshaMasaDinaHora!.varshaDayStartUtc} before the prior sidereal Aries ingress ${varshaMasaDinaHora!.varshaIngressUtc}. BPHS 27.13 assigns 15 virupas to that lord.',
        descriptionBn:
            '$planetBn-এর বর্ষবল = ${_fmt(varsha)} বিরূপ; prior sidereal মেষ-সংক্রান্তি ${varshaMasaDinaHora!.varshaIngressUtc}-এর আগে sunrise ${varshaMasaDinaHora!.varshaDayStartUtc} দিয়ে শুরু হওয়া জ্যোতিষীয় দিনের অধিপতি ${_planetNamesBn[varshaMasaDinaHora!.varshaLord!]}। BPHS 27.13 অনুযায়ী বর্ষেশ ১৫ বিরূপ পায়।',
      ),
    if (masa != null)
      ChartEvidence(
        ruleId: '$_shadbalaRuleVersion.masa.$planet',
        outputPath: r'$.metadata.masaLord',
        kind: EvidenceKind.strength,
        descriptionEn:
            '$planetEn Masa Bala = ${_fmt(masa)} virupas; the governed month lord is ${_planetNamesEn[varshaMasaDinaHora!.masaLord!]}, derived from the astrological weekday beginning at ${varshaMasaDinaHora!.masaDayStartUtc} before the current sidereal solar-sign ingress ${varshaMasaDinaHora!.masaIngressUtc}. BPHS 27.13 assigns 30 virupas to that lord.',
        descriptionBn:
            '$planetBn-এর মাসবল = ${_fmt(masa)} বিরূপ; current sidereal সৌর-রাশি প্রবেশ ${varshaMasaDinaHora!.masaIngressUtc}-এর আগে ${varshaMasaDinaHora!.masaDayStartUtc}-এ শুরু হওয়া জ্যোতিষীয় দিনের অধিপতি ${_planetNamesBn[varshaMasaDinaHora!.masaLord!]}। BPHS 27.13 অনুযায়ী মাসেশ ৩০ বিরূপ পায়।',
      ),
    if (dina != null)
      ChartEvidence(
        ruleId: '$_shadbalaRuleVersion.dina.$planet',
        outputPath: r'$.metadata.dinaLord',
        kind: EvidenceKind.strength,
        descriptionEn:
            '$planetEn Dina Bala = ${_fmt(dina)} virupas; the sunrise-to-sunrise astrological weekday starts at ${varshaMasaDinaHora!.astrologicalDayStartUtc} and is ruled by ${_planetNamesEn[varshaMasaDinaHora!.dinaLord!]}. BPHS 27.13 assigns 45 virupas to the day lord.',
        descriptionBn:
            '$planetBn-এর দিনবল = ${_fmt(dina)} বিরূপ; sunrise-to-sunrise জ্যোতিষীয় দিন ${varshaMasaDinaHora!.astrologicalDayStartUtc}-এ শুরু হয়েছে এবং এর অধিপতি ${_planetNamesBn[varshaMasaDinaHora!.dinaLord!]}। BPHS 27.13 অনুযায়ী দিনেশ ৪৫ বিরূপ পায়।',
      ),
    if (hora != null)
      ChartEvidence(
        ruleId: '$_shadbalaRuleVersion.hora.$planet',
        outputPath: r'$.metadata.horaLord',
        kind: EvidenceKind.strength,
        descriptionEn:
            '$planetEn Hora Bala = ${_fmt(hora)} virupas; hora ${varshaMasaDinaHora!.horaNumber} (${varshaMasaDinaHora!.horaPeriod}) is ruled by ${_planetNamesEn[varshaMasaDinaHora!.horaLord!]} using 12 equal daylight horas plus 12 equal night horas and the Saturn-Jupiter-Mars-Sun-Venus-Mercury-Moon cycle. BPHS 27.13 assigns 60 virupas to the Hora lord.',
        descriptionBn:
            '$planetBn-এর হোরাবল = ${_fmt(hora)} বিরূপ; daylight-এর ১২ ও night-এর ১২ সমান seasonal hora এবং শনি-বৃহস্পতি-মঙ্গল-সূর্য-শুক্র-বুধ-চন্দ্র ক্রমে ${varshaMasaDinaHora!.horaNumber} নম্বর (${varshaMasaDinaHora!.horaPeriod}) hora-এর অধিপতি ${_planetNamesBn[varshaMasaDinaHora!.horaLord!]}। BPHS 27.13 অনুযায়ী হোরেশ ৬০ বিরূপ পায়।',
      ),
    ChartEvidence(
      ruleId: '$_shadbalaRuleVersion.yuddha.$planet',
      outputPath: yuddha.outputPath,
      kind: EvidenceKind.strength,
      descriptionEn: yuddha.descriptionEn,
      descriptionBn: yuddha.descriptionBn,
    ),
    ChartEvidence(
      ruleId: '$_shadbalaRuleVersion.ayana.$planet',
      outputPath: r'$.planets[?(@.body=="' + planet + r'")].tropicalLongitude',
      kind: EvidenceKind.strength,
      descriptionEn:
          '$planetEn Ayana Bala = ${_fmt(ayana)} virupas from tropical longitude ${_fmt(position.tropicalLongitude)}° using the governed BPHS 27.15-17 45/33/12 khanda method.',
      descriptionBn:
          'BPHS 27.15-17-এর governed 45/33/12 খণ্ড পদ্ধতিতে tropical longitude ${_fmt(position.tropicalLongitude)}° থেকে $planetBn-এর অয়নবল = ${_fmt(ayana)} বিরূপ।',
    ),
    ChartEvidence(
      ruleId: '$_shadbalaRuleVersion.cheshta.$planet',
      outputPath: cheshta.outputPath,
      kind: EvidenceKind.strength,
      descriptionEn: cheshta.descriptionEn,
      descriptionBn: cheshta.descriptionBn,
    ),
    ChartEvidence(
      ruleId: '$_shadbalaRuleVersion.drik.$planet',
      outputPath: r'$.planets',
      kind: EvidenceKind.strength,
      descriptionEn:
          '$planetEn Drik Bala = ${_fmt(drik.virupas)} virupas from ${drik.contributions.length} non-zero received Sphuta-Drishti contributions under the governed BPHS Chapter-26/27 profile. Benefic/malefic quarter-weighting and the full Mercury/Jupiter super-addition are stored contribution by contribution.',
      descriptionBn:
          'governed BPHS অধ্যায় ২৬/২৭ profile-এ ${drik.contributions.length}টি non-zero প্রাপ্ত Sphuta-Drishti contribution থেকে $planetBn-এর দৃকবল = ${_fmt(drik.virupas)} বিরূপ। শুভ/অশুভ এক-চতুর্থাংশ weighting এবং বুধ/বৃহস্পতির full super-addition প্রতিটি contribution-এ আলাদা করে সংরক্ষিত।',
    ),
    ChartEvidence(
      ruleId: '$_shadbalaRuleVersion.naisargika.$planet',
      outputPath: r'$.planets[?(@.body=="' + planet + r'")].body',
      kind: EvidenceKind.strength,
      descriptionEn:
          '$planetEn Naisargika Bala = ${_fmt(naisargika)} virupas under the fixed seven-planet natural-strength scale.',
      descriptionBn:
          'সাতটি ধ্রুপদি গ্রহের স্থির স্বাভাবিক-বল স্কেলে $planetBn-এর নৈসর্গিক বল = ${_fmt(naisargika)} বিরূপ।',
    ),
    ChartEvidence(
      ruleId: '$_shadbalaRuleVersion.aggregateThreshold.$planet',
      outputPath: r'$.planets[?(@.body=="' + planet + r'")].body',
      kind: EvidenceKind.strength,
      descriptionEn: totalShadbala == null
          ? '$planetEn sixfold Shadbala aggregate is unavailable because one or more governed strength families are incomplete; the BPHS 27.32-33 requirement remains ${_fmt(requiredShadbala)} virupas (${_fmt(requiredShadbalaRupas)} rupas).'
          : '$planetEn total Shadbala = ${_fmt(totalShadbala)} virupas (${_fmt(totalShadbalaRupas!)} rupas) from Sthana + Dig + Kala + Cheshta + Naisargika + Drik. BPHS 27.32-33 required strength = ${_fmt(requiredShadbala)} virupas (${_fmt(requiredShadbalaRupas)} rupas), ratio = ${_fmt(requiredStrengthRatio!)}.',
      descriptionBn: totalShadbala == null
          ? '$planetBn-এর পূর্ণ ছয়-অংশের ষড়বল aggregate unavailable, কারণ এক বা একাধিক governed strength family অসম্পূর্ণ; BPHS 27.32-33 অনুযায়ী প্রয়োজনীয় বল ${_fmt(requiredShadbala)} বিরূপ (${_fmt(requiredShadbalaRupas)} রূপ)।'
          : '$planetBn-এর মোট ষড়বল = ${_fmt(totalShadbala)} বিরূপ (${_fmt(totalShadbalaRupas!)} রূপ), অর্থাৎ স্থান + দিক + কাল + চেষ্টা + নৈসর্গিক + দৃকবল। BPHS 27.32-33 অনুযায়ী প্রয়োজনীয় বল ${_fmt(requiredShadbala)} বিরূপ (${_fmt(requiredShadbalaRupas)} রূপ), ratio = ${_fmt(requiredStrengthRatio!)}।',
    ),
  ];

  return ShadbalaPlanetProfile(
    code: 'vedic.shadbala.$planet',
    ruleVersion: _shadbalaRuleVersion,
    planet: planet,
    ucchaBalaVirupas: uccha,
    saptavargajaBalaVirupas: saptavargaja,
    ojayugmaBalaVirupas: ojayugma,
    kendradiBalaVirupas: kendradi,
    drekkanaBalaVirupas: drekkana,
    sthanaBalaVirupas: sthana,
    digBalaVirupas: dig,
    nathonnataBalaVirupas: nathonnata,
    sunHourAngleHours: sunHourAngleHours,
    tribhagaBalaVirupas: tribhagaBala,
    tribhagaPeriod: tribhaga?.period,
    tribhagaThird: tribhaga?.third,
    tribhagaPeriodStartUtc: tribhaga?.startUtc,
    tribhagaPeriodEndUtc: tribhaga?.endUtc,
    pakshaBalaVirupas: paksha,
    varshaBalaVirupas: varsha,
    masaBalaVirupas: masa,
    dinaBalaVirupas: dina,
    horaBalaVirupas: hora,
    varshaLord: varshaMasaDinaHora?.varshaLord,
    masaLord: varshaMasaDinaHora?.masaLord,
    dinaLord: varshaMasaDinaHora?.dinaLord,
    horaLord: varshaMasaDinaHora?.horaLord,
    horaNumber: varshaMasaDinaHora?.horaNumber,
    varshaMasaDinaHoraProfile: varshaMasaDinaHora?.profile,
    ayanaBalaVirupas: ayana,
    yuddhaBalaVirupas: yuddha.virupas,
    yuddhaProfile: yuddha.profile,
    yuddhaRole: yuddha.role,
    yuddhaWarPartner: yuddha.partner,
    yuddhaSeparationDegrees: yuddha.separationDegrees,
    yuddhaLatitudeDegrees: yuddha.latitudeDegrees,
    yuddhaPartnerLatitudeDegrees: yuddha.partnerLatitudeDegrees,
    yuddhaPreWarStrengthDifferenceVirupas: yuddha.preWarStrengthDifference,
    kalaBalaPartialVirupas: kalaPartial,
    kalaBalaVirupas: kalaTotal,
    kalaComputedSubcomponents: List.unmodifiable(kalaComputed),
    kalaMissingSubcomponents: List.unmodifiable(kalaMissing),
    kalaBalaComplete: kalaComplete,
    cheshtaBalaVirupas: cheshta.virupas,
    cheshtaMethod: cheshta.method,
    cheshtaMotionState: cheshta.motionState,
    longitudeSpeedPerDay: position.longitudeSpeedPerDay,
    naisargikaBalaVirupas: naisargika,
    drikBalaVirupas: drik.virupas,
    drikProfile: 'bphsSphutaDrishtiDrikV1',
    drikContributions: drik.contributions,
    vargaContributions: vargaContributions,
    computedComponents: [
      'sthana',
      'dig',
      kalaComplete ? 'kala' : 'kalaPartial',
      if (cheshta.virupas != null) 'cheshta',
      'naisargika',
      'drik',
      if (aggregateAvailable) 'aggregateThresholdEvaluation',
    ],
    missingComponents: [
      if (!kalaComplete) 'kalaRemaining',
      if (cheshta.virupas == null) 'cheshta',
      if (!aggregateAvailable) 'aggregateThresholdEvaluation',
    ],
    aggregateAvailable: aggregateAvailable,
    totalShadbalaVirupas: totalShadbala,
    totalShadbalaRupas: totalShadbalaRupas,
    requiredShadbalaVirupas: requiredShadbala,
    requiredShadbalaRupas: requiredShadbalaRupas,
    requiredStrengthRatio: requiredStrengthRatio,
    surplusDeficitVirupas: surplusDeficit,
    thresholdStatus: thresholdStatus,
    thresholdProfile: 'bphs27_32_33RequiredTotalV1',
    narrativeEn:
        '$planetEn has governed Sthana Bala ${_fmt(sthana)} virupas, Dig Bala ${_fmt(dig)} virupas${nathonnata == null ? '' : ', Nathonnata Bala ${_fmt(nathonnata)} virupas'}, Paksha Bala ${_fmt(paksha)} virupas${tribhagaBala == null ? '' : ', Tribhaga Bala ${_fmt(tribhagaBala)} virupas'}${varsha == null ? '' : ', Varsha Bala ${_fmt(varsha)} virupas'}${masa == null ? '' : ', Masa Bala ${_fmt(masa)} virupas'}${dina == null ? '' : ', Dina Bala ${_fmt(dina)} virupas'}${hora == null ? '' : ', Hora Bala ${_fmt(hora)} virupas'}, Ayana Bala ${_fmt(ayana)} virupas${cheshta.virupas == null ? '' : ', Cheshta Bala ${_fmt(cheshta.virupas!)} virupas'}, Naisargika Bala ${_fmt(naisargika)} virupas and Drik Bala ${_fmt(drik.virupas)} virupas in Shadbala foundation v10. The pre-war Kala subtotal is ${_fmt(kalaPartial)} virupas; ${kalaComplete ? 'complete Kala after Yuddha is ${_fmt(kalaTotal!)} virupas' : 'remaining unavailable Kala items are ${kalaMissing.join(', ')}'}. ${cheshta.governanceEn} ${aggregateAvailable ? 'The sixfold total is ${_fmt(totalShadbala!)} virupas (${_fmt(totalShadbalaRupas!)} rupas) against the BPHS 27.32-33 requirement ${_fmt(requiredShadbala)} virupas; ratio ${_fmt(requiredStrengthRatio!)} and status $thresholdStatus. This is strength sufficiency only, not automatic beneficence or event success.' : 'The sixfold total and threshold status remain unavailable until every governed strength family is present.'}',
    narrativeBn:
        'ষড়বল foundation v10-এ $planetBn-এর governed স্থানবল ${_fmt(sthana)} বিরূপ, দিকবল ${_fmt(dig)} বিরূপ${nathonnata == null ? '' : ', নতোন্নত বল ${_fmt(nathonnata)} বিরূপ'}, পক্ষবল ${_fmt(paksha)} বিরূপ${tribhagaBala == null ? '' : ', ত্রিভাগ বল ${_fmt(tribhagaBala)} বিরূপ'}${varsha == null ? '' : ', বর্ষবল ${_fmt(varsha)} বিরূপ'}${masa == null ? '' : ', মাসবল ${_fmt(masa)} বিরূপ'}${dina == null ? '' : ', দিনবল ${_fmt(dina)} বিরূপ'}${hora == null ? '' : ', হোরাবল ${_fmt(hora)} বিরূপ'}, অয়নবল ${_fmt(ayana)} বিরূপ${cheshta.virupas == null ? '' : ', চেষ্টাবল ${_fmt(cheshta.virupas!)} বিরূপ'}, নৈসর্গিক বল ${_fmt(naisargika)} বিরূপ এবং দৃকবল ${_fmt(drik.virupas)} বিরূপ। যুদ্ধ-পূর্ব কালবল subtotal ${_fmt(kalaPartial)} বিরূপ; ${kalaComplete ? 'যুদ্ধবল-পরবর্তী পূর্ণ কালবল ${_fmt(kalaTotal!)} বিরূপ' : 'অনুপলব্ধ কালবল অংশ: ${kalaMissing.join(', ')}'}। ${cheshta.governanceBn} ${aggregateAvailable ? 'পূর্ণ ছয়-অংশের মোট বল ${_fmt(totalShadbala!)} বিরূপ (${_fmt(totalShadbalaRupas!)} রূপ), BPHS 27.32-33 প্রয়োজন ${_fmt(requiredShadbala)} বিরূপ; ratio ${_fmt(requiredStrengthRatio!)} এবং status $thresholdStatus। এটি শুধু strength sufficiency, স্বয়ংক্রিয় শুভতা বা নিশ্চিত ঘটনার ফল নয়।' : 'সব governed strength family না পাওয়া পর্যন্ত পূর্ণ total ও threshold status unavailable থাকবে।'}',
    evidence: evidence,
  );
}


double? _preWarShadbala(
  String planet,
  _Planet position,
  int ascendantSign,
  double ascendantLongitude,
  Map<String, _Planet> planets,
  double? sunHourAngleHours,
  _TribhagaContext? tribhaga,
  _VarshaMasaDinaHoraContext? varshaMasaDinaHora,
) {
  final uccha = _ucchaBala(planet, position.siderealLongitude);
  final saptavargaja = _saptavargajaContributions(
    planet,
    position,
    planets,
  ).fold<double>(0, (sum, value) => sum + value.virupas);
  final ojayugma = _ojayugmaBala(
    planet,
    position.signIndex,
    position.navamsaSignIndex,
  );
  final house = ((position.signIndex - ascendantSign + 12) % 12) + 1;
  final sthana = uccha +
      saptavargaja +
      ojayugma +
      _kendradiBala(house) +
      _drekkanaBala(planet, position.degreeInSign);
  final dig = _digBala(
    planet,
    position.siderealLongitude,
    ascendantLongitude,
  );
  final nathonnata = sunHourAngleHours == null
      ? null
      : _nathonnataBala(planet, sunHourAngleHours);
  final tribhagaBala = tribhaga == null
      ? null
      : _tribhagaBala(planet, tribhaga.isDay, tribhaga.third);
  final paksha = _pakshaBala(
    planet,
    planets['sun']!.siderealLongitude,
    planets['moon']!.siderealLongitude,
  );
  final varsha = _lordBala(planet, varshaMasaDinaHora?.varshaLord, 15.0);
  final masa = _lordBala(planet, varshaMasaDinaHora?.masaLord, 30.0);
  final dina = _lordBala(planet, varshaMasaDinaHora?.dinaLord, 45.0);
  final hora = _lordBala(planet, varshaMasaDinaHora?.horaLord, 60.0);
  final ayana = _ayanaBala(planet, position.tropicalLongitude);
  if (nathonnata == null ||
      tribhagaBala == null ||
      varsha == null ||
      masa == null ||
      dina == null ||
      hora == null) {
    return null;
  }
  final cheshta = _cheshtaBala(
    planet,
    position,
    ayanaBala: ayana,
    pakshaBala: paksha,
  ).virupas;
  if (cheshta == null) return null;
  final kalaBeforeYuddha = nathonnata +
      paksha +
      tribhagaBala +
      varsha +
      masa +
      dina +
      hora +
      ayana;
  return sthana +
      dig +
      kalaBeforeYuddha +
      cheshta +
      _naisargikaBala[planet]! +
      _drikBala(planet, position, planets).virupas;
}

Map<String, _YuddhaResult> _yuddhaResults(
  Map<String, _Planet> planets,
  Map<String, double?> preWarStrengths, {
  required bool latitudeEvidenceAvailable,
}) {
  final results = <String, _YuddhaResult>{};
  for (final planet in _classicalPlanets) {
    if (!_planetaryWarBodies.contains(planet)) {
      results[planet] = _YuddhaResult.noWar(
        role: 'notEligible',
        descriptionEn:
            '${_planetNamesEn[planet]} does not participate in the five-planet Yuddha Bala war set (Mars through Saturn), so its Yuddha correction is 0 virupas.',
        descriptionBn:
            '${_planetNamesBn[planet]} মঙ্গল-থেকে-শনি পাঁচটি তারাগ্রহের যুদ্ধবল সেটে অংশ নেয় না; তাই এর যুদ্ধবল correction 0 বিরূপ।',
      );
    } else if (!latitudeEvidenceAvailable) {
      results[planet] = _YuddhaResult.unavailable(
        role: 'legacyOutputWithoutLatitude',
        descriptionEn:
            '${_planetNamesEn[planet]} Yuddha Bala is unavailable because this legacy chart snapshot does not persist geocentric ecliptic latitude.',
        descriptionBn:
            'এই legacy chart snapshot-এ geocentric ecliptic latitude সংরক্ষিত নেই, তাই ${_planetNamesBn[planet]}-এর যুদ্ধবল unavailable।',
      );
    }
  }
  if (!latitudeEvidenceAvailable) return results;

  final partners = <String, List<String>>{
    for (final planet in _planetaryWarBodies) planet: <String>[],
  };
  final separationByPair = <String, double>{};
  for (var i = 0; i < _planetaryWarBodies.length; i += 1) {
    for (var j = i + 1; j < _planetaryWarBodies.length; j += 1) {
      final first = _planetaryWarBodies[i];
      final second = _planetaryWarBodies[j];
      final a = planets[first]!;
      final b = planets[second]!;
      if (a.signIndex != b.signIndex) continue;
      final separation = (a.siderealLongitude - b.siderealLongitude).abs();
      if (separation > _planetaryWarThresholdDegrees) continue;
      partners[first]!.add(second);
      partners[second]!.add(first);
      separationByPair[_pairKey(first, second)] = separation;
    }
  }

  for (final planet in _planetaryWarBodies) {
    final ownPartners = partners[planet]!;
    if (ownPartners.isEmpty) {
      results[planet] = _YuddhaResult.noWar(
        role: 'noWar',
        latitudeDegrees: planets[planet]!.eclipticLatitude,
        descriptionEn:
            '${_planetNamesEn[planet]} has no same-sign Mars-through-Saturn partner within ${_fmt(_planetaryWarThresholdDegrees)}°, so Yuddha Bala correction is 0 virupas.',
        descriptionBn:
            '${_planetNamesBn[planet]}-এর একই রাশিতে মঙ্গল-থেকে-শনি সেটের কোনো গ্রহ ${_fmt(_planetaryWarThresholdDegrees)}°-এর মধ্যে নেই; তাই যুদ্ধবল correction 0 বিরূপ।',
      );
      continue;
    }
    if (ownPartners.length > 1) {
      results[planet] = _YuddhaResult.unavailable(
        role: 'ambiguousMultiplePartners',
        latitudeDegrees: planets[planet]!.eclipticLatitude,
        descriptionEn:
            '${_planetNamesEn[planet]} is within the Yuddha threshold of multiple eligible planets (${ownPartners.map((p) => _planetNamesEn[p]).join(', ')}). The v1 pairwise correction is withheld rather than imposing an arbitrary war order.',
        descriptionBn:
            '${_planetNamesBn[planet]} একাধিক যোগ্য গ্রহের (${ownPartners.map((p) => _planetNamesBn[p]).join(', ')}) সঙ্গে যুদ্ধসীমার মধ্যে আছে। v1-এ ইচ্ছামতো যুদ্ধের ক্রম বসানো হচ্ছে না, তাই pairwise correction withheld।',
      );
    }
  }

  final processed = <String>{};
  for (final first in _planetaryWarBodies) {
    final firstPartners = partners[first]!;
    if (firstPartners.length != 1) continue;
    final second = firstPartners.single;
    if (partners[second]!.length != 1) continue;
    final key = _pairKey(first, second);
    if (!processed.add(key)) continue;
    final a = planets[first]!;
    final b = planets[second]!;
    final separation = separationByPair[key]!;
    final latA = a.eclipticLatitude!;
    final latB = b.eclipticLatitude!;
    if ((latA - latB).abs() <= _latitudeTieToleranceDegrees) {
      final en =
          '${_planetNamesEn[first]} and ${_planetNamesEn[second]} are in a qualifying war at ${_fmt(separation)}° separation, but their ecliptic latitudes tie within the v1 tolerance. No victor or Yuddha correction is fabricated.';
      final bn =
          '${_planetNamesBn[first]} ও ${_planetNamesBn[second]} ${_fmt(separation)}° দূরত্বে যোগ্য গ্রহযুদ্ধে আছে, কিন্তু v1 tolerance-এর মধ্যে তাদের ecliptic latitude সমান। তাই বিজয়ী বা যুদ্ধবল correction বানিয়ে দেওয়া হচ্ছে না।';
      results[first] = _YuddhaResult.unavailable(
        role: 'latitudeTie',
        partner: second,
        separationDegrees: separation,
        latitudeDegrees: latA,
        partnerLatitudeDegrees: latB,
        descriptionEn: en,
        descriptionBn: bn,
      );
      results[second] = _YuddhaResult.unavailable(
        role: 'latitudeTie',
        partner: first,
        separationDegrees: separation,
        latitudeDegrees: latB,
        partnerLatitudeDegrees: latA,
        descriptionEn: en,
        descriptionBn: bn,
      );
      continue;
    }
    final totalA = preWarStrengths[first];
    final totalB = preWarStrengths[second];
    if (totalA == null || totalB == null) {
      final en =
          '${_planetNamesEn[first]} and ${_planetNamesEn[second]} form a qualifying war, but the pre-war sixfold subtotal needed by BPHS 27.20 is incomplete for at least one participant. Yuddha correction stays unavailable.';
      final bn =
          '${_planetNamesBn[first]} ও ${_planetNamesBn[second]} যোগ্য গ্রহযুদ্ধে আছে, কিন্তু BPHS 27.20-এর জন্য প্রয়োজনীয় যুদ্ধ-পূর্ব ছয়বল subtotal অন্তত একটি গ্রহের ক্ষেত্রে অসম্পূর্ণ। তাই যুদ্ধবল correction unavailable।';
      results[first] = _YuddhaResult.unavailable(
        role: 'preWarStrengthUnavailable',
        partner: second,
        separationDegrees: separation,
        latitudeDegrees: latA,
        partnerLatitudeDegrees: latB,
        descriptionEn: en,
        descriptionBn: bn,
      );
      results[second] = _YuddhaResult.unavailable(
        role: 'preWarStrengthUnavailable',
        partner: first,
        separationDegrees: separation,
        latitudeDegrees: latB,
        partnerLatitudeDegrees: latA,
        descriptionEn: en,
        descriptionBn: bn,
      );
      continue;
    }
    final winner = latA > latB ? first : second;
    final loser = winner == first ? second : first;
    final difference = (totalA - totalB).abs();
    final winnerLat = planets[winner]!.eclipticLatitude!;
    final loserLat = planets[loser]!.eclipticLatitude!;
    results[winner] = _YuddhaResult.computed(
      virupas: difference,
      role: 'winner',
      partner: loser,
      separationDegrees: separation,
      latitudeDegrees: winnerLat,
      partnerLatitudeDegrees: loserLat,
      preWarStrengthDifference: difference,
      descriptionEn:
          '${_planetNamesEn[winner]} wins the v1 computational planetary war against ${_planetNamesEn[loser]}: same-sign separation ${_fmt(separation)}°, ecliptic latitudes ${_fmt(winnerLat)}° vs ${_fmt(loserLat)}°. BPHS 27.20 adds the pre-war Shadbala difference ${_fmt(difference)} virupas to the victor.',
      descriptionBn:
          '${_planetNamesBn[winner]} v1 computational গ্রহযুদ্ধে ${_planetNamesBn[loser]}-কে অতিক্রম করেছে: একই-রাশির দূরত্ব ${_fmt(separation)}°, ecliptic latitude ${_fmt(winnerLat)}° বনাম ${_fmt(loserLat)}°। BPHS 27.20 অনুযায়ী যুদ্ধ-পূর্ব ষড়বলের পার্থক্য ${_fmt(difference)} বিরূপ বিজয়ীর বলে যোগ হয়েছে।',
    );
    results[loser] = _YuddhaResult.computed(
      virupas: -difference,
      role: 'loser',
      partner: winner,
      separationDegrees: separation,
      latitudeDegrees: loserLat,
      partnerLatitudeDegrees: winnerLat,
      preWarStrengthDifference: difference,
      descriptionEn:
          '${_planetNamesEn[loser]} loses the v1 computational planetary war to ${_planetNamesEn[winner]}: same-sign separation ${_fmt(separation)}°, ecliptic latitudes ${_fmt(loserLat)}° vs ${_fmt(winnerLat)}°. BPHS 27.20 deducts the pre-war Shadbala difference ${_fmt(difference)} virupas from the vanquished.',
      descriptionBn:
          '${_planetNamesBn[loser]} v1 computational গ্রহযুদ্ধে ${_planetNamesBn[winner]}-এর কাছে পরাজিত: একই-রাশির দূরত্ব ${_fmt(separation)}°, ecliptic latitude ${_fmt(loserLat)}° বনাম ${_fmt(winnerLat)}°। BPHS 27.20 অনুযায়ী যুদ্ধ-পূর্ব ষড়বলের পার্থক্য ${_fmt(difference)} বিরূপ পরাজিত গ্রহের বল থেকে বিয়োগ হয়েছে।',
    );
  }
  return results;
}

String _pairKey(String first, String second) =>
    first.compareTo(second) < 0 ? '$first|$second' : '$second|$first';
