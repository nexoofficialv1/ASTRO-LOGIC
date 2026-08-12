part of 'vedic_lagna_judgment_engine.dart';

List<ChartFinding> _buildDetailedHouseSynthesis(
  int ascendantSign,
  Map<String, _ChartPlanet> planets,
) {
  final aspectorsByHouse = <int, Set<String>>{};
  for (final entry in _aspectRules.entries) {
    final sourceHouse = _houseOf(ascendantSign, planets[entry.key]!);
    for (final rule in entry.value) {
      final targetHouse = ((sourceHouse + rule.houseCount - 2) % 12) + 1;
      aspectorsByHouse.putIfAbsent(targetHouse, () => <String>{})
        ..add(entry.key);
    }
  }

  final findings = <ChartFinding>[];
  for (var house = 1; house <= 12; house += 1) {
    final signIndex = (ascendantSign + house - 1) % 12;
    final lord = _signLords[signIndex]!;
    final lordPosition = planets[lord]!;
    final lordHouse = _houseOf(ascendantSign, lordPosition);
    final lordDignity = _dignity(lord, lordPosition.signIndex);
    final lordRole = _functionalRole(ascendantSign, lord);
    final occupants = planets.entries
        .where((entry) => _houseOf(ascendantSign, entry.value) == house)
        .toList(growable: false)
      ..sort((first, second) => first.key.compareTo(second.key));
    final aspectors = aspectorsByHouse[house]?.toList(growable: false) ??
        <String>[];
    aspectors.sort();

    var score = _dignityScore(lordDignity) +
        _placementScore(lordHouse) +
        lordRole.score;
    final supportiveEn = <String>[];
    final supportiveBn = <String>[];
    final challengingEn = <String>[];
    final challengingBn = <String>[];
    final reviewEn = <String>[];
    final reviewBn = <String>[];

    void classify(
      int componentScore,
      String descriptionEn,
      String descriptionBn,
    ) {
      if (componentScore > 0) {
        supportiveEn.add(descriptionEn);
        supportiveBn.add(descriptionBn);
      } else if (componentScore < 0) {
        challengingEn.add(descriptionEn);
        challengingBn.add(descriptionBn);
      } else {
        reviewEn.add(descriptionEn);
        reviewBn.add(descriptionBn);
      }
    }

    classify(
      _dignityScore(lordDignity),
      '${_planetNamesEn[lord]} has ${_dignityEn[lordDignity]} dignity',
      '${_planetNamesBn[lord]} ${_dignityBn[lordDignity]} মর্যাদায় রয়েছে',
    );
    classify(
      _placementScore(lordHouse),
      'the house lord occupies house $lordHouse',
      'ভাবপতি $lordHouse নম্বর ভাবে রয়েছে',
    );
    classify(
      lordRole.score,
      'the lord’s functional ownership score is ${lordRole.score}',
      'ভাবপতির কার্যকর অধিপত্য স্কোর ${lordRole.score}',
    );

    for (final occupant in occupants) {
      if (!_planetNamesEn.containsKey(occupant.key)) {
        reviewEn.add(
          '${_displayPlanetNameEn(occupant.key)} occupies this house; node results require axis and dispositor review',
        );
        reviewBn.add(
          '${_displayPlanetNameBn(occupant.key)} এই ভাবে রয়েছে; নোডের ফলের জন্য অক্ষ ও রাশিপতি যাচাই প্রয়োজন',
        );
        continue;
      }
      final role = _functionalRole(ascendantSign, occupant.key);
      final dignity = _dignity(occupant.key, occupant.value.signIndex);
      final occupantScore = role.score + _dignityScore(dignity);
      score += occupantScore;
      classify(
        occupantScore,
        '${_planetNamesEn[occupant.key]} occupies the house with ${_dignityEn[dignity]} dignity and functional score ${role.score}',
        '${_planetNamesBn[occupant.key]} ${_dignityBn[dignity]} মর্যাদা ও কার্যকর স্কোর ${role.score} নিয়ে ভাবে রয়েছে',
      );
    }

    for (final aspector in aspectors) {
      final role = _functionalRole(ascendantSign, aspector);
      score += role.score;
      classify(
        role.score,
        '${_planetNamesEn[aspector]} casts a full sign aspect with functional score ${role.score}',
        '${_planetNamesBn[aspector]} কার্যকর স্কোর ${role.score} নিয়ে পূর্ণ রাশিদৃষ্টি দিচ্ছে',
      );
    }

    final hasContradiction =
        supportiveEn.isNotEmpty && challengingEn.isNotEmpty;
    final polarity = hasContradiction
        ? AnalysisPolarity.mixed
        : _polarity(score);
    final evidence = <ChartEvidence>[
      ChartEvidence(
        ruleId: 'vedic.life_area.house_$house.sign_lord.v1',
        outputPath: r'$.ascendant.signIndex',
        kind: EvidenceKind.lordship,
        descriptionEn:
            'Whole-sign house $house is ${_signNamesEn[signIndex]}, ruled by ${_planetNamesEn[lord]}.',
        descriptionBn:
            'হোল-সাইন $house নম্বর ভাব ${_signNamesBn[signIndex]}, যার অধিপতি ${_planetNamesBn[lord]}।',
      ),
      ChartEvidence(
        ruleId: 'vedic.life_area.house_$house.lord_condition.v1',
        outputPath:
            r'$.planets[?(@.body=="' + lord + r'")].signIndex',
        kind: EvidenceKind.strength,
        descriptionEn:
            '${_planetNamesEn[lord]} occupies house $lordHouse with ${_dignityEn[lordDignity]} dignity.',
        descriptionBn:
            '${_planetNamesBn[lord]} $lordHouse নম্বর ভাবে ${_dignityBn[lordDignity]} মর্যাদায় রয়েছে।',
      ),
      ChartEvidence(
        ruleId: 'vedic.life_area.house_$house.functional_role.v1',
        outputPath: r'$.ascendant.signIndex',
        kind: EvidenceKind.lordship,
        descriptionEn:
            '${_planetNamesEn[lord]} owns houses ${lordRole.ownedHouses.join(', ')} with functional score ${lordRole.score}.',
        descriptionBn:
            '${_planetNamesBn[lord]} ${lordRole.ownedHouses.join(', ')} নম্বর ভাবের অধিপতি; কার্যকর স্কোর ${lordRole.score}।',
      ),
      if (occupants.isEmpty)
        ChartEvidence(
          ruleId: 'vedic.life_area.house_$house.empty.v1',
          outputPath: r'$.planets[*].signIndex',
          kind: EvidenceKind.placement,
          descriptionEn:
              'No listed planet occupies house $house; an empty house is judged through its lord and aspects.',
          descriptionBn:
              '$house নম্বর ভাবে কোনো তালিকাভুক্ত গ্রহ নেই; খালি ভাবকে ভাবপতি ও দৃষ্টি দিয়ে বিচার করা হয়।',
        ),
      for (final occupant in occupants)
        ChartEvidence(
          ruleId:
              'vedic.life_area.house_$house.occupant.${occupant.key}.v1',
          outputPath: r'$.planets[?(@.body=="' +
              occupant.key +
              r'")].signIndex',
          kind: EvidenceKind.placement,
          descriptionEn:
              '${_displayPlanetNameEn(occupant.key)} occupies house $house.',
          descriptionBn:
              '${_displayPlanetNameBn(occupant.key)} $house নম্বর ভাবে রয়েছে।',
        ),
      for (final aspector in aspectors)
        ChartEvidence(
          ruleId:
              'vedic.life_area.house_$house.aspect.$aspector.v1',
          outputPath:
              r'$.planets[?(@.body=="' + aspector + r'")].signIndex',
          kind: EvidenceKind.aspect,
          descriptionEn:
              '${_planetNamesEn[aspector]} casts a Parashari full sign aspect on house $house.',
          descriptionBn:
              '${_planetNamesBn[aspector]} $house নম্বর ভাবে পরাশরী পূর্ণ রাশিদৃষ্টি দিচ্ছে।',
        ),
    ];
    final confidence = !hasContradiction &&
            score.abs() >= 3 &&
            evidence.map((value) => value.ruleId).toSet().length >= 3
        ? AnalysisConfidence.high
        : AnalysisConfidence.medium;
    final occupantsEn = occupants.isEmpty
        ? 'No planet occupies the house.'
        : 'Occupants: ${occupants.map((entry) => _displayPlanetNameEn(entry.key)).join(', ')}.';
    final occupantsBn = occupants.isEmpty
        ? 'ভাবটি গ্রহশূন্য।'
        : 'ভাবস্থিত গ্রহ: ${occupants.map((entry) => _displayPlanetNameBn(entry.key)).join(', ')}।';
    final aspectsEn = aspectors.isEmpty
        ? 'No enabled Parashari full sign aspect reaches it.'
        : 'Full sign aspects: ${aspectors.map(_displayPlanetNameEn).join(', ')}.';
    final aspectsBn = aspectors.isEmpty
        ? 'সক্রিয় নিয়মে কোনো পরাশরী পূর্ণ রাশিদৃষ্টি নেই।'
        : 'পূর্ণ রাশিদৃষ্টি: ${aspectors.map(_displayPlanetNameBn).join(', ')}।';
    final supportEn = supportiveEn.isEmpty
        ? 'No independently supportive component is established.'
        : 'Supportive evidence: ${supportiveEn.join('; ')}.';
    final supportBn = supportiveBn.isEmpty
        ? 'স্বতন্ত্র সহায়ক উপাদান প্রতিষ্ঠিত হয়নি।'
        : 'সহায়ক প্রমাণ: ${supportiveBn.join('; ')}।';
    final challengeEn = challengingEn.isEmpty
        ? 'No independently challenging component is established.'
        : 'Challenging evidence: ${challengingEn.join('; ')}.';
    final challengeBn = challengingBn.isEmpty
        ? 'স্বতন্ত্র প্রতিকূল উপাদান প্রতিষ্ঠিত হয়নি।'
        : 'প্রতিকূল প্রমাণ: ${challengingBn.join('; ')}।';
    final reviewTextEn = reviewEn.isEmpty
        ? ''
        : ' Review points: ${reviewEn.join('; ')}.';
    final reviewTextBn = reviewBn.isEmpty
        ? ''
        : ' পর্যালোচনার বিষয়: ${reviewBn.join('; ')}।';
    final contradictionEn = hasContradiction
        ? ' Supportive and challenging rules conflict, so the result remains mixed instead of being flattened into good or bad.'
        : '';
    final contradictionBn = hasContradiction
        ? ' সহায়ক ও প্রতিকূল নিয়ম পরস্পরবিরোধী হওয়ায় ফলকে সরলভাবে ভালো বা খারাপ না বলে মিশ্র রাখা হয়েছে।'
        : '';

    findings.add(
      ChartFinding(
        code: 'vedic.life_area.house_$house.synthesis',
        area: _houseLifeAreas[house - 1],
        polarity: polarity,
        confidence: confidence,
        titleEn:
            'House $house — ${_houseDomainsEn[house - 1]}: integrated ${_polarityEn[polarity]!.toLowerCase()} judgment',
        titleBn:
            '$house নম্বর ভাব — ${_houseDomainsBn[house - 1]}: সমন্বিত ${_polarityBn[polarity]} বিচার',
        narrativeEn:
            'House $house is ${_signNamesEn[signIndex]}, ruled by ${_planetNamesEn[lord]}. The lord occupies house $lordHouse in ${_signNamesEn[lordPosition.signIndex]} with ${_dignityEn[lordDignity]} dignity. $occupantsEn $aspectsEn $supportEn $challengeEn$reviewTextEn The transparent net rule score is $score.$contradictionEn Navamsha, exact aspect strength, the separate Shadbala foundation, dasha and transit are not folded into this house score, so this remains an astrologer-review draft rather than a guaranteed event prediction.',
        narrativeBn:
            '$house নম্বর ভাব ${_signNamesBn[signIndex]} রাশিতে এবং এর অধিপতি ${_planetNamesBn[lord]}। ভাবপতি $lordHouse নম্বর ভাবে ${_signNamesBn[lordPosition.signIndex]} রাশিতে ${_dignityBn[lordDignity]} মর্যাদায় রয়েছে। $occupantsBn $aspectsBn $supportBn $challengeBn$reviewTextBn স্বচ্ছ net rule score $score।$contradictionBn নবাংশ, সুনির্দিষ্ট দৃষ্টিবল, আলাদা ষড়বল foundation, দশা ও গোচর এই ভাব-স্কোরে মেশানো হয়নি; তাই এটি নিশ্চিত ঘটনা নয়, জ্যোতিষীর পর্যালোচনাযোগ্য খসড়া।',
        evidence: evidence,
      ),
    );
  }
  return findings;
}

