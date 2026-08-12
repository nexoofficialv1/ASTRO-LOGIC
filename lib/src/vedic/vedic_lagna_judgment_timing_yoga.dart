part of 'vedic_lagna_judgment_engine.dart';

List<AnalysisTimingWindow> _buildVimshottariTimingWindows(
  int ascendantSign,
  Map<String, _ChartPlanet> planets,
  Object? rawVimshottari, {
  required bool required,
  required bool requirePratyantardasha,
}) {
  if (rawVimshottari == null) {
    if (required) {
      throw StateError('Current Vedic chart requires Vimshottari output');
    }
    return const [];
  }
  final vimshottari = _requiredMap(rawVimshottari, 'vimshottari');
  final calendarVersion = vimshottari['ruleVersion'];
  if (calendarVersion != 'vimshottari-calendar-v1' &&
      calendarVersion != 'vimshottari-calendar-v2') {
    throw StateError('Unsupported Vimshottari rule version');
  }
  if (requirePratyantardasha &&
      calendarVersion != 'vimshottari-calendar-v2') {
    throw StateError('vedic-chart-v4 through v7 requires Pratyantardasha output');
  }
  final birthUtc = _requiredUtcDate(
    vimshottari['birthUtc'],
    'vimshottari.birthUtc',
  );
  final rawMahadashas = vimshottari['mahadashas'];
  if (rawMahadashas is! List || rawMahadashas.length != 9) {
    throw StateError('Vimshottari output requires nine Mahadashas');
  }
  final firstMahadasha = _requiredMap(
    rawMahadashas.first,
    'vimshottari.mahadashas[0]',
  );
  final firstLord = _requiredDashaLord(
    firstMahadasha['lord'],
    'vimshottari.mahadashas[0].lord',
  );
  final firstSequenceIndex = _vimshottariSequence.indexOf(firstLord);
  final windows = <AnalysisTimingWindow>[];
  DateTime? previousMahaEnd;

  for (var mahaIndex = 0;
      mahaIndex < rawMahadashas.length;
      mahaIndex += 1) {
    final mahaPath = 'vimshottari.mahadashas[$mahaIndex]';
    final maha = _requiredMap(rawMahadashas[mahaIndex], mahaPath);
    final mahaLord = _requiredDashaLord(maha['lord'], '$mahaPath.lord');
    final expectedMahaLord = _vimshottariSequence[
        (firstSequenceIndex + mahaIndex) % _vimshottariSequence.length];
    if (mahaLord != expectedMahaLord) {
      throw StateError('Vimshottari Mahadasha sequence is inconsistent');
    }
    final mahaStart = _requiredUtcDate(maha['startUtc'], '$mahaPath.startUtc');
    final mahaEnd = _requiredUtcDate(maha['endUtc'], '$mahaPath.endUtc');
    if (!mahaEnd.isAfter(mahaStart) ||
        (previousMahaEnd != null && mahaStart != previousMahaEnd)) {
      throw StateError('Vimshottari Mahadasha boundaries are inconsistent');
    }
    previousMahaEnd = mahaEnd;
    final rawAntardashas = maha['antardashas'];
    if (rawAntardashas is! List || rawAntardashas.length != 9) {
      throw StateError('Each Mahadasha requires nine Antardashas');
    }
    final mahaActivation = _dashaActivation(
      ascendantSign,
      planets,
      mahaLord,
    );
    final mahaSequenceIndex = _vimshottariSequence.indexOf(mahaLord);
    DateTime? previousAntarEnd;

    for (var antarIndex = 0;
        antarIndex < rawAntardashas.length;
        antarIndex += 1) {
      final antarPath = '$mahaPath.antardashas[$antarIndex]';
      final antar = _requiredMap(rawAntardashas[antarIndex], antarPath);
      final recordedMahaLord = _requiredDashaLord(
        antar['mahadashaLord'],
        '$antarPath.mahadashaLord',
      );
      final antarLord = _requiredDashaLord(
        antar['antardashaLord'],
        '$antarPath.antardashaLord',
      );
      final expectedAntarLord = _vimshottariSequence[
        (mahaSequenceIndex + antarIndex) % _vimshottariSequence.length
      ];
      if (recordedMahaLord != mahaLord ||
          antarLord != expectedAntarLord) {
        throw StateError('Vimshottari Antardasha sequence is inconsistent');
      }
      final start = _requiredUtcDate(antar['startUtc'], '$antarPath.startUtc');
      final end = _requiredUtcDate(antar['endUtc'], '$antarPath.endUtc');
      if (!end.isAfter(start) ||
          (previousAntarEnd != null && start != previousAntarEnd) ||
          (antarIndex == 0 && start != mahaStart) ||
          (antarIndex == rawAntardashas.length - 1 && end != mahaEnd)) {
        throw StateError('Vimshottari Antardasha boundaries are inconsistent');
      }
      previousAntarEnd = end;
      if (calendarVersion == 'vimshottari-calendar-v2') {
        _validatePratyantardashas(
          antar['pratyantardashas'],
          path: '$antarPath.pratyantardashas',
          mahaLord: mahaLord,
          antarLord: antarLord,
          antarStart: start,
          antarEnd: end,
        );
      }
      if (!end.isAfter(birthUtc)) continue;

      final antarActivation = _dashaActivation(
        ascendantSign,
        planets,
        antarLord,
      );
      final contradiction = mahaActivation.internalConflict ||
          antarActivation.internalConflict ||
          (mahaActivation.score != 0 &&
              antarActivation.score != 0 &&
              mahaActivation.score.sign != antarActivation.score.sign);
      final combinedScore = mahaActivation.score + antarActivation.score;
      final polarity = contradiction
          ? AnalysisPolarity.mixed
          : _polarity(combinedScore);
      final mahaEn = _displayPlanetNameEn(mahaLord);
      final mahaBn = _displayPlanetNameBn(mahaLord);
      final antarEn = _displayPlanetNameEn(antarLord);
      final antarBn = _displayPlanetNameBn(antarLord);
      final evidence = <ChartEvidence>[
        ChartEvidence(
          ruleId: 'vedic.dasha.vimshottari.calendar.v1',
          outputPath: r'$.' + antarPath,
          kind: EvidenceKind.dasha,
          descriptionEn:
              '$mahaEn Mahadasha and $antarEn Antardasha define this exact calendar window.',
          descriptionBn:
              '$mahaBn মহাদশা ও $antarBn অন্তর্দশা এই নির্দিষ্ট সময়সীমা নির্ধারণ করেছে।',
        ),
        ...mahaActivation.evidence,
        if (antarLord != mahaLord) ...antarActivation.evidence,
      ];
      final contradictionEn = contradiction
          ? ' The two lords point in opposite directions, so the result remains Mixed.'
          : '';
      final contradictionBn = contradiction
          ? ' দুই দশাপতি বিপরীত দিকে ইঙ্গিত করায় ফল Mixed রাখা হয়েছে।'
          : '';
      windows.add(
        AnalysisTimingWindow(
          code: 'vedic.dasha.vimshottari.$mahaLord.$antarLord.$mahaIndex.$antarIndex',
          area: LifeArea.overall,
          start: start,
          end: end,
          polarity: polarity,
          confidence: AnalysisConfidence.medium,
          narrativeEn:
              '$mahaEn Mahadasha / $antarEn Antardasha has a transparent activation score of $combinedScore (Mahadasha ${mahaActivation.score}, Antardasha ${antarActivation.score}). ${mahaActivation.summaryEn} ${antarActivation.summaryEn}$contradictionEn This is a broad activation tendency, not a promised event; transits, Pratyantardasha and the consultation question must be reviewed.',
          narrativeBn:
              '$mahaBn মহাদশা / $antarBn অন্তর্দশার স্বচ্ছ activation score $combinedScore (মহাদশা ${mahaActivation.score}, অন্তর্দশা ${antarActivation.score})। ${mahaActivation.summaryBn} ${antarActivation.summaryBn}$contradictionBn এটি সামগ্রিক সক্রিয়তার প্রবণতা, নিশ্চিত ঘটনা নয়; গোচর, প্রত্যন্তরদশা ও পরামর্শের নির্দিষ্ট প্রশ্ন যাচাই করতে হবে।',
          evidence: evidence,
        ),
      );
    }
  }
  return windows;
}

