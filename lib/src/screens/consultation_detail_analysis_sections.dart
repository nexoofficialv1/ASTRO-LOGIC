part of 'consultation_detail_screen.dart';

class _NumerologySnapshotSection extends StatelessWidget {
  const _NumerologySnapshotSection({required this.snapshots});

  final List<NumerologySnapshot> snapshots;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                AppCopy.of(context, 'savedNumerologySnapshots'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Chip(
              label: Text(
                '${AppCopy.of(context, 'analysisVersions')}: ${snapshots.length}',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(AppCopy.of(context, 'numerologyImmutableNote')),
        if (snapshots.isEmpty) ...[
          const SizedBox(height: 8),
          Text(AppCopy.of(context, 'noNumerologySnapshots')),
        ],
        for (final snapshot in snapshots)
          Card(
            child: ExpansionTile(
              leading: const Icon(Icons.lock_outline),
              title: Text(
                '${snapshot.nameLatin} · ${snapshot.targetYear}',
              ),
              subtitle: Text(
                '${snapshot.calculationSchemaVersion} · '
                '${snapshot.snapshotHash.substring(0, 16)}…',
              ),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: [
                _snapshotNumber(
                  context,
                  'driverNumber',
                  snapshot.calculation['driver'],
                ),
                _snapshotNumber(
                  context,
                  'lifePathNumber',
                  snapshot.calculation['lifePath'],
                ),
                _snapshotNumber(
                  context,
                  'personalYearNumber',
                  snapshot.calculation['personalYear'],
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: SelectableText(
                    '${AppCopy.of(context, 'snapshotHash')}: '
                    '${snapshot.snapshotHash}',
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _snapshotNumber(
    BuildContext context,
    String labelKey,
    Object? rawValue,
  ) {
    final value = rawValue is Map
        ? Map<String, Object?>.from(rawValue)
        : const <String, Object?>{};
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        '${AppCopy.of(context, labelKey)}: '
        '${value['compound'] ?? '—'} → ${value['reduced'] ?? '—'}',
      ),
    );
  }
}

class _KundliAnalysisSection extends StatelessWidget {
  const _KundliAnalysisSection({required this.analyses});

  final List<KundliAnalysisSnapshot> analyses;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    if (analyses.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppCopy.of(context, 'kundliAnalysis'),
            style: textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(AppCopy.of(context, 'noKundliAnalysis')),
        ],
      );
    }
    final latest = analyses.first;
    final analysis = latest.analysis;
    final findings = (analysis['findings'] as List? ?? const [])
        .whereType<Map>()
        .map((value) => Map<String, Object?>.from(value))
        .toList(growable: false);
    final lagnaFindings = findings
        .where((value) =>
            !(value['code'] as String).startsWith('vedic.yoga.') &&
            !(value['code'] as String).startsWith('vedic.dosha.') &&
            !(value['code'] as String).startsWith('vedic.divisional.') &&
            !(value['code'] as String).startsWith('vedic.life_area.') &&
            !(value['code'] as String).startsWith('vedic.house.') &&
            !(value['code'] as String).startsWith('vedic.occupancy.') &&
            !(value['code'] as String).startsWith('vedic.aspect.') &&
            !(value['code'] as String).startsWith('vedic.aspect_synthesis.') &&
            !(value['code'] as String).startsWith('vedic.conjunction.') &&
            !(value['code'] as String).startsWith('vedic.condition.') &&
            !(value['code'] as String).startsWith('vedic.friendship.') &&
            !(value['code'] as String)
                .startsWith('vedic.compound_friendship.') &&
            !(value['code'] as String).startsWith('vedic.moolatrikona.') &&
            !(value['code'] as String).startsWith('vedic.planetary_war.') &&
            !(value['code'] as String).startsWith('vedic.functional_role.') &&
            !(value['code'] as String).startsWith('vedic.shadbala.') &&
            !(value['code'] as String).startsWith('vedic.ashtakavarga.'))
        .toList(growable: false);
    final d9Findings = findings
        .where((value) =>
            (value['code'] as String).startsWith('vedic.divisional.d9.'))
        .toList(growable: false);
    final d10Findings = findings
        .where((value) =>
            (value['code'] as String).startsWith('vedic.divisional.d10.'))
        .toList(growable: false);
    final shadbalaFindings = findings
        .where((value) =>
            (value['code'] as String).startsWith('vedic.shadbala.'))
        .toList(growable: false);
    final ashtakavargaFindings = findings
        .where((value) =>
            (value['code'] as String).startsWith('vedic.ashtakavarga.'))
        .toList(growable: false);
    final yogaDoshaFindings = findings
        .where((value) =>
            (value['code'] as String).startsWith('vedic.yoga.') ||
            (value['code'] as String).startsWith('vedic.dosha.'))
        .toList(growable: false);
    final detailedLifeAreaFindings = findings
        .where((value) =>
            (value['code'] as String).startsWith('vedic.life_area.'))
        .toList(growable: false);
    final houseFindings = findings
        .where(
          (value) => (value['code'] as String).startsWith('vedic.house.'),
        )
        .toList(growable: false);
    final functionalFindings = findings
        .where((value) =>
            (value['code'] as String).startsWith('vedic.functional_role.'))
        .toList(growable: false);
    final occupancyFindings = findings
        .where((value) =>
            (value['code'] as String).startsWith('vedic.occupancy.'))
        .toList(growable: false);
    final aspectFindings = findings
        .where(
          (value) => (value['code'] as String).startsWith('vedic.aspect.'),
        )
        .toList(growable: false);
    final conditionFindings = findings
        .where((value) =>
            (value['code'] as String).startsWith('vedic.condition.'))
        .toList(growable: false);
    final aspectSynthesisFindings = findings
        .where((value) =>
            (value['code'] as String).startsWith('vedic.aspect_synthesis.'))
        .toList(growable: false);
    final conjunctionFindings = findings
        .where((value) =>
            (value['code'] as String).startsWith('vedic.conjunction.'))
        .toList(growable: false);
    final friendshipAndMoolatrikonaFindings = findings
        .where((value) =>
            (value['code'] as String).startsWith('vedic.friendship.') ||
            (value['code'] as String)
                .startsWith('vedic.compound_friendship.') ||
            (value['code'] as String).startsWith('vedic.moolatrikona.'))
        .toList(growable: false);
    final planetaryWarFindings = findings
        .where((value) =>
            (value['code'] as String).startsWith('vedic.planetary_war.'))
        .toList(growable: false);
    final timingWindows = (analysis['timingWindows'] as List? ?? const [])
        .whereType<Map>()
        .map((value) => Map<String, Object?>.from(value))
        .toList(growable: false);
    final remedies = (analysis['remedyCandidates'] as List? ?? const [])
        .whereType<Map>()
        .map((value) => Map<String, Object?>.from(value))
        .toList(growable: false);
    final gemstoneCandidates =
        (analysis['gemstoneCandidateReviews'] as List? ?? const [])
            .whereType<Map>()
            .map((value) => Map<String, Object?>.from(value))
            .toList(growable: false);
    final bengali = Localizations.localeOf(context).languageCode == 'bn';
    final warnings = (analysis[bengali ? 'warningsBn' : 'warningsEn']
                as List? ??
            const [])
        .whereType<String>()
        .toList(growable: false);
    final ashtakavargaProfile = analysis['ashtakavargaProfile'] is Map
        ? Map<String, Object?>.from(analysis['ashtakavargaProfile']! as Map)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                AppCopy.of(context, 'kundliAnalysis'),
                style: textTheme.titleLarge,
              ),
            ),
            Chip(
              label: Text(
                '${AppCopy.of(context, 'analysisVersions')}: ${analyses.length}',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(AppCopy.of(context, 'professionalReviewRequired')),
        const SizedBox(height: 8),
        _FindingGroup(
          title: AppCopy.of(context, 'lagnaJudgment'),
          findings: lagnaFindings,
          bengali: bengali,
        ),
        _FindingGroup(
          title: AppCopy.of(context, 'yogaDoshaReview'),
          findings: yogaDoshaFindings,
          bengali: bengali,
        ),
        _FindingGroup(
          title: AppCopy.of(context, 'd1D9Agreement'),
          findings: d9Findings,
          bengali: bengali,
        ),
        _FindingGroup(
          title: AppCopy.of(context, 'd10CareerReview'),
          findings: d10Findings,
          bengali: bengali,
        ),
        _FindingGroup(
          title: AppCopy.of(context, 'shadbalaReview'),
          findings: shadbalaFindings,
          bengali: bengali,
        ),
        _FindingGroup(
          title: AppCopy.of(context, 'ashtakavargaReview'),
          findings: ashtakavargaFindings,
          bengali: bengali,
        ),
        if (ashtakavargaProfile != null)
          _AshtakavargaMatrix(
            profile: ashtakavargaProfile,
            bengali: bengali,
          ),
        _FindingGroup(
          title: AppCopy.of(context, 'detailedLifeAreaJudgment'),
          findings: detailedLifeAreaFindings,
          bengali: bengali,
        ),
        _FindingGroup(
          title: AppCopy.of(context, 'twelveHouseJudgment'),
          findings: houseFindings,
          bengali: bengali,
        ),
        _FindingGroup(
          title: AppCopy.of(context, 'houseOccupancy'),
          findings: occupancyFindings,
          bengali: bengali,
        ),
        _FindingGroup(
          title: AppCopy.of(context, 'parashariAspects'),
          findings: aspectFindings,
          bengali: bengali,
        ),
        _FindingGroup(
          title: AppCopy.of(context, 'aspectSynthesis'),
          findings: aspectSynthesisFindings,
          bengali: bengali,
        ),
        _FindingGroup(
          title: AppCopy.of(context, 'conjunctions'),
          findings: conjunctionFindings,
          bengali: bengali,
        ),
        _FindingGroup(
          title: AppCopy.of(context, 'planetConditions'),
          findings: conditionFindings,
          bengali: bengali,
        ),
        _FindingGroup(
          title: AppCopy.of(context, 'friendshipAndMoolatrikona'),
          findings: friendshipAndMoolatrikonaFindings,
          bengali: bengali,
        ),
        _FindingGroup(
          title: AppCopy.of(context, 'planetaryWarReview'),
          findings: planetaryWarFindings,
          bengali: bengali,
        ),
        _FindingGroup(
          title: AppCopy.of(context, 'functionalPlanetRoles'),
          findings: functionalFindings,
          bengali: bengali,
        ),
        if (timingWindows.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            AppCopy.of(context, 'vimshottariTiming'),
            style: textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          for (final timing in timingWindows)
            Card(
              child: ExpansionTile(
                leading: const Icon(Icons.timeline_outlined),
                title: Text(
                  '${_timingDate(timing['start'])} → '
                  '${_timingDate(timing['end'])}',
                ),
                subtitle: Text(
                  '${AppCopy.of(context, timing['polarity'] as String? ?? '')} • '
                  '${AppCopy.of(context, timing['confidence'] as String? ?? '')}',
                ),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                expandedCrossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    timing[bengali ? 'narrativeBn' : 'narrativeEn']
                            as String? ??
                        '',
                  ),
                  const SizedBox(height: 10),
                  for (final evidence in
                      (timing['evidence'] as List? ?? const [])
                          .whereType<Map>())
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        '• ${evidence[bengali ? 'descriptionBn' : 'descriptionEn']}\n'
                        '  ${evidence['ruleId']} — ${evidence['outputPath']}',
                      ),
                    ),
                ],
              ),
            ),
        ],

