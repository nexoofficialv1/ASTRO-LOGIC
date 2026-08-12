import 'kp_event_judgment_engine.dart';
import 'kp_foundation_engine.dart';
import 'kp_house_evidence_engine.dart';

enum KpHoraryRulingSignificatorState {
  fruitful,
  mixed,
  detrimentalOnly,
  neutral,
}

enum KpHoraryTimingConfirmationState {
  corroboratedForPractitionerReview,
  partialCorroboration,
  contradictory,
  insufficientCorroboration,
  notEligible,
}

enum KpHoraryConfidenceCeiling {
  none,
  low,
  moderate,
}

/// Query-time KP Horary Ruling-Planet corroboration layer.
///
/// v1 deliberately does not reuse natal Vimshottari DBA, birth data, or a
/// future transit scanner. It asks a narrower question: when the Horary chart
/// itself returns a source-bounded Promise for a supported topic, do the
/// standard query-moment Ruling Planets independently overlap with the same
/// Horary event-house significators?
///
/// The standard confidence subset is Ascendant Star Lord, Ascendant Sign Lord,
/// Moon Star Lord and Moon Sign Lord. Day Lord remains audit-only until a
/// sunrise-based Hindu-day resolver exists. Expanded Ascendant/Moon Sub-Lord
/// roles also remain audit-only. This preserves the richer internal RP panel
/// without silently treating non-standard roles as extra confidence votes.
class KpHoraryTimingConfirmationEngine {
  const KpHoraryTimingConfirmationEngine._();

  static const engineVersion = '1.0.0';
  static const analysisSchemaVersion = 'kp-horary-rp-confirmation-v1';
  static const profileVersion = 'kp-horary-query-rp-overlap-v1';

  static const _standardConfidenceRoles = <String>{
    'ascendantStarLord',
    'ascendantSignLord',
    'moonStarLord',
    'moonSignLord',
  };