List<DashaActivationProfile> _buildDashaActivationProfiles(
  int ascendantSign,
  Map<String, _ChartPlanet> planets,
) =>
    _vimshottariSequence.map((lord) {
      final activation = _dashaActivation(ascendantSign, planets, lord);
      return DashaActivationProfile(
        lord: lord,
        score: activation.score,
        polarity: activation.internalConflict
            ? AnalysisPolarity.mixed
            : _polarity(activation.score),
        lifeAreas: activation.lifeAreas,
        summaryEn: activation.summaryEn,
        summaryBn: activation.summaryBn,
        evidence: activation.evidence,
      );
    }).toList(growable: false);

void _validatePratyantardashas(
  Object? rawPeriods, {
  required String path,
  required String mahaLord,
  required String antarLord,
  required DateTime antarStart,
  required DateTime antarEnd,
}) {
  if (rawPeriods is! List || rawPeriods.length != 9) {
    throw StateError('Each Antardasha requires nine Pratyantardashas');
  }
  final sequenceIndex = _vimshottariSequence.indexOf(antarLord);
  DateTime? previousEnd;
  for (var index = 0; index < rawPeriods.length; index += 1) {
    final periodPath = '$path[$index]';
    final period = _requiredMap(rawPeriods[index], periodPath);
    final recordedMaha = _requiredDashaLord(
      period['mahadashaLord'],
      '$periodPath.mahadashaLord',
    );
    final recordedAntar = _requiredDashaLord(
      period['antardashaLord'],
      '$periodPath.antardashaLord',
    );
    final pratyantarLord = _requiredDashaLord(
      period['pratyantardashaLord'],
      '$periodPath.pratyantardashaLord',
    );
    final expectedLord = _vimshottariSequence[
      (sequenceIndex + index) % _vimshottariSequence.length
    ];
    final start = _requiredUtcDate(
      period['startUtc'],
      '$periodPath.startUtc',
    );
    final end = _requiredUtcDate(period['endUtc'], '$periodPath.endUtc');
    if (recordedMaha != mahaLord ||
        recordedAntar != antarLord ||
        pratyantarLord != expectedLord ||
        !end.isAfter(start) ||
        (previousEnd != null && start != previousEnd) ||
        (index == 0 && start != antarStart) ||
        (index == rawPeriods.length - 1 && end != antarEnd)) {
      throw StateError('Vimshottari Pratyantardasha is inconsistent');
    }
    previousEnd = end;
  }
}

