import '../vedic/vimshottari_dasha_engine.dart';
import 'kp_event_judgment_engine.dart';
import 'kp_house_evidence_engine.dart';

enum KpDashaTimingWindowState {
  supportive,
  conflicting,
  insufficientCoverage,
}

enum KpDashaTimingGateState {
  openForPractitionerReview,
  blockedByDenial,
  blockedByInsufficientChartEvidence,
}

/// Source-bounded KP Dasha/Bhukti/Antara timing synthesis.
///
/// This engine deliberately keeps chart promise and timing separate. It reuses
/// the governed Vimshottari calendar arithmetic, but applies KP-native Moon
/// longitude and KP house-significator evidence. Transit and Ruling-Planet
/// confirmation remain outside this v1 timing layer.
class KpDashaTimingEngine {
  const KpDashaTimingEngine._();

  static const engineVersion = '1.0.0';
  static const analysisSchemaVersion = 'kp-dasha-timing-v1';
  static const profileVersion = 'kp-vimshottari-dba-house-coverage-v1';

  static KpDashaTimingSynthesis build({
    required KpEventTopic topic,
    required KpEventJudgment eventJudgment,
    required KpHouseEvidenceMatrix houseEvidence,
    required double moonSiderealLongitude,
    required DateTime birthUtc,
    required DateTime referenceUtc,
  }) {
    if (!moonSiderealLongitude.isFinite) {
      throw ArgumentError.value(
        moonSiderealLongitude,
        'moonSiderealLongitude',
      );
    }
    if (eventJudgment.topic != topic) {
      throw StateError('KP timing topic and event judgment topic disagree');
    }

    final ruleProfile = KpEventJudgmentEngine.profiles[topic]!;
    if (eventJudgment.ruleProfile.ruleVersion != ruleProfile.ruleVersion) {
      throw StateError('KP event-rule profile mismatch');
    }

    final lordEvidence = <String, KpDashaLordTimingEvidence>{};
    for (final planet in VimshottariDashaEngine.sequence) {
      final significator = houseEvidence.planet(planet).significator;
      lordEvidence[planet] = KpDashaLordTimingEvidence(
        planet: planet,
        conductiveHouses: _orderedIntersection(
          significator.combinedHouses,
          ruleProfile.conductiveHouses,
        ),
        detrimentalHouses: _orderedIntersection(
          significator.combinedHouses,
          ruleProfile.detrimentalHouses,
        ),
        levelEvidence: significator.levels
            .map(
              (level) => KpDashaLevelTimingEvidence(
                level: level.level,
                source: level.source,
                conductiveHouses: _orderedIntersection(
                  level.houses,
                  ruleProfile.conductiveHouses,
                ),
                detrimentalHouses: _orderedIntersection(
                  level.houses,
                  ruleProfile.detrimentalHouses,
                ),
              ),
            )
            .toList(growable: false),
      );
    }

    final calendar = VimshottariDashaEngine.calculate(
      moonSiderealLongitude: moonSiderealLongitude,
      birthUtc: birthUtc.toUtc(),
    );
    final normalizedBirth = birthUtc.toUtc();
    final normalizedReference = referenceUtc.toUtc();
    final windows = <KpDashaTimingWindow>[];

    final mahadashas = calendar['mahadashas']! as List<Object?>;
    for (final mahaRaw in mahadashas) {
      final maha = mahaRaw! as Map<String, Object?>;
      final dashaLord = maha['lord']! as String;
      final bhuktis = maha['antardashas']! as List<Object?>;
      for (final bhuktiRaw in bhuktis) {
        final bhukti = bhuktiRaw! as Map<String, Object?>;
        final bhuktiLord = bhukti['antardashaLord']! as String;
        final antaras = bhukti['pratyantardashas']! as List<Object?>;
        for (final antaraRaw in antaras) {
          final antara = antaraRaw! as Map<String, Object?>;
          final antaraLord = antara['pratyantardashaLord']! as String;
          final rawStart = DateTime.parse(
            antara['startUtc']! as String,
          ).toUtc();
          final rawEnd = DateTime.parse(
            antara['endUtc']! as String,
          ).toUtc();
          if (!rawEnd.isAfter(normalizedBirth)) continue;
          final start = rawStart.isBefore(normalizedBirth)
              ? normalizedBirth
              : rawStart;

          final chain = <KpDashaLordTimingEvidence>[
            lordEvidence[dashaLord]!,
            lordEvidence[bhuktiLord]!,
            lordEvidence[antaraLord]!,
          ];
          final conductiveCoverage = _orderedUnion(
            chain.expand((value) => value.conductiveHouses),
            ruleProfile.conductiveHouses,
          );
          final detrimentalCoverage = _orderedUnion(
            chain.expand((value) => value.detrimentalHouses),
            ruleProfile.detrimentalHouses,
          );
          final allLordsTouchConductive =
              chain.every((value) => value.conductiveHouses.isNotEmpty);
          final fullConductiveCoverage = ruleProfile.conductiveHouses
              .every(conductiveCoverage.contains);
          final anyDetrimental = detrimentalCoverage.isNotEmpty;

          final state = allLordsTouchConductive &&
                  fullConductiveCoverage &&
                  !anyDetrimental
              ? KpDashaTimingWindowState.supportive
              : allLordsTouchConductive || anyDetrimental
                  ? KpDashaTimingWindowState.conflicting
                  : KpDashaTimingWindowState.insufficientCoverage;

          windows.add(
            KpDashaTimingWindow(
              dashaLord: dashaLord,
              bhuktiLord: bhuktiLord,
              antaraLord: antaraLord,
              startUtc: start,
              endUtc: rawEnd,
              state: state,
              conductiveCoverage: conductiveCoverage,
              detrimentalCoverage: detrimentalCoverage,
              activeAtReference: _contains(
                start,
                rawEnd,
                normalizedReference,
              ),
            ),
          );
        }
      }
    }

    final gateState = switch (eventJudgment.state) {
      KpEventJudgmentState.promise =>
        KpDashaTimingGateState.openForPractitionerReview,
      KpEventJudgmentState.denial => KpDashaTimingGateState.blockedByDenial,
      KpEventJudgmentState.insufficientEvidence =>
        KpDashaTimingGateState.blockedByInsufficientChartEvidence,
    };
    final supportiveCount = windows
        .where((value) => value.state == KpDashaTimingWindowState.supportive)
        .length;
    final conflictingCount = windows
        .where((value) => value.state == KpDashaTimingWindowState.conflicting)
        .length;
    KpDashaTimingWindow? activeWindow;
    for (final window in windows) {
      if (window.activeAtReference) {
        activeWindow = window;
        break;
      }
    }

    final narrativeEn = switch (gateState) {
      KpDashaTimingGateState.openForPractitionerReview =>
        'Chart-promise review is open. Supportive DBA windows require every Dasha/Bhukti/Antara lord to signify at least one conductive house, the three-lord chain to cover the complete frozen house group, and no frozen detrimental-house hit. Transit and Ruling-Planet confirmation remain separate.',
      KpDashaTimingGateState.blockedByDenial =>
        'The chart-promise layer is in Denial state. DBA period evidence is retained for audit, but no period is promoted as an actionable timing window.',
      KpDashaTimingGateState.blockedByInsufficientChartEvidence =>
        'The chart-promise layer is inconclusive. DBA period evidence is retained for audit, but no period is promoted as an actionable timing window.',
    };
    final narrativeBn = switch (gateState) {
      KpDashaTimingGateState.openForPractitionerReview =>
        'Chart-promise review open আছে। Supportive DBA window হতে Dasha/Bhukti/Antara—তিন lord-কেই অন্তত একটি conductive house signify করতে হবে, তিন lord মিলে frozen house-group সম্পূর্ণ cover করতে হবে এবং frozen detrimental house hit থাকা যাবে না। Transit ও Ruling-Planet confirmation আলাদা evidence layer।',
      KpDashaTimingGateState.blockedByDenial =>
        'Chart-promise layer Denial state-এ আছে। Audit-এর জন্য DBA period evidence রাখা হয়েছে, কিন্তু কোনো period-কে actionable timing window হিসেবে promote করা হচ্ছে না।',
      KpDashaTimingGateState.blockedByInsufficientChartEvidence =>
        'Chart-promise layer inconclusive। Audit-এর জন্য DBA period evidence রাখা হয়েছে, কিন্তু কোনো period-কে actionable timing window হিসেবে promote করা হচ্ছে না।',
    };

    return KpDashaTimingSynthesis(
      engineVersion: engineVersion,
      analysisSchemaVersion: analysisSchemaVersion,
      profileVersion: profileVersion,
      vimshottariCalendarVersion:
          calendar['ruleVersion']! as String,
      yearMode: calendar['yearMode']! as String,
      yearLengthDays: calendar['yearLengthDays']! as double,
      topic: topic,
      ruleProfile: ruleProfile,
      chartJudgmentState: eventJudgment.state,
      gateState: gateState,
      birthUtc: normalizedBirth,
      referenceUtc: normalizedReference,
      moonSiderealLongitude: moonSiderealLongitude,
      lordEvidence:
          Map<String, KpDashaLordTimingEvidence>.unmodifiable(lordEvidence),
      windows: List<KpDashaTimingWindow>.unmodifiable(windows),
      supportiveWindowCount: supportiveCount,
      conflictingWindowCount: conflictingCount,
      activeWindow: activeWindow,
      narrativeEn: narrativeEn,
      narrativeBn: narrativeBn,
    );
  }

