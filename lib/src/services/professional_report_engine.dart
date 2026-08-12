import '../models/birth_record.dart';
import '../models/client.dart';
import '../models/consultation.dart';
import '../models/gemstone_remedy.dart';
import '../models/kundli_analysis_snapshot.dart';
import '../models/numerology_snapshot.dart';
import '../models/professional_report.dart';

class ProfessionalReportEngine {
  const ProfessionalReportEngine();

  static const engineId = 'astro-logic-professional-report';
  static const engineVersion = '1.4.0';
  static const reportSchemaVersion = 'professional-consultation-report-v1';

  ProfessionalConsultationReport build({
    required Consultation consultation,
    required Client client,
    required BirthRecord birthRecord,
    required DateTime asOfUtc,
    KundliAnalysisSnapshot? kundli,
    NumerologySnapshot? numerology,
    List<GemstoneRemedy> gemstoneRemedies = const [],
  }) {
    if (consultation.id == null || client.id == null || birthRecord.id == null) {
      throw ArgumentError('Saved consultation, client and birth record are required');
    }
    if (!asOfUtc.isUtc) {
      throw ArgumentError.value(asOfUtc, 'asOfUtc', 'UTC instant required');
    }
    if (consultation.clientId != client.id ||
        consultation.birthRecordId != birthRecord.id ||
        birthRecord.clientId != client.id) {
      throw ArgumentError('Consultation/client/birth-record linkage is invalid');
    }
    if (kundli != null && kundli.consultationId != consultation.id) {
      throw ArgumentError('Kundli analysis does not belong to consultation');
    }
    if (numerology != null &&
        (numerology.consultationId != consultation.id ||
            numerology.clientId != client.id ||
            numerology.birthRecordId != birthRecord.id)) {
      throw ArgumentError('Numerology snapshot does not belong to consultation');
    }
    if (kundli == null && numerology == null) {
      throw StateError('At least one immutable analysis snapshot is required');
    }
    if (gemstoneRemedies.any((value) => value.consultationId != consultation.id)) {
      throw ArgumentError('Gemstone/remedy record does not belong to consultation');
    }

    final sources = <ProfessionalReportSource>[
      if (kundli != null)
        ProfessionalReportSource(
          kind: 'kundliAnalysis',
          id: kundli.id,
          hash: kundli.analysisHash,
          schemaVersion: kundli.analysisSchemaVersion,
        ),
      if (numerology != null)
        ProfessionalReportSource(
          kind: 'numerologySnapshot',
          id: numerology.id,
          hash: numerology.snapshotHash,
          schemaVersion: numerology.analysisSchemaVersion,
        ),
    ];

    final analysis = kundli?.analysis;
    final findings = _maps(analysis?['findings']);
    final sections = <ProfessionalReportSection>[
      _profileSection(consultation, client, birthRecord),
      _executiveSection(findings, consultation.category),
      _findingSection(
        code: 'd1_overview',
        titleEn: 'D1 Rashi overview',
        titleBn: 'D1 রাশি সারাংশ',
        findings: findings.where(_isD1Finding).toList(growable: false),
        unavailableEn: 'No governed D1 interpretation snapshot is available.',
        unavailableBn: 'যাচাইকৃত D1 interpretation snapshot পাওয়া যায়নি।',
        maxItems: 14,
      ),
      _mapSection(
        code: 'd9_navamsa',
        titleEn: 'D9 Navamsha review',
        titleBn: 'D9 নবাংশ বিচার',
        values: _maps(analysis?['navamsaHouseInterpretations']),
        unavailableEn: 'D9 house/lord/aspect interpretation is not available in the selected Kundli snapshot.',
        unavailableBn: 'নির্বাচিত কুণ্ডলী snapshot-এ D9 ভাব/অধিপতি/দৃষ্টি interpretation নেই।',
      ),
      _d10Section(analysis),
      _findingSection(
        code: 'yoga_dosha',
        titleEn: 'Yoga and Dosha review',
        titleBn: 'যোগ ও দোষ পর্যালোচনা',
        findings: findings
            .where((value) => _code(value).startsWith('vedic.yoga.') || _code(value).startsWith('vedic.dosha.'))
            .toList(growable: false),
        unavailableEn: 'No enabled Yoga/Dosha finding is present in this snapshot.',
        unavailableBn: 'এই snapshot-এ সক্রিয় Yoga/Dosha finding নেই।',
        maxItems: 12,
      ),
      _shadbalaSection(analysis),
      _ashtakavargaSection(analysis),
      _dashaSection(analysis, asOfUtc),
      _transitTimingSection(),
      _numerologySection(numerology),
      _remedyGemstoneSection(analysis, gemstoneRemedies),
      _notesWarningsSection(consultation, analysis, numerology),
    ];

    return ProfessionalConsultationReport(
      consultationId: consultation.id!,
      clientId: client.id!,
      birthRecordId: birthRecord.id!,
      clientName: client.fullName,
      consultationSubject: consultation.subject,
      consultationCategory: consultation.category.name,
      birthLabel: birthRecord.label,
      birthLocalDateTime: birthRecord.localDateTime.toIso8601String(),
      birthPlace: birthRecord.placeName,
      birthTimeConfidence: birthRecord.confidence.name,
      asOfUtc: asOfUtc,
      sources: List.unmodifiable(sources),
      sections: List.unmodifiable(sections),
      warningsEn: const [
        'This report is a structured professional-review draft assembled only from persisted ASTRO LOGIC evidence. It does not create missing astrological findings.',
        'Astrological and numerological interpretations are traditional review frameworks, not scientifically validated facts or guaranteed outcomes.',
        'Medical, legal, financial and other high-stakes decisions require appropriate qualified professional advice.',
      ],
      warningsBn: const [
        'এই রিপোর্টটি শুধুমাত্র ASTRO LOGIC-এ সংরক্ষিত evidence থেকে তৈরি পেশাদার-পর্যালোচনাযোগ্য খসড়া; অনুপস্থিত জ্যোতিষীয় ফল নিজে থেকে তৈরি করে না।',
        'জ্যোতিষ ও সংখ্যাতত্ত্বের ব্যাখ্যা প্রচলিত পর্যালোচনা-পদ্ধতি; বৈজ্ঞানিকভাবে প্রমাণিত তথ্য বা নিশ্চিত ফল নয়।',
        'চিকিৎসা, আইন, অর্থ বা অন্য উচ্চ-ঝুঁকির সিদ্ধান্তে সংশ্লিষ্ট যোগ্য পেশাদারের পরামর্শ প্রয়োজন।',
      ],
      professionalReviewRequired: true,
    );
  }