  static KpHoraryTimingConfirmationSynthesis build({
    required KpEventTopic topic,
    required KpEventJudgment eventJudgment,
    required KpHouseEvidenceMatrix horaryHouseEvidence,
    required KpRulingPlanetPanel queryMomentRulingPlanets,
    required DateTime queryUtc,
  }) {
    if (eventJudgment.topic != topic) {
      throw StateError('KP Horary confirmation topic mismatch');
    }

    final rule = KpEventJudgmentEngine.profiles[topic]!;
    final planetStates = <String, KpHoraryPlanetSignificatorState>{};
    for (final planet in KpFoundationEngine.vimshottariSequence) {
      final significator = horaryHouseEvidence.planet(planet).significator;
      final conductive = _orderedIntersection(
        significator.combinedHouses,
        rule.conductiveHouses,
      );
      final detrimental = _orderedIntersection(
        significator.combinedHouses,
        rule.detrimentalHouses,
      );
      planetStates[planet] = KpHoraryPlanetSignificatorState(
        planet: planet,
        state: _stateFor(conductive, detrimental),
        conductiveHouses: conductive,
        detrimentalHouses: detrimental,
      );
    }

    final roleEvidence = queryMomentRulingPlanets.roles.map((role) {
      final planetState = planetStates[role.planet]!;
      final used = _standardConfidenceRoles.contains(role.role);
      final exclusionReason = used
          ? ''
          : role.role == 'dayLord'
              ? 'Day Lord is audit-only in v1 because sunrise-based Hindu-day resolution is not implemented.'
              : 'Expanded Sub-Lord Ruling-Planet role is retained for audit but does not raise the v1 confidence ceiling.';
      return KpHoraryRulingPlanetEvidence(
        rank: role.rank,
        role: role.role,
        planet: role.planet,
        usedForConfirmation: used,
        state: planetState.state,
        conductiveHouses: planetState.conductiveHouses,
        detrimentalHouses: planetState.detrimentalHouses,
        exclusionReason: exclusionReason,
      );
    }).toList(growable: false);

    final standardEvidence = roleEvidence
        .where((value) => value.usedForConfirmation)
        .toList(growable: false);
    final standardPlanetStates = <String, KpHoraryRulingSignificatorState>{};
    for (final evidence in standardEvidence) {
      standardPlanetStates.putIfAbsent(evidence.planet, () => evidence.state);
    }

    final fruitfulPlanets = standardPlanetStates.entries
        .where((entry) => entry.value == KpHoraryRulingSignificatorState.fruitful)
        .map((entry) => entry.key)
        .toList(growable: false);
    final mixedPlanets = standardPlanetStates.entries
        .where((entry) => entry.value == KpHoraryRulingSignificatorState.mixed)
        .map((entry) => entry.key)
        .toList(growable: false);
    final detrimentalPlanets = standardPlanetStates.entries
        .where((entry) =>
            entry.value == KpHoraryRulingSignificatorState.detrimentalOnly)
        .map((entry) => entry.key)
        .toList(growable: false);

    final primaryCuspSubLord = eventJudgment.primaryCuspSubLord;
    final primaryCuspSubLordRpOverlap = standardEvidence.any(
      (value) => value.planet == primaryCuspSubLord,
    );
    final primaryCuspSubLordFruitfulOverlap = fruitfulPlanets.contains(
      primaryCuspSubLord,
    );

    final eligible = eventJudgment.state == KpEventJudgmentState.promise;
    final state = !eligible
        ? KpHoraryTimingConfirmationState.notEligible
        : detrimentalPlanets.isNotEmpty
            ? KpHoraryTimingConfirmationState.contradictory
            : primaryCuspSubLordFruitfulOverlap
                ? KpHoraryTimingConfirmationState
                    .corroboratedForPractitionerReview
                : fruitfulPlanets.isNotEmpty || mixedPlanets.isNotEmpty
                    ? KpHoraryTimingConfirmationState.partialCorroboration
                    : KpHoraryTimingConfirmationState
                        .insufficientCorroboration;

    final confidenceCeiling = switch (state) {
      KpHoraryTimingConfirmationState.corroboratedForPractitionerReview =>
        KpHoraryConfidenceCeiling.moderate,
      KpHoraryTimingConfirmationState.partialCorroboration ||
      KpHoraryTimingConfirmationState.contradictory =>
        KpHoraryConfidenceCeiling.low,
      KpHoraryTimingConfirmationState.insufficientCorroboration ||
      KpHoraryTimingConfirmationState.notEligible =>
        KpHoraryConfidenceCeiling.none,
    };

    final narrativeEn = switch (state) {
      KpHoraryTimingConfirmationState.corroboratedForPractitionerReview =>
        'The Horary chart has a source-bounded Promise and the primary cusp sub-lord is independently present among the standard query-moment Ruling Planets as a fruitful event-house significator. This corroborates the query moment for practitioner review, but does not calculate or guarantee a future event date.',
      KpHoraryTimingConfirmationState.partialCorroboration =>
        'The Horary Promise has some fruitful or mixed overlap with the standard query-moment Ruling Planets, but the primary cusp sub-lord is not independently corroborated as a fruitful standard RP. Keep this as partial timing evidence only.',
      KpHoraryTimingConfirmationState.contradictory =>
        'The Horary chart has a Promise, but at least one standard query-moment Ruling Planet is a detrimental-only significator for the frozen event-house profile. The contradiction is preserved and confidence cannot rise above Low.',
      KpHoraryTimingConfirmationState.insufficientCorroboration =>
        'The Horary Promise has no sufficient standard query-moment Ruling-Planet overlap with the frozen event-house significators. The chart judgment remains, but timing corroboration is not promoted.',
      KpHoraryTimingConfirmationState.notEligible =>
        'Ruling-Planet timing corroboration is not promoted because the supported Horary cusp judgment is not Promise. Denial or mixed/insufficient cusp evidence remains unchanged.',
    };

    final narrativeBn = switch (state) {
      KpHoraryTimingConfirmationState.corroboratedForPractitionerReview =>
        'Horary chart-এ source-bounded Promise আছে এবং primary cusp sub-lord query moment-এর standard Ruling Planets-এর মধ্যে fruitful event-house significator হিসেবে স্বাধীনভাবে উপস্থিত। এটি practitioner review-এর জন্য query moment-কে corroborate করে, কিন্তু future event date গণনা বা নিশ্চয়তা দেয় না।',
      KpHoraryTimingConfirmationState.partialCorroboration =>
        'Horary Promise-এর সঙ্গে standard query-moment Ruling Planets-এর কিছু fruitful বা mixed overlap আছে, কিন্তু primary cusp sub-lord fruitful standard RP হিসেবে স্বাধীনভাবে corroborate হয়নি। এটিকে শুধু partial timing evidence হিসেবে রাখতে হবে।',
      KpHoraryTimingConfirmationState.contradictory =>
        'Horary chart-এ Promise আছে, কিন্তু অন্তত একটি standard query-moment Ruling Planet frozen event-house profile-এ detrimental-only significator। Contradiction সংরক্ষিত থাকবে এবং confidence Low-এর ওপরে উঠবে না।',
      KpHoraryTimingConfirmationState.insufficientCorroboration =>
        'Horary Promise-এর সঙ্গে frozen event-house significator অনুযায়ী যথেষ্ট standard query-moment Ruling-Planet overlap নেই। Chart judgment থাকবে, কিন্তু timing corroboration promote করা হবে না।',
      KpHoraryTimingConfirmationState.notEligible =>
        'Supported Horary cusp judgment Promise নয়, তাই Ruling-Planet timing corroboration promote করা হচ্ছে না। Denial বা mixed/insufficient cusp evidence অপরিবর্তিত থাকবে।',
    };

    return KpHoraryTimingConfirmationSynthesis(
      engineVersion: engineVersion,
      analysisSchemaVersion: analysisSchemaVersion,
      profileVersion: profileVersion,
      topic: topic,
      queryUtc: queryUtc.toUtc(),
      state: state,
      confidenceCeiling: confidenceCeiling,
      primaryCuspSubLord: primaryCuspSubLord,
      primaryCuspSubLordRpOverlap: primaryCuspSubLordRpOverlap,
      primaryCuspSubLordFruitfulOverlap: primaryCuspSubLordFruitfulOverlap,
      planetStates:
          Map<String, KpHoraryPlanetSignificatorState>.unmodifiable(planetStates),
      rulingPlanetEvidence:
          List<KpHoraryRulingPlanetEvidence>.unmodifiable(roleEvidence),
      fruitfulStandardPlanets: List<String>.unmodifiable(fruitfulPlanets),
      mixedStandardPlanets: List<String>.unmodifiable(mixedPlanets),
      detrimentalStandardPlanets:
          List<String>.unmodifiable(detrimentalPlanets),
      narrativeEn: narrativeEn,
      narrativeBn: narrativeBn,
    );
  }