List<ChartFinding> _buildHouseFindings(
  int ascendantSign,
  Map<String, _ChartPlanet> planets,
) {
  final findings = <ChartFinding>[];
  for (var houseNumber = 1; houseNumber <= 12; houseNumber += 1) {
    final signIndex = (ascendantSign + houseNumber - 1) % 12;
    final lord = _signLords[signIndex]!;
    final lordPosition = planets[lord]!;
    final placedHouse =
        ((lordPosition.signIndex - ascendantSign + 12) % 12) + 1;
    final dignity = _dignity(lord, lordPosition.signIndex);
    final dignityScore = _dignityScore(dignity);
    final placementScore = _placementScore(placedHouse);
    final score = dignityScore + placementScore;
    final polarity = _polarity(score);
    final sameDirection = dignityScore != 0 &&
        placementScore != 0 &&
        dignityScore.sign == placementScore.sign;
    final confidence = sameDirection
        ? AnalysisConfidence.high
        : AnalysisConfidence.medium;
    final role = _functionalRole(ascendantSign, lord);
    final lordEn = _planetNamesEn[lord]!;
    final lordBn = _planetNamesBn[lord]!;
    final signEn = _signNamesEn[signIndex];
    final signBn = _signNamesBn[signIndex];
    final lordSignEn = _signNamesEn[lordPosition.signIndex];
    final lordSignBn = _signNamesBn[lordPosition.signIndex];
    final dignityEn = _dignityEn[dignity]!;
    final dignityBn = _dignityBn[dignity]!;
    final domainEn = _houseDomainsEn[houseNumber - 1];
    final domainBn = _houseDomainsBn[houseNumber - 1];

    findings.add(
      ChartFinding(
        code: 'vedic.house.$houseNumber.condition.$lord',
        area: _houseLifeAreas[houseNumber - 1],
        polarity: polarity,
        confidence: confidence,
        titleEn:
            'House $houseNumber — $domainEn: ${_polarityEn[polarity]}',
        titleBn:
            '$houseNumber নম্বর ভাব — $domainBn: ${_polarityBn[polarity]}',
        narrativeEn:
            'House $houseNumber falls in $signEn and is ruled by $lordEn. $lordEn occupies house $placedHouse in $lordSignEn with $dignityEn dignity. The house-condition score is $score. The lord’s functional ownership tendency is ${_polarityEn[role.polarity]!.toLowerCase()} (score ${role.score}). This is a first-pass assessment of $domainEn; occupancy, aspects, combustion, divisional agreement and dasha are not included.',
        narrativeBn:
            '$houseNumber নম্বর ভাব $signBn রাশিতে এবং এর অধিপতি $lordBn। $lordBn $placedHouse নম্বর ভাবে $lordSignBn রাশিতে $dignityBn মর্যাদায় রয়েছে। ভাব-অবস্থার স্কোর $score। ভাবপতির কার্যকর অধিপত্য প্রবণতা ${_polarityBn[role.polarity]} (স্কোর ${role.score})। এটি $domainBn বিষয়ে প্রথম ধাপের বিচার; ভাবস্থিত গ্রহ, দৃষ্টি, অস্তাঙ্গতা, বিভাগীয় সমর্থন ও দশা অন্তর্ভুক্ত নয়।',
        evidence: [
          ChartEvidence(
            ruleId: 'vedic.house.$houseNumber.lordship.v1',
            outputPath: r'$.ascendant.signIndex',
            kind: EvidenceKind.lordship,
            descriptionEn:
                'Whole-sign house $houseNumber is $signEn, ruled by $lordEn.',
            descriptionBn:
                'হোল-সাইন $houseNumber নম্বর ভাব $signBn, যার অধিপতি $lordBn।',
          ),
          ChartEvidence(
            ruleId: 'vedic.house.$houseNumber.lord_placement.v1',
            outputPath: r'$.planets[?(@.body=="' + lord + r'")].signIndex',
            kind: EvidenceKind.placement,
            descriptionEn:
                '$lordEn, lord of house $houseNumber, is placed in house $placedHouse.',
            descriptionBn:
                '$houseNumber নম্বর ভাবপতি $lordBn $placedHouse নম্বর ভাবে রয়েছে।',
          ),
          ChartEvidence(
            ruleId: 'vedic.house.$houseNumber.lord_dignity.v1',
            outputPath: r'$.planets[?(@.body=="' + lord + r'")].signIndex',
            kind: EvidenceKind.strength,
            descriptionEn:
                '$lordEn has $dignityEn dignity in $lordSignEn.',
            descriptionBn:
                '$lordBn $lordSignBn রাশিতে $dignityBn মর্যাদায় রয়েছে।',
          ),
          ChartEvidence(
            ruleId: 'vedic.functional.$lord.ownership.v1',
            outputPath: r'$.ascendant.signIndex',
            kind: EvidenceKind.lordship,
            descriptionEn:
                '$lordEn owns houses ${role.ownedHouses.join(', ')}; functional tendency score ${role.score}.',
            descriptionBn:
                '$lordBn ${role.ownedHouses.join(', ')} নম্বর ভাবের অধিপতি; কার্যকর প্রবণতার স্কোর ${role.score}।',
          ),
        ],
      ),
    );
  }
  return findings;
}