  static List<int> _orderedIntersection(
    Iterable<int> values,
    List<int> order,
  ) {
    final set = values.toSet();
    return List<int>.unmodifiable(order.where(set.contains));
  }

  static List<int> _orderedUnion(
    Iterable<int> values,
    List<int> order,
  ) {
    final set = values.toSet();
    return List<int>.unmodifiable(order.where(set.contains));
  }

  static bool _contains(DateTime start, DateTime end, DateTime instant) =>
      !instant.isBefore(start) && instant.isBefore(end);
}


class KpDashaLevelTimingEvidence {
  const KpDashaLevelTimingEvidence({
    required this.level,
    required this.source,
    required this.conductiveHouses,
    required this.detrimentalHouses,
  });

  final int level;
  final String source;
  final List<int> conductiveHouses;
  final List<int> detrimentalHouses;

  Map<String, Object?> toJson() => <String, Object?>{
        'level': level,
        'source': source,
        'conductiveHouses': conductiveHouses,
        'detrimentalHouses': detrimentalHouses,
      };
}

class KpDashaLordTimingEvidence {
  const KpDashaLordTimingEvidence({
    required this.planet,
    required this.conductiveHouses,
    required this.detrimentalHouses,
    required this.levelEvidence,
  });

  final String planet;
  final List<int> conductiveHouses;
  final List<int> detrimentalHouses;
  final List<KpDashaLevelTimingEvidence> levelEvidence;

