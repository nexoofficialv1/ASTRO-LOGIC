import '../models/calculation_output_snapshot.dart';
import '../models/kundli_analysis.dart';

/// Bounded, source-versioned advanced Yoga/Dosha formation review.
///
/// This engine deliberately keeps structural formation, weakening evidence,
/// cancellation evidence and multi-yoga synthesis separate. It does not turn
/// a formation into a guaranteed event prediction and never emits High
/// confidence.
class VedicAdvancedYogaDoshaEngine {
  const VedicAdvancedYogaDoshaEngine();

  static const engineVersion = '1.0.0';
  static const ruleProfile = 'advanced-yoga-dosha-v1';

  List<ChartFinding> build(CalculationOutputSnapshot calculationOutput) {
    if (!calculationOutput.outputSchemaVersion.startsWith('vedic-chart-v')) {
      throw ArgumentError(
        'Advanced Yoga/Dosha review requires a Vedic chart output',
      );
    }
    final ascendant = _requiredMap(
      calculationOutput.output['ascendant'],
      'ascendant',
    );
    final ascendantSign = _requiredSignIndex(
      ascendant['signIndex'],
      'ascendant.signIndex',
    );
    final planets = _requiredPlanets(calculationOutput.output['planets']);
    for (final body in _classicalPlanets) {
      if (!planets.containsKey(body)) {
        throw StateError('Advanced Yoga/Dosha output is missing $body');
      }
    }

    return <ChartFinding>[
      ..._buildExpandedRajaYogas(ascendantSign, planets),
      ..._buildGreatAffluenceDhanaYogas(ascendantSign, planets),
      ..._buildVipareetaProfiles(ascendantSign, planets),
      ..._buildNeechaBhangaProfiles(ascendantSign, planets),
      ..._buildKujaMultiReferenceReview(ascendantSign, planets),
    ];
  }

  /// Creates one governance-level synthesis across old and new Yoga/Dosha
  /// findings. Contradictions are preserved instead of majority-voted away.
  ChartFinding? synthesize(List<ChartFinding> findings) {
    final relevant = findings
        .where(
          (value) =>
              (value.code.startsWith('vedic.yoga.') ||
                  value.code.startsWith('vedic.dosha.')) &&
              value.code != 'vedic.yoga.synthesis.advanced_v1' &&
              !value.code.endsWith('.not_matched'),
        )
        .toList(growable: false);
    if (relevant.length < 2) return null;

    final supportive = relevant
        .where((value) => value.polarity == AnalysisPolarity.supportive)
        .toList(growable: false);
    final mixed = relevant
        .where((value) => value.polarity == AnalysisPolarity.mixed)
        .toList(growable: false);
    final challenging = relevant
        .where((value) => value.polarity == AnalysisPolarity.challenging)
        .toList(growable: false);
    final hasContradiction = supportive.isNotEmpty &&
        (mixed.isNotEmpty || challenging.isNotEmpty);
    final polarity = hasContradiction
        ? AnalysisPolarity.mixed
        : supportive.length >= 2 && challenging.isEmpty && mixed.isEmpty
            ? AnalysisPolarity.supportive
            : AnalysisPolarity.mixed;
    final confidence = polarity == AnalysisPolarity.supportive
        ? AnalysisConfidence.medium
        : AnalysisConfidence.low;

    final supportiveCodes = supportive.map((value) => value.code).join(', ');
    final reviewCodes = <ChartFinding>[...mixed, ...challenging]
        .map((value) => value.code)
        .join(', ');

    return ChartFinding(
      code: 'vedic.yoga.synthesis.advanced_v1',
      area: LifeArea.overall,
      polarity: polarity,
      confidence: confidence,
      titleEn: polarity == AnalysisPolarity.supportive
          ? 'Yoga synthesis — multiple formations align'
          : 'Yoga/Dosha synthesis — review remains mixed',
      titleBn: polarity == AnalysisPolarity.supportive
          ? 'যোগ সমন্বয় — একাধিক গঠন একই দিকে'
          : 'যোগ/দোষ সমন্বয় — ফল মিশ্র পর্যালোচনায়',
      narrativeEn: hasContradiction
          ? 'Supportive structural formations coexist with weakening, cancellation-review, or dosha evidence. ASTRO LOGIC preserves that contradiction and does not use majority voting. Supportive findings: ${supportiveCodes.isEmpty ? 'none' : supportiveCodes}. Review findings: ${reviewCodes.isEmpty ? 'none' : reviewCodes}. Dasha, divisional agreement and strength must be reviewed before any practical conclusion.'
          : polarity == AnalysisPolarity.supportive
              ? '${supportive.length} enabled Yoga formations align without an enabled contradictory Yoga/Dosha flag in this ruleset. This raises structural review confidence only to Medium; it does not guarantee status, wealth, marriage or any timed event.'
              : 'The enabled Yoga/Dosha evidence is insufficient for a directional combined verdict. The synthesis remains Mixed/Low rather than forcing a result from a small number of formations.',
      narrativeBn: hasContradiction
          ? 'সমর্থক কাঠামোগত যোগের সঙ্গে দুর্বলতা, খণ্ডন-পর্যালোচনা বা দোষের প্রমাণ একসঙ্গে রয়েছে। ASTRO LOGIC এই বিরোধ অক্ষুণ্ণ রাখে এবং majority vote ব্যবহার করে না। সমর্থক finding: ${supportiveCodes.isEmpty ? 'কোনোটি নয়' : supportiveCodes}। review finding: ${reviewCodes.isEmpty ? 'কোনোটি নয়' : reviewCodes}। ব্যবহারিক সিদ্ধান্তের আগে দশা, বিভাগীয় মিল ও বল যাচাই করতে হবে।'
          : polarity == AnalysisPolarity.supportive
              ? 'সক্রিয় ruleset-এ ${supportive.length}টি যোগ-গঠন একই দিকে রয়েছে এবং বিপরীত Yoga/Dosha flag নেই। এতে কাঠামোগত review confidence সর্বোচ্চ Medium হয়; পদ, সম্পদ, বিবাহ বা সময়-নির্দিষ্ট ঘটনা নিশ্চিত হয় না।'
              : 'সক্রিয় Yoga/Dosha প্রমাণ সম্মিলিত দিক নির্ধারণের জন্য যথেষ্ট নয়। অল্প কয়েকটি গঠন থেকে জোর করে ফল না বানিয়ে synthesis Mixed/Low রাখা হয়েছে।',
      evidence: [
        ChartEvidence(
          ruleId: 'vedic.yoga.synthesis.no_majority_vote.v1',
          outputPath: r'$.planets[*]',
          kind: EvidenceKind.yoga,
          descriptionEn:
              'Synthesis reviews ${relevant.length} Yoga/Dosha findings and preserves directional contradictions.',
          descriptionBn:
              'সমন্বয় ${relevant.length}টি Yoga/Dosha finding পর্যালোচনা করে এবং দিকগত বিরোধ অক্ষুণ্ণ রাখে।',
        ),
      ],
    );
  }