        if (gemstoneCandidates.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            AppCopy.of(context, 'gemstoneCandidateReview'),
            style: textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          for (final candidate in gemstoneCandidates)
            Card(
              child: ExpansionTile(
                leading: const Icon(Icons.diamond_outlined),
                title: Text(
                  '${AppCopy.of(context, candidate['planet'] as String? ?? '')} · '
                  '${candidate[bengali ? 'primaryGemstoneBn' : 'primaryGemstone'] ?? ''}',
                ),
                subtitle: Text(
                  AppCopy.of(
                    context,
                    candidate['status'] as String? ?? 'insufficientEvidence',
                  ),
                ),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                expandedCrossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    candidate[bengali ? 'rationaleBn' : 'rationaleEn']
                            as String? ??
                        '',
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${AppCopy.of(context, 'cautions')}: '
                    '${candidate[bengali ? 'cautionBn' : 'cautionEn'] ?? ''}',
                  ),
                  const SizedBox(height: 10),
                  for (final evidence in
                      (candidate['evidence'] as List? ?? const [])
                          .whereType<Map>())
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        '• ${evidence[bengali ? 'descriptionBn' : 'descriptionEn'] ?? ''}\n'
                        '  ${evidence['ruleId']} — ${evidence['outputPath']}',
                      ),
                    ),
                ],
              ),
            ),
        ],
        if (remedies.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            AppCopy.of(context, 'remedyCandidates'),
            style: textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          for (final remedy in remedies)
            Card(
              child: ExpansionTile(
                leading: const Icon(Icons.diamond_outlined),
                title: Text(
                  remedy[bengali ? 'actionBn' : 'actionEn'] as String? ?? '',
                ),
                subtitle: Text(
                  remedy[bengali ? 'rationaleBn' : 'rationaleEn'] as String? ??
                      '',
                ),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                expandedCrossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${AppCopy.of(context, 'cautions')}: '
                    '${remedy[bengali ? 'cautionBn' : 'cautionEn']}',
                  ),
                  const SizedBox(height: 10),
                  for (final evidence in
                      (remedy['evidence'] as List? ?? const []).whereType<Map>())
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        '• ${evidence[bengali ? 'descriptionBn' : 'descriptionEn']}\n'
                        '  ${evidence['ruleId']} — ${evidence['outputPath']}',
                      ),
                    ),
                ],
              ),
            ),
        ],
        if (warnings.isNotEmpty) ...[
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppCopy.of(context, 'analysisWarnings'),
                    style: textTheme.titleSmall,
                  ),
                  const SizedBox(height: 6),
                  for (final warning in warnings)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('• $warning'),
                    ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  static String _timingDate(Object? value) {
    if (value is! String) return '—';
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return '—';
    final local = parsed.toLocal();
    String two(int number) => number.toString().padLeft(2, '0');
    return '${two(local.day)}-${two(local.month)}-${local.year}';
  }
}