  ProfessionalReportSection _profileSection(
    Consultation consultation,
    Client client,
    BirthRecord birthRecord,
  ) =>
      ProfessionalReportSection(
        code: 'client_profile',
        titleEn: 'Client and consultation profile',
        titleBn: 'ক্লায়েন্ট ও পরামর্শের পরিচিতি',
        status: ProfessionalReportSectionStatus.available,
        summaryEn: '${client.fullName} · ${consultation.category.name} · ${consultation.subject}',
        summaryBn: '${client.fullName} · ${consultation.category.name} · ${consultation.subject}',
        items: [
          ProfessionalReportItem(
            code: 'profile.birth_record',
            titleEn: 'Birth record: ${birthRecord.label}',
            titleBn: 'জন্মরেকর্ড: ${birthRecord.label}',
            narrativeEn: '${birthRecord.localDateTime.toIso8601String()} · ${birthRecord.placeName} · time confidence ${birthRecord.confidence.name}.',
            narrativeBn: '${birthRecord.localDateTime.toIso8601String()} · ${birthRecord.placeName} · জন্মসময়ের confidence ${birthRecord.confidence.name}।',
            tone: ProfessionalReportTone.neutral,
          ),
        ],
      );

  ProfessionalReportSection _executiveSection(
    List<Map<String, Object?>> findings,
    ConsultationCategory category,
  ) {
    if (findings.isEmpty) {
      return _unavailableSection(
        'executive_summary',
        'Executive summary',
        'কার্যকর সারাংশ',
        'No Kundli findings are available for an executive synthesis.',
        'কার্যকর সারাংশ তৈরির জন্য কোনো কুণ্ডলী finding নেই।',
      );
    }
    final targetArea = _categoryArea(category);
    final ranked = [...findings]..sort((a, b) {
      int score(Map<String, Object?> value) {
        var result = value['confidence'] == 'medium' ? 20 : 0;
        if (value['area'] == targetArea) result += 30;
        if (value['polarity'] != 'mixed') result += 10;
        if (_code(value).startsWith('vedic.life_area.')) result += 5;
        return result;
      }
      return score(b).compareTo(score(a));
    });
    final supportive = ranked.where((v) => v['polarity'] == 'supportive').take(3);
    final challenging = ranked.where((v) => v['polarity'] == 'challenging').take(3);
    final mixed = ranked.where((v) => v['polarity'] == 'mixed').take(2);
    final selected = [...supportive, ...challenging, ...mixed];
    return ProfessionalReportSection(
      code: 'executive_summary',
      titleEn: 'Executive summary',
      titleBn: 'কার্যকর সারাংশ',
      status: ProfessionalReportSectionStatus.limited,
      summaryEn: 'Curated from the highest-priority persisted findings, with ${category.name} evidence prioritised. Contradictions remain visible.',
      summaryBn: 'সংরক্ষিত findings-এর অগ্রাধিকারভিত্তিক সারাংশ; ${category.name} সম্পর্কিত evidence আগে রাখা হয়েছে এবং বিরোধী সংকেত অক্ষুণ্ণ।',
      items: selected.map(_findingItem).toList(growable: false),
    );
  }