  List<ChartFinding> _buildExpandedRajaYogas(
    int ascendantSign,
    Map<String, _YogaPlanet> planets,
  ) {
    final findings = <ChartFinding>[];
    final ninthLord = _lordOfHouse(ascendantSign, 9);
    final tenthLord = _lordOfHouse(ascendantSign, 10);
    if (ninthLord != tenthLord && _conjoined(ninthLord, tenthLord, planets)) {
      final house = _houseOf(ascendantSign, planets[ninthLord]!.signIndex);
      final auspicious = _auspiciousFormationHouses.contains(house);
      final review = _strengthReview({ninthLord, tenthLord}, planets);
      findings.add(
        _formationFinding(
          code: auspicious
              ? 'vedic.yoga.raja.dharma_karma_lords_conjunction.v1'
              : 'vedic.yoga.raja.dharma_karma_lords_conjunction.candidate.v1',
          area: LifeArea.career,
          titleEn: auspicious
              ? 'Raja Yoga — ninth and tenth lords conjoin'
              : 'Raja Yoga candidate — ninth and tenth lords conjoin',
          titleBn: auspicious
              ? 'রাজযোগ — নবমেশ ও দশমেশ যুক্ত'
              : 'রাজযোগ candidate — নবমেশ ও দশমেশ যুক্ত',
          formationEn:
              '${_planetEn[ninthLord]} (9th lord) and ${_planetEn[tenthLord]} (10th lord) conjoin in whole-sign house $house. Phaladeepika VI.37 explicitly identifies the 9th- and 10th-lord conjunction in an auspicious Bhava as Raja Yoga.',
          formationBn:
              '${_planetBn[ninthLord]} (নবমেশ) ও ${_planetBn[tenthLord]} (দশমেশ) হোল-সাইন $house নম্বর ভাবে যুক্ত। Phaladeepika VI.37-এ শুভ ভাবে নবমেশ-দশমেশ সংযোগকে রাজযোগ বলা হয়েছে।',
          evidence: [
            _evidence(
              'vedic.yoga.raja.phaladeepika.6.37.ninth_tenth.v1',
              EvidenceKind.yoga,
              '${_planetEn[ninthLord]} and ${_planetEn[tenthLord]} share ${_signEn[planets[ninthLord]!.signIndex]} in house $house.',
              '${_planetBn[ninthLord]} ও ${_planetBn[tenthLord]} $house নম্বর ভাবে ${_signBn[planets[ninthLord]!.signIndex]} রাশিতে যুক্ত।',
            ),
          ],
          review: review,
          structuralConditionSatisfied: auspicious,
          conditionCautionEn: auspicious
              ? null
              : 'The conjunction is not in the v1 auspicious-house set, so the direct Phaladeepika VI.37 formation is recorded only as a candidate.',
          conditionCautionBn: auspicious
              ? null
              : 'সংযোগটি v1 শুভ-ভাব তালিকায় নেই, তাই সরাসরি Phaladeepika VI.37 গঠনটি শুধু candidate হিসেবে রাখা হয়েছে।',
        ),
      );
    }

    final pairs = <_LordPair>[];
    for (final kendraHouse in const [4, 10]) {
      for (final trikonaHouse in const [5, 9]) {
        final kendraLord = _lordOfHouse(ascendantSign, kendraHouse);
        final trikonaLord = _lordOfHouse(ascendantSign, trikonaHouse);
        if (kendraLord == trikonaLord ||
            !_conjoined(kendraLord, trikonaLord, planets)) {
          continue;
        }
        final key = [kendraLord, trikonaLord]..sort();
        if (pairs.any((value) => value.key == key.join('|'))) continue;
        pairs.add(
          _LordPair(
            key.join('|'),
            kendraHouse,
            trikonaHouse,
            kendraLord,
            trikonaLord,
          ),
        );
      }
    }
    for (final pair in pairs) {
      final house = _houseOf(
        ascendantSign,
        planets[pair.kendraLord]!.signIndex,
      );
      final review = _strengthReview(
        {pair.kendraLord, pair.trikonaLord},
        planets,
      );
      findings.add(
        _formationFinding(
          code:
              'vedic.yoga.raja.kendra_trikona_h${pair.kendraHouse}_h${pair.trikonaHouse}.v1',
          area: LifeArea.overall,
          titleEn:
              'Raja Yoga — house ${pair.kendraHouse} and ${pair.trikonaHouse} lords join',
          titleBn:
              'রাজযোগ — ${pair.kendraHouse} ও ${pair.trikonaHouse} ভাবের অধিপতি যুক্ত',
          formationEn:
              '${_planetEn[pair.kendraLord]} (house ${pair.kendraHouse} lord) joins ${_planetEn[pair.trikonaLord]} (house ${pair.trikonaHouse} lord) in house $house. BPHS Chapter 39.37 and Chapter 41.28 support Kendra–Kona lord relationships as Raja-Yoga structure.',
          formationBn:
              '${_planetBn[pair.kendraLord]} (${pair.kendraHouse} ভাবের অধিপতি) ও ${_planetBn[pair.trikonaLord]} (${pair.trikonaHouse} ভাবের অধিপতি) $house নম্বর ভাবে যুক্ত। BPHS 39.37 ও 41.28 কেন্দ্র–কোণ অধিপতির সম্পর্ককে রাজযোগের কাঠামো হিসেবে সমর্থন করে।',
          evidence: [
            _evidence(
              'vedic.yoga.raja.bphs.kendra_kona_relationship.v1',
              EvidenceKind.lordship,
              'House ${pair.kendraHouse} lord ${_planetEn[pair.kendraLord]} and house ${pair.trikonaHouse} lord ${_planetEn[pair.trikonaLord]} conjoin.',
              '${pair.kendraHouse} ভাবের অধিপতি ${_planetBn[pair.kendraLord]} ও ${pair.trikonaHouse} ভাবের অধিপতি ${_planetBn[pair.trikonaLord]} যুক্ত।',
            ),
          ],
          review: review,
          structuralConditionSatisfied: true,
        ),
      );
    }
    return findings;
  }