List<ChartFinding> _buildOccupancyFindings(
  int ascendantSign,
  Map<String, _ChartPlanet> planets,
) {
  final findings = <ChartFinding>[];
  for (var houseNumber = 1; houseNumber <= 12; houseNumber += 1) {
    final occupants = planets.entries
        .where((entry) => _houseOf(ascendantSign, entry.value) == houseNumber)
        .toList(growable: false);
    var roleScore = 0;
    for (final occupant in occupants) {
      if (_planetNamesEn.containsKey(occupant.key)) {
        roleScore += _functionalRole(ascendantSign, occupant.key).score;
      }
    }
    final polarity = occupants.isEmpty
        ? AnalysisPolarity.mixed
        : _polarity(roleScore);
    final namesEn = occupants
        .map((entry) => _displayPlanetNameEn(entry.key))
        .join(', ');
    final namesBn = occupants
        .map((entry) => _displayPlanetNameBn(entry.key))
        .join(', ');
    final domainEn = _houseDomainsEn[houseNumber - 1];
    final domainBn = _houseDomainsBn[houseNumber - 1];
    final emptyEn =
        'No classical planet or lunar node occupies house $houseNumber. An empty house is not automatically weak; its lord and aspects remain decisive.';
    final emptyBn =
        '$houseNumber নম্বর ভাবে কোনো শাস্ত্রীয় গ্রহ বা চন্দ্রনোড নেই। খালি ভাব নিজে থেকে দুর্বল নয়; ভাবপতি ও দৃষ্টি গুরুত্বপূর্ণ।';
    findings.add(
      ChartFinding(
        code: 'vedic.occupancy.house_$houseNumber',
        area: _houseLifeAreas[houseNumber - 1],
        polarity: polarity,
        confidence: AnalysisConfidence.medium,
        titleEn: occupants.isEmpty
            ? 'House $houseNumber occupancy: Empty'
            : 'House $houseNumber occupants: $namesEn',
        titleBn: occupants.isEmpty
            ? '$houseNumber নম্বর ভাব: গ্রহশূন্য'
            : '$houseNumber নম্বর ভাবের গ্রহ: $namesBn',
        narrativeEn: occupants.isEmpty
            ? emptyEn
            : '$namesEn occupy house $houseNumber, associated with $domainEn. The provisional combined functional-ownership score of classical occupants is $roleScore. Occupancy alone does not finalize a result.',
        narrativeBn: occupants.isEmpty
            ? emptyBn
            : '$namesBn $houseNumber নম্বর ভাবে রয়েছে, যা $domainBn নির্দেশ করে। শাস্ত্রীয় ভাবস্থিত গ্রহগুলোর প্রাথমিক সম্মিলিত কার্যকর-অধিপত্য স্কোর $roleScore। শুধু ভাবস্থিতি দিয়ে চূড়ান্ত ফল বলা যায় না।',
        evidence: occupants.isEmpty
            ? [
                ChartEvidence(
                  ruleId: 'vedic.occupancy.house_$houseNumber.empty.v1',
                  outputPath: r'$.planets[*].signIndex',
                  kind: EvidenceKind.placement,
                  descriptionEn:
                      'No listed planet maps to whole-sign house $houseNumber.',
                  descriptionBn:
                      'তালিকাভুক্ত কোনো গ্রহ হোল-সাইন $houseNumber নম্বর ভাবে পড়েনি।',
                ),
              ]
            : [
                for (final occupant in occupants)
                  ChartEvidence(
                    ruleId:
                        'vedic.occupancy.house_$houseNumber.${occupant.key}.v1',
                    outputPath: r'$.planets[?(@.body=="' +
                        occupant.key +
                        r'")].signIndex',
                    kind: EvidenceKind.placement,
                    descriptionEn:
                        '${_displayPlanetNameEn(occupant.key)} occupies whole-sign house $houseNumber.',
                    descriptionBn:
                        '${_displayPlanetNameBn(occupant.key)} হোল-সাইন $houseNumber নম্বর ভাবে রয়েছে।',
                  ),
              ],
      ),
    );
  }
  return findings;
}