_DashaActivation _dashaActivation(
  int ascendantSign,
  Map<String, _ChartPlanet> planets,
  String lord,
) {
  final position = planets[lord];
  if (position == null) {
    throw StateError('Vimshottari output requires planet $lord');
  }
  final house = _houseOf(ascendantSign, position);
  final placement = _placementScore(house);
  final lordEn = _displayPlanetNameEn(lord);
  final lordBn = _displayPlanetNameBn(lord);
  if (_planetNamesEn.containsKey(lord)) {
    final d1 = _dignityScore(_dignity(lord, position.signIndex));
    final d9 = _dignityScore(_dignity(lord, position.navamsaSignIndex));
    final role = _functionalRole(ascendantSign, lord);
    final functional = role.score;
    final score = placement + d1 + d9 + functional;
    return _DashaActivation(
      score: score,
      internalConflict: false,
      lifeAreas: _lifeAreasForHouses([house, ...role.ownedHouses]),
      summaryEn:
          '$lordEn contributes house $house ($placement), D1 dignity ($d1), D9 dignity ($d9) and functional ownership ($functional).',
      summaryBn:
          '$lordBn ভাব $house ($placement), D1 মর্যাদা ($d1), D9 মর্যাদা ($d9) ও কার্যকর অধিপত্য ($functional) যোগ করেছে।',
      evidence: [
        ChartEvidence(
          ruleId: 'vedic.dasha.classical_lord.activation.v1.$lord',
          outputPath: r'$.planets[?(@.body=="' + lord + r'")]',
          kind: EvidenceKind.dasha,
          descriptionEn:
              '$lordEn activation uses whole-sign house, D1/D9 dignity and ascendant-specific functional ownership.',
          descriptionBn:
              '$lordBn-এর সক্রিয়তায় হোল-সাইন ভাব, D1/D9 মর্যাদা ও লগ্নভিত্তিক কার্যকর অধিপত্য ব্যবহৃত হয়েছে।',
        ),
      ],
    );
  }

  final dispositor = _signLords[position.signIndex]!;
  final dispositorPosition = planets[dispositor];
  if (dispositorPosition == null) {
    throw StateError('Node dispositor $dispositor is missing');
  }
  final dispositorRole = _functionalRole(ascendantSign, dispositor);
  final functional = dispositorRole.score;
  final dispositorD1 =
      _dignityScore(_dignity(dispositor, dispositorPosition.signIndex));
  final dispositorD9 = _dignityScore(
    _dignity(dispositor, dispositorPosition.navamsaSignIndex),
  );
  final baseScore = placement + functional + dispositorD1 + dispositorD9;
  final dispositorEn = _displayPlanetNameEn(dispositor);
  final dispositorBn = _displayPlanetNameBn(dispositor);
  final nodeReview = const VedicRahuKetuEngine().buildDashaAdjustment(
    NodeDashaContext(
      node: lord,
      ascendantSign: ascendantSign,
      nodeSign: position.signIndex,
      nodeHouse: house,
      dispositor: dispositor,
      classicalPlanets: [
        for (final body in _planetNamesEn.keys)
          NodeDashaPlanetContext(
            body: body,
            signIndex: planets[body]!.signIndex,
            activationScore: _classicalDashaScore(
              ascendantSign,
              planets,
              body,
            ),
            ownedHouses: _functionalRole(ascendantSign, body).ownedHouses,
          ),
      ],
    ),
  );
  final score = baseScore + nodeReview.scoreModifier;
  return _DashaActivation(
    score: score,
    internalConflict: nodeReview.internalConflict,
    lifeAreas:
        _lifeAreasForHouses([house, ...dispositorRole.ownedHouses]),
    summaryEn:
        '$lordEn contributes house $house ($placement); its sign dispositor $dispositorEn contributes functional ownership ($functional), D1 dignity ($dispositorD1) and D9 dignity ($dispositorD9). ${nodeReview.summaryEn} Node association modifier ${nodeReview.scoreModifier >= 0 ? '+' : ''}${nodeReview.scoreModifier}.',
    summaryBn:
        '$lordBn ভাব $house ($placement) যোগ করেছে; রাশিপতি $dispositorBn কার্যকর অধিপত্য ($functional), D1 মর্যাদা ($dispositorD1) ও D9 মর্যাদা ($dispositorD9) যোগ করেছে। ${nodeReview.summaryBn} Node association modifier ${nodeReview.scoreModifier >= 0 ? '+' : ''}${nodeReview.scoreModifier}।',
    evidence: [
      ChartEvidence(
        ruleId: 'vedic.dasha.node.house.v2.$lord',
        outputPath: r'$.planets[?(@.body=="' + lord + r'")].signIndex',
        kind: EvidenceKind.dasha,
        descriptionEn: '$lordEn occupies whole-sign house $house.',
        descriptionBn: '$lordBn হোল-সাইন $house নম্বর ভাবে রয়েছে।',
      ),
      ChartEvidence(
        ruleId: 'vedic.dasha.node.dispositor.v2.$lord.$dispositor',
        outputPath:
            r'$.planets[?(@.body=="' + dispositor + r'")]',
        kind: EvidenceKind.dasha,
        descriptionEn:
            '$dispositorEn is the sign dispositor used to qualify $lordEn activation; no separate Rahu/Ketu dignity is invented.',
        descriptionBn:
            '$lordBn-এর সক্রিয়তা বিচার করতে রাশিপতি $dispositorBn ব্যবহৃত হয়েছে; Rahu/Ketu-এর আলাদা fabricated dignity ব্যবহার হয়নি।',
      ),
      ...nodeReview.evidence,
    ],
  );
}

int _classicalDashaScore(
  int ascendantSign,
  Map<String, _ChartPlanet> planets,
  String lord,
) {
  final position = planets[lord]!;
  final house = _houseOf(ascendantSign, position);
  final placement = _placementScore(house);
  final d1 = _dignityScore(_dignity(lord, position.signIndex));
  final d9 = _dignityScore(_dignity(lord, position.navamsaSignIndex));
  final functional = _functionalRole(ascendantSign, lord).score;
  return placement + d1 + d9 + functional;
}

List<LifeArea> _lifeAreasForHouses(Iterable<int> houses) {
  final areas = <LifeArea>{};
  for (final house in houses) {
    areas.addAll(_dashaHouseLifeAreas[house] ?? const [LifeArea.overall]);
  }
  return areas.toList(growable: false);
}

String _requiredDashaLord(Object? value, String path) {
  if (value is! String || !_vimshottariSequence.contains(value)) {
    throw StateError('Missing or invalid $path');
  }
  return value;
}

DateTime _requiredUtcDate(Object? value, String path) {
  if (value is! String || !value.endsWith('Z')) {
    throw StateError('Missing or invalid $path');
  }
  final parsed = DateTime.tryParse(value);
  if (parsed == null || !parsed.isUtc) {
    throw StateError('Missing or invalid $path');
  }
  return parsed;
}

