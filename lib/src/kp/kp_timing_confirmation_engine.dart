import 'kp_dasha_timing_engine.dart';
import 'kp_event_judgment_engine.dart';
import 'kp_foundation_engine.dart';
import 'kp_house_evidence_engine.dart';

enum KpTransitSignificatorState {
  fruitful,
  mixed,
  detrimentalOnly,
  neutral,
}

enum KpTimingConfirmationState {
  confirmedForPractitionerReview,
  partialConfirmation,
  contradictory,
  insufficientConfirmation,
  notEligible,
}

enum KpTimingConfidenceCeiling {
  none,
  low,
  moderate,
}

/// Source-bounded KP transit + Ruling-Planet confirmation layer.
///
/// Operational interpretation frozen for v1:
/// - Dasha/Bhukti/Antara, Sun and Moon are evaluated by the Star-Lord of
///   their reference-time KP sidereal transit position.
/// - that Star-Lord is then checked against the natal KP house-significator
///   evidence for the event profile;
/// - Ruling-Planet overlap is a separate confirmation channel and never
///   rewrites the underlying DBA state;
/// - civil weekday/day-lord and the expanded Sub-Lord RP roles are displayed
///   for audit but are not used to raise confidence in v1.
///
/// This layer is intentionally a practitioner-review confirmation profile,
/// not a real-world prediction or exact-date guarantee.
class KpTimingConfirmationEngine {
  const KpTimingConfirmationEngine._();

  static const engineVersion = '1.0.0';
  static const analysisSchemaVersion = 'kp-transit-rp-confirmation-v1';
  static const profileVersion = 'kp-dba-transit-rp-confirmation-v1';

  static const _rpConfirmationRoles = <String>{
    'ascendantStarLord',
    'ascendantSignLord',
    'moonStarLord',
    'moonSignLord',
  };