  List<ChartFinding> _buildGreatAffluenceDhanaYogas(
    int ascendantSign,
    Map<String, _YogaPlanet> planets,
  ) {
    final fifthSign = _signOfHouse(ascendantSign, 5);
    final checks = <_DhanaCheck>[
      _DhanaCheck(
        2,
        fifthSign == 1 || fifthSign == 6,
        () => _inHouse('venus', 5, ascendantSign, planets) &&
            _inHouse('mars', 11, ascendantSign, planets),
        const {'venus', 'mars'},
        'Venus owns the fifth-house sign and occupies the fifth while Mars occupies the eleventh.',
        'পঞ্চম ভাব শুক্রের রাশি, শুক্র পঞ্চমে এবং মঙ্গল একাদশে।',
      ),
      _DhanaCheck(
        3,
        fifthSign == 2 || fifthSign == 5,
        () => _inHouse('mercury', 5, ascendantSign, planets) &&
            _allInHouse(const {'moon', 'mars', 'jupiter'}, 11, ascendantSign, planets),
        const {'mercury', 'moon', 'mars', 'jupiter'},
        'Mercury owns the fifth-house sign and occupies the fifth while Moon, Mars and Jupiter occupy the eleventh.',
        'পঞ্চম ভাব বুধের রাশি, বুধ পঞ্চমে এবং চন্দ্র, মঙ্গল ও বৃহস্পতি একাদশে।',
      ),
      _DhanaCheck(
        4,
        fifthSign == 4,
        () => _inHouse('sun', 5, ascendantSign, planets) &&
            _allInHouse(const {'saturn', 'moon', 'jupiter'}, 11, ascendantSign, planets),
        const {'sun', 'saturn', 'moon', 'jupiter'},
        'Leo is the fifth-house sign with Sun in the fifth while Saturn, Moon and Jupiter occupy the eleventh.',
        'পঞ্চম ভাব সিংহ, সূর্য পঞ্চমে এবং শনি, চন্দ্র ও বৃহস্পতি একাদশে।',
      ),
      _DhanaCheck(
        5,
        fifthSign == 9 || fifthSign == 10,
        () => _inHouse('saturn', 5, ascendantSign, planets) &&
            _allInHouse(const {'sun', 'moon'}, 11, ascendantSign, planets),
        const {'saturn', 'sun', 'moon'},
        'Saturn occupies its own fifth house while Sun and Moon occupy the eleventh.',
        'শনি নিজের পঞ্চম ভাবে এবং সূর্য ও চন্দ্র একাদশে।',
      ),
      _DhanaCheck(
        6,
        fifthSign == 8 || fifthSign == 11,
        () => _inHouse('jupiter', 5, ascendantSign, planets) &&
            _inHouse('mercury', 11, ascendantSign, planets),
        const {'jupiter', 'mercury'},
        'Jupiter occupies its own fifth house while Mercury occupies the eleventh.',
        'বৃহস্পতি নিজের পঞ্চম ভাবে এবং বুধ একাদশে।',
      ),
      _DhanaCheck(
        7,
        fifthSign == 0 || fifthSign == 7,
        () => _inHouse('mars', 5, ascendantSign, planets) &&
            _inHouse('venus', 11, ascendantSign, planets),
        const {'mars', 'venus'},
        'Mars occupies its own fifth house while Venus occupies the eleventh.',
        'মঙ্গল নিজের পঞ্চম ভাবে এবং শুক্র একাদশে।',
      ),
      _DhanaCheck(
        8,
        fifthSign == 3,
        () => _inHouse('moon', 5, ascendantSign, planets) &&
            _inHouse('saturn', 11, ascendantSign, planets),
        const {'moon', 'saturn'},
        'Cancer is the fifth-house sign with Moon in the fifth while Saturn occupies the eleventh.',
        'পঞ্চম ভাব কর্কট, চন্দ্র পঞ্চমে এবং শনি একাদশে।',
      ),
    ];

    final findings = <ChartFinding>[];
    for (final check in checks) {
      if (!check.signPrerequisite || !check.matches()) continue;
      final review = _strengthReview(check.participants, planets);
      findings.add(
        _formationFinding(
          code: 'vedic.yoga.dhana.bphs41.${check.verse}.v1',
          area: LifeArea.finance,
          titleEn: 'Dhana Yoga — BPHS 41.${check.verse} formation',
          titleBn: 'ধনযোগ — BPHS 41.${check.verse} গঠন',
          formationEn:
              '${check.descriptionEn} This matches the enabled great-affluence formula in BPHS Chapter 41 verse ${check.verse}.',
          formationBn:
              '${check.descriptionBn} এটি BPHS অধ্যায় ৪১-এর ${check.verse} নম্বর শ্লোকের সক্রিয় ধনসম্ভাবনার সূত্রের সঙ্গে মেলে।',
          evidence: [
            _evidence(
              'vedic.yoga.dhana.bphs41.${check.verse}.formation.v1',
              EvidenceKind.yoga,
              check.descriptionEn,
              check.descriptionBn,
            ),
          ],
          review: review,
          structuralConditionSatisfied: true,
        ),
      );
    }
    return findings;
  }

