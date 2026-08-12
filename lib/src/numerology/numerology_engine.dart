/// Deterministic, offline Numerology calculation foundation.
///
/// Interpretation and remedies remain outside this layer. v2 freezes the core
/// number and calendar-cycle policies. v2.1 adds a governed alternate-name
/// comparison layer without ranking, auto-selecting or recommending a name.
class NumerologyEngine {
  const NumerologyEngine();

  static const engineId = 'astro-logic-numerology';
  static const engineVersion = '2.1.0';
  static const outputSchemaVersion = 'numerology-profile-v3';
  static const calculationProfile = 'astro-logic-numerology-core-cycle-v2';
  static const nameCandidateComparisonProfile =
      'astro-logic-name-candidate-comparison-v1';
  static const maxAlternateNames = 8;

  NumerologyProfile calculate(NumerologyInput input) {
    final normalizedName = _normalizeLatinName(input.fullNameLatin);
    if (input.personalYear < 1900 || input.personalYear > 9999) {
      throw ArgumentError.value(
        input.personalYear,
        'personalYear',
        'Must be between 1900 and 9999',
      );
    }

    final normalizedCandidates = _normalizeCandidateNames(
      input.alternateNamesLatin,
      baseline: normalizedName,
    );
    final selectedName = _normalizeProfessionalSelection(
      input.professionalSelectedNameLatin,
      normalizedCandidates,
    );

    final date = input.birthDate;
    final driver = _reduce(date.day, preserveMasterNumbers: true);

    // Core-number policy: reduce month/day/year as separate date components,
    // preserving 11/22/33, then reduce their sum with masters preserved.
    final monthCore = _reduce(date.month, preserveMasterNumbers: true);
    final dayCore = _reduce(date.day, preserveMasterNumbers: true);
    final yearCore = _reduce(_digitSum(date.year), preserveMasterNumbers: true);
    final lifePathCompound =
        monthCore.reduced + dayCore.reduced + yearCore.reduced;
    final lifePath = _reduce(
      lifePathCompound,
      preserveMasterNumbers: true,
    );

    final pythagorean = _buildNameProfile(
      normalizedName,
      system: NumerologyNameSystem.pythagorean,
      preserveMasterNumbers: true,
    );
    final chaldean = _buildNameProfile(
      normalizedName,
      system: NumerologyNameSystem.chaldean,
      preserveMasterNumbers: false,
    );

    final maturityCompound =
        lifePath.reduced + pythagorean.expression.reduced;
    final maturity = _reduce(
      maturityCompound,
      preserveMasterNumbers: true,
    );

    // Calendar-cycle policy: month/day/universal-year are reduced to roots
    // first. The final total preserves 11/22/33 under the selected v2 school.
    final personalYearCycle = <PersonalYearCycleEntry>[
      for (var year = input.personalYear - 1;
          year <= input.personalYear + 1;
          year += 1)
        _personalYearEntry(date, year),
    ];
    final personalYear = personalYearCycle
        .firstWhere((entry) => entry.year == input.personalYear)
        .value;

    final candidateComparisons = <NameCandidateComparison>[
      for (var i = 0; i < normalizedCandidates.length; i += 1)
        _compareCandidateName(
          baselineName: normalizedName,
          candidateName: normalizedCandidates[i],
          baselinePythagorean: pythagorean,
          baselineChaldean: chaldean,
          driver: driver,
          lifePath: lifePath,
          maturity: maturity,
          selectedForProfessionalReview:
              selectedName == normalizedCandidates[i],
          index: i,
        ),
    ];

    return NumerologyProfile(
      normalizedName: normalizedName,
      birthDate: DateTime.utc(date.year, date.month, date.day),
      personalYearTarget: input.personalYear,
      driver: driver,
      lifePath: lifePath,
      maturity: maturity,
      personalYear: personalYear,
      personalYearCycle: List.unmodifiable(personalYearCycle),
      pythagorean: pythagorean,
      chaldean: chaldean,
      nameCandidateComparisons: List.unmodifiable(candidateComparisons),
      professionalSelectedNameLatin: selectedName,
      evidence: [
        NumerologyEvidence(
          ruleId: 'numerology.birth.driver.master_11_22_33.v2',
          inputPath: r'$.birthDate.day',
          calculation:
              '${date.day} -> ${driver.reduced}${driver.masterNumberPreserved ? ' (master preserved)' : ''}',
        ),
        NumerologyEvidence(
          ruleId: 'numerology.birth.life_path.component_reduction.v2',
          inputPath: r'$.birthDate',
          calculation:
              '${date.month}->${monthCore.reduced} + ${date.day}->${dayCore.reduced} + ${date.year}->${yearCore.reduced} = $lifePathCompound -> ${lifePath.reduced}${lifePath.masterNumberPreserved ? ' (master preserved)' : ''}',
        ),
        NumerologyEvidence(
          ruleId: 'numerology.name.pythagorean.mapping.v2',
          inputPath: r'$.fullNameLatin',
          calculation: pythagorean.expressionFormula,
        ),
        NumerologyEvidence(
          ruleId: 'numerology.name.chaldean.mapping.v2',
          inputPath: r'$.fullNameLatin',
          calculation: chaldean.expressionFormula,
        ),
        NumerologyEvidence(
          ruleId: 'numerology.core.maturity.life_path_plus_expression.v1',
          inputPath: r'$.lifePath+$.pythagorean.expression',
          calculation:
              '${lifePath.reduced} + ${pythagorean.expression.reduced} = $maturityCompound -> ${maturity.reduced}${maturity.masterNumberPreserved ? ' (master preserved)' : ''}',
        ),
        for (final entry in personalYearCycle)
          NumerologyEvidence(
            ruleId: 'numerology.cycle.personal_year.calendar_v2',
            inputPath: r'$.personalYearCycle',
            calculation: entry.formula,
          ),
        for (var i = 0; i < candidateComparisons.length; i += 1)
          NumerologyEvidence(
            ruleId: 'numerology.name.candidate_compare.v1',
            inputPath: r'$.alternateNamesLatin[' + i.toString() + r']',
            calculation: candidateComparisons[i].auditFormula,
          ),
      ],
    );
  }