  Map<String, Object?> toJson() => <String, Object?>{
        'planet': planet,
        'conductiveHouses': conductiveHouses,
        'detrimentalHouses': detrimentalHouses,
        'levelEvidence':
            levelEvidence.map((value) => value.toJson()).toList(growable: false),
      };
}

class KpDashaTimingWindow {
  const KpDashaTimingWindow({
    required this.dashaLord,
    required this.bhuktiLord,
    required this.antaraLord,
    required this.startUtc,
    required this.endUtc,
    required this.state,
    required this.conductiveCoverage,
    required this.detrimentalCoverage,
    required this.activeAtReference,
  });

  final String dashaLord;
  final String bhuktiLord;
  final String antaraLord;
  final DateTime startUtc;
  final DateTime endUtc;
  final KpDashaTimingWindowState state;
  final List<int> conductiveCoverage;
  final List<int> detrimentalCoverage;
  final bool activeAtReference;

  Map<String, Object?> toJson() => <String, Object?>{
        'dashaLord': dashaLord,
        'bhuktiLord': bhuktiLord,
        'antaraLord': antaraLord,
        'startUtc': startUtc.toUtc().toIso8601String(),
        'endUtc': endUtc.toUtc().toIso8601String(),
        'state': state.name,
        'conductiveCoverage': conductiveCoverage,
        'detrimentalCoverage': detrimentalCoverage,
        'activeAtReference': activeAtReference,
      };
}