  static KpHoraryRulingSignificatorState _stateFor(
    List<int> conductive,
    List<int> detrimental,
  ) {
    if (conductive.isNotEmpty && detrimental.isEmpty) {
      return KpHoraryRulingSignificatorState.fruitful;
    }
    if (conductive.isNotEmpty && detrimental.isNotEmpty) {
      return KpHoraryRulingSignificatorState.mixed;
    }
    if (conductive.isEmpty && detrimental.isNotEmpty) {
      return KpHoraryRulingSignificatorState.detrimentalOnly;
    }
    return KpHoraryRulingSignificatorState.neutral;
  }

  static List<int> _orderedIntersection(
    Iterable<int> values,
    List<int> order,
  ) {
    final set = values.toSet();
    return List<int>.unmodifiable(order.where(set.contains));
  }
}

class KpHoraryPlanetSignificatorState {
  const KpHoraryPlanetSignificatorState({
    required this.planet,
    required this.state,
    required this.conductiveHouses,
    required this.detrimentalHouses,
  });

  final String planet;
  final KpHoraryRulingSignificatorState state;
  final List<int> conductiveHouses;
  final List<int> detrimentalHouses;

  Map<String, Object?> toJson() => <String, Object?>{
        'planet': planet,
        'state': state.name,
        'conductiveHouses': conductiveHouses,
        'detrimentalHouses': detrimentalHouses,
      };
}

