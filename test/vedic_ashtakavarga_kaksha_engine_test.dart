import 'package:astro_logic/src/models/kundli_analysis.dart';
import 'package:astro_logic/src/vedic/vedic_ashtakavarga_kaksha_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const engine = VedicAshtakavargaKakshaEngine();

  BhinnashtakavargaSignProfile signWith(String contributor) =>
      BhinnashtakavargaSignProfile(
        signIndex: 0,
        positiveMarks: 1,
        contributors: [
          AshtakavargaContribution(
            reference: contributor,
            referenceSignIndex: 0,
            relativeHouse: 1,
          ),
        ],
      );

  test('maps all eight half-open Kaksha zones in fixed order', () {
    const lords = <String>[
      'saturn', 'jupiter', 'mars', 'sun',
      'venus', 'mercury', 'moon', 'lagna',
    ];
    for (var index = 0; index < 8; index += 1) {
      final start = index * 3.75;
      final result = engine.review(
        transitingPlanet: 'jupiter',
        signIndex: 0,
        degreeInSign: start,
        bavSign: signWith(lords[index]),
      );
      expect(result.kakshaNumber, index + 1);
      expect(result.kakshaLord, lords[index]);
      expect(result.startDegree, start);
      expect(result.endDegree, start + 3.75);
      expect(result.positiveMark, isTrue);
      expect(result.polarity, AnalysisPolarity.supportive);
    }
  });

  test('treats 3.749999 as Saturn and 3.75 as Jupiter', () {
    final before = engine.review(
      transitingPlanet: 'sun',
      signIndex: 0,
      degreeInSign: 3.749999,
      bavSign: signWith('saturn'),
    );
    final boundary = engine.review(
      transitingPlanet: 'sun',
      signIndex: 0,
      degreeInSign: 3.75,
      bavSign: signWith('jupiter'),
    );
    expect(before.kakshaNumber, 1);
    expect(boundary.kakshaNumber, 2);
  });

  test('absence of active Kaksha lord is challenging', () {
    final result = engine.review(
      transitingPlanet: 'saturn',
      signIndex: 0,
      degreeInSign: 15,
      bavSign: signWith('moon'),
    );
    expect(result.kakshaLord, 'venus');
    expect(result.positiveMark, isFalse);
    expect(result.polarity, AnalysisPolarity.challenging);
  });

  test('rejects Rahu/Ketu because the v1 BAV foundation has no node tables', () {
    expect(
      () => engine.review(
        transitingPlanet: 'rahu',
        signIndex: 0,
        degreeInSign: 1,
        bavSign: signWith('saturn'),
      ),
      throwsArgumentError,
    );
  });

  test('rejects degrees outside the sign', () {
    expect(
      () => engine.review(
        transitingPlanet: 'mars',
        signIndex: 0,
        degreeInSign: -0.001,
        bavSign: signWith('saturn'),
      ),
      throwsArgumentError,
    );
    expect(
      () => engine.review(
        transitingPlanet: 'mars',
        signIndex: 0,
        degreeInSign: 30,
        bavSign: signWith('saturn'),
      ),
      throwsArgumentError,
    );
  });
}
