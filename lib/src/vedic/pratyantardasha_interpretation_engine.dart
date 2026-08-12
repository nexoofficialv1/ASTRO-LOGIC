import '../models/kundli_analysis.dart';
import 'vimshottari_dasha_engine.dart';

/// Builds chart-specific interpretations for all Vimshottari Pratyantardashas.
///
/// The engine deliberately avoids fixed planet-pair event promises. It reuses
/// the audited chart-specific activation profile for each MD/AD/PD lord, keeps
/// the governed 3:2:1 hierarchy, and treats Pratyantardasha as the narrowest
/// activation/trigger layer that still requires transit and question-specific
/// confirmation.
class PratyantardashaInterpretationEngine {
  const PratyantardashaInterpretationEngine._();

  static const ruleVersion = 'pratyantardasha-interpretation-v1';

  static List<PratyantardashaInterpretation> build({
    required Object? rawVimshottari,
    required List<DashaActivationProfile> profiles,
  }) {
    final vimshottari = _requiredMap(rawVimshottari, 'vimshottari');
    if (vimshottari['ruleVersion'] != VimshottariDashaEngine.ruleVersion) {
      throw StateError(
        'Pratyantardasha interpretation requires ${VimshottariDashaEngine.ruleVersion}',
      );
    }
    final profileByLord = <String, DashaActivationProfile>{
      for (final profile in profiles) profile.lord: profile,
    };
    if (profileByLord.length != VimshottariDashaEngine.sequence.length ||
        VimshottariDashaEngine.sequence.any(
          (lord) => !profileByLord.containsKey(lord),
        )) {
      throw StateError(
        'Pratyantardasha interpretation requires nine unique Dasha activation profiles',
      );
    }

    final rawMahadashas = vimshottari['mahadashas'];
    if (rawMahadashas is! List ||
        rawMahadashas.length != VimshottariDashaEngine.sequence.length) {
      throw StateError('Vimshottari output requires nine Mahadashas');
    }

    final interpretations = <PratyantardashaInterpretation>[];
    for (var mahaIndex = 0; mahaIndex < rawMahadashas.length; mahaIndex += 1) {
      final mahaPath = 'vimshottari.mahadashas[$mahaIndex]';
      final maha = _requiredMap(rawMahadashas[mahaIndex], mahaPath);
      final mahaLord = _requiredLord(maha['lord'], '$mahaPath.lord');
      final rawAntardashas = maha['antardashas'];
      if (rawAntardashas is! List ||
          rawAntardashas.length != VimshottariDashaEngine.sequence.length) {
        throw StateError('Each Mahadasha requires nine Antardashas');
      }

      for (var antarIndex = 0;
          antarIndex < rawAntardashas.length;
          antarIndex += 1) {
        final antarPath = '$mahaPath.antardashas[$antarIndex]';
        final antar = _requiredMap(rawAntardashas[antarIndex], antarPath);
        final recordedMaha = _requiredLord(
          antar['mahadashaLord'],
          '$antarPath.mahadashaLord',
        );
        final antarLord = _requiredLord(
          antar['antardashaLord'],
          '$antarPath.antardashaLord',
        );
        if (recordedMaha != mahaLord) {
          throw StateError('Antardasha parent lord is inconsistent');
        }
        final rawPratyantardashas = antar['pratyantardashas'];
        if (rawPratyantardashas is! List ||
            rawPratyantardashas.length !=
                VimshottariDashaEngine.sequence.length) {
          throw StateError('Each Antardasha requires nine Pratyantardashas');
        }

        for (var pratyantarIndex = 0;
            pratyantarIndex < rawPratyantardashas.length;
            pratyantarIndex += 1) {
          final periodPath =
              '$antarPath.pratyantardashas[$pratyantarIndex]';
          final period = _requiredMap(
            rawPratyantardashas[pratyantarIndex],
            periodPath,
          );
          final periodMaha = _requiredLord(
            period['mahadashaLord'],
            '$periodPath.mahadashaLord',
          );
          final periodAntar = _requiredLord(
            period['antardashaLord'],
            '$periodPath.antardashaLord',
          );
          final pratyantarLord = _requiredLord(
            period['pratyantardashaLord'],
            '$periodPath.pratyantardashaLord',
          );
          if (periodMaha != mahaLord || periodAntar != antarLord) {
            throw StateError('Pratyantardasha parent lords are inconsistent');
          }
          final startUtc = _requiredUtc(period['startUtc'], '$periodPath.startUtc');
          final endUtc = _requiredUtc(period['endUtc'], '$periodPath.endUtc');
          if (!endUtc.isAfter(startUtc)) {
            throw StateError('Pratyantardasha end must be after start');
          }

          final mahaProfile = profileByLord[mahaLord]!;
          final antarProfile = profileByLord[antarLord]!;
          final pratyantarProfile = profileByLord[pratyantarLord]!;
          final scores = <int>[
            mahaProfile.score,
            antarProfile.score,
            pratyantarProfile.score,
          ];
          final nonZeroSigns = scores
              .where((score) => score != 0)
              .map((score) => score.sign)
              .toSet();
          final contradictorySignals = nonZeroSigns.length > 1;
          final weightedScore = (mahaProfile.score * 3) +
              (antarProfile.score * 2) +
              pratyantarProfile.score;
          final polarity = contradictorySignals
              ? AnalysisPolarity.mixed
              : _weightedPolarity(weightedScore);
          final reinforcedLifeAreas = _reinforcedLifeAreas(
            [
              mahaProfile.lifeAreas,
              antarProfile.lifeAreas,
              pratyantarProfile.lifeAreas,
            ],
            pratyantarProfile.lifeAreas,
          );
          final triggerRelation = _triggerRelation(
            mahaProfile.score,
            antarProfile.score,
            pratyantarProfile.score,
          );
          final confidence = polarity == AnalysisPolarity.mixed ||
                  contradictorySignals
              ? AnalysisConfidence.low
              : AnalysisConfidence.medium;
          final mahaEn = _planetNamesEn[mahaLord]!;
          final antarEn = _planetNamesEn[antarLord]!;
          final pratyantarEn = _planetNamesEn[pratyantarLord]!;
          final mahaBn = _planetNamesBn[mahaLord]!;
          final antarBn = _planetNamesBn[antarLord]!;
          final pratyantarBn = _planetNamesBn[pratyantarLord]!;
          final areasEn = reinforcedLifeAreas
              .map((area) => _lifeAreaNamesEn[area]!)
              .join(', ');
          final areasBn = reinforcedLifeAreas
              .map((area) => _lifeAreaNamesBn[area]!)
              .join(', ');
          final contradictionEn = contradictorySignals
              ? ' The three chart-specific lord signals oppose one another, so the combined interpretation remains Mixed.'
              : '';
          final contradictionBn = contradictorySignals
              ? ' তিনটি chart-specific দশাপতি signal পরস্পরের বিপরীত হওয়ায় সম্মিলিত ব্যাখ্যা Mixed রাখা হয়েছে।'
              : '';
          final triggerEn = _triggerNarrativeEn(
            triggerRelation,
            pratyantarEn,
          );
          final triggerBn = _triggerNarrativeBn(
            triggerRelation,
            pratyantarBn,
          );

          interpretations.add(
            PratyantardashaInterpretation(
              code:
                  'vedic.dasha.pratyantar.$mahaIndex.$antarIndex.$pratyantarIndex.$mahaLord.$antarLord.$pratyantarLord',
              ruleVersion: ruleVersion,
              mahadashaLord: mahaLord,
              antardashaLord: antarLord,
              pratyantardashaLord: pratyantarLord,
              startUtc: startUtc,
              endUtc: endUtc,
              mahadashaScore: mahaProfile.score,
              antardashaScore: antarProfile.score,
              pratyantardashaScore: pratyantarProfile.score,
              weightedScore: weightedScore,
              polarity: polarity,
              confidence: confidence,
              contradictorySignals: contradictorySignals,
              triggerRelation: triggerRelation,
              lifeAreas: reinforcedLifeAreas,
              titleEn:
                  '$mahaEn / $antarEn / $pratyantarEn chart-specific activation',
              titleBn:
                  '$mahaBn / $antarBn / $pratyantarBn চার্টভিত্তিক সক্রিয়তা',
              narrativeEn:
                  '$mahaEn Mahadasha sets the broader activation field: ${mahaProfile.summaryEn} $antarEn Antardasha modifies that field: ${antarProfile.summaryEn} $pratyantarEn Pratyantardasha is the immediate timing layer: ${pratyantarProfile.summaryEn} The governed 3:2:1 weighted score is $weightedScore and the combined polarity is ${polarity.name}.$contradictionEn $triggerEn Priority review areas for this period are $areasEn. This narrows chart activation, not a guaranteed event; transit and the consultation question must still confirm the result.',
              narrativeBn:
                  '$mahaBn মহাদশা বৃহত্তর activation field নির্ধারণ করছে: ${mahaProfile.summaryBn} $antarBn অন্তর্দশা সেই field-কে পরিবর্তিত করছে: ${antarProfile.summaryBn} $pratyantarBn প্রত্যন্তরদশা তাৎক্ষণিক timing layer: ${pratyantarProfile.summaryBn} Governed ৩:২:১ weighted score $weightedScore এবং সম্মিলিত polarity ${polarity.name}।$contradictionBn $triggerBn এই সময়ে অগ্রাধিকার দিয়ে পর্যালোচনার life area: $areasBn। এটি chart activation-এর সময়সীমা সূক্ষ্ম করে, নিশ্চিত ঘটনা বলে না; গোচর ও consultation question দিয়ে ফল নিশ্চিত করতে হবে।',
              evidence: [
                ChartEvidence(
                  ruleId:
                      'vedic.dasha.pratyantar.interpretation.v1.$mahaLord.$antarLord.$pratyantarLord',
                  outputPath: r'$.' + periodPath,
                  kind: EvidenceKind.dasha,
                  descriptionEn:
                      'Exact MD/AD/PD calendar boundaries are combined with the audited chart-specific activation profiles for $mahaEn, $antarEn and $pratyantarEn using the governed 3:2:1 hierarchy.',
                  descriptionBn:
                      'নির্দিষ্ট MD/AD/PD calendar boundary-এর সঙ্গে $mahaBn, $antarBn ও $pratyantarBn-এর audited chart-specific activation profile governed ৩:২:১ hierarchy-তে মিলিয়ে দেখা হয়েছে।',
                ),
              ],
            ),
          );
        }
      }
    }

    if (interpretations.length != 729) {
      throw StateError(
        'Pratyantardasha interpretation must produce exactly 729 periods',
      );
    }
    return List.unmodifiable(interpretations);
  }

