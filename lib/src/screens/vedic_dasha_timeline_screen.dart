import 'package:flutter/material.dart';

import '../localization/app_copy.dart';

class VedicDashaTimelineScreen extends StatefulWidget {
  const VedicDashaTimelineScreen({
    required this.vimshottari,
    required this.timingWindows,
    this.dashaActivationProfiles = const [],
    this.pratyantardashaInterpretations = const [],
    super.key,
  });

  final Map<String, Object?> vimshottari;
  final List<Map<String, Object?>> timingWindows;
  final List<Map<String, Object?>> dashaActivationProfiles;
  final List<Map<String, Object?>> pratyantardashaInterpretations;

  @override
  State<VedicDashaTimelineScreen> createState() =>
      _VedicDashaTimelineScreenState();
}

class _VedicDashaTimelineScreenState
    extends State<VedicDashaTimelineScreen> {
  late final List<_PratyantarPeriod> _periods;
  _TimelineScope _scope = _TimelineScope.current;

  @override
  void initState() {
    super.initState();
    _periods = _flatten(
      widget.vimshottari,
      widget.timingWindows,
      widget.dashaActivationProfiles,
      widget.pratyantardashaInterpretations,
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now().toUtc();
    final current = _periods
        .where((period) => period.contains(now))
        .toList(growable: false);
    final past = _periods
        .where((period) => !period.end.isAfter(now))
        .toList(growable: false)
        .reversed
        .toList(growable: false);
    final future = _periods
        .where((period) => period.start.isAfter(now))
        .toList(growable: false);
    final selected = switch (_scope) {
      _TimelineScope.current => current,
      _TimelineScope.past => past,
      _TimelineScope.future => future,
    };

    return Scaffold(
      appBar: AppBar(title: Text(AppCopy.of(context, 'dashaTimeline'))),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _CurrentDashaCard(
                  period: current.isEmpty ? null : current.first,
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _scopeChip(
                      context,
                      _TimelineScope.current,
                      'currentDasha',
                      current.length,
                    ),
                    _scopeChip(
                      context,
                      _TimelineScope.past,
                      'pastDasha',
                      past.length,
                    ),
                    _scopeChip(
                      context,
                      _TimelineScope.future,
                      'futureDasha',
                      future.length,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  AppCopy.of(context, 'pratyantarTimingCaution'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: selected.isEmpty
                ? Center(child: Text(AppCopy.of(context, 'noDashaPeriods')))
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: selected.length,
                    itemBuilder: (context, index) =>
                        _PeriodCard(period: selected[index]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _scopeChip(
    BuildContext context,
    _TimelineScope value,
    String labelKey,
    int count,
  ) =>
      ChoiceChip(
        selected: _scope == value,
        onSelected: (_) => setState(() => _scope = value),
        label: Text('${AppCopy.of(context, labelKey)} ($count)'),
      );

  static List<_PratyantarPeriod> _flatten(
    Map<String, Object?> vimshottari,
    List<Map<String, Object?>> timingWindows,
    List<Map<String, Object?>> dashaActivationProfiles,
    List<Map<String, Object?>> pratyantardashaInterpretations,
  ) {
    final birth = DateTime.parse(vimshottari['birthUtc']! as String).toUtc();
    final periods = <_PratyantarPeriod>[];
    final profiles = <String, _ActivationProfile>{
      for (final value in dashaActivationProfiles)
        if (value['lord'] is String)
          value['lord']! as String: _ActivationProfile.fromJson(value),
    };
    final interpretations = <String, _DetailedInterpretation>{
      for (final value in pratyantardashaInterpretations)
        if (_DetailedInterpretation.canParse(value))
          _DetailedInterpretation.keyFromJson(value):
              _DetailedInterpretation.fromJson(value),
    };
    final mahadashas = vimshottari['mahadashas']! as List;
    for (final rawMaha in mahadashas.whereType<Map>()) {
      final maha = Map<String, Object?>.from(rawMaha);
      final antardashas = maha['antardashas']! as List;
      for (final rawAntar in antardashas.whereType<Map>()) {
        final antar = Map<String, Object?>.from(rawAntar);
        final antarStart =
            DateTime.parse(antar['startUtc']! as String).toUtc();
        final antarEnd = DateTime.parse(antar['endUtc']! as String).toUtc();
        final matchingTimings = timingWindows.where((timing) {
          final start = DateTime.tryParse(timing['start'] as String? ?? '');
          final end = DateTime.tryParse(timing['end'] as String? ?? '');
          return start?.toUtc() == antarStart && end?.toUtc() == antarEnd;
        }).toList(growable: false);
        final parentTiming =
            matchingTimings.isEmpty ? null : matchingTimings.first;
        final pratyantardashas = antar['pratyantardashas']! as List;
        for (final rawPratyantar in pratyantardashas.whereType<Map>()) {
          final pratyantar = Map<String, Object?>.from(rawPratyantar);
          final start =
              DateTime.parse(pratyantar['startUtc']! as String).toUtc();
          final end =
              DateTime.parse(pratyantar['endUtc']! as String).toUtc();
          if (!end.isAfter(birth)) continue;
          final mahaLord = maha['lord']! as String;
          final antarLord = antar['antardashaLord']! as String;
          final pratyantarLord =
              pratyantar['pratyantardashaLord']! as String;
          final detailed = interpretations[
            _DetailedInterpretation.key(
              mahaLord,
              antarLord,
              pratyantarLord,
              start,
              end,
            )
          ];
          final mahaProfile = profiles[mahaLord];
          final antarProfile = profiles[antarLord];
          final pratyantarProfile = profiles[pratyantarLord];
          final completeProfiles = mahaProfile != null &&
              antarProfile != null &&
              pratyantarProfile != null;
          final scores = completeProfiles
              ? [
                  mahaProfile!.score,
                  antarProfile!.score,
                  pratyantarProfile!.score,
                ]
              : const <int>[];
          final nonZeroSigns = scores
              .where((score) => score != 0)
              .map((score) => score.sign)
              .toSet();
          final fallbackWeightedScore = completeProfiles
              ? (mahaProfile!.score * 3) +
                  (antarProfile!.score * 2) +
                  pratyantarProfile!.score
              : null;
          final weightedScore = detailed?.weightedScore ?? fallbackWeightedScore;
          final combinedPolarity = detailed?.polarity ??
              (completeProfiles
                  ? nonZeroSigns.length > 1
                      ? 'mixed'
                      : _weightedPolarity(fallbackWeightedScore!)
                  : parentTiming?['polarity'] as String?);
          final activatedAreas = detailed?.lifeAreas ??
              (completeProfiles
                  ? _reinforcedLifeAreas([
                      mahaProfile!.lifeAreas,
                      antarProfile!.lifeAreas,
                      pratyantarProfile!.lifeAreas,
                    ], pratyantarProfile!.lifeAreas)
                  : const <String>[]);
          periods.add(
            _PratyantarPeriod(
              mahaLord: mahaLord,
              antarLord: antarLord,
              pratyantarLord: pratyantarLord,
              start: start,
              end: end,
              polarity: combinedPolarity,
              confidence: detailed?.confidence ??
                  parentTiming?['confidence'] as String?,
              narrativeEn: parentTiming?['narrativeEn'] as String?,
              narrativeBn: parentTiming?['narrativeBn'] as String?,
              pratyantarScore: detailed?.pratyantardashaScore ??
                  pratyantarProfile?.score,
              pratyantarPolarity: pratyantarProfile?.polarity ??
                  _profilePolarity(detailed?.pratyantardashaScore),
              weightedScore: weightedScore,
              contradictorySignals: detailed?.contradictorySignals ??
                  nonZeroSigns.length > 1,
              activatedAreas: activatedAreas,
              pratyantarSummaryEn: pratyantarProfile?.summaryEn,
              pratyantarSummaryBn: pratyantarProfile?.summaryBn,
              detailedTitleEn: detailed?.titleEn,
              detailedTitleBn: detailed?.titleBn,
              detailedNarrativeEn: detailed?.narrativeEn,
              detailedNarrativeBn: detailed?.narrativeBn,
              triggerRelation: detailed?.triggerRelation,
            ),
          );
        }
      }
    }
    return periods;
  }

  static String _weightedPolarity(int score) => score >= 6
      ? 'supportive'
      : score <= -6
          ? 'challenging'
          : 'mixed';

  static String? _profilePolarity(int? score) => score == null
      ? null
      : score >= 2
          ? 'supportive'
          : score <= -2
              ? 'challenging'
              : 'mixed';

  static List<String> _reinforcedLifeAreas(
    List<List<String>> levels,
    List<String> fallback,
  ) {
    final counts = <String, int>{};
    for (final level in levels) {
      for (final area in level.toSet()) {
        counts[area] = (counts[area] ?? 0) + 1;
      }
    }
    final reinforced = counts.entries
        .where((entry) => entry.value >= 2)
        .map((entry) => entry.key)
        .toList(growable: false);
    return reinforced.isEmpty ? fallback : reinforced;
  }
}

class _CurrentDashaCard extends StatelessWidget {
  const _CurrentDashaCard({required this.period});

  final _PratyantarPeriod? period;

  @override
  Widget build(BuildContext context) {
    final current = period;
    if (current == null) {
      return Card(
        child: ListTile(
          leading: const Icon(Icons.info_outline),
          title: Text(AppCopy.of(context, 'noCurrentDasha')),
        ),
      );
    }
    return Card(
      child: ListTile(
        leading: const Icon(Icons.play_circle_outline),
        title: Text(AppCopy.of(context, 'currentDasha')),
        subtitle: Text(
          '${_chain(context, current)}\n'
          '${_date(current.start)} → ${_date(current.end)}',
        ),
        isThreeLine: true,
      ),
    );
  }
}

class _PeriodCard extends StatelessWidget {
  const _PeriodCard({required this.period});

  final _PratyantarPeriod period;

  @override
  Widget build(BuildContext context) {
    final bengali = Localizations.localeOf(context).languageCode == 'bn';
    final narrative = bengali ? period.narrativeBn : period.narrativeEn;
    final pratyantarSummary =
        bengali ? period.pratyantarSummaryBn : period.pratyantarSummaryEn;
    final detailedTitle =
        bengali ? period.detailedTitleBn : period.detailedTitleEn;
    final detailedNarrative =
        bengali ? period.detailedNarrativeBn : period.detailedNarrativeEn;
    final polarity = period.polarity == null
        ? AppCopy.of(context, 'reviewRequired')
        : AppCopy.of(context, period.polarity!);
    return Card(
      child: ExpansionTile(
        leading: const Icon(Icons.account_tree_outlined),
        title: Text(_chain(context, period)),
        subtitle: Text('${_date(period.start)} → ${_date(period.end)} • $polarity'),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            period.pratyantarScore == null
                ? AppCopy.of(context, 'pratyantarNoJudgment')
                : '${AppCopy.of(context, 'pratyantarOwnTendency')}: '
                    '${AppCopy.of(context, period.pratyantarPolarity!)} • '
                    '${AppCopy.of(context, 'score')}: '
                    '${period.pratyantarScore}',
          ),
          if (period.weightedScore != null) ...[
            const SizedBox(height: 8),
            Text(
              '${AppCopy.of(context, 'threeLevelDashaSynthesis')}: '
              '$polarity • ${AppCopy.of(context, 'weightedScore')}: '
              '${period.weightedScore} '
              '(${AppCopy.of(context, 'dashaWeightFormula')})',
            ),
          ],
          if (period.contradictorySignals) ...[
            const SizedBox(height: 8),
            Text(AppCopy.of(context, 'contradictoryDashaSignals')),
          ],
          if (period.activatedAreas.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '${AppCopy.of(context, 'activatedLifeAreas')}: '
              '${period.activatedAreas.map((area) => AppCopy.of(context, area)).join(', ')}',
            ),
          ],
          if (detailedNarrative != null) ...[
            const SizedBox(height: 12),
            Text(
              AppCopy.of(context, 'pratyantarDetailedInterpretation'),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            if (detailedTitle != null) ...[
              const SizedBox(height: 4),
              Text(detailedTitle),
            ],
            if (period.triggerRelation != null) ...[
              const SizedBox(height: 6),
              Text(
                '${AppCopy.of(context, 'pratyantarTriggerRelation')}: '
                '${AppCopy.of(context, 'pratyantarTrigger_${period.triggerRelation}')} ',
              ),
            ],
            const SizedBox(height: 6),
            Text(detailedNarrative),
          ],
          if (pratyantarSummary != null) ...[
            const SizedBox(height: 8),
            Text(pratyantarSummary),
          ],
          if (narrative != null) ...[
            const SizedBox(height: 8),
            Text(narrative),
          ],
        ],
      ),
    );
  }
}

class _PratyantarPeriod {
  const _PratyantarPeriod({
    required this.mahaLord,
    required this.antarLord,
    required this.pratyantarLord,
    required this.start,
    required this.end,
    required this.polarity,
    required this.confidence,
    required this.narrativeEn,
    required this.narrativeBn,
    required this.pratyantarScore,
    required this.pratyantarPolarity,
    required this.weightedScore,
    required this.contradictorySignals,
    required this.activatedAreas,
    required this.pratyantarSummaryEn,
    required this.pratyantarSummaryBn,
    required this.detailedTitleEn,
    required this.detailedTitleBn,
    required this.detailedNarrativeEn,
    required this.detailedNarrativeBn,
    required this.triggerRelation,
  });

  final String mahaLord;
  final String antarLord;
  final String pratyantarLord;
  final DateTime start;
  final DateTime end;
  final String? polarity;
  final String? confidence;
  final String? narrativeEn;
  final String? narrativeBn;
  final int? pratyantarScore;
  final String? pratyantarPolarity;
  final int? weightedScore;
  final bool contradictorySignals;
  final List<String> activatedAreas;
  final String? pratyantarSummaryEn;
  final String? pratyantarSummaryBn;
  final String? detailedTitleEn;
  final String? detailedTitleBn;
  final String? detailedNarrativeEn;
  final String? detailedNarrativeBn;
  final String? triggerRelation;

  bool contains(DateTime instant) =>
      !instant.isBefore(start) && instant.isBefore(end);
}

class _DetailedInterpretation {
  const _DetailedInterpretation({
    required this.pratyantardashaScore,
    required this.weightedScore,
    required this.polarity,
    required this.confidence,
    required this.contradictorySignals,
    required this.lifeAreas,
    required this.titleEn,
    required this.titleBn,
    required this.narrativeEn,
    required this.narrativeBn,
    required this.triggerRelation,
  });

  factory _DetailedInterpretation.fromJson(Map<String, Object?> json) =>
      _DetailedInterpretation(
        pratyantardashaScore:
            (json['pratyantardashaScore']! as num).toInt(),
        weightedScore: (json['weightedScore']! as num).toInt(),
        polarity: json['polarity']! as String,
        confidence: json['confidence']! as String,
        contradictorySignals: json['contradictorySignals']! as bool,
        lifeAreas: (json['lifeAreas']! as List).whereType<String>().toList(),
        titleEn: json['titleEn']! as String,
        titleBn: json['titleBn']! as String,
        narrativeEn: json['narrativeEn']! as String,
        narrativeBn: json['narrativeBn']! as String,
        triggerRelation: json['triggerRelation']! as String,
      );

  final int pratyantardashaScore;
  final int weightedScore;
  final String polarity;
  final String confidence;
  final bool contradictorySignals;
  final List<String> lifeAreas;
  final String titleEn;
  final String titleBn;
  final String narrativeEn;
  final String narrativeBn;
  final String triggerRelation;

  static bool canParse(Map<String, Object?> json) =>
      json['mahadashaLord'] is String &&
      json['antardashaLord'] is String &&
      json['pratyantardashaLord'] is String &&
      json['startUtc'] is String &&
      json['endUtc'] is String &&
      json['pratyantardashaScore'] is num &&
      json['weightedScore'] is num &&
      json['polarity'] is String &&
      json['confidence'] is String &&
      json['contradictorySignals'] is bool &&
      json['lifeAreas'] is List &&
      json['titleEn'] is String &&
      json['titleBn'] is String &&
      json['narrativeEn'] is String &&
      json['narrativeBn'] is String &&
      json['triggerRelation'] is String &&
      DateTime.tryParse(json['startUtc']! as String) != null &&
      DateTime.tryParse(json['endUtc']! as String) != null;

  static String keyFromJson(Map<String, Object?> json) => key(
        json['mahadashaLord']! as String,
        json['antardashaLord']! as String,
        json['pratyantardashaLord']! as String,
        DateTime.parse(json['startUtc']! as String).toUtc(),
        DateTime.parse(json['endUtc']! as String).toUtc(),
      );

  static String key(
    String mahaLord,
    String antarLord,
    String pratyantarLord,
    DateTime start,
    DateTime end,
  ) =>
      '$mahaLord|$antarLord|$pratyantarLord|${start.toUtc().toIso8601String()}|${end.toUtc().toIso8601String()}';
}

class _ActivationProfile {
  const _ActivationProfile({
    required this.score,
    required this.polarity,
    required this.lifeAreas,
    required this.summaryEn,
    required this.summaryBn,
  });

  factory _ActivationProfile.fromJson(Map<String, Object?> json) =>
      _ActivationProfile(
        score: (json['score']! as num).toInt(),
        polarity: json['polarity']! as String,
        lifeAreas: (json['lifeAreas']! as List).whereType<String>().toList(),
        summaryEn: json['summaryEn']! as String,
        summaryBn: json['summaryBn']! as String,
      );

  final int score;
  final String polarity;
  final List<String> lifeAreas;
  final String summaryEn;
  final String summaryBn;
}

enum _TimelineScope { current, past, future }

String _chain(BuildContext context, _PratyantarPeriod period) =>
    '${AppCopy.of(context, period.mahaLord)} / '
    '${AppCopy.of(context, period.antarLord)} / '
    '${AppCopy.of(context, period.pratyantarLord)}';

String _date(DateTime value) {
  final local = value.toLocal();
  String two(int number) => number.toString().padLeft(2, '0');
  return '${two(local.day)}-${two(local.month)}-${local.year}';
}