  ProfessionalReportSection _findingSection({
    required String code,
    required String titleEn,
    required String titleBn,
    required List<Map<String, Object?>> findings,
    required String unavailableEn,
    required String unavailableBn,
    required int maxItems,
  }) {
    if (findings.isEmpty) {
      return _unavailableSection(code, titleEn, titleBn, unavailableEn, unavailableBn);
    }
    final ordered = [...findings]..sort((a, b) => _findingRank(b).compareTo(_findingRank(a)));
    return ProfessionalReportSection(
      code: code,
      titleEn: titleEn,
      titleBn: titleBn,
      status: ordered.length > maxItems ? ProfessionalReportSectionStatus.limited : ProfessionalReportSectionStatus.available,
      summaryEn: ordered.length > maxItems
          ? 'Showing the $maxItems highest-priority findings from ${ordered.length} governed records.'
          : '${ordered.length} governed finding(s) included.',
      summaryBn: ordered.length > maxItems
          ? '${ordered.length}টি governed record থেকে অগ্রাধিকারের প্রথম $maxItemsটি দেখানো হয়েছে।'
          : '${ordered.length}টি governed finding অন্তর্ভুক্ত।',
      items: ordered.take(maxItems).map(_findingItem).toList(growable: false),
    );
  }

  ProfessionalReportSection _mapSection({
    required String code,
    required String titleEn,
    required String titleBn,
    required List<Map<String, Object?>> values,
    required String unavailableEn,
    required String unavailableBn,
  }) {
    if (values.isEmpty) return _unavailableSection(code, titleEn, titleBn, unavailableEn, unavailableBn);
    return ProfessionalReportSection(
      code: code,
      titleEn: titleEn,
      titleBn: titleBn,
      status: ProfessionalReportSectionStatus.available,
      summaryEn: '${values.length} governed divisional record(s).',
      summaryBn: '${values.length}টি governed divisional record।',
      items: values.map(_mapNarrativeItem).toList(growable: false),
    );
  }

  ProfessionalReportSection _d10Section(Map<String, Object?>? analysis) {
    final values = _maps(analysis?['dashamsaHouseInterpretations']);
    final synthesis = _map(analysis?['dashamsaCareerSynthesis']);
    if (values.isEmpty && synthesis == null) {
      return _unavailableSection(
        'd10_career', 'D10 career review', 'D10 কর্মজীবন বিচার',
        'D10 career interpretation is not available in the selected Kundli snapshot.',
        'নির্বাচিত কুণ্ডলী snapshot-এ D10 কর্মজীবন interpretation নেই।',
      );
    }
    return ProfessionalReportSection(
      code: 'd10_career',
      titleEn: 'D10 career review',
      titleBn: 'D10 কর্মজীবন বিচার',
      status: ProfessionalReportSectionStatus.available,
      summaryEn: 'D1 tenth-lord and D10 structural evidence are kept separate before synthesis.',
      summaryBn: 'Synthesis-এর আগে D1 দশমপতি ও D10 structural evidence আলাদা রাখা হয়েছে।',
      items: [
        if (synthesis != null) _mapNarrativeItem(synthesis),
        ...values.map(_mapNarrativeItem),
      ],
    );
  }