  static AnalysisPolarity _weightedPolarity(int score) => score >= 6
      ? AnalysisPolarity.supportive
      : score <= -6
          ? AnalysisPolarity.challenging
          : AnalysisPolarity.mixed;

  static PratyantardashaTriggerRelation _triggerRelation(
    int mahaScore,
    int antarScore,
    int pratyantarScore,
  ) {
    final parentScore = (mahaScore * 3) + (antarScore * 2);
    if (parentScore == 0 || pratyantarScore == 0) {
      return PratyantardashaTriggerRelation.neutral;
    }
    return parentScore.sign == pratyantarScore.sign
        ? PratyantardashaTriggerRelation.reinforcing
        : PratyantardashaTriggerRelation.countertrend;
  }

  static String _triggerNarrativeEn(
    PratyantardashaTriggerRelation relation,
    String lord,
  ) =>
      switch (relation) {
        PratyantardashaTriggerRelation.reinforcing =>
          '$lord reinforces the prevailing MD/AD direction, so its own activated topics deserve closer timing review.',
        PratyantardashaTriggerRelation.countertrend =>
          '$lord runs counter to the prevailing MD/AD direction, so mixed or interrupting manifestations should be reviewed instead of forcing one-sided judgment.',
        PratyantardashaTriggerRelation.neutral =>
          '$lord does not add a directional trigger to the prevailing MD/AD score, so its activated topics remain review-only.',
      };