  List<ChartFinding> _buildVipareetaProfiles(
    int ascendantSign,
    Map<String, _YogaPlanet> planets,
  ) {
    const profiles = <int, _VipareetaName>{
      6: _VipareetaName('harsha', 'Harsha', 'হর্ষ'),
      8: _VipareetaName('sarala', 'Sarala', 'সরল'),
      12: _VipareetaName('vimala', 'Vimala', 'বিমল'),
    };
    final findings = <ChartFinding>[];
    for (final entry in profiles.entries) {
      final ownedHouse = entry.key;
      final name = entry.value;
      final lord = _lordOfHouse(ascendantSign, ownedHouse);
      final placedHouse = _houseOf(ascendantSign, planets[lord]!.signIndex);
      if (!_dusthanaHouses.contains(placedHouse)) continue;
      final review = _strengthReview({lord}, planets);
      final otherOwned = _ownedHouses(ascendantSign, lord)
          .where((value) => value != ownedHouse)
          .toList(growable: false);
      findings.add(
        ChartFinding(
          code: 'vedic.yoga.vipareeta.${name.code}.v1',
          area: ownedHouse == 6
              ? LifeArea.obstacles
              : ownedHouse == 8
                  ? LifeArea.longevity
                  : LifeArea.expenses,
          polarity: review.hasChallenge
              ? AnalysisPolarity.mixed
              : AnalysisPolarity.supportive,
          confidence: AnalysisConfidence.medium,
          titleEn:
              '${name.nameEn} / Vipareeta review — house $ownedHouse lord in house $placedHouse',
          titleBn:
              '${name.nameBn} / বিপরীত যোগ পর্যালোচনা — $ownedHouse ভাবের অধিপতি $placedHouse ভাবে',
          narrativeEn:
              '${_planetEn[lord]} rules house $ownedHouse and occupies dusthana house $placedHouse, matching the enabled Phaladeepika VI.57 Harsha/Sarala/Vimala structural profile. ${review.textEn} The same planet also owns ${otherOwned.isEmpty ? 'no second house in this Lagna scheme' : 'house ${otherOwned.join(' and ')}'}, which is retained as context rather than silently cancelling the formation. This is a resilience/reversal review profile, not a promise that hardship will produce success.',
          narrativeBn:
              '${_planetBn[lord]} $ownedHouse ভাবের অধিপতি হয়ে দুষ্টস্থান $placedHouse ভাবে রয়েছে—সক্রিয় Phaladeepika VI.57 হর্ষ/সরল/বিমল কাঠামোর সঙ্গে মেলে। ${review.textBn} একই গ্রহ ${otherOwned.isEmpty ? 'এই লগ্নে দ্বিতীয় কোনো ভাবের অধিপতি নয়' : '${otherOwned.join(' ও ')} ভাবেরও অধিপতি'}; এই তথ্য গঠনটিকে নীরবে বাতিল না করে context হিসেবে রাখা হয়েছে। এটি প্রতিকূলতা-উল্টে-দেওয়ার review profile, কষ্টের পর সাফল্যের নিশ্চয়তা নয়।',
          evidence: [
            _evidence(
              'vedic.yoga.vipareeta.phaladeepika.6.57.${name.code}.v1',
              EvidenceKind.yoga,
              '${_planetEn[lord]}, lord of house $ownedHouse, occupies dusthana house $placedHouse.',
              '${_planetBn[lord]}, $ownedHouse ভাবের অধিপতি, দুষ্টস্থান $placedHouse ভাবে রয়েছে।',
            ),
            if (review.hasChallenge)
              _evidence(
                'vedic.yoga.vipareeta.strength_review.v1',
                EvidenceKind.strength,
                review.textEn,
                review.textBn,
              ),
          ],
        ),
      );
    }
    return findings;
  }