  static PersonalYearCycleEntry _personalYearEntry(DateTime birthDate, int year) {
    final monthRoot = _reduce(
      birthDate.month,
      preserveMasterNumbers: false,
    ).reduced;
    final dayRoot = _reduce(
      birthDate.day,
      preserveMasterNumbers: false,
    ).reduced;
    final universalYearRoot = _reduce(
      _digitSum(year),
      preserveMasterNumbers: false,
    ).reduced;
    final compound = monthRoot + dayRoot + universalYearRoot;
    final value = _reduce(compound, preserveMasterNumbers: true);
    return PersonalYearCycleEntry(
      year: year,
      value: value,
      formula:
          '$year: month ${birthDate.month}->$monthRoot + day ${birthDate.day}->$dayRoot + universal year $year->$universalYearRoot = $compound -> ${value.reduced}${value.masterNumberPreserved ? ' (master preserved)' : ''}',
    );
  }

  static NameCandidateComparison _compareCandidateName({
    required String baselineName,
    required String candidateName,
    required NameNumerologyProfile baselinePythagorean,
    required NameNumerologyProfile baselineChaldean,
    required NumerologyValue driver,
    required NumerologyValue lifePath,
    required NumerologyValue maturity,
    required bool selectedForProfessionalReview,
    required int index,
  }) {
    final candidatePythagorean = _buildNameProfile(
      candidateName,
      system: NumerologyNameSystem.pythagorean,
      preserveMasterNumbers: true,
    );
    final candidateChaldean = _buildNameProfile(
      candidateName,
      system: NumerologyNameSystem.chaldean,
      preserveMasterNumbers: false,
    );

    final pythagoreanReducedChanged = candidatePythagorean.expression.reduced !=
        baselinePythagorean.expression.reduced;
    final chaldeanReducedChanged = candidateChaldean.expression.reduced !=
        baselineChaldean.expression.reduced;
    final status = pythagoreanReducedChanged && chaldeanReducedChanged
        ? NameCandidateComparisonStatus.bothSystemsReducedChange
        : pythagoreanReducedChanged || chaldeanReducedChanged
            ? NameCandidateComparisonStatus.oneSystemReducedChange
            : NameCandidateComparisonStatus.noReducedChange;

    final flags = <String>[
      if (candidatePythagorean.expression.compound !=
          baselinePythagorean.expression.compound)
        'pythagoreanCompoundChanged',
      if (pythagoreanReducedChanged) 'pythagoreanReducedChanged',
      if (candidateChaldean.expression.compound !=
          baselineChaldean.expression.compound)
        'chaldeanCompoundChanged',
      if (chaldeanReducedChanged) 'chaldeanReducedChanged',
      if (candidatePythagorean.soulUrge!.reduced !=
          baselinePythagorean.soulUrge!.reduced)
        'soulUrgeReducedChanged',
      if (candidatePythagorean.personality!.reduced !=
          baselinePythagorean.personality!.reduced)
        'personalityReducedChanged',
      if (candidatePythagorean.expression.masterNumberPreserved &&
          !baselinePythagorean.expression.masterNumberPreserved)
        'pythagoreanMasterIntroduced',
      if (!candidatePythagorean.expression.masterNumberPreserved &&
          baselinePythagorean.expression.masterNumberPreserved)
        'pythagoreanMasterRemoved',
      if (pythagoreanReducedChanged != chaldeanReducedChanged)
        'systemsDifferOnReducedChange',
    ];

    final coreNumbers = <String, int>{
      'driver': driver.reduced,
      'lifePath': lifePath.reduced,
      'maturity': maturity.reduced,
    };
    List<String> overlaps(int expression) => coreNumbers.entries
        .where((entry) => entry.value == expression)
        .map((entry) => entry.key)
        .toList(growable: false);

    final baselinePythagoreanOverlaps =
        overlaps(baselinePythagorean.expression.reduced);
    final candidatePythagoreanOverlaps =
        overlaps(candidatePythagorean.expression.reduced);
    final baselineChaldeanOverlaps =
        overlaps(baselineChaldean.expression.reduced);
    final candidateChaldeanOverlaps =
        overlaps(candidateChaldean.expression.reduced);
    if (!_sameStrings(
      baselinePythagoreanOverlaps,
      candidatePythagoreanOverlaps,
    )) {
      flags.add('pythagoreanCoreOverlapChanged');
    }
    if (!_sameStrings(
      baselineChaldeanOverlaps,
      candidateChaldeanOverlaps,
    )) {
      flags.add('chaldeanCoreOverlapChanged');
    }

    final pythagoreanDelta = NumerologyNameDelta(
      baselineCompound: baselinePythagorean.expression.compound,
      candidateCompound: candidatePythagorean.expression.compound,
      compoundDelta: candidatePythagorean.expression.compound -
          baselinePythagorean.expression.compound,
      baselineReduced: baselinePythagorean.expression.reduced,
      candidateReduced: candidatePythagorean.expression.reduced,
      reducedChanged: pythagoreanReducedChanged,
    );
    final chaldeanDelta = NumerologyNameDelta(
      baselineCompound: baselineChaldean.expression.compound,
      candidateCompound: candidateChaldean.expression.compound,
      compoundDelta: candidateChaldean.expression.compound -
          baselineChaldean.expression.compound,
      baselineReduced: baselineChaldean.expression.reduced,
      candidateReduced: candidateChaldean.expression.reduced,
      reducedChanged: chaldeanReducedChanged,
    );

    return NameCandidateComparison(
      index: index,
      baselineName: baselineName,
      candidateName: candidateName,
      status: status,
      pythagorean: candidatePythagorean,
      chaldean: candidateChaldean,
      pythagoreanDelta: pythagoreanDelta,
      chaldeanDelta: chaldeanDelta,
      baselinePythagoreanCoreOverlaps: baselinePythagoreanOverlaps,
      candidatePythagoreanCoreOverlaps: candidatePythagoreanOverlaps,
      baselineChaldeanCoreOverlaps: baselineChaldeanOverlaps,
      candidateChaldeanCoreOverlaps: candidateChaldeanOverlaps,
      flags: List.unmodifiable(flags),
      selectedForProfessionalReview: selectedForProfessionalReview,
      auditFormula:
          '$baselineName -> $candidateName | Pythagorean ${pythagoreanDelta.baselineCompound}->${pythagoreanDelta.candidateCompound} (${pythagoreanDelta.baselineReduced}->${pythagoreanDelta.candidateReduced}); Chaldean ${chaldeanDelta.baselineCompound}->${chaldeanDelta.candidateCompound} (${chaldeanDelta.baselineReduced}->${chaldeanDelta.candidateReduced}); status=${status.name}; selectedByProfessional=$selectedForProfessionalReview',
    );
  }