  ProfessionalReportSection _shadbalaSection(Map<String, Object?>? analysis) {
    final profiles = _maps(analysis?['shadbalaProfiles']);
    if (profiles.isEmpty) {
      return _unavailableSection('shadbala', 'Shadbala strength review', 'ষড়বল শক্তি বিচার', 'No Shadbala profile is available.', 'কোনো ষড়বল profile পাওয়া যায়নি।');
    }
    final items = profiles.map((value) {
      final planet = value['planet'] ?? 'Planet';
      final total = value['totalShadbalaVirupas'];
      final required = value['requiredShadbalaVirupas'];
      final ratio = value['requiredStrengthRatio'];
      final status = value['thresholdStatus'] ?? 'unavailable';
      return ProfessionalReportItem(
        code: 'report.shadbala.${planet.toString().toLowerCase()}',
        titleEn: '$planet — $status',
        titleBn: '$planet — $status',
        narrativeEn: total == null
            ? 'Complete aggregate unavailable; missing components remain gated.'
            : 'Total ${_num(total)} virupas; required ${_num(required)}; ratio ${_num(ratio)}. Threshold is strength sufficiency only, not automatic beneficence.',
        narrativeBn: total == null
            ? 'পূর্ণ aggregate unavailable; missing component অনুমান করা হয়নি।'
            : 'মোট ${_num(total)} virupa; প্রয়োজন ${_num(required)}; ratio ${_num(ratio)}। Threshold শুধু strength sufficiency, স্বয়ংক্রিয় শুভতা নয়।',
        tone: status == 'meetsRequired' ? ProfessionalReportTone.supportive : status == 'belowRequired' ? ProfessionalReportTone.challenging : ProfessionalReportTone.mixed,
        evidencePaths: [r'$.shadbalaProfiles'],
      );
    }).toList(growable: false);
    return ProfessionalReportSection(
      code: 'shadbala',
      titleEn: 'Shadbala strength review',
      titleBn: 'ষড়বল শক্তি বিচার',
      status: ProfessionalReportSectionStatus.available,
      summaryEn: 'Seven classical planets; quantitative strength is not treated as automatic favourable/adverse outcome.',
      summaryBn: 'সাত ধ্রুপদি গ্রহ; পরিমাণগত বলকে স্বয়ংক্রিয় শুভ/অশুভ ফল ধরা হয় না।',
      items: items,
    );
  }

  ProfessionalReportSection _ashtakavargaSection(Map<String, Object?>? analysis) {
    final profile = _map(analysis?['ashtakavargaProfile']);
    if (profile == null) {
      return _unavailableSection('ashtakavarga', 'Ashtakavarga review', 'অষ্টকবর্গ বিচার', 'No Ashtakavarga profile is available.', 'কোনো অষ্টকবর্গ profile পাওয়া যায়নি।');
    }
    final sav = _maps(profile['sarvashtakavarga']);
    final items = sav.map((value) => ProfessionalReportItem(
      code: 'report.ashtakavarga.house_${value['houseNumber'] ?? value['signIndex']}',
      titleEn: 'House ${value['houseNumber'] ?? '—'} — ${value['positiveMarks'] ?? '—'} positive marks',
      titleBn: 'ভাব ${value['houseNumber'] ?? '—'} — ${value['positiveMarks'] ?? '—'} positive mark',
      narrativeEn: (value['narrativeEn'] ?? 'Raw SAV comparative house support.') as String,
      narrativeBn: (value['narrativeBn'] ?? 'Raw SAV comparative house support।') as String,
      tone: _tone(value['polarity'] as String?),
      confidence: value['confidence'] as String?,
      evidencePaths: const [r'$.ashtakavargaProfile.sarvashtakavarga'],
    )).toList(growable: false);
    return ProfessionalReportSection(
      code: 'ashtakavarga',
      titleEn: 'Ashtakavarga review',
      titleBn: 'অষ্টকবর্গ বিচার',
      status: ProfessionalReportSectionStatus.available,
      summaryEn: 'Unreduced SAV house support is shown separately from Trikona/Ekadhipatya/Pinda stages. Raw checksum: ${profile['totalPositiveMarks'] ?? '—'}.',
      summaryBn: 'Unreduced SAV ভাব-সমর্থন Trikona/Ekadhipatya/Pinda stage থেকে আলাদা। Raw checksum: ${profile['totalPositiveMarks'] ?? '—'}।',
      items: items,
    );
  }

  ProfessionalReportSection _dashaSection(Map<String, Object?>? analysis, DateTime asOfUtc) {
    final pd = _maps(analysis?['pratyantardashaInterpretations']);
    final windows = _maps(analysis?['timingWindows']);
    if (pd.isEmpty && windows.isEmpty) {
      return _unavailableSection('dasha_timing', 'Dasha and Pratyantardasha', 'দশা ও প্রত্যন্তরদশা', 'No persisted Vimshottari timing evidence is available.', 'সংরক্ষিত বিমশোত্তরী timing evidence নেই।');
    }
    Map<String, Object?>? current;
    for (final value in pd) {
      final start = DateTime.tryParse(value['startUtc']?.toString() ?? '');
      final end = DateTime.tryParse(value['endUtc']?.toString() ?? '');
      if (start != null && end != null && !asOfUtc.isBefore(start) && asOfUtc.isBefore(end)) {
        current = value;
        break;
      }
    }
    final items = <ProfessionalReportItem>[];
    if (current != null) items.add(_mapNarrativeItem(current));
    for (final value in windows.take(4)) {
      items.add(ProfessionalReportItem(
        code: value['code']?.toString() ?? 'report.dasha.window',
        titleEn: '${value['area'] ?? 'Timing'} · ${value['start'] ?? ''} → ${value['end'] ?? ''}',
        titleBn: '${value['area'] ?? 'সময়কাল'} · ${value['start'] ?? ''} → ${value['end'] ?? ''}',
        narrativeEn: value['narrativeEn']?.toString() ?? '',
        narrativeBn: value['narrativeBn']?.toString() ?? '',
        tone: _tone(value['polarity'] as String?),
        confidence: value['confidence'] as String?,
        evidencePaths: _evidencePaths(value),
      ));
    }
    return ProfessionalReportSection(
      code: 'dasha_timing',
      titleEn: 'Dasha and Pratyantardasha',
      titleBn: 'দশা ও প্রত্যন্তরদশা',
      status: ProfessionalReportSectionStatus.limited,
      summaryEn: current == null ? 'Timing evidence exists, but no current Pratyantardasha was found for the report as-of instant.' : 'Current Pratyantardasha plus a concise set of persisted timing windows as of ${asOfUtc.toIso8601String()}.',
      summaryBn: current == null ? 'Timing evidence আছে, কিন্তু report as-of instant-এ current Pratyantardasha পাওয়া যায়নি।' : '${asOfUtc.toIso8601String()} অনুযায়ী current Pratyantardasha ও সংক্ষিপ্ত timing window।',
      items: items,
    );
  }

