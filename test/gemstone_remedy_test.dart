import 'package:astro_logic/src/models/gemstone_remedy.dart';
import 'package:astro_logic/src/services/gemstone_remedy_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime.utc(2026, 8, 5, 12);

  GemstoneRemedy fixture({
    RemedyDecision decision = RemedyDecision.draft,
    List<String> evidenceReferences = const [],
  }) =>
      GemstoneRemedy(
        id: 9,
        consultationId: 4,
        planet: RemedyPlanet.jupiter,
        primaryGemstone: 'Yellow Sapphire',
        substituteGemstone: 'Yellow Topaz',
        weightValue: 5.25,
        weightUnit: GemstoneWeightUnit.ratti,
        metal: 'Gold',
        finger: 'Index finger',
        wearingDay: 'Thursday',
        instructions: 'Astrologer-reviewed traditional instruction.',
        astrologicalReason: 'Jupiter evidence requires professional review.',
        evidenceReferences: evidenceReferences,
        cautions: 'Verify suitability and authenticity before use.',
        decision: decision,
        createdAt: now,
        updatedAt: now,
      );

  test('gemstone remedy round-trips all governed fields', () {
    final remedy = fixture(evidenceReferences: const ['D1:Jupiter', 'D9:Lord']);
    final restored = GemstoneRemedy.fromDatabaseMap({
      'id': 9,
      ...remedy.toDatabaseMap(),
    });

    expect(restored.planet, RemedyPlanet.jupiter);
    expect(restored.weightValue, 5.25);
    expect(restored.weightUnit, GemstoneWeightUnit.ratti);
    expect(restored.evidenceReferences, ['D1:Jupiter', 'D9:Lord']);
  });

  test('approval requires verified output and astrological evidence', () {
    final approved = fixture(decision: RemedyDecision.approved);

    expect(
      () => GemstoneRemedyPolicy.validate(
        approved,
        verifiedOutputExists: false,
      ),
      throwsStateError,
    );
    expect(
      () => GemstoneRemedyPolicy.validate(
        approved,
        verifiedOutputExists: true,
      ),
      throwsStateError,
    );
  });

  test('evidence-backed approval passes policy', () {
    final approved = fixture(
      decision: RemedyDecision.approved,
      evidenceReferences: const ['output:42:D1:Jupiter'],
    );

    expect(
      () => GemstoneRemedyPolicy.validate(
        approved,
        verifiedOutputExists: true,
      ),
      returnsNormally,
    );
  });
}