List<ChartFinding> _buildAspectFindings(
  int ascendantSign,
  Map<String, _ChartPlanet> planets,
) {
  final findings = <ChartFinding>[];
  for (final entry in _aspectRules.entries) {
    final planet = entry.key;
    final position = planets[planet]!;
    final sourceHouse = _houseOf(ascendantSign, position);
    final role = _functionalRole(ascendantSign, planet);
    for (final rule in entry.value) {
      final targetHouse = ((sourceHouse + rule.houseCount - 2) % 12) + 1;
      final targetOccupants = planets.entries
          .where((value) =>
              _houseOf(ascendantSign, value.value) == targetHouse)
          .map((value) => _displayPlanetNameEn(value.key))
          .toList(growable: false);
      final targetOccupantsBn = planets.entries
          .where((value) =>
              _houseOf(ascendantSign, value.value) == targetHouse)
          .map((value) => _displayPlanetNameBn(value.key))
          .toList(growable: false);
      final planetEn = _planetNamesEn[planet]!;
      final planetBn = _planetNamesBn[planet]!;
      final targetEn = targetOccupants.isEmpty
          ? 'no resident planet'
          : targetOccupants.join(', ');
      final targetBn = targetOccupantsBn.isEmpty
          ? 'কোনো ভাবস্থিত গ্রহ নেই'
          : targetOccupantsBn.join(', ');
      findings.add(
        ChartFinding(
          code:
              'vedic.aspect.$planet.${rule.houseCount}th.house_$targetHouse',
          area: _houseLifeAreas[targetHouse - 1],
          polarity: role.polarity,
          confidence: AnalysisConfidence.medium,
          titleEn:
              '$planetEn ${rule.labelEn} aspect to house $targetHouse',
          titleBn:
              '$planetBn-এর ${rule.labelBn} দৃষ্টি $targetHouse নম্বর ভাবে',
          narrativeEn:
              '$planetEn in house $sourceHouse casts its ${rule.labelEn} full sign aspect on house $targetHouse (${_houseDomainsEn[targetHouse - 1]}), containing $targetEn. Its provisional functional tendency is ${_polarityEn[role.polarity]!.toLowerCase()}. Aspect strength and synthesis with the aspected house lord are not included yet.',
          narrativeBn:
              '$sourceHouse নম্বর ভাবের $planetBn তার ${rule.labelBn} পূর্ণ রাশিদৃষ্টি $targetHouse নম্বর ভাবে (${_houseDomainsBn[targetHouse - 1]}) দিচ্ছে; সেখানে $targetBn। গ্রহটির প্রাথমিক কার্যকর প্রবণতা ${_polarityBn[role.polarity]}। দৃষ্টিবল ও দৃষ্ট ভাবপতির সঙ্গে সম্মিলিত বিচার এখনো অন্তর্ভুক্ত নয়।',
          evidence: [
            ChartEvidence(
              ruleId:
                  'vedic.aspect.$planet.${rule.houseCount}th.full_sign.v1',
              outputPath: r'$.planets[?(@.body=="' +
                  planet +
                  r'")].signIndex',
              kind: EvidenceKind.aspect,
              descriptionEn:
                  '$planetEn in house $sourceHouse has a full ${rule.labelEn} sign aspect to house $targetHouse.',
              descriptionBn:
                  '$sourceHouse নম্বর ভাবের $planetBn-এর ${rule.labelBn} পূর্ণ রাশিদৃষ্টি $targetHouse নম্বর ভাবে পড়ছে।',
            ),
          ],
        ),
      );
    }
  }
  return findings;
}

List<ChartFinding> _buildAspectSynthesisFindings(
  int ascendantSign,
  Map<String, _ChartPlanet> planets,
) {
  final aspectorsByHouse = <int, Set<String>>{};
  for (final entry in _aspectRules.entries) {
    final sourceHouse = _houseOf(ascendantSign, planets[entry.key]!);
    for (final rule in entry.value) {
      final targetHouse = ((sourceHouse + rule.houseCount - 2) % 12) + 1;
      aspectorsByHouse.putIfAbsent(targetHouse, () => <String>{})
        ..add(entry.key);
    }
  }
  final findings = <ChartFinding>[];
  for (var house = 1; house <= 12; house += 1) {
    final aspectors = aspectorsByHouse[house]?.toList(growable: false)
      ?..sort();
    if (aspectors == null || aspectors.length < 2) continue;
    final roles = {
      for (final planet in aspectors)
        planet: _functionalRole(ascendantSign, planet),
    };
    final hasSupportive = roles.values
        .any((role) => role.polarity == AnalysisPolarity.supportive);
    final hasChallenging = roles.values
        .any((role) => role.polarity == AnalysisPolarity.challenging);
    final polarity = hasSupportive && hasChallenging
        ? AnalysisPolarity.mixed
        : hasSupportive
            ? AnalysisPolarity.supportive
            : hasChallenging
                ? AnalysisPolarity.challenging
                : AnalysisPolarity.mixed;
    final namesEn = aspectors.map(_displayPlanetNameEn).join(', ');
    final namesBn = aspectors.map(_displayPlanetNameBn).join(', ');
    findings.add(
      ChartFinding(
        code: 'vedic.aspect_synthesis.house_$house',
        area: _houseLifeAreas[house - 1],
        polarity: polarity,
        confidence: AnalysisConfidence.medium,
        titleEn:
            'House $house multi-aspect synthesis: ${_polarityEn[polarity]}',
        titleBn:
            '$house নম্বর ভাবের বহু-দৃষ্টি বিচার: ${_polarityBn[polarity]}',
        narrativeEn:
            '$namesEn cast full sign aspects on house $house. Their functional ownership tendencies produce a ${_polarityEn[polarity]!.toLowerCase()} first-pass synthesis. Exact aspect strength, the house lord and divisional agreement can modify it.',
        narrativeBn:
            '$namesBn $house নম্বর ভাবে পূর্ণ রাশিদৃষ্টি দিচ্ছে। তাদের কার্যকর অধিপত্য প্রবণতা মিলিয়ে প্রথম ধাপের ফল ${_polarityBn[polarity]}। সুনির্দিষ্ট দৃষ্টিবল, ভাবপতি ও বিভাগীয় সমর্থনে ফল বদলাতে পারে।',
        evidence: [
          for (final planet in aspectors)
            ChartEvidence(
              ruleId: 'vedic.aspect_synthesis.$planet.house_$house.v1',
              outputPath: r'$.planets[?(@.body=="' +
                  planet +
                  r'")].signIndex',
              kind: EvidenceKind.aspect,
              descriptionEn:
                  '${_displayPlanetNameEn(planet)} aspects house $house; functional tendency ${_polarityEn[roles[planet]!.polarity]!.toLowerCase()} (score ${roles[planet]!.score}).',
              descriptionBn:
                  '${_displayPlanetNameBn(planet)} $house নম্বর ভাবে দৃষ্টি দেয়; কার্যকর প্রবণতা ${_polarityBn[roles[planet]!.polarity]} (স্কোর ${roles[planet]!.score})।',
            ),
        ],
      ),
    );
  }
  return findings;
}