  ProfessionalReportSection _transitTimingSection() => _unavailableSection(
        'transit_question_timing',
        'Transit, question timing and confidence',
        'গোচর, প্রশ্নভিত্তিক সময় ও confidence',
        'The current app computes governed transit/question-timing/conflict layers, but no immutable selected-date timing snapshot is persisted yet. Report v1 therefore does not fabricate this section.',
        'বর্তমান অ্যাপে governed transit/question-timing/conflict calculation আছে, কিন্তু selected-date timing-এর immutable snapshot এখনও persist হয় না। তাই Report v1 এই অংশ অনুমান করে তৈরি করে না।',
      );

  ProfessionalReportSection _numerologySection(NumerologySnapshot? snapshot) {
    if (snapshot == null) {
      return _unavailableSection(
        'numerology',
        'Numerology review',
        'সংখ্যাতত্ত্ব বিচার',
        'No immutable Numerology snapshot is linked to this consultation.',
        'এই consultation-এর সঙ্গে কোনো immutable Numerology snapshot যুক্ত নেই।',
      );
    }
    final findings = _maps(snapshot.analysis['findings']);
    final crossSystem = _maps(snapshot.analysis['crossSystemFindings']);
    final nameCandidates = _maps(snapshot.analysis['nameCandidateReviews']);
    final timing = _maps(snapshot.analysis['timingWindows']);
    final remedies = _maps(snapshot.analysis['remedyCandidates']);
    final confidence = _map(snapshot.analysis['confidenceSummary']);
    final items = <ProfessionalReportItem>[
      ...findings.map(_findingItem),
      ...crossSystem.map(_findingItem),
      ...nameCandidates.map(
        (value) => ProfessionalReportItem(
          code: value['code']?.toString() ?? 'numerology.name_candidate',
          titleEn:
              'Alternate spelling review — ${value['candidateNameLatin'] ?? '—'}${value['selectedForProfessionalReview'] == true ? ' · professional focus' : ''}',
          titleBn:
              'বিকল্প বানান review — ${value['candidateNameLatin'] ?? '—'}${value['selectedForProfessionalReview'] == true ? ' · professional focus' : ''}',
          narrativeEn:
              '${value['narrativeEn'] ?? ''} Caution: ${value['cautionEn'] ?? ''}'.trim(),
          narrativeBn:
              '${value['narrativeBn'] ?? value['narrativeEn'] ?? ''} সতর্কতা: ${value['cautionBn'] ?? value['cautionEn'] ?? ''}'.trim(),
          tone: ProfessionalReportTone.neutral,
          confidence: value['confidence']?.toString(),
          evidencePaths: _evidencePaths(value),
        ),
      ),
      if (confidence != null)
        ProfessionalReportItem(
          code: 'numerology.confidence.policy',
          titleEn:
              'Prediction confidence — ${confidence['predictionConfidence'] ?? 'low'}',
          titleBn:
              'Prediction confidence — ${confidence['predictionConfidence'] ?? 'low'}',
          narrativeEn: confidence['rationaleEn']?.toString() ?? '',
          narrativeBn:
              confidence['rationaleBn']?.toString() ??
                  confidence['rationaleEn']?.toString() ??
                  '',
          tone: ProfessionalReportTone.neutral,
          confidence: confidence['predictionConfidence']?.toString(),
        ),
      ...timing.map(
        (value) => ProfessionalReportItem(
          code: value['code']?.toString() ?? 'numerology.personal_year',
          titleEn:
              'Personal Year context ${_yearFromIso(value['start']) ?? '—'}',
          titleBn:
              'পার্সোনাল ইয়ার context ${_yearFromIso(value['start']) ?? '—'}',
          narrativeEn: value['narrativeEn']?.toString() ?? '',
          narrativeBn:
              value['narrativeBn']?.toString() ??
                  value['narrativeEn']?.toString() ??
                  '',
          tone: ProfessionalReportTone.neutral,
          confidence: value['confidence']?.toString(),
          evidencePaths: _evidencePaths(value),
        ),
      ),
      ...remedies.map(
        (value) => ProfessionalReportItem(
          code: value['code']?.toString() ?? 'numerology.remedy.behavioral',
          titleEn: 'Numerology behavioural review',
          titleBn: 'সংখ্যাতত্ত্ব behavioural review',
          narrativeEn:
              '${value['actionEn'] ?? ''} ${value['rationaleEn'] ?? ''} Caution: ${value['cautionEn'] ?? ''}'
                  .trim(),
          narrativeBn:
              '${value['actionBn'] ?? value['actionEn'] ?? ''} ${value['rationaleBn'] ?? value['rationaleEn'] ?? ''} সতর্কতা: ${value['cautionBn'] ?? value['cautionEn'] ?? ''}'
                  .trim(),
          tone: ProfessionalReportTone.neutral,
          evidencePaths: _evidencePaths(value),
        ),
      ),
    ];
    return ProfessionalReportSection(
      code: 'numerology',
      titleEn: 'Numerology review',
      titleBn: 'সংখ্যাতত্ত্ব বিচার',
      status: ProfessionalReportSectionStatus.available,
      summaryEn:
          'Snapshot ${snapshot.analysisSchemaVersion}; target year ${snapshot.targetYear}; exact stored Latin spelling: ${snapshot.nameLatin}. Includes governed core-number interpretation, ${nameCandidates.length} alternate-name arithmetic comparison record(s), three-year cycle context, Low prediction-confidence policy and ${crossSystem.length} guarded Vedic cross-check record(s). Alternate candidates are not ranked or automatically recommended.',
      summaryBn:
          'Snapshot ${snapshot.analysisSchemaVersion}; target year ${snapshot.targetYear}; সংরক্ষিত Latin spelling: ${snapshot.nameLatin}। Governed core-number interpretation, ${nameCandidates.length}টি alternate-name arithmetic comparison record, তিন বছরের cycle context, Low prediction-confidence policy এবং ${crossSystem.length}টি guarded Vedic cross-check record অন্তর্ভুক্ত। Alternate candidate-কে rank বা automatic recommendation করা হয় না।',
      items: items,
    );
  }

