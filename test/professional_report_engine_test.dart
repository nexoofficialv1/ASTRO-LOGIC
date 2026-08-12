import 'package:astro_logic/src/models/birth_record.dart';
import 'package:astro_logic/src/models/client.dart';
import 'package:astro_logic/src/models/consultation.dart';
import 'package:astro_logic/src/models/kundli_analysis_snapshot.dart';
import 'package:astro_logic/src/models/numerology_snapshot.dart';
import 'package:astro_logic/src/services/professional_report_engine.dart';
import 'package:astro_logic/src/services/professional_report_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const engine = ProfessionalReportEngine();
  final asOf = DateTime.utc(2026, 8, 9, 0, 0);

  test('builds governed 13-section bilingual report from immutable sources', () {
    final report = engine.build(
      consultation: _consultation(),
      client: _client(),
      birthRecord: _birth(),
      asOfUtc: asOf,
      kundli: _kundli(),
      numerology: _numerology(),
    );

    expect(report.sections.length, 13);
    expect(
      report.sections.map((value) => value.code).toSet(),
      ProfessionalReportPolicy.requiredSectionCodes,
    );
    expect(report.sources.length, 2);
    expect(report.professionalReviewRequired, isTrue);
    ProfessionalReportPolicy.validate(report);
  });

  test('does not fabricate selected-date transit timing without persisted snapshot', () {
    final report = engine.build(
      consultation: _consultation(),
      client: _client(),
      birthRecord: _birth(),
      asOfUtc: asOf,
      kundli: _kundli(),
    );
    final section = report.sections.singleWhere(
      (value) => value.code == 'transit_question_timing',
    );
    expect(section.status.name, 'unavailable');
    expect(section.items, isEmpty);
  });

  test('selects current Pratyantardasha using half-open UTC boundary', () {
    final report = engine.build(
      consultation: _consultation(),
      client: _client(),
      birthRecord: _birth(),
      asOfUtc: asOf,
      kundli: _kundli(),
    );
    final section = report.sections.singleWhere(
      (value) => value.code == 'dasha_timing',
    );
    expect(section.items.first.code, 'vedic.pd.current');
  });


  test('renders automated behavioural remedies in the remedy/gemstone section', () {
    final report = engine.build(
      consultation: _consultation(),
      client: _client(),
      birthRecord: _birth(),
      asOfUtc: asOf,
      kundli: _kundli(),
    );
    final section = report.sections.singleWhere(
      (value) => value.code == 'remedy_gemstone',
    );
    expect(section.status.name, 'limited');
    expect(
      section.items.any(
        (value) => value.code == 'vedic.remedy.behavioral.finance.v1',
      ),
      isTrue,
    );
    expect(
      section.items.any(
        (value) => value.code == 'vedic.gemstone.saturn.v1',
      ),
      isTrue,
    );
    expect(section.summaryEn, contains('Eligible / Contraindicated / Insufficient Evidence'));
  });


  test('renders Numerology v2 confidence, cycle and guarded cross-system context', () {
    final report = engine.build(
      consultation: _consultation(),
      client: _client(),
      birthRecord: _birth(),
      asOfUtc: asOf,
      kundli: _kundli(),
      numerology: _numerology(),
    );
    final section = report.sections.singleWhere(
      (value) => value.code == 'numerology',
    );
    expect(section.summaryEn, contains('three-year cycle context'));
    expect(section.summaryEn, contains('1 guarded Vedic cross-check'));
    expect(section.summaryEn, contains('1 alternate-name arithmetic comparison'));
    expect(
      section.items.any((value) => value.code == 'numerology.confidence.policy'),
      isTrue,
    );
    expect(
      section.items.any((value) => value.code == 'numerology.personal_year.2026.8'),
      isTrue,
    );
    expect(
      section.items.any((value) => value.code.startsWith('numerology.vedic_crosscheck.')),
      isTrue,
    );
    expect(
      section.items.any((value) => value.code == 'numerology.name_candidate.1'),
      isTrue,
    );
  });

  test('requires at least one immutable analysis snapshot', () {
    expect(
      () => engine.build(
        consultation: _consultation(),
        client: _client(),
        birthRecord: _birth(),
        asOfUtc: asOf,
      ),
      throwsStateError,
    );
  });

  test('rejects non-UTC report as-of instant', () {
    expect(
      () => engine.build(
        consultation: _consultation(),
        client: _client(),
        birthRecord: _birth(),
        asOfUtc: DateTime(2026, 8, 9),
        kundli: _kundli(),
      ),
      throwsArgumentError,
    );
  });
}

Consultation _consultation() => Consultation(
      id: 7,
      clientId: 1,
      birthRecordId: 2,
      subject: 'Career direction',
      category: ConsultationCategory.career,
      systems: const [AstrologySystem.vedic, AstrologySystem.numerology],
      status: ConsultationStatus.reviewed,
      notes: 'Astrologer note',
      createdAt: DateTime.utc(2026, 8, 1),
      updatedAt: DateTime.utc(2026, 8, 8),
    );