List<ChartFinding> _buildConjunctionFindings(
  int ascendantSign,
  Map<String, _ChartPlanet> planets,
) {
  final entries = planets.entries.toList(growable: false);
  final findings = <ChartFinding>[];
  for (var firstIndex = 0; firstIndex < entries.length; firstIndex += 1) {
    for (var secondIndex = firstIndex + 1;
        secondIndex < entries.length;
        secondIndex += 1) {
      final first = entries[firstIndex];
      final second = entries[secondIndex];
      if (first.value.signIndex != second.value.signIndex) continue;
      final firstClassical = _planetNamesEn.containsKey(first.key);
      final secondClassical = _planetNamesEn.containsKey(second.key);
      var polarity = AnalysisPolarity.mixed;
      if (firstClassical && secondClassical) {
        final firstPolarity =
            _functionalRole(ascendantSign, first.key).polarity;
        final secondPolarity =
            _functionalRole(ascendantSign, second.key).polarity;
        if (firstPolarity == AnalysisPolarity.supportive &&
            secondPolarity == AnalysisPolarity.supportive) {
          polarity = AnalysisPolarity.supportive;
        } else if (firstPolarity == AnalysisPolarity.challenging &&
            secondPolarity == AnalysisPolarity.challenging) {
          polarity = AnalysisPolarity.challenging;
        }
      }
      final separation = _angularSeparation(
        first.value.siderealLongitude,
        second.value.siderealLongitude,
      );
      final firstEn = _displayPlanetNameEn(first.key);
      final secondEn = _displayPlanetNameEn(second.key);
      final firstBn = _displayPlanetNameBn(first.key);
      final secondBn = _displayPlanetNameBn(second.key);
      final house = _houseOf(ascendantSign, first.value);
      findings.add(
        ChartFinding(
          code: 'vedic.conjunction.${first.key}.${second.key}',
          area: _houseLifeAreas[house - 1],
          polarity: polarity,
          confidence: AnalysisConfidence.medium,
          titleEn: '$firstEn–$secondEn same-sign conjunction',
          titleBn: '$firstBn–$secondBn একই-রাশির সংযোগ',
          narrativeEn:
              '$firstEn and $secondEn occupy ${_signNamesEn[first.value.signIndex]} in house $house, separated by ${separation.toStringAsFixed(3)}°. This first-pass conjunction synthesis is ${_polarityEn[polarity]!.toLowerCase()}; exact orb effects and any planetary-war flag are judged separately.',
          narrativeBn:
              '$firstBn ও $secondBn $house নম্বর ভাবে ${_signNamesBn[first.value.signIndex]} রাশিতে রয়েছে; কৌণিক দূরত্ব ${separation.toStringAsFixed(3)}°। প্রথম ধাপের সংযোগ বিচার ${_polarityBn[polarity]}; সুনির্দিষ্ট অরবের ফল ও গ্রহযুদ্ধ বিচার করা হয়নি।',
          evidence: [
            ChartEvidence(
              ruleId:
                  'vedic.conjunction.${first.key}.${second.key}.same_sign.v1',
              outputPath: r'$.planets[*].signIndex',
              kind: EvidenceKind.placement,
              descriptionEn:
                  '$firstEn and $secondEn share sign index ${first.value.signIndex}; separation ${separation.toStringAsFixed(3)}°.',
              descriptionBn:
                  '$firstBn ও $secondBn একই ${first.value.signIndex} রাশি-সূচকে; দূরত্ব ${separation.toStringAsFixed(3)}°।',
            ),
          ],
        ),
      );
    }
  }
  return findings;
}

List<ChartFinding> _buildFriendshipFindings(
  Map<String, _ChartPlanet> planets,
) {
  final findings = <ChartFinding>[];
  for (final planet in _planetNamesEn.keys) {
    final position = planets[planet]!;
    final dispositor = _signLords[position.signIndex]!;
    final relationship = planet == dispositor
        ? _NaturalRelationship.own
        : _naturalFriends[planet]!.contains(dispositor)
            ? _NaturalRelationship.friend
            : _naturalEnemies[planet]!.contains(dispositor)
                ? _NaturalRelationship.enemy
                : _NaturalRelationship.neutral;
    final polarity = switch (relationship) {
      _NaturalRelationship.friend || _NaturalRelationship.own =>
        AnalysisPolarity.supportive,
      _NaturalRelationship.enemy => AnalysisPolarity.challenging,
      _NaturalRelationship.neutral => AnalysisPolarity.mixed,
    };
    final planetEn = _planetNamesEn[planet]!;
    final planetBn = _planetNamesBn[planet]!;
    final hostEn = _planetNamesEn[dispositor]!;
    final hostBn = _planetNamesBn[dispositor]!;
    findings.add(
      ChartFinding(
        code: 'vedic.friendship.$planet.$dispositor',
        area: LifeArea.overall,
        polarity: polarity,
        confidence: AnalysisConfidence.medium,
        titleEn:
            '$planetEn in ${_naturalRelationshipEn[relationship]} territory',
        titleBn:
            '$planetBn ${_naturalRelationshipBn[relationship]} রাশিক্ষেত্রে',
        narrativeEn:
            '$planetEn occupies ${_signNamesEn[position.signIndex]}, ruled by $hostEn. Its permanent natural relationship toward the dispositor is ${_naturalRelationshipEn[relationship]}. Temporary and compound friendship are reported separately.',
        narrativeBn:
            '$planetBn ${_signNamesBn[position.signIndex]} রাশিতে রয়েছে, যার অধিপতি $hostBn। রাশিপতির প্রতি এর স্থায়ী নৈসর্গিক সম্পর্ক ${_naturalRelationshipBn[relationship]}। তৎকালিক ও পঞ্চধা মৈত্রী অন্তর্ভুক্ত নয়।',
        evidence: [
          ChartEvidence(
            ruleId: 'vedic.friendship.$planet.$dispositor.permanent.v1',
            outputPath: r'$.planets[?(@.body=="' + planet + r'")].signIndex',
            kind: EvidenceKind.strength,
            descriptionEn:
                '${_signNamesEn[position.signIndex]} is ruled by $hostEn; $planetEn regards $hostEn as ${_naturalRelationshipEn[relationship]}.',
            descriptionBn:
                '${_signNamesBn[position.signIndex]}-এর অধিপতি $hostBn; $planetBn-এর দৃষ্টিতে $hostBn ${_naturalRelationshipBn[relationship]}।',
          ),
        ],
      ),
    );
  }
  return findings;
}