  List<ChartFinding> _buildNeechaBhangaProfiles(
    int ascendantSign,
    Map<String, _YogaPlanet> planets,
  ) {
    final findings = <ChartFinding>[];
    final moonSign = planets['moon']!.signIndex;
    for (final planet in _classicalPlanets) {
      final position = planets[planet]!;
      if (_debilitationSigns[planet] != position.signIndex) continue;
      final dispositor = _signLords[position.signIndex]!;
      final exaltationSign = _exaltationSigns[planet]!;
      final exaltationLord = _signLords[exaltationSign]!;
      final conditions = <_CancellationCondition>[];

      final dispositorKendraLagna =
          _isKendraFrom(ascendantSign, planets[dispositor]!.signIndex);
      final dispositorKendraMoon =
          _isKendraFrom(moonSign, planets[dispositor]!.signIndex);
      if (dispositorKendraLagna || dispositorKendraMoon) {
        conditions.add(
          _CancellationCondition(
            'dispositor_kendra',
            '${_planetEn[dispositor]}, lord of the debilitation sign, is in a Kendra from ${dispositorKendraLagna ? 'Lagna' : 'Moon'}${dispositorKendraLagna && dispositorKendraMoon ? ' and Moon' : ''}.',
            'নীচ রাশির অধিপতি ${_planetBn[dispositor]} ${dispositorKendraLagna ? 'লগ্ন' : 'চন্দ্র'}${dispositorKendraLagna && dispositorKendraMoon ? ' ও চন্দ্র' : ''} থেকে কেন্দ্রে রয়েছে।',
          ),
        );
      }

      final exaltLordKendraLagna =
          _isKendraFrom(ascendantSign, planets[exaltationLord]!.signIndex);
      final exaltLordKendraMoon =
          _isKendraFrom(moonSign, planets[exaltationLord]!.signIndex);
      if (exaltLordKendraLagna || exaltLordKendraMoon) {
        conditions.add(
          _CancellationCondition(
            'exaltation_lord_kendra',
            '${_planetEn[exaltationLord]}, lord of ${_planetEn[planet]}\'s exaltation sign, is in a Kendra from ${exaltLordKendraLagna ? 'Lagna' : 'Moon'}${exaltLordKendraLagna && exaltLordKendraMoon ? ' and Moon' : ''}.',
            '${_planetBn[planet]}-এর উচ্চ রাশির অধিপতি ${_planetBn[exaltationLord]} ${exaltLordKendraLagna ? 'লগ্ন' : 'চন্দ্র'}${exaltLordKendraLagna && exaltLordKendraMoon ? ' ও চন্দ্র' : ''} থেকে কেন্দ্রে রয়েছে।',
          ),
        );
      }

      if (_mutualKendra(
        planets[dispositor]!.signIndex,
        planets[exaltationLord]!.signIndex,
      )) {
        conditions.add(
          _CancellationCondition(
            'dispositor_exaltation_lord_mutual_kendra',
            '${_planetEn[dispositor]} and ${_planetEn[exaltationLord]} occupy mutual Kendras.',
            '${_planetBn[dispositor]} ও ${_planetBn[exaltationLord]} পারস্পরিক কেন্দ্রে রয়েছে।',
          ),
        );
      }

      if (_aspects(dispositor, planets[dispositor]!, position)) {
        conditions.add(
          _CancellationCondition(
            'dispositor_aspects_debilitated_planet',
            '${_planetEn[dispositor]}, lord of the occupied debilitation sign, casts an enabled full-sign aspect on ${_planetEn[planet]}.',
            'নীচ রাশির অধিপতি ${_planetBn[dispositor]} ${_planetBn[planet]}-কে সক্রিয় পূর্ণ রাশিদৃষ্টি দিচ্ছে।',
          ),
        );
      }
      if (conditions.isEmpty) continue;

      final confidence = conditions.length >= 2
          ? AnalysisConfidence.medium
          : AnalysisConfidence.low;
      findings.add(
        ChartFinding(
          code: 'vedic.yoga.neechabhanga.$planet.v1',
          area: LifeArea.overall,
          polarity: AnalysisPolarity.mixed,
          confidence: confidence,
          titleEn:
              'Neecha-bhanga review — ${_planetEn[planet]} has ${conditions.length} cancellation condition${conditions.length == 1 ? '' : 's'}',
          titleBn:
              'নীচভঙ্গ পর্যালোচনা — ${_planetBn[planet]}-এর ${conditions.length}টি খণ্ডন-শর্ত মিলেছে',
          narrativeEn:
              '${_planetEn[planet]} is debilitated in ${_signEn[position.signIndex]}, but ${conditions.length} enabled Phaladeepika VII.27-29 cancellation condition${conditions.length == 1 ? '' : 's'} are present. The D1 debilitation is not erased from the data and ASTRO LOGIC does not automatically relabel the planet as strong or benefic. D9, complete Shadbala, functional lordship, affliction and Dasha activation must still be reviewed.',
          narrativeBn:
              '${_planetBn[planet]} ${_signBn[position.signIndex]} রাশিতে নীচ, কিন্তু সক্রিয় Phaladeepika VII.27-29 profile-এ ${conditions.length}টি নীচভঙ্গ-শর্ত উপস্থিত। D1-এর নীচতা data থেকে মুছে দেওয়া হয় না এবং ASTRO LOGIC গ্রহটিকে স্বয়ংক্রিয়ভাবে শক্তিশালী বা শুভ বলে পুনঃশ্রেণিবদ্ধ করে না। D9, পূর্ণ ষড়বল, কার্যকর অধিপত্য, পীড়ন ও দশা-সক্রিয়তা এখনও যাচাই করতে হবে।',
          evidence: [
            for (final condition in conditions)
              _evidence(
                'vedic.yoga.neechabhanga.phaladeepika7.${condition.code}.v1',
                EvidenceKind.yoga,
                condition.descriptionEn,
                condition.descriptionBn,
              ),
          ],
        ),
      );
    }
    return findings;
  }