Client _client() => Client(
      id: 1,
      fullName: 'Test Client',
      mobile: '',
      email: '',
      gender: ClientGender.other,
      notes: '',
      createdAt: DateTime.utc(2026),
      birthRecords: [_birth()],
    );

BirthRecord _birth() => BirthRecord(
      id: 2,
      clientId: 1,
      label: 'Primary',
      localDateTime: DateTime(1990, 1, 1, 10, 30),
      utcOffsetMinutes: 330,
      placeName: 'Kolkata',
      latitude: 22.57,
      longitude: 88.36,
      confidence: BirthTimeConfidence.recorded,
      sourceNote: 'recorded',
    );

KundliAnalysisSnapshot _kundli() => KundliAnalysisSnapshot(
      id: 11,
      consultationId: 7,
      calculationOutputId: 9,
      engineId: 'vedic-lagna-judgment',
      engineVersion: '28.0.0',
      analysisSchemaVersion: 'kundli-analysis-v28',
      analysis: {
        'findings': [
          {
            'code': 'vedic.life_area.career',
            'area': 'career',
            'polarity': 'supportive',
            'confidence': 'medium',
            'titleEn': 'Career structure supportive',
            'titleBn': 'কর্মজীবনের কাঠামো সহায়ক',
            'narrativeEn': 'Governed D1 evidence.',
            'narrativeBn': 'Governed D1 evidence।',
            'evidence': [
              {'outputPath': r'$.planets.jupiter'}
            ],
          },
          {
            'code': 'vedic.yoga.test',
            'area': 'career',
            'polarity': 'mixed',
            'confidence': 'low',
            'titleEn': 'Yoga review',
            'titleBn': 'যোগ বিচার',
            'narrativeEn': 'Formation only.',
            'narrativeBn': 'শুধু formation।',
            'evidence': const [],
          },
        ],
        'navamsaHouseInterpretations': [
          {
            'code': 'vedic.divisional.d9.house_10',
            'polarity': 'mixed',
            'confidence': 'medium',
            'titleEn': 'D9 house 10',
            'titleBn': 'D9 ভাব ১০',
            'narrativeEn': 'D9 evidence.',
            'narrativeBn': 'D9 evidence।',
            'evidence': const [],
          },
        ],
        'dashamsaHouseInterpretations': [
          {
            'code': 'vedic.divisional.d10.house_10',
            'polarity': 'supportive',
            'confidence': 'medium',
            'titleEn': 'D10 house 10',
            'titleBn': 'D10 ভাব ১০',
            'narrativeEn': 'D10 evidence.',
            'narrativeBn': 'D10 evidence।',
            'evidence': const [],
          },
        ],
        'dashamsaCareerSynthesis': {
          'code': 'vedic.divisional.d10.career_synthesis',
          'polarity': 'supportive',
          'confidence': 'medium',
          'titleEn': 'Career synthesis',
          'titleBn': 'কর্মজীবন synthesis',
          'narrativeEn': 'D1 and D10 agree.',
          'narrativeBn': 'D1 ও D10 একমত।',
          'evidence': const [],
        },
        'shadbalaProfiles': [
          {
            'planet': 'Jupiter',
            'aggregateAvailable': true,
            'totalShadbalaVirupas': 410.0,
            'requiredShadbalaVirupas': 390.0,
            'requiredStrengthRatio': 1.051,
            'thresholdStatus': 'meetsRequired',
          },
        ],
        'ashtakavargaProfile': {
          'totalPositiveMarks': 337,
          'sarvashtakavarga': [
            {
              'houseNumber': 10,
              'positiveMarks': 31,
              'polarity': 'supportive',
              'confidence': 'medium',
              'narrativeEn': 'Comparative house support.',
              'narrativeBn': 'তুলনামূলক ভাব-সমর্থন।',
            },
          ],
        },
        'pratyantardashaInterpretations': [
          {
            'code': 'vedic.pd.current',
            'startUtc': '2026-08-01T00:00:00.000Z',
            'endUtc': '2026-08-09T00:00:01.000Z',
            'polarity': 'mixed',
            'confidence': 'medium',
            'titleEn': 'Current PD',
            'titleBn': 'বর্তমান PD',
            'narrativeEn': 'Current review layer.',
            'narrativeBn': 'বর্তমান review layer।',
            'evidence': const [],
          },
        ],
        'timingWindows': const [],
        'gemstoneCandidateReviews': [
          {
            'code': 'vedic.gemstone.saturn.v1',
            'ruleVersion': 'vedic-gemstone-candidate-v1',
            'mappingProfile': 'astro-logic-navaratna-mapping-v1',
            'planet': 'saturn',
            'primaryGemstone': 'Blue Sapphire',
            'primaryGemstoneBn': 'নীলা',
            'status': 'eligible',
            'rationaleEn': 'Eligible for professional strengthening review only.',
            'rationaleBn': 'শুধু professional strengthening review-এর জন্য eligible।',
            'cautionEn': 'No automatic wearing approval.',
            'cautionBn': 'কোনো automatic wearing approval নয়।',
            'evidence': [
              {'outputPath': r'$.shadbalaProfiles[6]'},
              {'outputPath': r'$.vimshottari'},
            ],
          },
        ],
        'remedyCandidates': [
          {
            'code': 'vedic.remedy.behavioral.finance.v1',
            'kind': 'behavioral',
            'targetPlanet': null,
            'actionEn': 'Use a written budget and independent due diligence.',
            'actionBn': 'লিখিত budget ও স্বাধীন due diligence ব্যবহার করুন।',
            'rationaleEn': 'Two independent finance rules are challenging.',
            'rationaleBn': 'দুটি স্বাধীন finance rule challenging।',
            'cautionEn': 'Astrology is not investment advice.',
            'cautionBn': 'জ্যোতিষ বিনিয়োগ-পরামর্শ নয়।',
            'evidence': [
              {'outputPath': r'$.houses[1]'},
              {'outputPath': r'$.ashtakavarga.sarvashtakavarga[1]'},
            ],
          },
        ],
        'warningsEn': ['Professional review required.'],
        'warningsBn': ['পেশাদার যাচাই প্রয়োজন।'],
      },
      analysisHash: 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
      createdAt: DateTime.utc(2026, 8, 8),
    );