List<ChartFinding> _buildCompoundFriendshipFindings(
  Map<String, _ChartPlanet> planets,
) {
  final findings = <ChartFinding>[];
  for (final planet in _planetNamesEn.keys) {
    final position = planets[planet]!;
    final dispositor = _signLords[position.signIndex]!;
    if (planet == dispositor) continue;
    final dispositorPosition = planets[dispositor]!;
    final natural = _naturalFriends[planet]!.contains(dispositor)
        ? _NaturalRelationship.friend
        : _naturalEnemies[planet]!.contains(dispositor)
            ? _NaturalRelationship.enemy
            : _NaturalRelationship.neutral;
    final relativeHouse =
        ((dispositorPosition.signIndex - position.signIndex + 12) % 12) + 1;
    final temporaryFriend = _temporaryFriendHouses.contains(relativeHouse);
    final compound = _compoundRelationship(natural, temporaryFriend);
    final polarity = switch (compound) {
      _CompoundRelationship.greatFriend ||
      _CompoundRelationship.friend =>
        AnalysisPolarity.supportive,
      _CompoundRelationship.greatEnemy ||
      _CompoundRelationship.enemy =>
        AnalysisPolarity.challenging,
      _CompoundRelationship.neutral => AnalysisPolarity.mixed,
    };
    final planetEn = _planetNamesEn[planet]!;
    final planetBn = _planetNamesBn[planet]!;
    final hostEn = _planetNamesEn[dispositor]!;
    final hostBn = _planetNamesBn[dispositor]!;
    final temporaryEn = temporaryFriend ? 'friend' : 'enemy';
    final temporaryBn = temporaryFriend ? 'মিত্র' : 'শত্রু';
    findings.add(
      ChartFinding(
        code: 'vedic.compound_friendship.$planet.$dispositor',
        area: LifeArea.overall,
        polarity: polarity,
        confidence: AnalysisConfidence.medium,
        titleEn:
            '$planetEn–$hostEn compound relation: ${_compoundRelationshipEn[compound]}',
        titleBn:
            '$planetBn–$hostBn পঞ্চধা সম্পর্ক: ${_compoundRelationshipBn[compound]}',
        narrativeEn:
            '$hostEn is in the $relativeHouse${_ordinalSuffix(relativeHouse)} sign from $planetEn, making the temporary relationship $temporaryEn. Combining it with the ${_naturalRelationshipEn[natural]} natural relationship gives ${_compoundRelationshipEn[compound]}. Own-sign placements remain separately labelled own.',
        narrativeBn:
            '$planetBn থেকে $hostBn $relativeHouse নম্বর রাশিতে থাকায় তৎকালিক সম্পর্ক $temporaryBn। ${_naturalRelationshipBn[natural]} নৈসর্গিক সম্পর্কের সঙ্গে মিলিয়ে পঞ্চধা ফল ${_compoundRelationshipBn[compound]}। স্বক্ষেত্র অবস্থান আলাদাভাবে নিজ ক্ষেত্র হিসেবে দেখানো হয়।',
        evidence: [
          ChartEvidence(
            ruleId:
                'vedic.temporary_friendship.$planet.$dispositor.house_$relativeHouse.v1',
            outputPath: r'$.planets[*].signIndex',
            kind: EvidenceKind.strength,
            descriptionEn:
                '$hostEn is $relativeHouse signs from $planetEn; temporary relationship $temporaryEn.',
            descriptionBn:
                '$planetBn থেকে $hostBn $relativeHouse রাশি দূরে; তৎকালিক সম্পর্ক $temporaryBn।',
          ),
          ChartEvidence(
            ruleId:
                'vedic.compound_friendship.$planet.$dispositor.combine.v1',
            outputPath: r'$.planets[*].signIndex',
            kind: EvidenceKind.strength,
            descriptionEn:
                'Natural ${_naturalRelationshipEn[natural]} + temporary $temporaryEn = ${_compoundRelationshipEn[compound]}.',
            descriptionBn:
                'নৈসর্গিক ${_naturalRelationshipBn[natural]} + তৎকালিক $temporaryBn = ${_compoundRelationshipBn[compound]}।',
          ),
        ],
      ),
    );
  }
  return findings;
}

_CompoundRelationship _compoundRelationship(
  _NaturalRelationship natural,
  bool temporaryFriend,
) {
  if (temporaryFriend) {
    return switch (natural) {
      _NaturalRelationship.friend => _CompoundRelationship.greatFriend,
      _NaturalRelationship.neutral => _CompoundRelationship.friend,
      _NaturalRelationship.enemy => _CompoundRelationship.neutral,
      _NaturalRelationship.own => _CompoundRelationship.greatFriend,
    };
  }
  return switch (natural) {
    _NaturalRelationship.friend => _CompoundRelationship.neutral,
    _NaturalRelationship.neutral => _CompoundRelationship.enemy,
    _NaturalRelationship.enemy => _CompoundRelationship.greatEnemy,
    _NaturalRelationship.own => _CompoundRelationship.neutral,
  };
}

String _ordinalSuffix(int value) {
  if (value >= 11 && value <= 13) return 'th';
  return switch (value % 10) { 1 => 'st', 2 => 'nd', 3 => 'rd', _ => 'th' };
}

List<ChartFinding> _buildMoolatrikonaFindings(
  Map<String, _ChartPlanet> planets,
) {
  final findings = <ChartFinding>[];
  for (final entry in _moolatrikonaRanges.entries) {
    final planet = entry.key;
    final range = entry.value;
    final position = planets[planet]!;
    final degree = position.siderealLongitude % 30.0;
    if (position.signIndex != range.signIndex ||
        degree < range.startDegree ||
        degree >= range.endDegree) {
      continue;
    }
    final planetEn = _planetNamesEn[planet]!;
    final planetBn = _planetNamesBn[planet]!;
    findings.add(
      ChartFinding(
        code: 'vedic.moolatrikona.$planet',
        area: LifeArea.overall,
        polarity: AnalysisPolarity.supportive,
        confidence: AnalysisConfidence.medium,
        titleEn: '$planetEn in Moolatrikona range',
        titleBn: '$planetBn মূলত্রিকোণ সীমায়',
        narrativeEn:
            '$planetEn is at ${degree.toStringAsFixed(3)}° within ${_signNamesEn[position.signIndex]}, inside the versioned Moolatrikona interval [${range.startDegree.toStringAsFixed(0)}°, ${range.endDegree.toStringAsFixed(0)}°). This is recorded separately from broad sign dignity.',
        narrativeBn:
            '$planetBn ${_signNamesBn[position.signIndex]} রাশির ${degree.toStringAsFixed(3)}°-এ, versioned মূলত্রিকোণ সীমা [${range.startDegree.toStringAsFixed(0)}°, ${range.endDegree.toStringAsFixed(0)}°)-এর মধ্যে। এটি সাধারণ রাশি-মর্যাদা থেকে আলাদাভাবে নথিভুক্ত।',
        evidence: [
          ChartEvidence(
            ruleId: 'vedic.moolatrikona.$planet.degree_range.v1',
            outputPath: r'$.planets[?(@.body=="' +
                planet +
                r'")].siderealLongitude',
            kind: EvidenceKind.strength,
            descriptionEn:
                '$planetEn degree-in-sign ${degree.toStringAsFixed(3)}° matches [${range.startDegree}°, ${range.endDegree}°).',
            descriptionBn:
                '$planetBn-এর রাশির ভিতরের ডিগ্রি ${degree.toStringAsFixed(3)}°, যা [${range.startDegree}°, ${range.endDegree}°)-এর মধ্যে।',
          ),
        ],
      ),
    );
  }
  return findings;
}