  List<ChartFinding> _buildKujaMultiReferenceReview(
    int ascendantSign,
    Map<String, _YogaPlanet> planets,
  ) {
    final mars = planets['mars']!;
    final references = <_MarsReference>[
      _MarsReference('lagna', 'Lagna', 'লগ্ন', ascendantSign),
      _MarsReference('moon', 'Moon', 'চন্দ্র', planets['moon']!.signIndex),
      _MarsReference('venus', 'Venus', 'শুক্র', planets['venus']!.signIndex),
    ];
    final matches = <_MarsReferenceMatch>[];
    for (final reference in references) {
      final house = _houseFromSign(reference.signIndex, mars.signIndex);
      final core = _kujaCoreHouses.contains(house);
      final extended = house == 2;
      if (core || extended) {
        matches.add(_MarsReferenceMatch(reference, house, core));
      }
    }
    if (matches.isEmpty) return const <ChartFinding>[];

    final dignity = _dignity('mars', mars.signIndex);
    final dignityMitigation = dignity == _Dignity.exalted || dignity == _Dignity.own;
    final jupiterSupport = planets['jupiter']!.signIndex == mars.signIndex ||
        _aspects('jupiter', planets['jupiter']!, mars);
    final d9Dignity = _dignity('mars', mars.navamsaSignIndex);
    final d9Mitigation = d9Dignity == _Dignity.exalted || d9Dignity == _Dignity.own;
    final mitigationsEn = <String>[
      if (dignityMitigation) 'D1 Mars dignity is ${dignity.name}',
      if (d9Mitigation) 'D9 Mars dignity is ${d9Dignity.name}',
      if (jupiterSupport) 'Jupiter conjunction/full-sign aspect supports Mars',
    ];
    final mitigationsBn = <String>[
      if (dignityMitigation) 'D1-এ মঙ্গলের মর্যাদা ${_dignityBn[dignity]}',
      if (d9Mitigation) 'D9-এ মঙ্গলের মর্যাদা ${_dignityBn[d9Dignity]}',
      if (jupiterSupport) 'বৃহস্পতির সংযোগ/পূর্ণ রাশিদৃষ্টি মঙ্গলকে সমর্থন করছে',
    ];
    final coreCount = matches.where((value) => value.core).length;
    final confidence = coreCount >= 2
        ? AnalysisConfidence.medium
        : AnalysisConfidence.low;

    return [
      ChartFinding(
        code: 'vedic.dosha.kuja.multi_reference.v1',
        area: LifeArea.marriage,
        polarity: AnalysisPolarity.mixed,
        confidence: confidence,
        titleEn:
            'Kuja-dosha multi-reference review — ${matches.length}/3 references matched',
        titleBn:
            'কুজদোষ multi-reference পর্যালোচনা — ৩টির মধ্যে ${matches.length}টি reference মিলেছে',
        narrativeEn:
            'Mars matches the enabled Kuja screening houses from ${matches.map((value) => '${value.reference.nameEn} (house ${value.house}${value.core ? ', core' : ', extended'})').join('; ')}. ${mitigationsEn.isEmpty ? 'No enabled dignity, D9 dignity or Jupiter-support mitigation is established.' : 'Possible mitigation evidence: ${mitigationsEn.join('; ')}.'} Mitigation is not treated as automatic cancellation. This is a compatibility-review flag only; it must never be used alone to predict divorce, injury, abuse, spouse harm or death.',
        narrativeBn:
            'মঙ্গল সক্রিয় Kuja screening অনুযায়ী ${matches.map((value) => '${value.reference.nameBn} থেকে ${value.house} ভাব${value.core ? ', মূল' : ', সম্প্রসারিত'}').join('; ')}-এ মিলেছে। ${mitigationsBn.isEmpty ? 'সক্রিয় মর্যাদা, D9 মর্যাদা বা বৃহস্পতি-সমর্থনভিত্তিক mitigation প্রতিষ্ঠিত নয়।' : 'সম্ভাব্য mitigation evidence: ${mitigationsBn.join('; ')}।'} mitigation-কে স্বয়ংক্রিয় সম্পূর্ণ খণ্ডন ধরা হয় না। এটি শুধু compatibility-review flag; একে একা ব্যবহার করে বিবাহবিচ্ছেদ, আঘাত, নির্যাতন, সঙ্গীর ক্ষতি বা মৃত্যু অনুমান করা যাবে না।',
        evidence: [
          for (final match in matches)
            _evidence(
              'vedic.dosha.kuja.${match.reference.code}.${match.core ? 'core' : 'extended'}.v1',
              EvidenceKind.dosha,
              'Mars is house ${match.house} from ${match.reference.nameEn}.',
              'মঙ্গল ${match.reference.nameBn} থেকে ${match.house} নম্বর ভাবে।',
            ),
          if (dignityMitigation)
            _evidence(
              'vedic.dosha.kuja.mitigation.d1_dignity.v1',
              EvidenceKind.strength,
              'Mars is ${dignity.name} in D1.',
              'মঙ্গল D1-এ ${_dignityBn[dignity]} মর্যাদায়।',
            ),
          if (d9Mitigation)
            _evidence(
              'vedic.dosha.kuja.mitigation.d9_dignity.v1',
              EvidenceKind.divisional,
              'Mars is ${d9Dignity.name} in D9.',
              'মঙ্গল D9-এ ${_dignityBn[d9Dignity]} মর্যাদায়।',
            ),
          if (jupiterSupport)
            _evidence(
              'vedic.dosha.kuja.mitigation.jupiter_review.v2',
              EvidenceKind.aspect,
              'Jupiter conjoins or casts an enabled full-sign aspect on Mars.',
              'বৃহস্পতি মঙ্গলের সঙ্গে যুক্ত বা মঙ্গলকে সক্রিয় পূর্ণ রাশিদৃষ্টি দিচ্ছে।',
            ),
        ],
      ),
    ];
  }

  ChartFinding _formationFinding({
    required String code,
    required LifeArea area,
    required String titleEn,
    required String titleBn,
    required String formationEn,
    required String formationBn,
    required List<ChartEvidence> evidence,
    required _StrengthReview review,
    required bool structuralConditionSatisfied,
    String? conditionCautionEn,
    String? conditionCautionBn,
  }) {
    final challenged = review.hasChallenge || !structuralConditionSatisfied;
    return ChartFinding(
      code: code,
      area: area,
      polarity: challenged
          ? AnalysisPolarity.mixed
          : AnalysisPolarity.supportive,
      confidence: challenged
          ? AnalysisConfidence.low
          : AnalysisConfidence.medium,
      titleEn: titleEn,
      titleBn: titleBn,
      narrativeEn:
          '$formationEn ${conditionCautionEn ?? ''} ${review.textEn} This records a structural Yoga formation/review only. Strength, divisional agreement and Dasha timing remain separate, and no status or wealth outcome is guaranteed.'
              .replaceAll(RegExp(r' +'), ' '),
      narrativeBn:
          '$formationBn ${conditionCautionBn ?? ''} ${review.textBn} এটি শুধু কাঠামোগত Yoga গঠন/পর্যালোচনা নথিভুক্ত করে। বল, বিভাগীয় মিল ও দশার সময়কাল আলাদা থাকবে এবং পদ বা সম্পদের ফল নিশ্চিত করা হয় না।'
              .replaceAll(RegExp(r' +'), ' '),
      evidence: [
        ...evidence,
        if (review.hasChallenge)
          _evidence(
            'vedic.yoga.participant_strength_review.v2',
            EvidenceKind.strength,
            review.textEn,
            review.textBn,
          ),
      ],
    );
  }

