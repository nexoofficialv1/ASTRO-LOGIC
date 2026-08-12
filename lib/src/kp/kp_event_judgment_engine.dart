import 'kp_foundation_engine.dart';
import 'kp_house_evidence_engine.dart';

enum KpEventTopic { marriage, children }

enum KpEventJudgmentState { promise, denial, insufficientEvidence }

class KpEventRuleProfile {
  const KpEventRuleProfile({
    required this.topic,
    required this.ruleVersion,
    required this.primaryCusp,
    required this.conductiveHouses,
    required this.detrimentalHouses,
    required this.sourceNote,
  });

  final KpEventTopic topic;
  final String ruleVersion;
  final int primaryCusp;
  final List<int> conductiveHouses;
  final List<int> detrimentalHouses;
  final String sourceNote;
}

/// Conservative chart-promise review based on the primary cusp's sub-lord.
///
/// This engine does not time events, does not merge Vedic/Numerology evidence,
/// and never upgrades an astrological rule result into a real-world guarantee.
class KpEventJudgmentEngine {
  const KpEventJudgmentEngine._();

  static const engineVersion = '1.0.0';
  static const analysisSchemaVersion = 'kp-event-judgment-v1';
  static const profileVersion = 'kp-cusp-sublord-promise-review-v1';

  static const Map<KpEventTopic, KpEventRuleProfile> profiles =
      <KpEventTopic, KpEventRuleProfile>{
    KpEventTopic.marriage: KpEventRuleProfile(
      topic: KpEventTopic.marriage,
      ruleVersion: 'kp-marriage-house-group-v1',
      primaryCusp: 7,
      conductiveHouses: <int>[2, 7, 11],
      detrimentalHouses: <int>[1, 6, 10],
      sourceNote:
          '7th cusp sub-lord reviewed against conductive houses 2/7/11 and their 12th-house detriments 1/6/10.',
    ),
    KpEventTopic.children: KpEventRuleProfile(
      topic: KpEventTopic.children,
      ruleVersion: 'kp-children-house-group-v1',
      primaryCusp: 5,
      conductiveHouses: <int>[2, 5, 11],
      detrimentalHouses: <int>[1, 4, 10],
      sourceNote:
          '5th cusp sub-lord reviewed against the 2/5/11 child-birth house group; detriments are the 12th houses from that group.',
    ),
  };

  static KpEventJudgment judge({
    required KpEventTopic topic,
    required List<KpCuspClassification> cusps,
    required KpHouseEvidenceMatrix houseEvidence,
  }) {
    if (cusps.length != 12) {
      throw ArgumentError.value(cusps.length, 'cusps', 'Requires 12 cusps');
    }
    final profile = profiles[topic]!;
    final cusp = cusps[profile.primaryCusp - 1];
    final subLord = cusp.point.subLord;
    final significator = houseEvidence.planet(subLord).significator;

    final conductiveHits = _hitsByLevel(
      significator,
      profile.conductiveHouses,
    );
    final detrimentalHits = _hitsByLevel(
      significator,
      profile.detrimentalHouses,
    );
    final hasConductive = conductiveHits.any((entry) => entry.houses.isNotEmpty);
    final hasDetrimental =
        detrimentalHits.any((entry) => entry.houses.isNotEmpty);

    final state = switch ((hasConductive, hasDetrimental)) {
      (true, false) => KpEventJudgmentState.promise,
      (false, true) => KpEventJudgmentState.denial,
      _ => KpEventJudgmentState.insufficientEvidence,
    };
    final clarity = state == KpEventJudgmentState.insufficientEvidence
        ? 'Low'
        : 'Medium';

    final narrativeEn = switch (state) {
      KpEventJudgmentState.promise =>
        'The primary cusp sub-lord signifies at least one conductive house and no frozen detrimental house in this v1 profile. Treat this as a KP chart-promise indication for practitioner review, not as a guaranteed real-world outcome.',
      KpEventJudgmentState.denial =>
        'The primary cusp sub-lord signifies frozen detrimental houses without a conductive-house link in this v1 profile. Treat this as a KP denial indication for practitioner review, not as certainty that the real-world event cannot occur.',
      KpEventJudgmentState.insufficientEvidence =>
        'The primary cusp sub-lord evidence is mixed or does not connect clearly with either side of the frozen v1 house-group profile. No Promise/Denial conclusion is automated.',
    };
    final narrativeBn = switch (state) {
      KpEventJudgmentState.promise =>
        'Primary cusp-এর sub-lord এই v1 profile-এ অন্তত একটি conductive house signify করছে এবং frozen detrimental house পাওয়া যায়নি। এটি practitioner review-এর জন্য KP chart-promise indication; বাস্তব জীবনের ফল নিশ্চিত বলে ধরা যাবে না।',
      KpEventJudgmentState.denial =>
        'Primary cusp-এর sub-lord এই v1 profile-এ conductive link ছাড়া frozen detrimental house signify করছে। এটি practitioner review-এর জন্য KP denial indication; বাস্তবে ঘটনাটি কখনোই ঘটবে না—এমন নিশ্চিত দাবি নয়।',
      KpEventJudgmentState.insufficientEvidence =>
        'Primary cusp sub-lord evidence mixed, অথবা frozen v1 house-group-এর কোনো দিকেই স্পষ্ট link নেই। তাই Promise/Denial automatic conclusion দেওয়া হচ্ছে না।',
    };

    return KpEventJudgment(
      engineVersion: engineVersion,
      analysisSchemaVersion: analysisSchemaVersion,
      profileVersion: profileVersion,
      topic: topic,
      ruleProfile: profile,
      primaryCuspSubLord: subLord,
      subLordSignificator: significator,
      conductiveHits: conductiveHits,
      detrimentalHits: detrimentalHits,
      state: state,
      evidenceClarity: clarity,
      narrativeEn: narrativeEn,
      narrativeBn: narrativeBn,
    );
  }