class KpDashaTimingSynthesis {
  const KpDashaTimingSynthesis({
    required this.engineVersion,
    required this.analysisSchemaVersion,
    required this.profileVersion,
    required this.vimshottariCalendarVersion,
    required this.yearMode,
    required this.yearLengthDays,
    required this.topic,
    required this.ruleProfile,
    required this.chartJudgmentState,
    required this.gateState,
    required this.birthUtc,
    required this.referenceUtc,
    required this.moonSiderealLongitude,
    required this.lordEvidence,
    required this.windows,
    required this.supportiveWindowCount,
    required this.conflictingWindowCount,
    required this.activeWindow,
    required this.narrativeEn,
    required this.narrativeBn,
  });

  final String engineVersion;
  final String analysisSchemaVersion;
  final String profileVersion;
  final String vimshottariCalendarVersion;
  final String yearMode;
  final double yearLengthDays;
  final KpEventTopic topic;
  final KpEventRuleProfile ruleProfile;
  final KpEventJudgmentState chartJudgmentState;
  final KpDashaTimingGateState gateState;
  final DateTime birthUtc;
  final DateTime referenceUtc;
  final double moonSiderealLongitude;
  final Map<String, KpDashaLordTimingEvidence> lordEvidence;
  final List<KpDashaTimingWindow> windows;
  final int supportiveWindowCount;
  final int conflictingWindowCount;
  final KpDashaTimingWindow? activeWindow;
  final String narrativeEn;
  final String narrativeBn;

  List<KpDashaTimingWindow> nextSupportiveWindows({int limit = 5}) {
    if (limit <= 0) return const <KpDashaTimingWindow>[];
    if (gateState != KpDashaTimingGateState.openForPractitionerReview) {
      return const <KpDashaTimingWindow>[];
    }
    return windows
        .where(
          (window) =>
              window.state == KpDashaTimingWindowState.supportive &&
              window.endUtc.isAfter(referenceUtc),
        )
        .take(limit)
        .toList(growable: false);
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'engineVersion': engineVersion,
        'analysisSchemaVersion': analysisSchemaVersion,
        'profileVersion': profileVersion,
        'vimshottariCalendarVersion': vimshottariCalendarVersion,
        'yearMode': yearMode,
        'yearLengthDays': yearLengthDays,
        'topic': topic.name,
        'ruleProfile': <String, Object?>{
          'ruleVersion': ruleProfile.ruleVersion,
          'primaryCusp': ruleProfile.primaryCusp,
          'conductiveHouses': ruleProfile.conductiveHouses,
          'detrimentalHouses': ruleProfile.detrimentalHouses,
        },
        'chartJudgmentState': chartJudgmentState.name,
        'gateState': gateState.name,
        'birthUtc': birthUtc.toUtc().toIso8601String(),
        'referenceUtc': referenceUtc.toUtc().toIso8601String(),
        'moonSiderealLongitude': moonSiderealLongitude,
        'lordEvidence': <String, Object?>{
          for (final entry in lordEvidence.entries)
            entry.key: entry.value.toJson(),
        },
        'windows': windows.map((value) => value.toJson()).toList(growable: false),
        'supportiveWindowCount': supportiveWindowCount,
        'conflictingWindowCount': conflictingWindowCount,
        'activeWindow': activeWindow?.toJson(),
        'nextSupportiveWindows': nextSupportiveWindows()
            .map((value) => value.toJson())
            .toList(growable: false),
        'narrativeEn': narrativeEn,
        'narrativeBn': narrativeBn,
        'transitConfirmationIncluded': false,
        'rulingPlanetConfirmationIncluded': false,
        'automaticRealWorldPrediction': false,
        'crossSystemConfidenceUplift': false,
      };
}
