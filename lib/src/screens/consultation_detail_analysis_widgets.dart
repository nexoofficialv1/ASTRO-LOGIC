part of 'consultation_detail_screen.dart';

class _AshtakavargaMatrix extends StatelessWidget {
  const _AshtakavargaMatrix({
    required this.profile,
    required this.bengali,
  });

  final Map<String, Object?> profile;
  final bool bengali;

  static const _signsEn = <String>[
    'Ar', 'Ta', 'Ge', 'Cn', 'Le', 'Vi', 'Li', 'Sc', 'Sg', 'Cp', 'Aq', 'Pi',
  ];
  static const _signsBn = <String>[
    'মেষ', 'বৃষ', 'মিথুন', 'কর্কট', 'সিংহ', 'কন্যা',
    'তুলা', 'বৃশ্চিক', 'ধনু', 'মকর', 'কুম্ভ', 'মীন',
  ];
  static const _planetEn = <String, String>{
    'sun': 'Sun',
    'moon': 'Moon',
    'mars': 'Mars',
    'mercury': 'Mercury',
    'jupiter': 'Jupiter',
    'venus': 'Venus',
    'saturn': 'Saturn',
  };
  static const _planetBn = <String, String>{
    'sun': 'সূর্য',
    'moon': 'চন্দ্র',
    'mars': 'মঙ্গল',
    'mercury': 'বুধ',
    'jupiter': 'বৃহস্পতি',
    'venus': 'শুক্র',
    'saturn': 'শনি',
  };