  static bool _sameStrings(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i += 1) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  static List<String> _normalizeCandidateNames(
    List<String> values, {
    required String baseline,
  }) {
    if (values.length > maxAlternateNames) {
      throw ArgumentError.value(
        values.length,
        'alternateNamesLatin',
        'At most $maxAlternateNames alternate spellings may be compared',
      );
    }
    final normalized = <String>[];
    final seen = <String>{baseline};
    for (final value in values) {
      if (value.trim().isEmpty) continue;
      final candidate = _normalizeLatinName(value);
      if (!seen.add(candidate)) {
        throw ArgumentError.value(
          value,
          'alternateNamesLatin',
          candidate == baseline
              ? 'Alternate spelling must differ from the original spelling'
              : 'Duplicate alternate spelling after normalization',
        );
      }
      normalized.add(candidate);
    }
    return List.unmodifiable(normalized);
  }

  static String? _normalizeProfessionalSelection(
    String? value,
    List<String> normalizedCandidates,
  ) {
    if (value == null || value.trim().isEmpty) return null;
    final normalized = _normalizeLatinName(value);
    if (!normalizedCandidates.contains(normalized)) {
      throw ArgumentError.value(
        value,
        'professionalSelectedNameLatin',
        'Professional selection must match one entered alternate spelling',
      );
    }
    return normalized;
  }

