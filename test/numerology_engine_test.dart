import 'package:astro_logic/src/numerology/numerology_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const engine = NumerologyEngine();

  test('calculates audited birth, maturity, cycles and dual-system name numbers', () {
    final profile = engine.calculate(
      NumerologyInput(
        fullNameLatin: 'Bappa Ray',
        birthDate: DateTime(1984, 3, 13),
        personalYear: 2026,
      ),
    );

    expect(profile.normalizedName, 'BAPPA RAY');
    expect(profile.driver.compound, 13);
    expect(profile.driver.reduced, 4);
    expect(profile.lifePath.compound, 29);
    expect(profile.lifePath.reduced, 11);
    expect(profile.lifePath.masterNumberPreserved, isTrue);
    expect(profile.maturity.compound, 19);
    expect(profile.maturity.reduced, 1);
    expect(profile.personalYear.compound, 8);
    expect(profile.personalYear.reduced, 8);
    expect(
      profile.personalYearCycle.map((value) => value.year),
      orderedEquals([2025, 2026, 2027]),
    );
    expect(
      profile.personalYearCycle.map((value) => value.value.reduced),
      orderedEquals([7, 8, 9]),
    );
    expect(profile.pythagorean.expression.compound, 35);
    expect(profile.pythagorean.expression.reduced, 8);
    expect(profile.pythagorean.soulUrge!.reduced, 3);
    expect(profile.pythagorean.personality!.reduced, 5);
    expect(profile.chaldean.expression.compound, 24);
    expect(profile.chaldean.expression.reduced, 6);
    expect(profile.chaldean.soulUrge, isNull);
    expect(profile.evidence, hasLength(8));
  });

  test('preserves a component master number in the v2 Life Path profile', () {
    final profile = engine.calculate(
      NumerologyInput(
        fullNameLatin: 'Test Name',
        birthDate: DateTime(2005, 11, 4),
        personalYear: 2026,
      ),
    );

    expect(profile.lifePath.compound, 22);
    expect(profile.lifePath.reduced, 22);
    expect(profile.lifePath.masterNumberPreserved, isTrue);
    expect(
      profile.evidence.firstWhere(
        (value) => value.ruleId.contains('life_path.component_reduction'),
      ).calculation,
      contains('11->11'),
    );
  });

  test('calendar Personal Year profile can preserve a final Master 11', () {
    final profile = engine.calculate(
      NumerologyInput(
        fullNameLatin: 'Test Name',
        birthDate: DateTime(1959, 12, 16),
        personalYear: 2026,
      ),
    );

    expect(profile.personalYear.compound, 11);
    expect(profile.personalYear.reduced, 11);
    expect(profile.personalYear.masterNumberPreserved, isTrue);
  });

  test('uses the frozen Pythagorean and Chaldean letter assignments', () {
    final profile = engine.calculate(
      NumerologyInput(
        fullNameLatin: 'AJZ',
        birthDate: DateTime(2000, 1, 1),
        personalYear: 2026,
      ),
    );

    expect(
      profile.pythagorean.letters.map((value) => value.value),
      orderedEquals([1, 1, 8]),
    );
    expect(
      profile.chaldean.letters.map((value) => value.value),
      orderedEquals([1, 1, 7]),
    );
  });

  test('keeps zero vowel subtotal explicit rather than inventing a number', () {
    final profile = engine.calculate(
      NumerologyInput(
        fullNameLatin: 'Rhythm',
        birthDate: DateTime(1990, 1, 1),
        personalYear: 2026,
      ),
    );

    expect(profile.pythagorean.soulUrge!.compound, 0);
    expect(profile.pythagorean.soulUrge!.reduced, 0);
  });

  test('keeps spelling visible and rejects automatic Bengali transliteration', () {
    expect(
      () => engine.calculate(
        NumerologyInput(
          fullNameLatin: 'বাপ্পা রায়',
          birthDate: DateTime(1984, 3, 13),
          personalYear: 2026,
        ),
      ),
      throwsArgumentError,
    );
  });


  test('compares alternate spellings without ranking or auto-selection', () {
    final profile = engine.calculate(
      NumerologyInput(
        fullNameLatin: 'Bappa Ray',
        birthDate: DateTime(1984, 3, 13),
        personalYear: 2026,
        alternateNamesLatin: const ['Bappa Roy', 'Bappa Rai'],
      ),
    );

    expect(profile.nameCandidateComparisons, hasLength(2));
    expect(profile.professionalSelectedNameLatin, isNull);
    expect(
      profile.nameCandidateComparisons.every(
        (value) => !value.selectedForProfessionalReview,
      ),
      isTrue,
    );
    final first = profile.nameCandidateComparisons.first;
    expect(first.baselineName, 'BAPPA RAY');
    expect(first.candidateName, 'BAPPA ROY');
    expect(first.pythagoreanDelta.baselineCompound, 35);
    expect(first.pythagoreanDelta.candidateCompound, isNot(35));
    expect(first.auditFormula, contains('selectedByProfessional=false'));
    expect(first.toMap()['rankingScore'], isNull);
    expect(first.toMap()['automaticRecommendation'], isFalse);
    final policy = profile.toMap()['candidatePolicy'] as Map;
    expect(policy['rankingEnabled'], isFalse);
    expect(policy['automaticSelectionEnabled'], isFalse);
    expect(policy['coreOverlapIsFavourabilitySignal'], isFalse);
  });

  test('stores only an explicit professional focus from the entered candidates', () {
    final profile = engine.calculate(
      NumerologyInput(
        fullNameLatin: 'Bappa Ray',
        birthDate: DateTime(1984, 3, 13),
        personalYear: 2026,
        alternateNamesLatin: const ['Bappa Roy', 'Bappa Rai'],
        professionalSelectedNameLatin: 'bappa rai',
      ),
    );

    expect(profile.professionalSelectedNameLatin, 'BAPPA RAI');
    expect(
      profile.nameCandidateComparisons
          .singleWhere((value) => value.candidateName == 'BAPPA RAI')
          .selectedForProfessionalReview,
      isTrue,
    );
    expect(
      profile.nameCandidateComparisons
          .where((value) => value.selectedForProfessionalReview),
      hasLength(1),
    );
  });

  test('rejects duplicate, baseline-equivalent and non-candidate selections', () {
    NumerologyInput input(List<String> candidates, {String? selected}) =>
        NumerologyInput(
          fullNameLatin: 'Bappa Ray',
          birthDate: DateTime(1984, 3, 13),
          personalYear: 2026,
          alternateNamesLatin: candidates,
          professionalSelectedNameLatin: selected,
        );

    expect(() => engine.calculate(input(['bappa ray'])), throwsArgumentError);
    expect(
      () => engine.calculate(input(['Bappa Roy', 'bappa roy'])),
      throwsArgumentError,
    );
    expect(
      () => engine.calculate(
        input(['Bappa Roy'], selected: 'Bappa Rai'),
      ),
      throwsArgumentError,
    );
    expect(
      () => engine.calculate(
        input(List.generate(9, (index) => 'Name ${String.fromCharCode(65 + index)}')),
      ),
      throwsArgumentError,
    );
  });

  test('serializes the v2.1 professional-review output contract', () {
    final output = engine
        .calculate(
          NumerologyInput(
            fullNameLatin: "Anne-Marie O'Neil",
            birthDate: DateTime(1990, 11, 22),
            personalYear: 2027,
          ),
        )
        .toMap();

    expect(output['engineVersion'], '2.1.0');
    expect(output['outputSchemaVersion'], 'numerology-profile-v3');
    expect(output['calculationProfile'], 'astro-logic-numerology-core-cycle-v2');
    expect(output['professionalReviewRequired'], isTrue);
    expect(output['normalizedName'], "ANNE-MARIE O'NEIL");
    expect(output['personalYearCycle'], isA<List>());
    expect(output['scientificStatus'], contains('not a scientifically'));
  });
}