List<ChartFinding> _buildPanchMahapurushaFindings(
  int ascendantSign,
  Map<String, _ChartPlanet> planets,
) {
  final findings = <ChartFinding>[];
  final sun = planets['sun']!;
  for (final profile in _mahapurushaProfiles) {
    final position = planets[profile.planet]!;
    final house = _houseOf(ascendantSign, position);
    final dignity = _dignity(profile.planet, position.signIndex);
    final dignityMatches =
        dignity == _Dignity.exalted || dignity == _Dignity.ownSign;
    if (!_mahapurushaKendras.contains(house) || !dignityMatches) continue;

    final separation = _angularSeparation(
      sun.siderealLongitude,
      position.siderealLongitude,
    );
    final combust = separation <=
        _combustionThreshold(profile.planet, position.retrograde);
    final warPartners = _planetaryWarBodies
        .where((planet) => planet != profile.planet)
        .where(
          (planet) =>
              _angularSeparation(
                position.siderealLongitude,
                planets[planet]!.siderealLongitude,
              ) <=
              _planetaryWarReviewThreshold,
        )
        .toList(growable: false);
    final nodePartners = <String>[
      if (planets['rahu']?.signIndex == position.signIndex) 'rahu',
      if (planets['ketu']?.signIndex == position.signIndex) 'ketu',
    ];
    final reviewModifiers = combust ||
        position.retrograde ||
        warPartners.isNotEmpty ||
        nodePartners.isNotEmpty;
    final planetEn = _planetNamesEn[profile.planet]!;
    final planetBn = _planetNamesBn[profile.planet]!;
    final modifiersEn = <String>[
      if (combust)
        'combustion review (${separation.toStringAsFixed(3)}° from the Sun)',
      if (position.retrograde) 'retrograde-state review',
      if (warPartners.isNotEmpty)
        'planetary-war proximity with ${warPartners.map(_displayPlanetNameEn).join(', ')}',
      if (nodePartners.isNotEmpty)
        'same-sign node contact with ${nodePartners.map(_displayPlanetNameEn).join(', ')}',
    ];
    final modifiersBn = <String>[
      if (combust)
        'অস্তাঙ্গতা পর্যালোচনা (সূর্য থেকে ${separation.toStringAsFixed(3)}°)',
      if (position.retrograde) 'বক্রী-অবস্থা পর্যালোচনা',
      if (warPartners.isNotEmpty)
        '${warPartners.map(_displayPlanetNameBn).join(', ')}-এর সঙ্গে গ্রহযুদ্ধ নৈকট্য',
      if (nodePartners.isNotEmpty)
        '${nodePartners.map(_displayPlanetNameBn).join(', ')}-এর সঙ্গে একই-রাশির নোড সংযোগ',
    ];
    final modifierNarrativeEn = modifiersEn.isEmpty
        ? 'No enabled combustion, retrograde, planetary-war-proximity or node-conjunction review flag modifies this formation.'
        : 'Strength review remains open because of ${modifiersEn.join('; ')}.';
    final modifierNarrativeBn = modifiersBn.isEmpty
        ? 'সক্রিয় নিয়মে অস্তাঙ্গতা, বক্রী, গ্রহযুদ্ধ-নৈকট্য বা নোড-সংযোগের কোনো সংশোধক সংকেত নেই।'
        : '${modifiersBn.join('; ')} থাকার কারণে যোগের শক্তি পর্যালোচনাধীন থাকবে।';

    findings.add(
      ChartFinding(
        code: 'vedic.yoga.panchamahapurusha.${profile.code}',
        area: _houseLifeAreas[house - 1],
        polarity: reviewModifiers
            ? AnalysisPolarity.mixed
            : AnalysisPolarity.supportive,
        confidence: reviewModifiers
            ? AnalysisConfidence.medium
            : AnalysisConfidence.high,
        titleEn: '${profile.nameEn} Panch Mahapurusha formation',
        titleBn: '${profile.nameBn} পঞ্চ মহাপুরুষ যোগের গঠন',
        narrativeEn:
            '$planetEn is in whole-sign house $house, a Kendra from Lagna, and has ${_dignityEn[dignity]} dignity in ${_signNamesEn[position.signIndex]}; therefore the versioned D1 formation rule for ${profile.nameEn} is satisfied. $modifierNarrativeEn This records structural potential only. The separate Shadbala foundation, Navamsha agreement, broader affliction and Dasha activation are not folded into this yoga finding, and guaranteed events are not inferred.',
        narrativeBn:
            '$planetBn লগ্ন থেকে কেন্দ্র $house নম্বর ভাবে ${_signNamesBn[position.signIndex]} রাশিতে ${_dignityBn[dignity]} মর্যাদায় রয়েছে; তাই ${profile.nameBn}-এর versioned D1 গঠন-নিয়ম পূর্ণ হয়েছে। $modifierNarrativeBn এটি শুধু কাঠামোগত সম্ভাবনা নথিভুক্ত করে। আলাদা ষড়বল foundation, নবাংশের সমর্থন, বিস্তৃত পীড়ন ও দশার সক্রিয়তা এই যোগ-ফলে মেশানো হয়নি এবং নিশ্চিত ঘটনা অনুমান করা হয়নি।',
        evidence: [
          ChartEvidence(
            ruleId:
                'vedic.yoga.panchamahapurusha.${profile.code}.kendra.v1',
            outputPath: r'$.ascendant.signIndex',
            kind: EvidenceKind.yoga,
            descriptionEn:
                '$planetEn occupies whole-sign Kendra house $house from Lagna.',
            descriptionBn:
                '$planetBn লগ্ন থেকে হোল-সাইন কেন্দ্র $house নম্বর ভাবে রয়েছে।',
          ),
          ChartEvidence(
            ruleId:
                'vedic.yoga.panchamahapurusha.${profile.code}.dignity.v1',
            outputPath: r'$.planets[?(@.body=="' +
                profile.planet +
                r'")].signIndex',
            kind: EvidenceKind.strength,
            descriptionEn:
                '$planetEn has ${_dignityEn[dignity]} dignity in ${_signNamesEn[position.signIndex]}.',
            descriptionBn:
                '$planetBn ${_signNamesBn[position.signIndex]} রাশিতে ${_dignityBn[dignity]} মর্যাদায় রয়েছে।',
          ),
          if (reviewModifiers)
            ChartEvidence(
              ruleId:
                  'vedic.yoga.panchamahapurusha.${profile.code}.modifier_review.v1',
              outputPath: r'$.planets[*]',
              kind: EvidenceKind.strength,
              descriptionEn: modifierNarrativeEn,
              descriptionBn: modifierNarrativeBn,
            ),
        ],
      ),
    );
  }
  return findings;
}