  ProfessionalReportSection _remedyGemstoneSection(
    Map<String, Object?>? analysis,
    List<GemstoneRemedy> remedies,
  ) {
    final automated = _maps(analysis?['remedyCandidates']);
    final gemstoneCandidates = _maps(analysis?['gemstoneCandidateReviews']);
    final reviewed = remedies
        .where((value) => value.decision != RemedyDecision.draft)
        .toList(growable: false);
    if (automated.isEmpty && gemstoneCandidates.isEmpty && reviewed.isEmpty) {
      return _unavailableSection(
        'remedy_gemstone',
        'Remedy and gemstone record',
        'সমাধান ও রত্ন নথি',
        'No evidence-gated behavioural remedy, automated gemstone review status or practitioner-reviewed gemstone record is available.',
        'কোনো evidence-gated behavioural remedy, automated gemstone review status বা practitioner-reviewed gemstone record নেই।',
      );
    }

    final items = <ProfessionalReportItem>[
      ...automated.map(
        (value) => ProfessionalReportItem(
          code: value['code']?.toString() ?? 'vedic.remedy.behavioral',
          titleEn: 'Automated ${value['kind'] ?? 'remedy'} review',
          titleBn: 'স্বয়ংক্রিয় ${value['kind'] ?? 'remedy'} পর্যালোচনা',
          narrativeEn:
              '${value['actionEn'] ?? ''} ${value['rationaleEn'] ?? ''} Caution: ${value['cautionEn'] ?? ''}'.trim(),
          narrativeBn:
              '${value['actionBn'] ?? value['actionEn'] ?? ''} ${value['rationaleBn'] ?? value['rationaleEn'] ?? ''} সতর্কতা: ${value['cautionBn'] ?? value['cautionEn'] ?? ''}'.trim(),
          tone: ProfessionalReportTone.neutral,
          evidencePaths: _evidencePaths(value),
        ),
      ),
      ...gemstoneCandidates.map(
        (value) => ProfessionalReportItem(
          code: value['code']?.toString() ?? 'vedic.gemstone.review',
          titleEn:
              '${value['planet'] ?? 'planet'}: ${value['primaryGemstone'] ?? 'gemstone'} — ${value['status'] ?? 'insufficientEvidence'}',
          titleBn:
              '${value['planet'] ?? 'planet'}: ${value['primaryGemstoneBn'] ?? value['primaryGemstone'] ?? 'gemstone'} — ${value['status'] ?? 'insufficientEvidence'}',
          narrativeEn:
              '${value['rationaleEn'] ?? ''} Caution: ${value['cautionEn'] ?? ''}'.trim(),
          narrativeBn:
              '${value['rationaleBn'] ?? value['rationaleEn'] ?? ''} সতর্কতা: ${value['cautionBn'] ?? value['cautionEn'] ?? ''}'.trim(),
          tone: value['status'] == 'contraindicated'
              ? ProfessionalReportTone.challenging
              : ProfessionalReportTone.neutral,
          evidencePaths: _evidencePaths(value),
        ),
      ),
      ...reviewed.map(
        (value) => ProfessionalReportItem(
          code: 'practitioner.gemstone.${value.id}',
          titleEn:
              '${value.planet.name}: ${value.primaryGemstone} — ${value.decision.name}',
          titleBn:
              '${value.planet.name}: ${value.primaryGemstone} — ${value.decision.name}',
          narrativeEn:
              '${value.astrologicalReason}${value.cautions.isEmpty ? '' : ' Caution: ${value.cautions}'}',
          narrativeBn:
              '${value.astrologicalReason}${value.cautions.isEmpty ? '' : ' সতর্কতা: ${value.cautions}'}',
          tone: value.decision == RemedyDecision.approved
              ? ProfessionalReportTone.neutral
              : ProfessionalReportTone.challenging,
          evidencePaths: value.evidenceReferences,
        ),
      ),
    ];

    return ProfessionalReportSection(
      code: 'remedy_gemstone',
      titleEn: 'Remedy and gemstone review',
      titleBn: 'সমাধান ও রত্ন পর্যালোচনা',
      status: ProfessionalReportSectionStatus.limited,
      summaryEn:
          'Behavioural remedy drafts come from Vedic Remedy Recommendation v1. Gemstone Candidate v1 publishes Eligible / Contraindicated / Insufficient Evidence review states only; it never approves wearing details. Practitioner-entered gemstone records still require explicit astrologer approval.',
      summaryBn:
          'Behavioural remedy draft Vedic Remedy Recommendation v1 থেকে আসে। Gemstone Candidate v1 শুধু Eligible / Contraindicated / Insufficient Evidence review state প্রকাশ করে; wearing details কখনও auto-approve করে না। Practitioner-entered gemstone record-এ এখনও explicit astrologer approval আবশ্যক।',
      items: items,
    );
  }