List<ChartFinding> _buildPlanetaryWarFindings(
  int ascendantSign,
  Map<String, _ChartPlanet> planets,
) {
  final findings = <ChartFinding>[];
  for (var firstIndex = 0;
      firstIndex < _planetaryWarBodies.length;
      firstIndex += 1) {
    for (var secondIndex = firstIndex + 1;
        secondIndex < _planetaryWarBodies.length;
        secondIndex += 1) {
      final first = _planetaryWarBodies[firstIndex];
      final second = _planetaryWarBodies[secondIndex];
      final firstPosition = planets[first]!;
      final secondPosition = planets[second]!;
      final separation = _angularSeparation(
        firstPosition.siderealLongitude,
        secondPosition.siderealLongitude,
      );
      if (separation > _planetaryWarReviewThreshold) continue;
      final firstEn = _planetNamesEn[first]!;
      final secondEn = _planetNamesEn[second]!;
      final firstBn = _planetNamesBn[first]!;
      final secondBn = _planetNamesBn[second]!;
      final house = _houseOf(ascendantSign, firstPosition);
      final firstLatitude = firstPosition.eclipticLatitude;
      final secondLatitude = secondPosition.eclipticLatitude;
      final hasLatitude = firstLatitude != null && secondLatitude != null;
      final latitudeWinner = !hasLatitude ||
              (firstLatitude! - secondLatitude!).abs() <= 1e-9
          ? null
          : (firstLatitude > secondLatitude ? first : second);
      final winnerEn = latitudeWinner == null
          ? null
          : _planetNamesEn[latitudeWinner]!;
      final winnerBn = latitudeWinner == null
          ? null
          : _planetNamesBn[latitudeWinner]!;
      findings.add(
        ChartFinding(
          code: 'vedic.planetary_war.$first.$second',
          area: _houseLifeAreas[house - 1],
          polarity: AnalysisPolarity.mixed,
          confidence: AnalysisConfidence.medium,
          titleEn: '$firstEn–$secondEn planetary-war review',
          titleBn: '$firstBn–$secondBn গ্রহযুদ্ধ পর্যালোচনা',
          narrativeEn: hasLatitude
              ? '$firstEn and $secondEn are separated by ${separation.toStringAsFixed(3)}°, within the versioned ${_planetaryWarReviewThreshold.toStringAsFixed(1)}° review threshold. Persisted ecliptic latitudes are ${firstLatitude!.toStringAsFixed(3)}° and ${secondLatitude!.toStringAsFixed(3)}°; ${winnerEn == null ? 'the latitude tie keeps the computational victor unresolved' : '$winnerEn is the northern-latitude computational victor used only by Shadbala Yuddha correction'}. This remains a review signal, not an event guarantee.'
              : '$firstEn and $secondEn are separated by ${separation.toStringAsFixed(3)}°, within the versioned ${_planetaryWarReviewThreshold.toStringAsFixed(1)}° review threshold. This legacy output lacks persisted ecliptic latitude, so no computational victor is declared.',
          narrativeBn: hasLatitude
              ? '$firstBn ও $secondBn-এর কৌণিক দূরত্ব ${separation.toStringAsFixed(3)}°, যা versioned ${_planetaryWarReviewThreshold.toStringAsFixed(1)}° পর্যালোচনা সীমার মধ্যে। persisted ecliptic latitude যথাক্রমে ${firstLatitude!.toStringAsFixed(3)}° ও ${secondLatitude!.toStringAsFixed(3)}°; ${winnerBn == null ? 'latitude tie থাকায় computational victor অনির্ধারিত' : '$winnerBn কেবল Shadbala যুদ্ধবল correction-এর northern-latitude computational victor'}। এটি review signal, নিশ্চিত ঘটনা নয়।'
              : '$firstBn ও $secondBn-এর কৌণিক দূরত্ব ${separation.toStringAsFixed(3)}°, যা versioned ${_planetaryWarReviewThreshold.toStringAsFixed(1)}° পর্যালোচনা সীমার মধ্যে। এই legacy output-এ persisted ecliptic latitude নেই, তাই computational victor ঘোষণা করা হয় না।',
          evidence: [
            ChartEvidence(
              ruleId: 'vedic.planetary_war.$first.$second.proximity.v2',
              outputPath: hasLatitude
                  ? r'$.planets[*].eclipticLatitude'
                  : r'$.planets[*].siderealLongitude',
              kind: EvidenceKind.strength,
              descriptionEn: hasLatitude
                  ? '$firstEn–$secondEn separation ${separation.toStringAsFixed(3)}°; ecliptic latitudes ${firstLatitude!.toStringAsFixed(3)}°/${secondLatitude!.toStringAsFixed(3)}°.'
                  : '$firstEn–$secondEn circular longitude separation ${separation.toStringAsFixed(3)}°.',
              descriptionBn: hasLatitude
                  ? '$firstBn–$secondBn দূরত্ব ${separation.toStringAsFixed(3)}°; ecliptic latitude ${firstLatitude!.toStringAsFixed(3)}°/${secondLatitude!.toStringAsFixed(3)}°।'
                  : '$firstBn–$secondBn বৃত্তীয় দ্রাঘিমা দূরত্ব ${separation.toStringAsFixed(3)}°।',
            ),
          ],
        ),
      );
    }
  }
  return findings;
}

List<ChartFinding> _buildPlanetConditionFindings(
  Map<String, _ChartPlanet> planets,
) {
  final findings = <ChartFinding>[];
  final sun = planets['sun']!;
  for (final planet in _combustionBodies) {
    final position = planets[planet]!;
    final threshold = _combustionThreshold(planet, position.retrograde);
    final separation = _angularSeparation(
      sun.siderealLongitude,
      position.siderealLongitude,
    );
    if (separation <= threshold) {
      final planetEn = _planetNamesEn[planet]!;
      final planetBn = _planetNamesBn[planet]!;
      findings.add(
        ChartFinding(
          code: 'vedic.condition.combust.$planet',
          area: LifeArea.overall,
          polarity: AnalysisPolarity.challenging,
          confidence: AnalysisConfidence.medium,
          titleEn: '$planetEn combustion review',
          titleBn: '$planetBn অস্তাঙ্গতা পর্যালোচনা',
          narrativeEn:
              '$planetEn is ${separation.toStringAsFixed(3)}° from the Sun, inside the versioned ${threshold.toStringAsFixed(1)}° combustion threshold. This can reduce independent expression, but dignity, house role, retrograde state and relevant yogas can modify the result; the planet is not treated as destroyed.',
          narrativeBn:
              '$planetBn সূর্য থেকে ${separation.toStringAsFixed(3)}° দূরে, যা versioned ${threshold.toStringAsFixed(1)}° অস্তাঙ্গতার সীমার মধ্যে। এতে স্বাধীন প্রকাশ কমতে পারে, তবে মর্যাদা, ভাবগত ভূমিকা, বক্রী অবস্থা ও সংশ্লিষ্ট যোগ ফল বদলাতে পারে; গ্রহটিকে নষ্ট বলে ধরা হয় না।',
          evidence: [
            ChartEvidence(
              ruleId: 'vedic.condition.combust.$planet.v1',
              outputPath: r'$.planets[*].siderealLongitude',
              kind: EvidenceKind.strength,
              descriptionEn:
                  'Sun–$planetEn angular separation ${separation.toStringAsFixed(3)}°; threshold ${threshold.toStringAsFixed(1)}°.',
              descriptionBn:
                  'সূর্য–$planetBn কৌণিক দূরত্ব ${separation.toStringAsFixed(3)}°; সীমা ${threshold.toStringAsFixed(1)}°।',
            ),
          ],
        ),
      );
    }
  }
  for (final planet in _retrogradeBodies) {
    final position = planets[planet]!;
    if (!position.retrograde) continue;
    final planetEn = _planetNamesEn[planet]!;
    final planetBn = _planetNamesBn[planet]!;
    findings.add(
      ChartFinding(
        code: 'vedic.condition.retrograde.$planet',
        area: LifeArea.overall,
        polarity: AnalysisPolarity.mixed,
        confidence: AnalysisConfidence.medium,
        titleEn: '$planetEn is retrograde',
        titleBn: '$planetBn বক্রী',
        narrativeEn:
            '$planetEn has negative longitudinal speed at birth. The engine marks this as an intensified/review condition, not as automatically favourable or unfavourable.',
        narrativeBn:
            'জন্মসময়ে $planetBn-এর দ্রাঘিমাগত গতি ঋণাত্মক। ইঞ্জিন এটিকে তীব্রতা/পর্যালোচনার অবস্থা হিসেবে দেখায়, নিজে থেকে শুভ বা অশুভ বলে না।',
        evidence: [
          ChartEvidence(
            ruleId: 'vedic.condition.retrograde.$planet.v1',
            outputPath: r'$.planets[?(@.body=="' +
                planet +
                r'")].retrograde',
            kind: EvidenceKind.strength,
            descriptionEn:
                '$planetEn is marked retrograde in the verified calculation output.',
            descriptionBn:
                'যাচাইকৃত গণনার ফলে $planetBn-কে বক্রী হিসেবে চিহ্নিত করা হয়েছে।',
          ),
        ],
      ),
    );
  }
  return findings;
}