  static NameNumerologyProfile _buildNameProfile(
    String normalizedName, {
    required NumerologyNameSystem system,
    required bool preserveMasterNumbers,
  }) {
    final values = <NumerologyLetterValue>[];
    var vowelTotal = 0;
    var consonantTotal = 0;
    for (final codeUnit in normalizedName.codeUnits) {
      if (codeUnit < 65 || codeUnit > 90) continue;
      final letter = String.fromCharCode(codeUnit);
      final value = system == NumerologyNameSystem.pythagorean
          ? ((codeUnit - 65) % 9) + 1
          : _chaldeanValues[letter]!;
      final vowel = _vowels.contains(letter);
      values.add(
        NumerologyLetterValue(letter: letter, value: value, vowel: vowel),
      );
      if (vowel) {
        vowelTotal += value;
      } else {
        consonantTotal += value;
      }
    }
    final expressionTotal = vowelTotal + consonantTotal;
    final expression = _reduce(
      expressionTotal,
      preserveMasterNumbers: preserveMasterNumbers,
    );
    final soulUrge = system == NumerologyNameSystem.pythagorean
        ? _reduce(vowelTotal, preserveMasterNumbers: true)
        : null;
    final personality = system == NumerologyNameSystem.pythagorean
        ? _reduce(consonantTotal, preserveMasterNumbers: true)
        : null;
    final formula =
        '${values.map((value) => '${value.letter}(${value.value})').join(' + ')} = '
        '$expressionTotal -> ${expression.reduced}';
    return NameNumerologyProfile(
      system: system,
      letters: values,
      expression: expression,
      soulUrge: soulUrge,
      personality: personality,
      expressionFormula: formula,
    );
  }

  static String _normalizeLatinName(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(value, 'fullNameLatin', 'Name is required');
    }
    if (!RegExp(r"^[A-Za-z .'-]+$").hasMatch(trimmed)) {
      throw ArgumentError.value(
        value,
        'fullNameLatin',
        'Use the exact Latin/English spelling; automatic transliteration is disabled',
      );
    }
    final normalized = trimmed.toUpperCase().replaceAll(RegExp(r'\s+'), ' ');
    if (!RegExp(r'[A-Z]').hasMatch(normalized)) {
      throw ArgumentError.value(
        value,
        'fullNameLatin',
        'At least one Latin letter is required',
      );
    }
    return normalized;
  }

  static NumerologyValue _reduce(
    int value, {
    required bool preserveMasterNumbers,
  }) {
    if (value < 0) throw ArgumentError.value(value, 'value');
    final compound = value;
    var current = value;
    while (current > 9 &&
        !(preserveMasterNumbers && _masterNumbers.contains(current))) {
      current = _digitSum(current);
    }
    return NumerologyValue(
      compound: compound,
      reduced: current,
      masterNumberPreserved:
          preserveMasterNumbers && _masterNumbers.contains(current),
    );
  }

  static int _digitSum(int value) => value
      .abs()
      .toString()
      .codeUnits
      .fold(0, (sum, digit) => sum + digit - 48);

  static const _masterNumbers = <int>{11, 22, 33};
  static const _vowels = <String>{'A', 'E', 'I', 'O', 'U'};
  static const _chaldeanValues = <String, int>{
    'A': 1,
    'I': 1,
    'J': 1,
    'Q': 1,
    'Y': 1,
    'B': 2,
    'K': 2,
    'R': 2,
    'C': 3,
    'G': 3,
    'L': 3,
    'S': 3,
    'D': 4,
    'M': 4,
    'T': 4,
    'E': 5,
    'H': 5,
    'N': 5,
    'X': 5,
    'U': 6,
    'V': 6,
    'W': 6,
    'O': 7,
    'Z': 7,
    'F': 8,
    'P': 8,
  };
}