  @override
  Widget build(BuildContext context) {
    final sav = (profile['sarvashtakavarga'] as List? ?? const [])
        .whereType<Map>()
        .map((value) => Map<String, Object?>.from(value))
        .toList(growable: false)
      ..sort((a, b) =>
          (a['houseNumber'] as num).toInt().compareTo((b['houseNumber'] as num).toInt()));
    final bav = (profile['bhinnashtakavarga'] as List? ?? const [])
        .whereType<Map>()
        .map((value) => Map<String, Object?>.from(value))
        .toList(growable: false);
    final total = (profile['totalPositiveMarks'] as num?)?.toInt();
    final average = (profile['averagePositiveMarks'] as num?)?.toDouble();
    final reduction = profile['reductionProfile'] is Map
        ? Map<String, Object?>.from(profile['reductionProfile']! as Map)
        : null;
    final reducedByPlanet = <String, Map<String, Object?>>{
      for (final value in (reduction?['planets'] as List? ?? const []).whereType<Map>())
        if (value['planet'] is String)
          value['planet'] as String: Map<String, Object?>.from(value),
    };
    final reducedAggregate = (reduction?['reducedAggregateMarks'] as List? ?? const [])
        .whereType<num>()
        .map((value) => value.toInt())
        .toList(growable: false);
    final reducedTotal = (reduction?['reducedAggregateTotal'] as num?)?.toInt();
    final pinda = profile['pindaProfile'] is Map
        ? Map<String, Object?>.from(profile['pindaProfile']! as Map)
        : null;
    final pindaPlanets = (pinda?['planets'] as List? ?? const [])
        .whereType<Map>()
        .map((value) => Map<String, Object?>.from(value))
        .toList(growable: false);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              bengali ? 'অষ্টকবর্গ সংখ্যাতালিকা' : 'Ashtakavarga score matrix',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              bengali
                  ? 'SAV মোট: ${total ?? '—'} • গড়: ${average?.toStringAsFixed(2) ?? '—'} • স্কোরগুলি unreduced positive mark।'
                  : 'SAV total: ${total ?? '—'} • average: ${average?.toStringAsFixed(2) ?? '—'} • scores are unreduced positive marks.',
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final row in sav)
                  Chip(
                    label: Text(
                      '${bengali ? 'ভাব' : 'H'}${row['houseNumber']} · ${row['positiveMarks']}',
                    ),
                  ),
              ],
            ),
            const Divider(height: 24),
            for (final row in bav)
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(bottom: 10),
                title: Text(
                  '${(bengali ? _planetBn : _planetEn)[row['planet']] ?? row['planet']} '
                  '(${row['totalPositiveMarks']}/${row['fixedTotalPositiveMarks']})',
                ),
                children: [
                  Builder(
                    builder: (context) {
                      final reduced = reducedByPlanet[row['planet']];
                      final trikona = (reduced?['trikonaReducedMarks'] as List? ?? const [])
                          .whereType<num>()
                          .map((value) => value.toInt())
                          .toList(growable: false);
                      final ekadhipatya =
                          (reduced?['ekadhipatyaReducedMarks'] as List? ?? const [])
                              .whereType<num>()
                              .map((value) => value.toInt())
                              .toList(growable: false);
                      return Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final sign in (row['signs'] as List? ?? const [])
                              .whereType<Map>()
                              .map((value) => Map<String, Object?>.from(value)))
                            Chip(
                              visualDensity: VisualDensity.compact,
                              label: Text(() {
                                final index = (sign['signIndex'] as num).toInt();
                                final raw = (sign['positiveMarks'] as num).toInt();
                                final t = index < trikona.length ? trikona[index] : null;
                                final e = index < ekadhipatya.length ? ekadhipatya[index] : null;
                                final name = (bengali ? _signsBn : _signsEn)[index];
                                return t == null || e == null
                                    ? '$name $raw'
                                    : '$name $raw→$t→$e';
                              }()),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            if (reduction != null) ...[
              const Divider(height: 24),
              Text(
                bengali
                    ? 'Shodhana: Raw → Trikona → Ekadhipatya'
                    : 'Shodhana: Raw → Trikona → Ekadhipatya',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 6),
              Text(
                bengali
                    ? 'Reduced aggregate মোট: ${reducedTotal ?? '—'}। এই reduced score-এ raw SAV-এর >30 / 25–30 / <25 band প্রয়োগ করা হয় না।'
                    : 'Reduced aggregate total: ${reducedTotal ?? '—'}. Raw-SAV >30 / 25–30 / <25 bands are not applied to this reduced stage.',
              ),
              if (reducedAggregate.length == 12) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (var index = 0; index < 12; index += 1)
                      Chip(
                        visualDensity: VisualDensity.compact,
                        label: Text(
                          '${(bengali ? _signsBn : _signsEn)[index]} ${reducedAggregate[index]}',
                        ),
                      ),
                  ],
                ),
              ],
            ],
            if (pindaPlanets.isNotEmpty) ...[
              const Divider(height: 24),
              Text(
                bengali ? 'Shodhya Pinda' : 'Shodhya Pinda',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 6),
              Text(
                bengali
                    ? 'Ekadhipatya-reduced BAV থেকে Rashi Pinda + Graha Pinda = Shodhya/Yoga Pinda। এটি এখন calculation/audit layer; timing guarantee নয়।'
                    : 'From the Ekadhipatya-reduced BAV: Rashi Pinda + Graha Pinda = Shodhya/Yoga Pinda. This is currently a calculation/audit layer, not a timing guarantee.',
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final row in pindaPlanets)
                    Chip(
                      visualDensity: VisualDensity.compact,
                      label: Text(
                        '${(bengali ? _planetBn : _planetEn)[row['planet']] ?? row['planet']} '
                        '${row['rashiPinda'] ?? '—'} + ${row['grahaPinda'] ?? '—'} = ${row['shodhyaPinda'] ?? '—'}',
                      ),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 6),
            Text(
              bengali
                  ? 'নোট: 337 শুধু unreduced SAV-এর fixed checksum। BAV chip-এ Raw→Trikona→Ekadhipatya দেখানো হয়; Pinda reduction-পরবর্তী আলাদা calculation stage।'
                  : 'Note: 337 is only the fixed unreduced-SAV checksum. BAV chips show Raw→Trikona→Ekadhipatya; Pinda is a separate post-reduction calculation stage.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _FindingGroup extends StatelessWidget {
  const _FindingGroup({
    required this.title,
    required this.findings,
    required this.bengali,
  });

  final String title;
  final List<Map<String, Object?>> findings;
  final bool bengali;

  @override
  Widget build(BuildContext context) {
    if (findings.isEmpty) return const SizedBox.shrink();
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Text(title, style: textTheme.titleMedium),
        const SizedBox(height: 6),
        for (final finding in findings)
          Card(
            child: ExpansionTile(
              leading: const Icon(Icons.rule_folder_outlined),
              title: Text(
                finding[bengali ? 'titleBn' : 'titleEn'] as String? ?? '',
              ),
              subtitle: Text(
                '${AppCopy.of(context, finding['area'] as String? ?? '')} • '
                '${AppCopy.of(context, finding['polarity'] as String? ?? '')} • '
                '${AppCopy.of(context, finding['confidence'] as String? ?? '')}',
              ),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  finding[bengali ? 'narrativeBn' : 'narrativeEn']
                          as String? ??
                      '',
                ),
                const SizedBox(height: 12),
                Text(
                  AppCopy.of(context, 'chartEvidence'),
                  style: textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                for (final evidence in
                    (finding['evidence'] as List? ?? const []).whereType<Map>())
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
    );
  }
}

class _StatusActions extends StatelessWidget {
  const _StatusActions({
    required this.consultation,
    required this.outputsExist,
    required this.onTransition,
  });

  final Consultation consultation;
  final bool outputsExist;
  final ValueChanged<ConsultationStatus> onTransition;

  @override
  Widget build(BuildContext context) {
    return switch (consultation.status) {
      ConsultationStatus.draft => FilledButton.icon(
          onPressed: outputsExist
              ? () => onTransition(ConsultationStatus.reviewed)
              : null,
          icon: const Icon(Icons.fact_check_outlined),
          label: Text(AppCopy.of(context, 'markReviewed')),
        ),
      ConsultationStatus.reviewed => Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            OutlinedButton.icon(
              onPressed: () => onTransition(ConsultationStatus.draft),
              icon: const Icon(Icons.undo),
              label: Text(AppCopy.of(context, 'reopenDraft')),
            ),
            FilledButton.icon(
              onPressed: outputsExist
                  ? () => onTransition(ConsultationStatus.finalized)
                  : null,
              icon: const Icon(Icons.lock_outline),
              label: Text(AppCopy.of(context, 'finalizeConsultation')),
            ),
          ],
        ),
      ConsultationStatus.finalized => ListTile(
          leading: const Icon(Icons.lock),
          title: Text(AppCopy.of(context, 'finalizedLocked')),
        ),
    };
  }
}