List<ChartFinding> _buildFunctionalRoleFindings(int ascendantSign) {
  final findings = <ChartFinding>[];
  for (final planet in _planetNamesEn.keys) {
    final role = _functionalRole(ascendantSign, planet);
    final planetEn = _planetNamesEn[planet]!;
    final planetBn = _planetNamesBn[planet]!;
    final ownedEn = role.ownedHouses.join(', ');
    final ownedBn = role.ownedHouses.join(', ');
    final yogaEn = role.yogaKaraka
        ? ' It simultaneously owns a Kendra and a Trikona (Yoga-karaka flag).'
        : '';
    final yogaBn = role.yogaKaraka
        ? ' এটি একই সঙ্গে একটি কেন্দ্র ও একটি ত্রিকোণ ভাবের অধিপতি (যোগকারক সংকেত)।'
        : '';
    findings.add(
      ChartFinding(
        code: 'vedic.functional_role.$planet',
        area: LifeArea.overall,
        polarity: role.polarity,
        confidence: AnalysisConfidence.medium,
        titleEn:
            '$planetEn functional tendency: ${_polarityEn[role.polarity]}',
        titleBn:
            '$planetBn-এর কার্যকর প্রবণতা: ${_polarityBn[role.polarity]}',
        narrativeEn:
            '$planetEn owns houses $ownedEn for this ascendant. The transparent ownership score is ${role.score}.$yogaEn This label is provisional until Parashari exceptions, associations and yogas are reviewed.',
        narrativeBn:
            'এই লগ্নে $planetBn $ownedBn নম্বর ভাবের অধিপতি। স্বচ্ছ অধিপত্য স্কোর ${role.score}।$yogaBn পরাশরী ব্যতিক্রম, সংযোগ ও যোগ যাচাই না হওয়া পর্যন্ত এই লেবেল প্রাথমিক।',
        evidence: [
          for (final ownedHouse in role.ownedHouses)
            ChartEvidence(
              ruleId:
                  'vedic.functional.$planet.house_$ownedHouse.ownership.v1',
              outputPath: r'$.ascendant.signIndex',
              kind: EvidenceKind.lordship,
              descriptionEn:
                  '$planetEn owns whole-sign house $ownedHouse for this ascendant.',
              descriptionBn:
                  'এই লগ্নে $planetBn হোল-সাইন $ownedHouse নম্বর ভাবের অধিপতি।',
            ),
        ],
      ),
    );
  }
  return findings;
}

int _houseOf(int ascendantSign, _ChartPlanet planet) =>
    ((planet.signIndex - ascendantSign + 12) % 12) + 1;

bool _castsFullAspectOnSign(
  String planet,
  int targetSign,
  Map<String, _ChartPlanet> planets,
) {
  final sourceSign = planets[planet]!.signIndex;
  final relativeHouse = ((targetSign - sourceSign + 12) % 12) + 1;
  return _aspectRules[planet]!
      .any((rule) => rule.houseCount == relativeHouse);
}

_StrengthReview _participantStrengthReview(
  List<String> participants,
  Map<String, _ChartPlanet> planets,
) {
  final issuesEn = <String>[];
  final issuesBn = <String>[];
  final sun = planets['sun']!;
  for (final planet in participants.toSet()) {
    final position = planets[planet]!;
    if (_dignity(planet, position.signIndex) == _Dignity.debilitated) {
      issuesEn.add('${_planetNamesEn[planet]} is debilitated');
      issuesBn.add('${_planetNamesBn[planet]} নীচ রাশিতে');
    }
    if (planet != 'sun') {
      final separation = _angularSeparation(
        sun.siderealLongitude,
        position.siderealLongitude,
      );
      if (separation <=
          _combustionThreshold(planet, position.retrograde)) {
        issuesEn.add('${_planetNamesEn[planet]} is combust');
        issuesBn.add('${_planetNamesBn[planet]} অস্তাঙ্গ');
      }
    }
  }
  return _StrengthReview(
    hasChallenge: issuesEn.isNotEmpty,
    textEn: issuesEn.isEmpty
        ? 'No enabled debilitation or combustion flag challenges the participants.'
        : 'Strength review: ${issuesEn.join('; ')}.',
    textBn: issuesBn.isEmpty
        ? 'সক্রিয় নিয়মে অংশগ্রহণকারী গ্রহগুলির নীচতা বা অস্তাঙ্গতার চ্যালেঞ্জ নেই।'
        : 'বল পর্যালোচনা: ${issuesBn.join('; ')}।',
  );
}

String _displayPlanetNameEn(String planet) =>
    _planetNamesEn[planet] ?? _nodeNamesEn[planet] ?? planet;

String _displayPlanetNameBn(String planet) =>
    _planetNamesBn[planet] ?? _nodeNamesBn[planet] ?? planet;

double _combustionThreshold(String planet, bool retrograde) =>
    switch (planet) {
      'moon' => 12.0,
      'mars' => retrograde ? 8.0 : 17.0,
      'mercury' => retrograde ? 12.0 : 14.0,
      'jupiter' => 11.0,
      'venus' => retrograde ? 8.0 : 10.0,
      'saturn' => 16.0,
      _ => throw ArgumentError.value(planet, 'planet'),
    };

double _angularSeparation(double first, double second) {
  final direct = (first - second).abs();
  return direct <= 180.0 ? direct : 360.0 - direct;
}

_FunctionalRole _functionalRole(int ascendantSign, String planet) {
  final ownedHouses = <int>[];
  var score = 0;
  for (var houseNumber = 1; houseNumber <= 12; houseNumber += 1) {
    final signIndex = (ascendantSign + houseNumber - 1) % 12;
    if (_signLords[signIndex] == planet) {
      ownedHouses.add(houseNumber);
      score += _ownershipScores[houseNumber]!;
    }
  }
  final yogaKaraka = ownedHouses.any(_kendraForYoga.contains) &&
      ownedHouses.any(_trikonaForYoga.contains);
  if (yogaKaraka) score += 1;
  return _FunctionalRole(
    ownedHouses: ownedHouses,
    score: score,
    yogaKaraka: yogaKaraka,
    polarity: _polarity(score),
  );
}

int _dignityScore(_Dignity dignity) => switch (dignity) {
      _Dignity.exalted => 2,
      _Dignity.ownSign => 1,
      _Dignity.debilitated => -2,
      _Dignity.neutral => 0,
    };

int _placementScore(int house) => _supportiveHouses.contains(house)
    ? 1
    : _challengingHouses.contains(house)
        ? -1
        : 0;

AnalysisPolarity _polarity(int score) => score >= 2
    ? AnalysisPolarity.supportive
    : score <= -2
        ? AnalysisPolarity.challenging
        : AnalysisPolarity.mixed;