NumerologySnapshot _numerology() => NumerologySnapshot(
      id: 15,
      consultationId: 7,
      clientId: 1,
      birthRecordId: 2,
      targetYear: 2026,
      nameLatin: 'TEST CLIENT',
      calculationEngineId: 'astro-logic-numerology',
      calculationEngineVersion: '2.1.0',
      calculationSchemaVersion: 'numerology-profile-v3',
      calculation: const {},
      analysisEngineId: 'astro-logic-numerology-judgment',
      analysisEngineVersion: '2.1.0',
      analysisSchemaVersion: 'numerology-analysis-v3',
      analysis: {
        'findings': [
          {
            'code': 'numerology.life_path.1',
            'area': 'overall',
            'polarity': 'mixed',
            'confidence': 'low',
            'titleEn': 'Life Path 1',
            'titleBn': 'লাইফ পাথ ১',
            'narrativeEn': 'Traditional symbolic review.',
            'narrativeBn': 'প্রচলিত প্রতীকী বিচার।',
            'evidence': const [],
          },
        ],
        'nameCandidateReviews': [
          {
            'code': 'numerology.name_candidate.1',
            'candidateNameLatin': 'TEST KLIENT',
            'comparisonStatus': 'bothSystemsReducedChange',
            'selectedForProfessionalReview': true,
            'confidence': 'medium',
            'narrativeEn': 'Arithmetic comparison only; professional focus recorded.',
            'narrativeBn': 'শুধু arithmetic comparison; professional focus সংরক্ষিত।',
            'cautionEn': 'No ranking, lucky-name claim or legal-name-change recommendation.',
            'cautionBn': 'Ranking, lucky-name claim বা legal-name-change recommendation নেই।',
            'evidence': [
              {'outputPath': r'$.nameCandidateComparisons[0].pythagoreanDelta'},
            ],
          },
        ],
        'crossSystemFindings': [
          {
            'code': 'numerology.vedic_crosscheck.life_path.sun.insufficientEvidence',
            'area': 'overall',
            'polarity': 'mixed',
            'confidence': 'low',
            'titleEn': 'Life Path 1 ↔ Sun — Vedic context',
            'titleBn': 'লাইফ পাথ ১ ↔ সূর্য — বৈদিক context',
            'narrativeEn': 'Caution context only; no confidence uplift.',
            'narrativeBn': 'শুধু caution context; confidence বৃদ্ধি নয়।',
            'evidence': const [],
          },
        ],
        'timingWindows': [
          {
            'code': 'numerology.personal_year.2026.8',
            'area': 'overall',
            'start': '2026-01-01T00:00:00.000Z',
            'end': '2027-01-01T00:00:00.000Z',
            'polarity': 'mixed',
            'confidence': 'low',
            'narrativeEn': 'Target calendar-year planning context: Personal Year 8.',
            'narrativeBn': 'Target calendar-year planning context: Personal Year 8।',
            'evidence': const [],
          },
        ],
        'remedyCandidates': [
          {
            'code': 'numerology.remedy.personal_year.8.behavioral',
            'kind': 'behavioral',
            'actionEn': 'Review cash flow monthly.',
            'actionBn': 'মাসে একবার cash flow পর্যালোচনা করুন।',
            'rationaleEn': 'Low-risk planning exercise.',
            'rationaleBn': 'কম-ঝুঁকির planning exercise।',
            'cautionEn': 'Not prediction or professional financial advice.',
            'cautionBn': 'Prediction বা professional financial advice নয়।',
            'evidence': const [],
          },
        ],
        'confidenceSummary': {
          'predictionConfidence': 'low',
          'rationaleEn': 'Arithmetic deterministic; symbolic prediction remains Low.',
          'rationaleBn': 'Arithmetic deterministic; symbolic prediction Low থাকে।',
        },
        'warningsEn': ['Traditional numerology only.'],
        'warningsBn': ['শুধু প্রচলিত সংখ্যাতত্ত্ব।'],
      },
      snapshotHash: 'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
      createdAt: DateTime.utc(2026, 8, 8),
    );