List<ChartFinding> _buildKujaDoshaReview(
  int ascendantSign,
  Map<String, _ChartPlanet> planets,
) {
  final mars = planets['mars']!;
  final marsHouse = _houseOf(ascendantSign, mars);
  final coreMatch = _kujaCoreHouses.contains(marsHouse);
  final extendedMatch = marsHouse == 2;
  final dignity = _dignity('mars', mars.signIndex);
  final dignityMitigation =
      dignity == _Dignity.exalted || dignity == _Dignity.ownSign;
  final jupiter = planets['jupiter']!;
  final jupiterHouse = _houseOf(ascendantSign, jupiter);
  final jupiterSupport = jupiter.signIndex == mars.signIndex ||
      _aspectRules['jupiter']!.any(
        (rule) =>
            ((jupiterHouse + rule.houseCount - 2) % 12) + 1 == marsHouse,
      );
  final matched = coreMatch || extendedMatch;
  final profileLabelEn = coreMatch
      ? 'core Lagna houses 1/4/7/8/12'
      : extendedMatch
          ? 'extended 2nd-house variant'
          : 'neither the core nor extended Lagna-house list';
  final profileLabelBn = coreMatch
      ? 'মূল লগ্ন-ভাব ১/৪/৭/৮/১২'
      : extendedMatch
          ? 'সম্প্রসারিত ২য়-ভাব মত'
          : 'মূল বা সম্প্রসারিত কোনো লগ্ন-ভাব তালিকাই নয়';
  final mitigationEn = <String>[
    if (dignityMitigation)
      'Mars is ${_dignityEn[dignity]} in ${_signNamesEn[mars.signIndex]}',
    if (jupiterSupport)
      'Jupiter ${jupiter.signIndex == mars.signIndex ? 'conjoins' : 'casts an enabled full sign aspect on'} Mars',
  ];
  final mitigationBn = <String>[
    if (dignityMitigation)
      'মঙ্গল ${_signNamesBn[mars.signIndex]} রাশিতে ${_dignityBn[dignity]} মর্যাদায় রয়েছে',
    if (jupiterSupport)
      'বৃহস্পতি মঙ্গলকে ${jupiter.signIndex == mars.signIndex ? 'সংযোগ' : 'সক্রিয় পূর্ণ রাশিদৃষ্টি'} দিচ্ছে',
  ];
  final statusEn = matched
      ? 'Mars occupies house $marsHouse, matching the $profileLabelEn.'
      : 'Mars occupies house $marsHouse, matching $profileLabelEn; this Lagna-only screen is not triggered.';
  final statusBn = matched
      ? 'মঙ্গল $marsHouse নম্বর ভাবে রয়েছে, যা $profileLabelBn-এর সঙ্গে মেলে।'
      : 'মঙ্গল $marsHouse নম্বর ভাবে রয়েছে, যা $profileLabelBn; এই Lagna-only screen সক্রিয় হয়নি।';
  final mitigationTextEn = mitigationEn.isEmpty
      ? 'No enabled dignity or Jupiter-support mitigation is established.'
      : 'Possible mitigating evidence: ${mitigationEn.join('; ')}. It is not treated as automatic cancellation.';
  final mitigationTextBn = mitigationBn.isEmpty
      ? 'সক্রিয় নিয়মে মর্যাদা বা বৃহস্পতির সমর্থনভিত্তিক প্রশমন প্রতিষ্ঠিত হয়নি।'
      : 'সম্ভাব্য প্রশমন-প্রমাণ: ${mitigationBn.join('; ')}। এটিকে স্বয়ংক্রিয় সম্পূর্ণ খণ্ডন ধরা হয়নি।';

  return [
    ChartFinding(
      code: matched
          ? 'vedic.dosha.kuja.lagna_screen.matched'
          : 'vedic.dosha.kuja.lagna_screen.not_matched',
      area: LifeArea.marriage,
      polarity: AnalysisPolarity.mixed,
      confidence: AnalysisConfidence.medium,
      titleEn: matched
          ? 'Kuja-dosha review screen matched'
          : 'Kuja-dosha Lagna screen not matched',
      titleBn: matched
          ? 'কুজদোষ পর্যালোচনা স্ক্রিন মিলেছে'
          : 'কুজদোষের লগ্ন-স্ক্রিন মেলেনি',
      narrativeEn:
          '$statusEn $mitigationTextEn This is a transparent screening flag, not a marriage verdict. Moon/Venus reference counts, D9, seventh-house condition, partner comparison and disputed regional cancellations are not yet applied. It must never be used alone to predict divorce, harm or death of a spouse.',
      narrativeBn:
          '$statusBn $mitigationTextBn এটি স্বচ্ছ screening flag, বিবাহের চূড়ান্ত রায় নয়। চন্দ্র/শুক্র থেকে গণনা, D9, সপ্তম ভাবের পূর্ণ অবস্থা, সঙ্গীর কুণ্ডলী-মিল এবং মতভেদযুক্ত আঞ্চলিক খণ্ডন এখনো প্রয়োগ করা হয়নি। শুধু এটি দিয়ে বিবাহবিচ্ছেদ, সঙ্গীর ক্ষতি বা মৃত্যু অনুমান করা যাবে না।',
      evidence: [
        ChartEvidence(
          ruleId: extendedMatch
              ? 'vedic.dosha.kuja.lagna_house.extended.v1'
              : 'vedic.dosha.kuja.lagna_house.core.v1',
          outputPath: r'$.planets[?(@.body=="mars")].signIndex',
          kind: EvidenceKind.dosha,
          descriptionEn:
              'Mars is in whole-sign house $marsHouse from Lagna; applied profile: $profileLabelEn.',
          descriptionBn:
              'মঙ্গল লগ্ন থেকে হোল-সাইন $marsHouse নম্বর ভাবে; প্রয়োগ করা প্রোফাইল: $profileLabelBn।',
        ),
        if (dignityMitigation)
          ChartEvidence(
            ruleId: 'vedic.dosha.kuja.mitigation.dignity_review.v1',
            outputPath: r'$.planets[?(@.body=="mars")].signIndex',
            kind: EvidenceKind.strength,
            descriptionEn: mitigationEn.first,
            descriptionBn: mitigationBn.first,
          ),
        if (jupiterSupport)
          ChartEvidence(
            ruleId: 'vedic.dosha.kuja.mitigation.jupiter_review.v1',
            outputPath: r'$.planets[*].signIndex',
            kind: EvidenceKind.aspect,
            descriptionEn:
                'Jupiter support is recorded for professional mitigation review; it does not auto-cancel the screen.',
            descriptionBn:
                'পেশাদার প্রশমন পর্যালোচনার জন্য বৃহস্পতির সমর্থন নথিভুক্ত; এটি স্ক্রিনকে স্বয়ংক্রিয়ভাবে বাতিল করে না।',
          ),
      ],
    ),
  ];
}