class NumerologyInput {
  const NumerologyInput({
    required this.fullNameLatin,
    required this.birthDate,
    required this.personalYear,
    this.alternateNamesLatin = const [],
    this.professionalSelectedNameLatin,
  });

  final String fullNameLatin;
  final DateTime birthDate;
  final int personalYear;
  final List<String> alternateNamesLatin;
  final String? professionalSelectedNameLatin;
}

enum NumerologyNameSystem { pythagorean, chaldean }

enum NameCandidateComparisonStatus {
  noReducedChange,
  oneSystemReducedChange,
  bothSystemsReducedChange,
}

class NumerologyValue {
  const NumerologyValue({
    required this.compound,
    required this.reduced,
    required this.masterNumberPreserved,
  });

  final int compound;
  final int reduced;
  final bool masterNumberPreserved;

  Map<String, Object?> toMap() => {
        'compound': compound,
        'reduced': reduced,
        'masterNumberPreserved': masterNumberPreserved,
      };
}

class PersonalYearCycleEntry {
  const PersonalYearCycleEntry({
    required this.year,
    required this.value,
    required this.formula,
  });

  final int year;
  final NumerologyValue value;
  final String formula;

  Map<String, Object?> toMap() => {
        'year': year,
        'value': value.toMap(),
        'formula': formula,
      };
}

class NumerologyLetterValue {
  const NumerologyLetterValue({
    required this.letter,
    required this.value,
    required this.vowel,
  });

  final String letter;
  final int value;
  final bool vowel;

  Map<String, Object?> toMap() => {
        'letter': letter,
        'value': value,
        'vowel': vowel,
      };
}

class NameNumerologyProfile {
  const NameNumerologyProfile({
    required this.system,
    required this.letters,
    required this.expression,
    required this.soulUrge,
    required this.personality,
    required this.expressionFormula,
  });

  final NumerologyNameSystem system;
  final List<NumerologyLetterValue> letters;
  final NumerologyValue expression;
  final NumerologyValue? soulUrge;
  final NumerologyValue? personality;
  final String expressionFormula;

  Map<String, Object?> toMap() => {
        'system': system.name,
        'letters': letters.map((value) => value.toMap()).toList(growable: false),
        'expression': expression.toMap(),
        'soulUrge': soulUrge?.toMap(),
        'personality': personality?.toMap(),
        'expressionFormula': expressionFormula,
      };
}

class NumerologyNameDelta {
  const NumerologyNameDelta({
    required this.baselineCompound,
    required this.candidateCompound,
    required this.compoundDelta,
    required this.baselineReduced,
    required this.candidateReduced,
    required this.reducedChanged,
  });

  final int baselineCompound;
  final int candidateCompound;
  final int compoundDelta;
  final int baselineReduced;
  final int candidateReduced;
  final bool reducedChanged;

  Map<String, Object?> toMap() => {
        'baselineCompound': baselineCompound,
        'candidateCompound': candidateCompound,
        'compoundDelta': compoundDelta,
        'baselineReduced': baselineReduced,
        'candidateReduced': candidateReduced,
        'reducedChanged': reducedChanged,
      };
}

class NameCandidateComparison {
  const NameCandidateComparison({
    required this.index,
    required this.baselineName,
    required this.candidateName,
    required this.status,
    required this.pythagorean,
    required this.chaldean,
    required this.pythagoreanDelta,
    required this.chaldeanDelta,
    required this.baselinePythagoreanCoreOverlaps,
    required this.candidatePythagoreanCoreOverlaps,
    required this.baselineChaldeanCoreOverlaps,
    required this.candidateChaldeanCoreOverlaps,
    required this.flags,
    required this.selectedForProfessionalReview,
    required this.auditFormula,
  });