  _StrengthReview _strengthReview(
    Set<String> participants,
    Map<String, _YogaPlanet> planets,
  ) {
    final issuesEn = <String>[];
    final issuesBn = <String>[];
    final sun = planets['sun']!;
    for (final planet in participants) {
      final position = planets[planet]!;
      if (_dignity(planet, position.signIndex) == _Dignity.debilitated) {
        issuesEn.add('${_planetEn[planet]} is debilitated');
        issuesBn.add('${_planetBn[planet]} নীচ রাশিতে');
      }
      if (planet != 'sun') {
        final separation = _angularSeparation(
          sun.siderealLongitude,
          position.siderealLongitude,
        );
        if (separation <= _combustionThreshold(planet, position.retrograde)) {
          issuesEn.add('${_planetEn[planet]} is combust');
          issuesBn.add('${_planetBn[planet]} অস্তাঙ্গ');
        }
      }
      if (planet != 'rahu' &&
          planet != 'ketu' &&
          (planets['rahu']?.signIndex == position.signIndex ||
              planets['ketu']?.signIndex == position.signIndex)) {
        issuesEn.add('${_planetEn[planet]} shares its sign with a lunar node');
        issuesBn.add('${_planetBn[planet]} চন্দ্রনোডের সঙ্গে একই রাশিতে');
      }
    }
    return _StrengthReview(
      issuesEn.isNotEmpty,
      issuesEn.isEmpty
          ? 'No enabled debilitation, combustion or node-contact weakening flag challenges the participating planets.'
          : 'Weakening review: ${issuesEn.join('; ')}.',
      issuesBn.isEmpty
          ? 'সক্রিয় নিয়মে অংশগ্রহণকারী গ্রহগুলির নীচতা, অস্তাঙ্গতা বা নোড-সংযোগভিত্তিক দুর্বলতার flag নেই।'
          : 'দুর্বলতা পর্যালোচনা: ${issuesBn.join('; ')}।',
    );
  }

  static ChartEvidence _evidence(
    String ruleId,
    EvidenceKind kind,
    String en,
    String bn,
  ) =>
      ChartEvidence(
        ruleId: ruleId,
        outputPath: r'$.planets[*].signIndex',
        kind: kind,
        descriptionEn: en,
        descriptionBn: bn,
      );

  static bool _inHouse(
    String planet,
    int house,
    int ascendantSign,
    Map<String, _YogaPlanet> planets,
  ) =>
      _houseOf(ascendantSign, planets[planet]!.signIndex) == house;

  static bool _allInHouse(
    Set<String> bodies,
    int house,
    int ascendantSign,
    Map<String, _YogaPlanet> planets,
  ) =>
      bodies.every((body) => _inHouse(body, house, ascendantSign, planets));

  static bool _conjoined(
    String first,
    String second,
    Map<String, _YogaPlanet> planets,
  ) =>
      planets[first]!.signIndex == planets[second]!.signIndex;

  static bool _isKendraFrom(int referenceSign, int targetSign) =>
      _kendras.contains(_houseFromSign(referenceSign, targetSign));

  static bool _mutualKendra(int firstSign, int secondSign) =>
      _kendras.contains(_houseFromSign(firstSign, secondSign));

  static bool _aspects(
    String aspector,
    _YogaPlanet source,
    _YogaPlanet target,
  ) {
    final relative = _houseFromSign(source.signIndex, target.signIndex);
    return _aspectHouses[aspector]?.contains(relative) ?? false;
  }

  static String _lordOfHouse(int ascendantSign, int house) =>
      _signLords[_signOfHouse(ascendantSign, house)]!;

  static int _signOfHouse(int ascendantSign, int house) =>
      (ascendantSign + house - 1) % 12;

  static int _houseOf(int ascendantSign, int signIndex) =>
      _houseFromSign(ascendantSign, signIndex);

  static int _houseFromSign(int referenceSign, int targetSign) =>
      ((targetSign - referenceSign + 12) % 12) + 1;

  static List<int> _ownedHouses(int ascendantSign, String planet) => [
        for (var house = 1; house <= 12; house += 1)
          if (_lordOfHouse(ascendantSign, house) == planet) house,
      ];

  static _Dignity _dignity(String planet, int signIndex) {
    if (_exaltationSigns[planet] == signIndex) return _Dignity.exalted;
    if (_debilitationSigns[planet] == signIndex) return _Dignity.debilitated;
    if (_ownSigns[planet]!.contains(signIndex)) return _Dignity.own;
    return _Dignity.neutral;
  }

  static double _angularSeparation(double first, double second) {
    final direct = (first - second).abs();
    return direct <= 180 ? direct : 360 - direct;
  }

  static double _combustionThreshold(String planet, bool retrograde) =>
      switch (planet) {
        'moon' => 12.0,
        'mars' => retrograde ? 8.0 : 17.0,
        'mercury' => retrograde ? 12.0 : 14.0,
        'jupiter' => 11.0,
        'venus' => retrograde ? 8.0 : 10.0,
        'saturn' => 16.0,
        _ => 0.0,
      };

  static Map<String, Object?> _requiredMap(Object? value, String path) {
    if (value is! Map) throw StateError('Missing or invalid $path');
    return Map<String, Object?>.from(value);
  }

  static int _requiredSignIndex(Object? value, String path) {
    if (value is! num || value.toInt() < 0 || value.toInt() > 11) {
      throw StateError('Missing or invalid $path');
    }
    return value.toInt();
  }

  static double _requiredLongitude(Object? value, String path) {
    if (value is! num ||
        !value.toDouble().isFinite ||
        value.toDouble() < 0 ||
        value.toDouble() >= 360) {
      throw StateError('Missing or invalid $path');
    }
    return value.toDouble();
  }