List<ChartFinding> _buildGajakesariFindings(
  int ascendantSign,
  Map<String, _ChartPlanet> planets,
) {
  final jupiter = planets['jupiter']!;
  final moon = planets['moon']!;
  final jupiterHouse = _houseOf(ascendantSign, jupiter);
  final jupiterFromMoon =
      ((jupiter.signIndex - moon.signIndex + 12) % 12) + 1;
  final fromLagna = _mahapurushaKendras.contains(jupiterHouse);
  final fromMoon = _mahapurushaKendras.contains(jupiterFromMoon);
  if (!fromLagna && !fromMoon) return const [];

  final beneficSupporters = _gajakesariBeneficSupporters
      .where(
        (planet) =>
            planets[planet]!.signIndex == jupiter.signIndex ||
            _castsFullAspectOnSign(
              planet,
              jupiter.signIndex,
              planets,
            ),
      )
      .toList(growable: false);
  final dignity = _dignity('jupiter', jupiter.signIndex);
  final dispositor = _signLords[jupiter.signIndex]!;
  final enemySign = 'jupiter' != dispositor &&
      _naturalEnemies['jupiter']!.contains(dispositor);
  final sun = planets['sun']!;
  final sunSeparation = _angularSeparation(
    sun.siderealLongitude,
    jupiter.siderealLongitude,
  );
  final combust = sunSeparation <=
      _combustionThreshold('jupiter', jupiter.retrograde);
  final debilitated = dignity == _Dignity.debilitated;
  final established = beneficSupporters.isNotEmpty &&
      !debilitated &&
      !combust &&
      !enemySign;
  final missingEn = <String>[
    if (beneficSupporters.isEmpty)
      'no enabled Mercury/Venus conjunction or full sign aspect supports Jupiter',
    if (debilitated) 'Jupiter is debilitated',
    if (combust)
      'Jupiter is inside the combustion threshold (${sunSeparation.toStringAsFixed(3)}° from the Sun)',
    if (enemySign)
      'Jupiter occupies a sign ruled by its natural enemy ${_planetNamesEn[dispositor]}',
  ];
  final missingBn = <String>[
    if (beneficSupporters.isEmpty)
      'সক্রিয় নিয়মে বুধ/শুক্রের সংযোগ বা পূর্ণ রাশিদৃষ্টি বৃহস্পতিকে সমর্থন করছে না',
    if (debilitated) 'বৃহস্পতি নীচ রাশিতে',
    if (combust)
      'বৃহস্পতি অস্তাঙ্গতা সীমার মধ্যে (সূর্য থেকে ${sunSeparation.toStringAsFixed(3)}°)',
    if (enemySign)
      'বৃহস্পতি তার নৈসর্গিক শত্রু ${_planetNamesBn[dispositor]}-এর রাশিতে',
  ];
  final geometryEn = <String>[
    if (fromLagna) 'house $jupiterHouse from Lagna',
    if (fromMoon) '$jupiterFromMoon from the Moon',
  ].join(' and ');
  final geometryBn = <String>[
    if (fromLagna) 'লগ্ন থেকে $jupiterHouse নম্বর ভাব',
    if (fromMoon) 'চন্দ্র থেকে $jupiterFromMoon নম্বর ভাব',
  ].join(' এবং ');
  final supportEn = beneficSupporters.isEmpty
      ? 'No enabled benefic supporter is established.'
      : 'Enabled benefic support: ${beneficSupporters.map(_displayPlanetNameEn).join(', ')}.';
  final supportBn = beneficSupporters.isEmpty
      ? 'সক্রিয় নিয়মে অন্য শুভগ্রহের সমর্থন প্রতিষ্ঠিত হয়নি।'
      : 'সক্রিয় শুভগ্রহের সমর্থন: ${beneficSupporters.map(_displayPlanetNameBn).join(', ')}।';

  return [
    ChartFinding(
      code: established
          ? 'vedic.yoga.gajakesari.bphs.established'
          : 'vedic.yoga.gajakesari.bphs.candidate',
      area: LifeArea.overall,
      polarity: established
          ? AnalysisPolarity.supportive
          : AnalysisPolarity.mixed,
      confidence: established
          ? AnalysisConfidence.high
          : AnalysisConfidence.medium,
      titleEn: established
          ? 'Gajakesari Yoga — BPHS profile formed'
          : 'Gajakesari geometry — qualifier review required',
      titleBn: established
          ? 'গজকেশরী যোগ — BPHS প্রোফাইল গঠিত'
          : 'গজকেশরী জ্যামিতি — যোগ্যতা পর্যালোচনা প্রয়োজন',
      narrativeEn: established
          ? 'Jupiter is in an angle at $geometryEn, receives the required enabled benefic support, and is not debilitated, combust or in a natural-enemy sign. $supportEn The versioned BPHS D1 formation is established, but strength, Navamsha and Dasha activation must still be reviewed; wealth, status or any event is not guaranteed.'
          : 'Jupiter satisfies the angular geometry at $geometryEn, but the complete versioned BPHS profile is not established because ${missingEn.join('; ')}. $supportEn The app preserves this as a candidate instead of calling the yoga formed.',
      narrativeBn: established
          ? 'বৃহস্পতি $geometryBn-এ কেন্দ্রে রয়েছে, প্রয়োজনীয় সক্রিয় শুভগ্রহের সমর্থন পাচ্ছে এবং নীচ, অস্তাঙ্গ বা নৈসর্গিক শত্রুর রাশিতে নয়। $supportBn Versioned BPHS D1 গঠন প্রতিষ্ঠিত; তবু বল, নবাংশ ও দশার সক্রিয়তা যাচাই করতে হবে—সম্পদ, মর্যাদা বা কোনো ঘটনা নিশ্চিত নয়।'
          : 'বৃহস্পতি $geometryBn-এ কেন্দ্রের জ্যামিতি পূরণ করেছে, কিন্তু ${missingBn.join('; ')} হওয়ায় সম্পূর্ণ versioned BPHS প্রোফাইল প্রতিষ্ঠিত নয়। $supportBn অ্যাপ এটিকে যোগ গঠিত না বলে candidate হিসেবে রাখে।',
      evidence: [
        if (fromLagna)
          ChartEvidence(
            ruleId: 'vedic.yoga.gajakesari.jupiter_kendra_lagna.v1',
            outputPath: r'$.ascendant.signIndex',
            kind: EvidenceKind.yoga,
            descriptionEn:
                'Jupiter occupies Kendra house $jupiterHouse from Lagna.',
            descriptionBn:
                'বৃহস্পতি লগ্ন থেকে কেন্দ্র $jupiterHouse নম্বর ভাবে রয়েছে।',
          ),
        if (fromMoon)
          ChartEvidence(
            ruleId: 'vedic.yoga.gajakesari.jupiter_kendra_moon.v1',
            outputPath: r'$.planets[*].signIndex',
            kind: EvidenceKind.yoga,
            descriptionEn:
                'Jupiter is $jupiterFromMoon from the Moon, an angular relationship.',
            descriptionBn:
                'বৃহস্পতি চন্দ্র থেকে $jupiterFromMoon নম্বর স্থানে, অর্থাৎ কেন্দ্রীয় সম্পর্কে রয়েছে।',
          ),
        ChartEvidence(
          ruleId: 'vedic.yoga.gajakesari.benefic_support.v1',
          outputPath: r'$.planets[*].signIndex',
          kind: EvidenceKind.aspect,
          descriptionEn: supportEn,
          descriptionBn: supportBn,
        ),
        ChartEvidence(
          ruleId: 'vedic.yoga.gajakesari.jupiter_condition.v1',
          outputPath: r'$.planets[*]',
          kind: EvidenceKind.strength,
          descriptionEn:
              'Jupiter condition: ${_dignityEn[dignity]} dignity; combust=$combust; natural-enemy sign=$enemySign.',
          descriptionBn:
              'বৃহস্পতির অবস্থা: ${_dignityBn[dignity]} মর্যাদা; অস্তাঙ্গ=$combust; নৈসর্গিক শত্রুর রাশি=$enemySign।',
        ),
      ],
    ),
  ];
}