  ProfessionalReportSection _notesWarningsSection(
    Consultation consultation,
    Map<String, Object?>? analysis,
    NumerologySnapshot? numerology,
  ) {
    final warningsEn = <String>[
      ..._strings(analysis?['warningsEn']),
      ..._strings(numerology?.analysis['warningsEn']),
    ];
    final warningsBn = <String>[
      ..._strings(analysis?['warningsBn']),
      ..._strings(numerology?.analysis['warningsBn']),
    ];
    final itemCount = [warningsEn.length, warningsBn.length].reduce((a, b) => a > b ? a : b);
    final items = <ProfessionalReportItem>[];
    for (var i = 0; i < itemCount; i++) {
      items.add(ProfessionalReportItem(
        code: 'report.warning.$i',
        titleEn: i == 0 ? 'Professional review note' : 'Scope note ${i + 1}',
        titleBn: i == 0 ? 'পেশাদার পর্যালোচনা নোট' : 'পরিধি নোট ${i + 1}',
        narrativeEn: i < warningsEn.length ? warningsEn[i] : '',
        narrativeBn: i < warningsBn.length ? warningsBn[i] : '',
        tone: ProfessionalReportTone.neutral,
      ));
    }
    if (consultation.notes.trim().isNotEmpty) {
      items.insert(0, ProfessionalReportItem(
        code: 'report.professional_notes',
        titleEn: 'Consultation notes',
        titleBn: 'পরামর্শের নোট',
        narrativeEn: consultation.notes.trim(),
        narrativeBn: consultation.notes.trim(),
        tone: ProfessionalReportTone.neutral,
      ));
    }
    return ProfessionalReportSection(
      code: 'professional_notes_warnings',
      titleEn: 'Professional notes and scope warnings',
      titleBn: 'পেশাদার নোট ও পরিধি সতর্কতা',
      status: ProfessionalReportSectionStatus.available,
      summaryEn: 'Review notes are retained rather than hidden from the client-ready draft.',
      summaryBn: 'Review note গোপন না করে client-ready draft-এ সংরক্ষিত রাখা হয়েছে।',
      items: items,
    );
  }