  static Map<String, _YogaPlanet> _requiredPlanets(Object? value) {
    if (value is! List) throw StateError('Missing or invalid planets');
    final result = <String, _YogaPlanet>{};
    for (var index = 0; index < value.length; index += 1) {
      final raw = value[index];
      if (raw is! Map) throw StateError('Invalid planets[$index]');
      final map = Map<String, Object?>.from(raw);
      final body = map['body'];
      if (body is! String || body.trim().isEmpty) {
        throw StateError('Missing planets[$index].body');
      }
      final signIndex = _requiredSignIndex(
        map['signIndex'],
        'planets[$index].signIndex',
      );
      final longitude = _requiredLongitude(
        map['siderealLongitude'],
        'planets[$index].siderealLongitude',
      );
      final navamsa = map['navamsaSignIndex'];
      final navamsaSignIndex = navamsa == null
          ? ((longitude * 9.0) ~/ 30.0) % 12
          : _requiredSignIndex(
              navamsa,
              'planets[$index].navamsaSignIndex',
            );
      final retrograde = map['retrograde'];
      if (retrograde is! bool) {
        throw StateError('Missing planets[$index].retrograde');
      }
      result[body] = _YogaPlanet(
        signIndex,
        longitude,
        navamsaSignIndex,
        retrograde,
      );
    }
    return result;
  }

  static const _classicalPlanets = <String>{
    'sun',
    'moon',
    'mars',
    'mercury',
    'jupiter',
    'venus',
    'saturn',
  };
  static const _kendras = <int>{1, 4, 7, 10};
  static const _dusthanaHouses = <int>{6, 8, 12};
  static const _auspiciousFormationHouses = <int>{1, 4, 5, 7, 9, 10};
  static const _kujaCoreHouses = <int>{1, 4, 7, 8, 12};
  static const _signLords = <int, String>{
    0: 'mars',
    1: 'venus',
    2: 'mercury',
    3: 'moon',
    4: 'sun',
    5: 'mercury',
    6: 'venus',
    7: 'mars',
    8: 'jupiter',
    9: 'saturn',
    10: 'saturn',
    11: 'jupiter',
  };
  static const _exaltationSigns = <String, int>{
    'sun': 0,
    'moon': 1,
    'mars': 9,
    'mercury': 5,
    'jupiter': 3,
    'venus': 11,
    'saturn': 6,
  };
  static const _debilitationSigns = <String, int>{
    'sun': 6,
    'moon': 7,
    'mars': 3,
    'mercury': 11,
    'jupiter': 9,
    'venus': 5,
    'saturn': 0,
  };
  static const _ownSigns = <String, Set<int>>{
    'sun': {4},
    'moon': {3},
    'mars': {0, 7},
    'mercury': {2, 5},
    'jupiter': {8, 11},
    'venus': {1, 6},
    'saturn': {9, 10},
  };
  static const _aspectHouses = <String, Set<int>>{
    'sun': {7},
    'moon': {7},
    'mercury': {7},
    'venus': {7},
    'mars': {4, 7, 8},
    'jupiter': {5, 7, 9},
    'saturn': {3, 7, 10},
  };
  static const _planetEn = <String, String>{
    'sun': 'Sun',
    'moon': 'Moon',
    'mars': 'Mars',
    'mercury': 'Mercury',
    'jupiter': 'Jupiter',
    'venus': 'Venus',
    'saturn': 'Saturn',
  };
  static const _planetBn = <String, String>{
    'sun': 'সূর্য',
    'moon': 'চন্দ্র',
    'mars': 'মঙ্গল',
    'mercury': 'বুধ',
    'jupiter': 'বৃহস্পতি',
    'venus': 'শুক্র',
    'saturn': 'শনি',
  };
  static const _signEn = <String>[
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
  static const _signBn = <String>[
    'মেষ',
    'বৃষ',
    'মিথুন',
    'কর্কট',
    'সিংহ',
    'কন্যা',
    'তুলা',
    'বৃশ্চিক',
    'ধনু',
    'মকর',
    'কুম্ভ',
    'মীন',
  ];
  static const _dignityBn = <_Dignity, String>{
    _Dignity.exalted: 'উচ্চ',
    _Dignity.own: 'নিজ',
    _Dignity.neutral: 'সম',
    _Dignity.debilitated: 'নীচ',
  };
}

class _YogaPlanet {
  const _YogaPlanet(
    this.signIndex,
    this.siderealLongitude,
    this.navamsaSignIndex,
    this.retrograde,
  );

  final int signIndex;
  final double siderealLongitude;
  final int navamsaSignIndex;
  final bool retrograde;
}

class _StrengthReview {
  const _StrengthReview(this.hasChallenge, this.textEn, this.textBn);

  final bool hasChallenge;
  final String textEn;
  final String textBn;
}

class _LordPair {
  const _LordPair(
    this.key,
    this.kendraHouse,
    this.trikonaHouse,
    this.kendraLord,
    this.trikonaLord,
  );

  final String key;
  final int kendraHouse;
  final int trikonaHouse;
  final String kendraLord;
  final String trikonaLord;
}

class _DhanaCheck {
  const _DhanaCheck(
    this.verse,
    this.signPrerequisite,
    this.matches,
    this.participants,
    this.descriptionEn,
    this.descriptionBn,
  );

  final int verse;
  final bool signPrerequisite;
  final bool Function() matches;
  final Set<String> participants;
  final String descriptionEn;
  final String descriptionBn;
}

class _VipareetaName {
  const _VipareetaName(this.code, this.nameEn, this.nameBn);

  final String code;
  final String nameEn;
  final String nameBn;
}

class _CancellationCondition {
  const _CancellationCondition(
    this.code,
    this.descriptionEn,
    this.descriptionBn,
  );

  final String code;
  final String descriptionEn;
  final String descriptionBn;
}

class _MarsReference {
  const _MarsReference(this.code, this.nameEn, this.nameBn, this.signIndex);

  final String code;
  final String nameEn;
  final String nameBn;
  final int signIndex;
}

class _MarsReferenceMatch {
  const _MarsReferenceMatch(this.reference, this.house, this.core);

  final _MarsReference reference;
  final int house;
  final bool core;
}

enum _Dignity { exalted, own, neutral, debilitated }