List<ChartFinding> _buildRajaDhanaYogaFindings(
  int ascendantSign,
  Map<String, _ChartPlanet> planets,
) {
  final findings = <ChartFinding>[];
  final lagnaLord = _signLords[ascendantSign]!;
  final fifthSign = (ascendantSign + 4) % 12;
  final eleventhSign = (ascendantSign + 10) % 12;
  final fifthLord = _signLords[fifthSign]!;
  final eleventhLord = _signLords[eleventhSign]!;
  final lagnaLordPosition = planets[lagnaLord]!;
  final fifthLordPosition = planets[fifthLord]!;
  final eleventhLordPosition = planets[eleventhLord]!;
  final conjunction =
      lagnaLordPosition.signIndex == fifthLordPosition.signIndex;
  final conjunctionHouse = _houseOf(ascendantSign, lagnaLordPosition);
  final inKendraOrTrikona =
      _rajaYogaKendraTrikona.contains(conjunctionHouse);

  if (conjunction && inKendraOrTrikona) {
    final strengthReview = _participantStrengthReview(
      [lagnaLord, fifthLord],
      planets,
    );
    findings.add(
      ChartFinding(
        code: 'vedic.yoga.raja.lagna_fifth_lord_conjunction.v1',
        area: LifeArea.career,
        polarity: strengthReview.hasChallenge
            ? AnalysisPolarity.mixed
            : AnalysisPolarity.supportive,
        confidence: strengthReview.hasChallenge
            ? AnalysisConfidence.medium
            : AnalysisConfidence.high,
        titleEn: 'Raja Yoga — Lagna and fifth lords connected',
        titleBn: 'রাজযোগ — লগ্নেশ ও পঞ্চমেশ যুক্ত',
        narrativeEn:
            '${_planetNamesEn[lagnaLord]} (Lagna lord) and ${_planetNamesEn[fifthLord]} (fifth lord) conjoin in whole-sign house $conjunctionHouse, which is a Kendra/Trikona in the applied BPHS D1 rule. ${strengthReview.textEn} This is a formation record, not a promise of office, authority or status; D9/D10, strength and the separate Dasha activation windows must be cross-reviewed.',
        narrativeBn:
            '${_planetNamesBn[lagnaLord]} (লগ্নেশ) ও ${_planetNamesBn[fifthLord]} (পঞ্চমেশ) হোল-সাইন $conjunctionHouse নম্বর কেন্দ্র/ত্রিকোণ ভাবে যুক্ত—প্রয়োগ করা BPHS D1 নিয়ম পূর্ণ। ${strengthReview.textBn} এটি যোগের গঠন নথি, পদ, কর্তৃত্ব বা মর্যাদার প্রতিশ্রুতি নয়; D9/D10, বল ও আলাদা দশা-সক্রিয়তার সময়কাল মিলিয়ে দেখতে হবে।',
        evidence: [
          ChartEvidence(
            ruleId: 'vedic.yoga.raja.lagna_fifth_lords.conjunction.v1',
            outputPath: r'$.planets[*].signIndex',
            kind: EvidenceKind.yoga,
            descriptionEn:
                'Lagna lord ${_planetNamesEn[lagnaLord]} and fifth lord ${_planetNamesEn[fifthLord]} share sign ${_signNamesEn[lagnaLordPosition.signIndex]}.',
            descriptionBn:
                'লগ্নেশ ${_planetNamesBn[lagnaLord]} ও পঞ্চমেশ ${_planetNamesBn[fifthLord]} একই ${_signNamesBn[lagnaLordPosition.signIndex]} রাশিতে।',
          ),
          ChartEvidence(
            ruleId:
                'vedic.yoga.raja.lagna_fifth_lords.kendra_trikona.v1',
            outputPath: r'$.ascendant.signIndex',
            kind: EvidenceKind.placement,
            descriptionEn:
                'The conjunction occupies Kendra/Trikona house $conjunctionHouse.',
            descriptionBn:
                'সংযোগটি কেন্দ্র/ত্রিকোণ $conjunctionHouse নম্বর ভাবে রয়েছে।',
          ),
          if (strengthReview.hasChallenge)
            ChartEvidence(
              ruleId:
                  'vedic.yoga.raja.lagna_fifth_lords.strength_review.v1',
              outputPath: r'$.planets[*]',
              kind: EvidenceKind.strength,
              descriptionEn: strengthReview.textEn,
              descriptionBn: strengthReview.textBn,
            ),
        ],
      ),
    );
  }

  final fifthLordHouse = _houseOf(ascendantSign, fifthLordPosition);
  final eleventhLordHouse = _houseOf(ascendantSign, eleventhLordPosition);
  if (fifthLordHouse == 5 && eleventhLordHouse == 11) {
    final strengthReview = _participantStrengthReview(
      [fifthLord, eleventhLord],
      planets,
    );
    findings.add(
      ChartFinding(
        code: 'vedic.yoga.dhana.fifth_eleventh_lords_own_houses.v1',
        area: LifeArea.finance,
        polarity: strengthReview.hasChallenge
            ? AnalysisPolarity.mixed
            : AnalysisPolarity.supportive,
        confidence: strengthReview.hasChallenge
            ? AnalysisConfidence.medium
            : AnalysisConfidence.high,
        titleEn: 'Dhana Yoga — fifth and eleventh lords in own houses',
        titleBn: 'ধনযোগ — পঞ্চমেশ ও একাদশেশ নিজ নিজ ভাবে',
        narrativeEn:
            '${_planetNamesEn[fifthLord]} occupies its own fifth house and ${_planetNamesEn[eleventhLord]} occupies its own eleventh house, satisfying the enabled BPHS D1 affluence formula. ${strengthReview.textEn} It indicates financial potential for professional review, not guaranteed wealth; separate Dasha windows, divisional strength, liabilities and contradictory rules must be cross-reviewed.',
        narrativeBn:
            '${_planetNamesBn[fifthLord]} নিজের পঞ্চম ভাবে এবং ${_planetNamesBn[eleventhLord]} নিজের একাদশ ভাবে রয়েছে—সক্রিয় BPHS D1 ধনসম্ভাবনার সূত্র পূর্ণ। ${strengthReview.textBn} এটি পেশাদার পর্যালোচনার আর্থিক সম্ভাবনা, নিশ্চিত সম্পদ নয়; আলাদা দশা-সময়কাল, বিভাগীয় বল, দায় ও বিরোধী নিয়ম মিলিয়ে যাচাই করতে হবে।',
        evidence: [
          ChartEvidence(
            ruleId: 'vedic.yoga.dhana.fifth_lord.own_house.v1',
            outputPath: r'$.planets[*].signIndex',
            kind: EvidenceKind.lordship,
            descriptionEn:
                'Fifth lord ${_planetNamesEn[fifthLord]} occupies house 5.',
            descriptionBn:
                'পঞ্চমেশ ${_planetNamesBn[fifthLord]} ৫ নম্বর ভাবে রয়েছে।',
          ),
          ChartEvidence(
            ruleId: 'vedic.yoga.dhana.eleventh_lord.own_house.v1',
            outputPath: r'$.planets[*].signIndex',
            kind: EvidenceKind.lordship,
            descriptionEn:
                'Eleventh lord ${_planetNamesEn[eleventhLord]} occupies house 11.',
            descriptionBn:
                'একাদশেশ ${_planetNamesBn[eleventhLord]} ১১ নম্বর ভাবে রয়েছে।',
          ),
          if (strengthReview.hasChallenge)
            ChartEvidence(
              ruleId:
                  'vedic.yoga.dhana.fifth_eleventh_lords.strength_review.v1',
              outputPath: r'$.planets[*]',
              kind: EvidenceKind.strength,
              descriptionEn: strengthReview.textEn,
              descriptionBn: strengthReview.textBn,
            ),
        ],
      ),
    );
  }
  return findings;
}