  static KpTimingConfirmationSynthesis build({
    required KpEventTopic topic,
    required KpEventJudgment eventJudgment,
    required KpDashaTimingSynthesis timingSynthesis,
    required KpHouseEvidenceMatrix natalHouseEvidence,
    required Map<String, KpPointClassification> referenceTransitPoints,
    required KpRulingPlanetPanel referenceRulingPlanets,
    required DateTime referenceUtc,
  }) {
    if (eventJudgment.topic != topic || timingSynthesis.topic != topic) {
      throw StateError('KP confirmation topic mismatch');
    }
    final normalizedReference = referenceUtc.toUtc();
    if (timingSynthesis.referenceUtc.toUtc() != normalizedReference) {
      throw StateError('KP confirmation and DBA reference time must match');
    }
    for (final planet in <String>[
      ...KpFoundationEngine.vimshottariSequence,
      'sun',
      'moon',
    ]) {
      if (!referenceTransitPoints.containsKey(planet)) {
        throw StateError('Missing reference KP transit classification: $planet');
      }
    }

    final rule = KpEventJudgmentEngine.profiles[topic]!;
    final natalPlanetStates = <String, KpNatalSignificatorState>{};
    for (final planet in KpFoundationEngine.vimshottariSequence) {
      final profile = natalHouseEvidence.planet(planet).significator;
      final conductive = _orderedIntersection(
        profile.combinedHouses,
        rule.conductiveHouses,
      );
      final detrimental = _orderedIntersection(
        profile.combinedHouses,
        rule.detrimentalHouses,
      );
      natalPlanetStates[planet] = KpNatalSignificatorState(
        planet: planet,
        state: _stateFor(conductive, detrimental),
        conductiveHouses: conductive,
        detrimentalHouses: detrimental,
      );
    }

    KpTransitConfirmationEvidence transitFor(String role, String planet) {
      final point = referenceTransitPoints[planet]!;
      final starState = natalPlanetStates[point.starLord]!;
      return KpTransitConfirmationEvidence(
        role: role,
        transitPlanet: planet,
        transitStarLord: point.starLord,
        transitSubLord: point.subLord,
        starLordNatalState: starState.state,
        conductiveHouses: starState.conductiveHouses,
        detrimentalHouses: starState.detrimentalHouses,
      );
    }

    final active = timingSynthesis.activeWindow;
    final dbaTransitEvidence = <KpTransitConfirmationEvidence>[];
    if (active != null) {
      dbaTransitEvidence.addAll(<KpTransitConfirmationEvidence>[
        transitFor('dasha', active.dashaLord),
        transitFor('bhukti', active.bhuktiLord),
        transitFor('antara', active.antaraLord),
      ]);
    }
    final luminaryTransitEvidence = <KpTransitConfirmationEvidence>[
      transitFor('sun', 'sun'),
      transitFor('moon', 'moon'),
    ];

    final rpEvidence = referenceRulingPlanets.roles
        .map((role) {
          final natal = natalPlanetStates[role.planet]!;
          final used = _rpConfirmationRoles.contains(role.role);
          String exclusionReason = '';
          if (!used) {
            exclusionReason = role.role == 'dayLord'
                ? 'Civil weekday day-lord is not used for confidence in v1 because sunrise-based Hindu-day resolution is not implemented.'
                : 'Expanded Sub-Lord RP role is retained for audit but not used by the standard five-role confirmation subset.';
          }
          return KpRulingPlanetConfirmationEvidence(
            rank: role.rank,
            role: role.role,
            planet: role.planet,
            usedForConfirmation: used,
            natalState: natal.state,
            conductiveHouses: natal.conductiveHouses,
            detrimentalHouses: natal.detrimentalHouses,
            exclusionReason: exclusionReason,
          );
        })
        .toList(growable: false);

    final dbaEligible = timingSynthesis.gateState ==
            KpDashaTimingGateState.openForPractitionerReview &&
        active != null &&
        active.state == KpDashaTimingWindowState.supportive;
    final allDbaFruitful = dbaEligible &&
        dbaTransitEvidence.isNotEmpty &&
        dbaTransitEvidence.every(
          (value) => value.starLordNatalState == KpTransitSignificatorState.fruitful,
        );
    final allLuminariesFruitful = luminaryTransitEvidence.every(
      (value) => value.starLordNatalState == KpTransitSignificatorState.fruitful,
    );
    final transitContradiction = <KpTransitConfirmationEvidence>[
      ...dbaTransitEvidence,
      ...luminaryTransitEvidence,
    ].any(
      (value) =>
          value.starLordNatalState == KpTransitSignificatorState.detrimentalOnly,
    );
    final fruitfulRp = rpEvidence
        .where(
          (value) =>
              value.usedForConfirmation &&
              value.natalState == KpTransitSignificatorState.fruitful,
        )
        .toList(growable: false);
    final mixedRp = rpEvidence
        .where(
          (value) =>
              value.usedForConfirmation &&
              value.natalState == KpTransitSignificatorState.mixed,
        )
        .toList(growable: false);

    final state = !dbaEligible
        ? KpTimingConfirmationState.notEligible
        : transitContradiction
            ? KpTimingConfirmationState.contradictory
            : allDbaFruitful && allLuminariesFruitful && fruitfulRp.isNotEmpty
                ? KpTimingConfirmationState.confirmedForPractitionerReview
                : dbaTransitEvidence.any(
                          (value) =>
                              value.starLordNatalState ==
                              KpTransitSignificatorState.fruitful,
                        ) ||
                        luminaryTransitEvidence.any(
                          (value) =>
                              value.starLordNatalState ==
                              KpTransitSignificatorState.fruitful,
                        ) ||
                        fruitfulRp.isNotEmpty ||
                        mixedRp.isNotEmpty
                    ? KpTimingConfirmationState.partialConfirmation
                    : KpTimingConfirmationState.insufficientConfirmation;

    final confidenceCeiling = switch (state) {
      KpTimingConfirmationState.confirmedForPractitionerReview =>
        KpTimingConfidenceCeiling.moderate,
      KpTimingConfirmationState.partialConfirmation ||
      KpTimingConfirmationState.contradictory => KpTimingConfidenceCeiling.low,
      KpTimingConfirmationState.insufficientConfirmation ||
      KpTimingConfirmationState.notEligible => KpTimingConfidenceCeiling.none,
    };

    final narrativeEn = switch (state) {
      KpTimingConfirmationState.confirmedForPractitionerReview =>
        'The active supportive DBA is independently confirmed at the reference moment by fruitful Star-Lord transit for all three DBA lords, fruitful Sun and Moon Star-Lord transit, and at least one standard Ruling-Planet overlap. Confidence is capped at Moderate and remains practitioner-review evidence, not a guaranteed event date.',
      KpTimingConfirmationState.partialConfirmation =>
        'The active supportive DBA has partial transit/Ruling-Planet support, but the full confirmation profile is not satisfied. Keep the DBA window and the missing or mixed confirmation evidence separate.',
      KpTimingConfirmationState.contradictory =>
        'The active supportive DBA has a reference transit whose Star-Lord is a detrimental-only natal significator for this event profile. The contradiction is preserved and confidence cannot rise above Low.',
      KpTimingConfirmationState.insufficientConfirmation =>
        'The active supportive DBA has no sufficient independent transit or standard Ruling-Planet overlap at this reference moment. The DBA evidence remains valid but unconfirmed.',
      KpTimingConfirmationState.notEligible =>
        'Transit/Ruling-Planet confirmation is not promoted because the current DBA is not an active supportive window under the frozen v077 timing gate.',
    };
    final narrativeBn = switch (state) {
      KpTimingConfirmationState.confirmedForPractitionerReview =>
        'বর্তমান supportive DBA-কে reference moment-এ তিন DBA lord-এর fruitful Star-Lord transit, Sun ও Moon-এর fruitful Star-Lord transit এবং অন্তত একটি standard Ruling-Planet overlap আলাদাভাবে support করছে। Confidence সর্বোচ্চ Moderate; এটি practitioner-review evidence, নিশ্চিত event date নয়।',
      KpTimingConfirmationState.partialConfirmation =>
        'বর্তমান supportive DBA-তে কিছু transit/Ruling-Planet support আছে, কিন্তু সম্পূর্ণ confirmation profile পূরণ হয়নি। DBA window এবং missing/mixed confirmation evidence আলাদা করে রাখতে হবে।',
      KpTimingConfirmationState.contradictory =>
        'বর্তমান supportive DBA-র reference transit evidence-এর মধ্যে এমন Star-Lord আছে যা এই event profile-এ detrimental-only natal significator। Contradiction সংরক্ষিত থাকবে এবং confidence Low-এর ওপরে উঠবে না।',
      KpTimingConfirmationState.insufficientConfirmation =>
        'বর্তমান supportive DBA-র জন্য reference moment-এ যথেষ্ট independent transit বা standard Ruling-Planet overlap পাওয়া যায়নি। DBA evidence থাকবে, কিন্তু confirmed বলা হবে না।',
      KpTimingConfirmationState.notEligible =>
        'Frozen v077 timing gate অনুযায়ী বর্তমান DBA active supportive window নয়, তাই Transit/Ruling-Planet confirmation promote করা হচ্ছে না।',
    };

    return KpTimingConfirmationSynthesis(
      engineVersion: engineVersion,
      analysisSchemaVersion: analysisSchemaVersion,
      profileVersion: profileVersion,
      topic: topic,
      referenceUtc: normalizedReference,
      activeDbaWindow: active,
      state: state,
      confidenceCeiling: confidenceCeiling,
      natalPlanetStates:
          Map<String, KpNatalSignificatorState>.unmodifiable(natalPlanetStates),
      dbaTransitEvidence:
          List<KpTransitConfirmationEvidence>.unmodifiable(dbaTransitEvidence),
      luminaryTransitEvidence:
          List<KpTransitConfirmationEvidence>.unmodifiable(luminaryTransitEvidence),
      rulingPlanetEvidence:
          List<KpRulingPlanetConfirmationEvidence>.unmodifiable(rpEvidence),
      allDbaTransitStarLordsFruitful: allDbaFruitful,
      allLuminaryTransitStarLordsFruitful: allLuminariesFruitful,
      fruitfulRulingPlanetOverlapCount: fruitfulRp.length,
      mixedRulingPlanetOverlapCount: mixedRp.length,
      contradictionPresent: transitContradiction,
      narrativeEn: narrativeEn,
      narrativeBn: narrativeBn,
    );
  }