  static String _triggerNarrativeBn(
    PratyantardashaTriggerRelation relation,
    String lord,
  ) =>
      switch (relation) {
        PratyantardashaTriggerRelation.reinforcing =>
          '$lord চলমান MD/AD direction-কে reinforce করছে; তাই তার সক্রিয় বিষয়গুলির timing আরও কাছ থেকে পর্যালোচনা করা উচিত।',
        PratyantardashaTriggerRelation.countertrend =>
          '$lord চলমান MD/AD direction-এর বিপরীতে কাজ করছে; তাই একমুখী সিদ্ধান্ত না দিয়ে mixed বা interrupting manifestation পর্যালোচনা করা উচিত।',
        PratyantardashaTriggerRelation.neutral =>
          '$lord চলমান MD/AD score-এ directional trigger যোগ করছে না; তাই তার সক্রিয় বিষয়গুলি review-only থাকবে।',
      };

  static List<LifeArea> _reinforcedLifeAreas(
    List<List<LifeArea>> levels,
    List<LifeArea> fallback,
  ) {
    final counts = <LifeArea, int>{};
    for (final level in levels) {
      for (final area in level.toSet()) {
        counts[area] = (counts[area] ?? 0) + 1;
      }
    }
    final reinforced = counts.entries
        .where((entry) => entry.value >= 2)
        .map((entry) => entry.key)
        .toList(growable: false);
    return reinforced.isEmpty ? List.unmodifiable(fallback) : reinforced;
  }