  static List<KpEventLevelHit> _hitsByLevel(
    KpSignificatorProfile profile,
    List<int> targetHouses,
  ) {
    final targets = targetHouses.toSet();
    return profile.levels
        .map(
          (level) => KpEventLevelHit(
            level: level.level,
            source: level.source,
            houses: List<int>.unmodifiable(
              level.houses.where(targets.contains),
            ),
          ),
        )
        .toList(growable: false);
  }
}

class KpEventLevelHit {
  const KpEventLevelHit({
    required this.level,
    required this.source,
    required this.houses,
  });
  final int level;
  final String source;
  final List<int> houses;

  Map<String, Object?> toJson() => <String, Object?>{
        'level': level,
        'source': source,
        'houses': houses,
      };
}

class KpEventJudgment {
  const KpEventJudgment({
    required this.engineVersion,
    required this.analysisSchemaVersion,
    required this.profileVersion,
    required this.topic,
    required this.ruleProfile,
    required this.primaryCuspSubLord,
    required this.subLordSignificator,
    required this.conductiveHits,
    required this.detrimentalHits,
    required this.state,
    required this.evidenceClarity,
    required this.narrativeEn,
    required this.narrativeBn,
  });

  final String engineVersion;
  final String analysisSchemaVersion;
  final String profileVersion;
  final KpEventTopic topic;
  final KpEventRuleProfile ruleProfile;
  final String primaryCuspSubLord;
  final KpSignificatorProfile subLordSignificator;
  final List<KpEventLevelHit> conductiveHits;
  final List<KpEventLevelHit> detrimentalHits;
  final KpEventJudgmentState state;
  final String evidenceClarity;
  final String narrativeEn;
  final String narrativeBn;

  Map<String, Object?> toJson() => <String, Object?>{
        'engineVersion': engineVersion,
        'analysisSchemaVersion': analysisSchemaVersion,
        'profileVersion': profileVersion,
        'topic': topic.name,
        'ruleProfile': <String, Object?>{
          'ruleVersion': ruleProfile.ruleVersion,
          'primaryCusp': ruleProfile.primaryCusp,
          'conductiveHouses': ruleProfile.conductiveHouses,
          'detrimentalHouses': ruleProfile.detrimentalHouses,
          'sourceNote': ruleProfile.sourceNote,
        },
        'primaryCuspSubLord': primaryCuspSubLord,
        'subLordSignificator': subLordSignificator.toJson(),
        'conductiveHits':
            conductiveHits.map((value) => value.toJson()).toList(growable: false),
        'detrimentalHits':
            detrimentalHits.map((value) => value.toJson()).toList(growable: false),
        'state': state.name,
        'evidenceClarity': evidenceClarity,
        'narrativeEn': narrativeEn,
        'narrativeBn': narrativeBn,
        'automaticTiming': false,
        'realWorldGuarantee': false,
        'crossSystemConfidenceUplift': false,
      };
}