  static KpTransitSignificatorState _stateFor(
    List<int> conductive,
    List<int> detrimental,
  ) {
    if (conductive.isNotEmpty && detrimental.isEmpty) {
      return KpTransitSignificatorState.fruitful;
    }
    if (conductive.isNotEmpty && detrimental.isNotEmpty) {
      return KpTransitSignificatorState.mixed;
    }
    if (conductive.isEmpty && detrimental.isNotEmpty) {
      return KpTransitSignificatorState.detrimentalOnly;
    }
    return KpTransitSignificatorState.neutral;
  }

  static List<int> _orderedIntersection(
    Iterable<int> values,
    List<int> order,
  ) {
    final set = values.toSet();
    return List<int>.unmodifiable(order.where(set.contains));
  }
}

class KpNatalSignificatorState {
  const KpNatalSignificatorState({
    required this.planet,
    required this.state,
    required this.conductiveHouses,
    required this.detrimentalHouses,
  });

  final String planet;
  final KpTransitSignificatorState state;
  final List<int> conductiveHouses;
  final List<int> detrimentalHouses;

  Map<String, Object?> toJson() => <String, Object?>{
        'planet': planet,
        'state': state.name,
        'conductiveHouses': conductiveHouses,
        'detrimentalHouses': detrimentalHouses,
      };
}

class KpTransitConfirmationEvidence {
  const KpTransitConfirmationEvidence({
    required this.role,
    required this.transitPlanet,
    required this.transitStarLord,
    required this.transitSubLord,
    required this.starLordNatalState,
    required this.conductiveHouses,
    required this.detrimentalHouses,
  });

  final String role;
  final String transitPlanet;
  final String transitStarLord;
  final String transitSubLord;
  final KpTransitSignificatorState starLordNatalState;
  final List<int> conductiveHouses;
  final List<int> detrimentalHouses;