  static Map<String, Object?> _requiredMap(Object? value, String path) {
    if (value is! Map) throw StateError('Missing or invalid $path');
    return Map<String, Object?>.from(value);
  }

  static String _requiredLord(Object? value, String path) {
    if (value is! String || !VimshottariDashaEngine.sequence.contains(value)) {
      throw StateError('Missing or invalid $path');
    }
    return value;
  }

  static DateTime _requiredUtc(Object? value, String path) {
    if (value is! String || !value.endsWith('Z')) {
      throw StateError('Missing or invalid $path');
    }
    final parsed = DateTime.tryParse(value);
    if (parsed == null || !parsed.isUtc) {
      throw StateError('Missing or invalid $path');
    }
    return parsed;
  }

  static const _planetNamesEn = <String, String>{
    'sun': 'Sun',
    'moon': 'Moon',
    'mars': 'Mars',
    'mercury': 'Mercury',
    'jupiter': 'Jupiter',
    'venus': 'Venus',
    'saturn': 'Saturn',
    'rahu': 'Rahu',
    'ketu': 'Ketu',
  };

  static const _planetNamesBn = <String, String>{
    'sun': 'সূর্য',
    'moon': 'চন্দ্র',
    'mars': 'মঙ্গল',
    'mercury': 'বুধ',
    'jupiter': 'বৃহস্পতি',
    'venus': 'শুক্র',
    'saturn': 'শনি',
    'rahu': 'রাহু',
    'ketu': 'কেতু',
  };

  static const _lifeAreaNamesEn = <LifeArea, String>{
    LifeArea.overall: 'overall direction',
    LifeArea.self: 'self and vitality',
    LifeArea.family: 'family and speech',
    LifeArea.communication: 'communication and initiative',
    LifeArea.siblings: 'siblings',
    LifeArea.career: 'career',
    LifeArea.finance: 'finance',
    LifeArea.marriage: 'marriage and partnership',
    LifeArea.health: 'health review',
    LifeArea.obstacles: 'obstacles, debt and conflict',
    LifeArea.longevity: 'transformation and longevity themes',
    LifeArea.fortune: 'fortune and dharma',
    LifeArea.gains: 'gains and networks',
    LifeArea.expenses: 'expenses and withdrawal',
    LifeArea.education: 'education',
    LifeArea.property: 'property and home',
    LifeArea.children: 'children and creativity',
    LifeArea.spirituality: 'spirituality',
  };

  static const _lifeAreaNamesBn = <LifeArea, String>{
    LifeArea.overall: 'সামগ্রিক দিক',
    LifeArea.self: 'স্বভাব ও প্রাণশক্তি',
    LifeArea.family: 'পরিবার ও বাকশক্তি',
    LifeArea.communication: 'যোগাযোগ ও উদ্যোগ',
    LifeArea.siblings: 'ভাইবোন',
    LifeArea.career: 'পেশা',
    LifeArea.finance: 'অর্থ',
    LifeArea.marriage: 'বিবাহ ও অংশীদারিত্ব',
    LifeArea.health: 'স্বাস্থ্য-পর্যালোচনা',
    LifeArea.obstacles: 'বাধা, ঋণ ও বিরোধ',
    LifeArea.longevity: 'রূপান্তর ও আয়ু-সংক্রান্ত বিষয়',
    LifeArea.fortune: 'ভাগ্য ও ধর্ম',
    LifeArea.gains: 'লাভ ও যোগাযোগবৃত্ত',
    LifeArea.expenses: 'ব্যয় ও প্রত্যাহার',
    LifeArea.education: 'শিক্ষা',
    LifeArea.property: 'সম্পত্তি ও গৃহ',
    LifeArea.children: 'সন্তান ও সৃজনশীলতা',
    LifeArea.spirituality: 'আধ্যাত্মিকতা',
  };
}