  static bool _isD1Finding(Map<String, Object?> value) {
    final code = _code(value);
    const excluded = [
      'vedic.yoga.', 'vedic.dosha.', 'vedic.divisional.', 'vedic.shadbala.',
      'vedic.ashtakavarga.', 'vedic.planetary_war.',
    ];
    return code.startsWith('vedic.') && !excluded.any(code.startsWith);
  }

  static int _findingRank(Map<String, Object?> value) {
    var score = value['confidence'] == 'medium' ? 20 : value['confidence'] == 'high' ? 30 : 10;
    if (value['polarity'] != 'mixed') score += 5;
    if (_code(value).startsWith('vedic.life_area.')) score += 5;
    return score;
  }

  static ProfessionalReportItem _findingItem(Map<String, Object?> value) => ProfessionalReportItem(
        code: _code(value),
        titleEn: value['titleEn']?.toString() ?? _code(value),
        titleBn: value['titleBn']?.toString() ?? value['titleEn']?.toString() ?? _code(value),
        narrativeEn: value['narrativeEn']?.toString() ?? '',
        narrativeBn: value['narrativeBn']?.toString() ?? value['narrativeEn']?.toString() ?? '',
        tone: _tone(value['polarity'] as String?),
        confidence: value['confidence'] as String?,
        evidencePaths: _evidencePaths(value),
      );

  static ProfessionalReportItem _mapNarrativeItem(Map<String, Object?> value) => ProfessionalReportItem(
        code: value['code']?.toString() ?? 'report.record',
        titleEn: value['titleEn']?.toString() ?? value['code']?.toString() ?? 'Review record',
        titleBn: value['titleBn']?.toString() ?? value['titleEn']?.toString() ?? value['code']?.toString() ?? 'পর্যালোচনা রেকর্ড',
        narrativeEn: value['narrativeEn']?.toString() ?? '',
        narrativeBn: value['narrativeBn']?.toString() ?? value['narrativeEn']?.toString() ?? '',
        tone: _tone(value['polarity'] as String?),
        confidence: value['confidence'] as String?,
        evidencePaths: _evidencePaths(value),
      );

  static List<String> _evidencePaths(Map<String, Object?> value) => _maps(value['evidence'])
      .map((e) => e['outputPath']?.toString())
      .whereType<String>()
      .toSet()
      .toList(growable: false);

  static ProfessionalReportTone _tone(String? value) {
    switch (value) {
      case 'supportive': return ProfessionalReportTone.supportive;
      case 'challenging': return ProfessionalReportTone.challenging;
      case 'mixed': return ProfessionalReportTone.mixed;
      default: return ProfessionalReportTone.neutral;
    }
  }

  static ProfessionalReportSection _unavailableSection(
    String code, String titleEn, String titleBn, String en, String bn,
  ) => ProfessionalReportSection(
        code: code,
        titleEn: titleEn,
        titleBn: titleBn,
        status: ProfessionalReportSectionStatus.unavailable,
        summaryEn: en,
        summaryBn: bn,
        items: const [],
      );

  static List<Map<String, Object?>> _maps(Object? value) => value is List
      ? value.whereType<Map>().map((v) => Map<String, Object?>.from(v)).toList(growable: false)
      : const [];

  static Map<String, Object?>? _map(Object? value) => value is Map ? Map<String, Object?>.from(value) : null;
  static int? _yearFromIso(Object? value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString())?.year;
  }


  static List<String> _strings(Object? value) => value is List ? value.whereType<String>().toList(growable: false) : const [];
  static String _code(Map<String, Object?> value) => value['code']?.toString() ?? '';
  static String _num(Object? value) => value is num ? value.toStringAsFixed(value % 1 == 0 ? 0 : 2) : '—';

  static String _categoryArea(ConsultationCategory category) {
    switch (category) {
      case ConsultationCategory.career: return 'career';
      case ConsultationCategory.business: return 'career';
      case ConsultationCategory.marriage: return 'marriage';
      case ConsultationCategory.finance: return 'finance';
      case ConsultationCategory.education: return 'education';
      case ConsultationCategory.health: return 'health';
      case ConsultationCategory.property: return 'property';
      case ConsultationCategory.children: return 'children';
      case ConsultationCategory.travelRelocation: return 'expenses';
      case ConsultationCategory.general: return 'overall';
    }
  }
}