  Map<String, Object?> toJson() => <String, Object?>{
        'role': role,
        'transitPlanet': transitPlanet,
        'transitStarLord': transitStarLord,
        'transitSubLord': transitSubLord,
        'starLordNatalState': starLordNatalState.name,
        'conductiveHouses': conductiveHouses,
        'detrimentalHouses': detrimentalHouses,
      };
}

class KpRulingPlanetConfirmationEvidence {
  const KpRulingPlanetConfirmationEvidence({
    required this.rank,
    required this.role,
    required this.planet,
    required this.usedForConfirmation,
    required this.natalState,
    required this.conductiveHouses,
    required this.detrimentalHouses,
    required this.exclusionReason,
  });

  final int rank;
  final String role;
  final String planet;
  final bool usedForConfirmation;
  final KpTransitSignificatorState natalState;
  final List<int> conductiveHouses;
  final List<int> detrimentalHouses;
  final String exclusionReason;

  Map<String, Object?> toJson() => <String, Object?>{
        'rank': rank,
        'role': role,
        'planet': planet,
        'usedForConfirmation': usedForConfirmation,
        'natalState': natalState.name,
        'conductiveHouses': conductiveHouses,
        'detrimentalHouses': detrimentalHouses,
        'exclusionReason': exclusionReason,
      };
}

class KpTimingConfirmationSynthesis {
  const KpTimingConfirmationSynthesis({
    required this.engineVersion,
    required this.analysisSchemaVersion,
    required this.profileVersion,
    required this.topic,
    required this.referenceUtc,
    required this.activeDbaWindow,
    required this.state,
    required this.confidenceCeiling,
    required this.natalPlanetStates,
    required this.dbaTransitEvidence,
    required this.luminaryTransitEvidence,
    required this.rulingPlanetEvidence,
    required this.allDbaTransitStarLordsFruitful,
    required this.allLuminaryTransitStarLordsFruitful,
    required this.fruitfulRulingPlanetOverlapCount,
    required this.mixedRulingPlanetOverlapCount,
    required this.contradictionPresent,
    required this.narrativeEn,
    required this.narrativeBn,
  });

  final String engineVersion;
  final String analysisSchemaVersion;
  final String profileVersion;
  final KpEventTopic topic;
  final DateTime referenceUtc;
  final KpDashaTimingWindow? activeDbaWindow;
  final KpTimingConfirmationState state;
  final KpTimingConfidenceCeiling confidenceCeiling;
  final Map<String, KpNatalSignificatorState> natalPlanetStates;
  final List<KpTransitConfirmationEvidence> dbaTransitEvidence;
  final List<KpTransitConfirmationEvidence> luminaryTransitEvidence;
  final List<KpRulingPlanetConfirmationEvidence> rulingPlanetEvidence;
  final bool allDbaTransitStarLordsFruitful;
  final bool allLuminaryTransitStarLordsFruitful;
  final int fruitfulRulingPlanetOverlapCount;
  final int mixedRulingPlanetOverlapCount;
  final bool contradictionPresent;
  final String narrativeEn;
  final String narrativeBn;

  Map<String, Object?> toJson() => <String, Object?>{
        'engineVersion': engineVersion,
        'analysisSchemaVersion': analysisSchemaVersion,
        'profileVersion': profileVersion,
        'topic': topic.name,
        'referenceUtc': referenceUtc.toUtc().toIso8601String(),
        'activeDbaWindow': activeDbaWindow?.toJson(),
        'state': state.name,
        'confidenceCeiling': confidenceCeiling.name,
        'natalPlanetStates': <String, Object?>{
          for (final entry in natalPlanetStates.entries)
            entry.key: entry.value.toJson(),
        },
        'dbaTransitEvidence': dbaTransitEvidence
            .map((value) => value.toJson())
            .toList(growable: false),
        'luminaryTransitEvidence': luminaryTransitEvidence
            .map((value) => value.toJson())
            .toList(growable: false),
        'rulingPlanetEvidence': rulingPlanetEvidence
            .map((value) => value.toJson())
            .toList(growable: false),
        'allDbaTransitStarLordsFruitful': allDbaTransitStarLordsFruitful,
        'allLuminaryTransitStarLordsFruitful':
            allLuminaryTransitStarLordsFruitful,
        'fruitfulRulingPlanetOverlapCount': fruitfulRulingPlanetOverlapCount,
        'mixedRulingPlanetOverlapCount': mixedRulingPlanetOverlapCount,
        'contradictionPresent': contradictionPresent,
        'narrativeEn': narrativeEn,
        'narrativeBn': narrativeBn,
        'transitConfirmationIncluded': true,
        'rulingPlanetConfirmationIncluded': true,
        'rulingPlanetDayLordConfidenceExcluded': true,
        'automaticExactEventDate': false,
        'automaticRealWorldPrediction': false,
        'crossSystemConfidenceUplift': false,
        'maximumConfidenceCeiling': 'moderate',
      };
}