class KpHoraryRulingPlanetEvidence {
  const KpHoraryRulingPlanetEvidence({
    required this.rank,
    required this.role,
    required this.planet,
    required this.usedForConfirmation,
    required this.state,
    required this.conductiveHouses,
    required this.detrimentalHouses,
    required this.exclusionReason,
  });

  final int rank;
  final String role;
  final String planet;
  final bool usedForConfirmation;
  final KpHoraryRulingSignificatorState state;
  final List<int> conductiveHouses;
  final List<int> detrimentalHouses;
  final String exclusionReason;

  Map<String, Object?> toJson() => <String, Object?>{
        'rank': rank,
        'role': role,
        'planet': planet,
        'usedForConfirmation': usedForConfirmation,
        'state': state.name,
        'conductiveHouses': conductiveHouses,
        'detrimentalHouses': detrimentalHouses,
        'exclusionReason': exclusionReason,
      };
}

class KpHoraryTimingConfirmationSynthesis {
  const KpHoraryTimingConfirmationSynthesis({
    required this.engineVersion,
    required this.analysisSchemaVersion,
    required this.profileVersion,
    required this.topic,
    required this.queryUtc,
    required this.state,
    required this.confidenceCeiling,
    required this.primaryCuspSubLord,
    required this.primaryCuspSubLordRpOverlap,
    required this.primaryCuspSubLordFruitfulOverlap,
    required this.planetStates,
    required this.rulingPlanetEvidence,
    required this.fruitfulStandardPlanets,
    required this.mixedStandardPlanets,
    required this.detrimentalStandardPlanets,
    required this.narrativeEn,
    required this.narrativeBn,
  });

  final String engineVersion;
  final String analysisSchemaVersion;
  final String profileVersion;
  final KpEventTopic topic;
  final DateTime queryUtc;
  final KpHoraryTimingConfirmationState state;
  final KpHoraryConfidenceCeiling confidenceCeiling;
  final String primaryCuspSubLord;
  final bool primaryCuspSubLordRpOverlap;
  final bool primaryCuspSubLordFruitfulOverlap;
  final Map<String, KpHoraryPlanetSignificatorState> planetStates;
  final List<KpHoraryRulingPlanetEvidence> rulingPlanetEvidence;
  final List<String> fruitfulStandardPlanets;
  final List<String> mixedStandardPlanets;
  final List<String> detrimentalStandardPlanets;
  final String narrativeEn;
  final String narrativeBn;

  Map<String, Object?> toJson() => <String, Object?>{
        'engineVersion': engineVersion,
        'analysisSchemaVersion': analysisSchemaVersion,
        'profileVersion': profileVersion,
        'topic': topic.name,
        'queryUtc': queryUtc.toIso8601String(),
        'state': state.name,
        'confidenceCeiling': confidenceCeiling.name,
        'primaryCuspSubLord': primaryCuspSubLord,
        'primaryCuspSubLordRpOverlap': primaryCuspSubLordRpOverlap,
        'primaryCuspSubLordFruitfulOverlap':
            primaryCuspSubLordFruitfulOverlap,
        'fruitfulStandardPlanets': fruitfulStandardPlanets,
        'mixedStandardPlanets': mixedStandardPlanets,
        'detrimentalStandardPlanets': detrimentalStandardPlanets,
        'planetStates': <String, Object?>{
          for (final entry in planetStates.entries) entry.key: entry.value.toJson(),
        },
        'rulingPlanetEvidence': rulingPlanetEvidence
            .map((value) => value.toJson())
            .toList(growable: false),
        'narrativeEn': narrativeEn,
        'narrativeBn': narrativeBn,
        'natalBirthDataUsed': false,
        'natalDashaUsed': false,
        'futureTransitScannerUsed': false,
        'exactEventDateClaimed': false,
        'realWorldGuarantee': false,
        'practitionerReviewRequired': true,
      };
}