List<ChartFinding> _buildD1D9AgreementFindings(
  Map<String, _ChartPlanet> planets,
) {
  final findings = <ChartFinding>[];
  for (final planet in _planetNamesEn.keys) {
    final position = planets[planet]!;
    final d1Dignity = _dignity(planet, position.signIndex);
    final d9Dignity = _dignity(planet, position.navamsaSignIndex);
    final d1Score = _dignityScore(d1Dignity);
    final d9Score = _dignityScore(d9Dignity);
    final vargottama = position.signIndex == position.navamsaSignIndex;
    final contradiction = d1Score != 0 &&
        d9Score != 0 &&
        d1Score.sign != d9Score.sign;
    final polarity = contradiction
        ? AnalysisPolarity.mixed
        : d1Score + d9Score > 0
            ? AnalysisPolarity.supportive
            : d1Score + d9Score < 0
                ? AnalysisPolarity.challenging
                : AnalysisPolarity.mixed;
    final confidence = d1Score != 0 &&
            d9Score != 0 &&
            d1Score.sign == d9Score.sign
        ? AnalysisConfidence.high
        : AnalysisConfidence.medium;
    final planetEn = _planetNamesEn[planet]!;
    final planetBn = _planetNamesBn[planet]!;
    final vargottamaEn = vargottama
        ? ' The planet is Vargottama because D1 and D9 retain the same sign.'
        : '';
    final vargottamaBn = vargottama
        ? ' D1 ও D9-এ একই রাশি থাকায় গ্রহটি বর্গোত্তম।'
        : '';
    final contradictionEn = contradiction
        ? ' D1 and D9 dignity point in opposite directions, so the result remains Mixed.'
        : '';
    final contradictionBn = contradiction
        ? ' D1 ও D9 মর্যাদা বিপরীত দিকে ইঙ্গিত করায় ফল মিশ্র রাখা হয়েছে।'
        : '';

    findings.add(
      ChartFinding(
        code: 'vedic.divisional.d1_d9.$planet',
        area: LifeArea.overall,
        polarity: polarity,
        confidence: confidence,
        titleEn:
            '$planetEn D1-D9 agreement: ${_polarityEn[polarity]}',
        titleBn:
            '$planetBn D1-D9 মিল: ${_polarityBn[polarity]}',
        narrativeEn:
            '$planetEn is ${_dignityEn[d1Dignity]} in D1 ${_signNamesEn[position.signIndex]} and ${_dignityEn[d9Dignity]} in D9 ${_signNamesEn[position.navamsaSignIndex]}. The transparent dignity scores are D1=$d1Score and D9=$d9Score.$vargottamaEn$contradictionEn This is divisional dignity agreement only; D9 houses, lordship, aspects, the separate Shadbala foundation and Dasha activation are not folded into this finding.',
        narrativeBn:
            '$planetBn D1-এর ${_signNamesBn[position.signIndex]} রাশিতে ${_dignityBn[d1Dignity]} এবং D9-এর ${_signNamesBn[position.navamsaSignIndex]} রাশিতে ${_dignityBn[d9Dignity]} মর্যাদায় রয়েছে। স্বচ্ছ মর্যাদা স্কোর D1=$d1Score ও D9=$d9Score।$vargottamaBn$contradictionBn এটি শুধু বিভাগীয় মর্যাদা-মিল; D9 ভাব, অধিপত্য, দৃষ্টি, আলাদা ষড়বল foundation বা দশার সক্রিয়তা এই ফলে মেশানো হয়নি।',
        evidence: [
          ChartEvidence(
            ruleId: 'vedic.divisional.d1_d9.$planet.d1_dignity.v1',
            outputPath: r'$.planets[?(@.body=="' +
                planet +
                r'")].signIndex',
            kind: EvidenceKind.strength,
            descriptionEn:
                '$planetEn D1 sign ${_signNamesEn[position.signIndex]}; dignity ${_dignityEn[d1Dignity]}.',
            descriptionBn:
                '$planetBn-এর D1 রাশি ${_signNamesBn[position.signIndex]}; মর্যাদা ${_dignityBn[d1Dignity]}।',
          ),
          ChartEvidence(
            ruleId: 'vedic.divisional.d1_d9.$planet.d9_dignity.v1',
            outputPath: r'$.planets[?(@.body=="' +
                planet +
                r'")].navamsaSignIndex',
            kind: EvidenceKind.divisional,
            descriptionEn:
                '$planetEn D9 sign ${_signNamesEn[position.navamsaSignIndex]}; dignity ${_dignityEn[d9Dignity]}; Vargottama=$vargottama.',
            descriptionBn:
                '$planetBn-এর D9 রাশি ${_signNamesBn[position.navamsaSignIndex]}; মর্যাদা ${_dignityBn[d9Dignity]}; বর্গোত্তম=$vargottama।',
          ),
        ],
      ),
    );
  }
  return findings;
}