  final int index;
  final String baselineName;
  final String candidateName;
  final NameCandidateComparisonStatus status;
  final NameNumerologyProfile pythagorean;
  final NameNumerologyProfile chaldean;
  final NumerologyNameDelta pythagoreanDelta;
  final NumerologyNameDelta chaldeanDelta;
  final List<String> baselinePythagoreanCoreOverlaps;
  final List<String> candidatePythagoreanCoreOverlaps;
  final List<String> baselineChaldeanCoreOverlaps;
  final List<String> candidateChaldeanCoreOverlaps;
  final List<String> flags;
  final bool selectedForProfessionalReview;
  final String auditFormula;

  Map<String, Object?> toMap() => {
        'index': index,
        'baselineName': baselineName,
        'candidateName': candidateName,
        'status': status.name,
        'pythagorean': pythagorean.toMap(),
        'chaldean': chaldean.toMap(),
        'pythagoreanDelta': pythagoreanDelta.toMap(),
        'chaldeanDelta': chaldeanDelta.toMap(),
        'baselinePythagoreanCoreOverlaps': baselinePythagoreanCoreOverlaps,
        'candidatePythagoreanCoreOverlaps': candidatePythagoreanCoreOverlaps,
        'baselineChaldeanCoreOverlaps': baselineChaldeanCoreOverlaps,
        'candidateChaldeanCoreOverlaps': candidateChaldeanCoreOverlaps,
        'flags': flags,
        'selectedForProfessionalReview': selectedForProfessionalReview,
        'auditFormula': auditFormula,
        'rankingScore': null,
        'automaticRecommendation': false,
      };
}

class NumerologyEvidence {
  const NumerologyEvidence({
    required this.ruleId,
    required this.inputPath,
    required this.calculation,
  });

  final String ruleId;
  final String inputPath;
  final String calculation;

  Map<String, Object?> toMap() => {
        'ruleId': ruleId,
        'inputPath': inputPath,
        'calculation': calculation,
      };
}

class NumerologyProfile {
  const NumerologyProfile({
    required this.normalizedName,
    required this.birthDate,
    required this.personalYearTarget,
    required this.driver,
    required this.lifePath,
    required this.maturity,
    required this.personalYear,
    required this.personalYearCycle,
    required this.pythagorean,
    required this.chaldean,
    required this.nameCandidateComparisons,
    required this.professionalSelectedNameLatin,
    required this.evidence,
  });

  final String normalizedName;
  final DateTime birthDate;
  final int personalYearTarget;
  final NumerologyValue driver;
  final NumerologyValue lifePath;
  final NumerologyValue maturity;
  final NumerologyValue personalYear;
  final List<PersonalYearCycleEntry> personalYearCycle;
  final NameNumerologyProfile pythagorean;
  final NameNumerologyProfile chaldean;
  final List<NameCandidateComparison> nameCandidateComparisons;
  final String? professionalSelectedNameLatin;
  final List<NumerologyEvidence> evidence;

  Map<String, Object?> toMap() => {
        'engineId': NumerologyEngine.engineId,
        'engineVersion': NumerologyEngine.engineVersion,
        'outputSchemaVersion': NumerologyEngine.outputSchemaVersion,
        'calculationProfile': NumerologyEngine.calculationProfile,
        'nameCandidateComparisonProfile':
            NumerologyEngine.nameCandidateComparisonProfile,
        'normalizedName': normalizedName,
        'birthDate': _dateText(birthDate),
        'personalYearTarget': personalYearTarget,
        'driver': driver.toMap(),
        'lifePath': lifePath.toMap(),
        'maturity': maturity.toMap(),
        'personalYear': personalYear.toMap(),
        'personalYearCycle':
            personalYearCycle.map((value) => value.toMap()).toList(growable: false),
        'pythagorean': pythagorean.toMap(),
        'chaldean': chaldean.toMap(),
        'nameCandidateComparisons': nameCandidateComparisons
            .map((value) => value.toMap())
            .toList(growable: false),
        'professionalSelectedNameLatin': professionalSelectedNameLatin,
        'candidatePolicy': {
          'maxCandidates': NumerologyEngine.maxAlternateNames,
          'rankingEnabled': false,
          'automaticSelectionEnabled': false,
          'legalNameChangeRecommendationEnabled': false,
          'coreOverlapIsFavourabilitySignal': false,
          'selectionSource': professionalSelectedNameLatin == null
              ? 'none'
              : 'explicitProfessionalChoice',
        },
        'evidence': evidence.map((value) => value.toMap()).toList(growable: false),
        'professionalReviewRequired': true,
        'scientificStatus':
            'Traditional numerology profile; not a scientifically validated prediction',
      };

  static String _dateText(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}
