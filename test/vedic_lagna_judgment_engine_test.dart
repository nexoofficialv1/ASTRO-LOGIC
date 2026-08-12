import 'package:astro_logic/src/models/calculation_output_snapshot.dart';
import 'package:astro_logic/src/models/kundli_analysis.dart';
import 'package:astro_logic/src/services/kundli_judgment_policy.dart';
import 'package:astro_logic/src/vedic/vedic_lagna_judgment_engine.dart';
import 'package:astro_logic/src/vedic/vimshottari_dasha_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('own-sign Lagna lord in first house is supportive with high confidence',
      () async {
    const engine = VedicLagnaJudgmentEngine();
    final analysis = await engine.analyze(
      _output(ascendantSign: 0, lordBody: 'mars', lordSign: 0),
    );
    final finding = analysis.findings[1];

    expect(finding.polarity, AnalysisPolarity.supportive);
    expect(finding.confidence, AnalysisConfidence.high);
    expect(finding.evidence.map((value) => value.ruleId).toSet(), hasLength(2));
    expect(analysis.remedyCandidates, isEmpty);
    expect(analysis.gemstoneCandidateReviews, hasLength(7));
    expect(
      () => KundliJudgmentPolicy.validate(
        analysis,
        preciseBirthTime: true,
      ),
      returnsNormally,
    );
  });

  test('debilitated Libra Lagna lord in twelfth creates review-only remedy',
      () async {
    const engine = VedicLagnaJudgmentEngine();
    final analysis = await engine.analyze(
      _output(ascendantSign: 6, lordBody: 'venus', lordSign: 5),
    );
    final finding = analysis.findings[1];
    expect(finding.polarity, AnalysisPolarity.challenging);
    expect(finding.confidence, AnalysisConfidence.high);
    expect(
      analysis.remedyCandidates.any(
        (value) => value.kind == AnalysisRemedyKind.gemstone,
      ),
      isFalse,
    );
    expect(
      analysis.remedyCandidates.every(
        (value) => value.kind == AnalysisRemedyKind.behavioral,
      ),
      isTrue,
    );
    expect(analysis.timingWindows, isEmpty);
  });

  test('rejects a non-Vedic calculation output schema', () async {
    const engine = VedicLagnaJudgmentEngine();
    final output = _output(
      ascendantSign: 0,
      lordBody: 'mars',
      lordSign: 0,
      schema: 'western-chart-v1',
    );

    await expectLater(engine.analyze(output), throwsArgumentError);
  });

  test('builds evidence-backed Vimshottari Antardasha timing windows',
      () async {
    const engine = VedicLagnaJudgmentEngine();
    final analysis = await engine.analyze(
      _output(
        ascendantSign: 0,
        lordBody: 'mars',
        lordSign: 0,
        schema: 'vedic-chart-v4',
        includeVimshottari: true,
      ),
    );

    expect(analysis.timingWindows, isNotEmpty);
    expect(analysis.dashaActivationProfiles, hasLength(9));
    expect(analysis.pratyantardashaInterpretations, hasLength(729));
    expect(analysis.navamsaHouseInterpretations, hasLength(12));
    expect(analysis.shadbalaProfiles, hasLength(7));
    expect(analysis.ashtakavargaProfile, isNotNull);
    expect(analysis.ashtakavargaProfile!.bhinnashtakavarga, hasLength(7));
    expect(analysis.ashtakavargaProfile!.sarvashtakavarga, hasLength(12));
    expect(analysis.ashtakavargaProfile!.totalPositiveMarks, 337);
    expect(analysis.ashtakavargaProfile!.ruleVersion, 'ashtakavarga-foundation-v3');
    expect(analysis.ashtakavargaProfile!.reductionProfile, isNotNull);
    expect(analysis.ashtakavargaProfile!.reductionProfile!.planets, hasLength(7));
    expect(analysis.ashtakavargaProfile!.pindaProfile, isNotNull);
    expect(analysis.ashtakavargaProfile!.pindaProfile!.planets, hasLength(7));
    expect(analysis.ashtakavargaProfile!.pindaProfile!.ruleVersion, 'ashtakavarga-pinda-v1');
    expect(
      analysis.shadbalaProfiles.every(
        (value) =>
            value.ruleVersion == 'shadbala-foundation-v10' &&
            !value.aggregateAvailable &&
            value.digBalaVirupas >= 0 &&
            value.digBalaVirupas <= 60 &&
            value.pakshaBalaVirupas >= 0 &&
            value.pakshaBalaVirupas <= 60 &&
            value.ayanaBalaVirupas >= 0 &&
            value.ayanaBalaVirupas <= 60 &&
            value.drikBalaVirupas.isFinite &&
            value.drikProfile == 'bphsSphutaDrishtiDrikV1' &&
            value.drikContributions.every(
              (item) => item.aspectVirupas > 0 && item.aspectVirupas <= 60,
            ) &&
            !value.kalaBalaComplete &&
            value.totalShadbalaVirupas == null &&
            value.evidence.isNotEmpty,
      ),
      isTrue,
    );
    expect(
      analysis.toJson()['shadbalaProfiles'] as List,
      hasLength(7),
    );
    expect(
      analysis.findings
          .where((value) => value.code.startsWith('vedic.shadbala.'))
          .length,
      7,
    );
    expect(
      analysis.findings
          .where((value) => value.code.startsWith('vedic.ashtakavarga.house_'))
          .length,
      12,
    );
    expect(
      analysis.toJson()['pratyantardashaInterpretations'] as List,
      hasLength(729),
    );
    expect(
      analysis.toJson()['navamsaHouseInterpretations'] as List,
      hasLength(12),
    );
    expect(
      analysis.findings
          .where((value) =>
              value.code.startsWith('vedic.divisional.d9.house_'))
          .length,
      12,
    );
    expect(
      analysis.pratyantardashaInterpretations.every(
        (value) =>
            value.ruleVersion == 'pratyantardasha-interpretation-v1' &&
            value.lifeAreas.isNotEmpty &&
            value.evidence.isNotEmpty,
      ),
      isTrue,
    );
    expect(
      analysis.dashaActivationProfiles.map((value) => value.lord).toSet(),
      hasLength(9),
    );
    expect(
      analysis.dashaActivationProfiles.every(
        (value) => value.lifeAreas.isNotEmpty && value.evidence.isNotEmpty,
      ),
      isTrue,
    );
    final rahu = analysis.dashaActivationProfiles.firstWhere(
      (value) => value.lord == 'rahu',
    );
    expect(
      rahu.evidence.any((value) => value.ruleId.contains('dispositor')),
      isTrue,
    );
    expect(
      analysis.timingWindows.every(
        (value) => value.confidence == AnalysisConfidence.medium,
      ),
      isTrue,
    );
    expect(
      analysis.timingWindows.first.evidence.first.ruleId,
      'vedic.dasha.vimshottari.calendar.v1',
    );
    expect(analysis.timingWindows.first.narrativeEn, contains('activation score'));
    expect(analysis.timingWindows.first.narrativeBn, contains('activation score'));
    expect(
      () => KundliJudgmentPolicy.validate(
        analysis,
        preciseBirthTime: false,
      ),
      returnsNormally,
    );
  });

  test('requires Vimshottari data for vedic-chart-v3', () async {
    const engine = VedicLagnaJudgmentEngine();

    await expectLater(
      engine.analyze(
        _output(
          ascendantSign: 0,
          lordBody: 'mars',
          lordSign: 0,
          schema: 'vedic-chart-v3',
        ),
      ),
      throwsStateError,
    );
  });

  test('rejects an inconsistent Vimshottari Antardasha boundary', () async {
    const engine = VedicLagnaJudgmentEngine();
    final output = _output(
      ascendantSign: 0,
      lordBody: 'mars',
      lordSign: 0,
      schema: 'vedic-chart-v3',
      includeVimshottari: true,
    );
    final vimshottari =
        output.output['vimshottari']! as Map<String, Object?>;
    final mahadashas =
        (vimshottari['mahadashas']! as List).cast<Map<String, Object?>>();
    final antardashas = (mahadashas.first['antardashas']! as List)
        .cast<Map<String, Object?>>();
    antardashas[1]['startUtc'] = antardashas.first['startUtc'];

    await expectLater(engine.analyze(output), throwsStateError);
  });

  test('rejects an inconsistent Pratyantardasha boundary', () async {
    const engine = VedicLagnaJudgmentEngine();
    final output = _output(
      ascendantSign: 0,
      lordBody: 'mars',
      lordSign: 0,
      schema: 'vedic-chart-v4',
      includeVimshottari: true,
    );
    final vimshottari =
        output.output['vimshottari']! as Map<String, Object?>;
    final mahadashas =
        (vimshottari['mahadashas']! as List).cast<Map<String, Object?>>();
    final antardashas = (mahadashas.first['antardashas']! as List)
        .cast<Map<String, Object?>>();
    final pratyantardashas =
        (antardashas.first['pratyantardashas']! as List)
            .cast<Map<String, Object?>>();
    pratyantardashas[1]['startUtc'] = pratyantardashas.first['startUtc'];

    await expectLater(engine.analyze(output), throwsStateError);
  });

  test('evaluates all houses and functional ownership for Libra ascendant',
      () async {
    const engine = VedicLagnaJudgmentEngine();
    final analysis = await engine.analyze(
      _output(
        ascendantSign: 6,
        lordBody: 'venus',
        lordSign: 5,
        planetSigns: const {
          'saturn': 6,
          'mercury': 11,
        },
      ),
    );
    final houseFindings = analysis.findings
        .where((value) => value.code.startsWith('vedic.house.'))
        .toList(growable: false);
    final fourth = houseFindings.firstWhere(
      (value) => value.code.startsWith('vedic.house.4.'),
    );
    final twelfth = houseFindings.firstWhere(
      (value) => value.code.startsWith('vedic.house.12.'),
    );
    final saturnRole = analysis.findings.firstWhere(
      (value) => value.code == 'vedic.functional_role.saturn',
    );
    final jupiterRole = analysis.findings.firstWhere(
      (value) => value.code == 'vedic.functional_role.jupiter',
    );

    expect(houseFindings, hasLength(12));
    expect(fourth.polarity, AnalysisPolarity.supportive);
    expect(fourth.confidence, AnalysisConfidence.high);
    expect(twelfth.polarity, AnalysisPolarity.challenging);
    expect(twelfth.confidence, AnalysisConfidence.high);
    expect(saturnRole.polarity, AnalysisPolarity.supportive);
    expect(saturnRole.narrativeEn, contains('Yoga-karaka flag'));
    expect(jupiterRole.polarity, AnalysisPolarity.challenging);
  });

  test('builds twelve integrated detailed life-area judgments', () async {
    const engine = VedicLagnaJudgmentEngine();
    final analysis = await engine.analyze(
      _output(
        ascendantSign: 0,
        lordBody: 'mars',
        lordSign: 0,
        planetSigns: const {
          'jupiter': 4,
          'saturn': 6,
        },
      ),
    );
    final detailed = analysis.findings
        .where((value) => value.code.startsWith('vedic.life_area.'))
        .toList(growable: false);

    expect(detailed, hasLength(12));
    for (final finding in detailed) {
      expect(finding.evidence.length, greaterThanOrEqualTo(3));
      expect(finding.narrativeEn, contains('transparent net rule score'));
      expect(finding.narrativeEn, contains('Navamsha'));
      expect(finding.narrativeBn, contains('স্বচ্ছ net rule score'));
      expect(finding.narrativeBn, contains('নবাংশ'));
    }
    expect(
      detailed.any((value) =>
          value.narrativeEn.contains('Supportive evidence:') &&
          value.narrativeEn.contains('Challenging evidence:')),
      isTrue,
    );
    expect(
      () => KundliJudgmentPolicy.validate(
        analysis,
        preciseBirthTime: true,
      ),
      returnsNormally,
    );
  });

  test('detects Ruchaka formation with independent strength evidence',
      () async {
    const engine = VedicLagnaJudgmentEngine();
    final analysis = await engine.analyze(
      _output(ascendantSign: 0, lordBody: 'mars', lordSign: 0),
    );
    final ruchaka = analysis.findings.firstWhere(
      (value) => value.code == 'vedic.yoga.panchamahapurusha.ruchaka',
    );

    expect(ruchaka.polarity, AnalysisPolarity.supportive);
    expect(ruchaka.confidence, AnalysisConfidence.high);
    expect(ruchaka.evidence, hasLength(2));
    expect(ruchaka.narrativeEn, contains('structural potential only'));
    expect(ruchaka.narrativeBn, contains('কাঠামোগত সম্ভাবনা'));
  });

  test('keeps Kuja screen mixed and records mitigation without auto-cancel',
      () async {
    const engine = VedicLagnaJudgmentEngine();
    final analysis = await engine.analyze(
      _output(ascendantSign: 0, lordBody: 'mars', lordSign: 0),
    );
    final kuja = analysis.findings.firstWhere(
      (value) => value.code == 'vedic.dosha.kuja.lagna_screen.matched',
    );

    expect(kuja.polarity, AnalysisPolarity.mixed);
    expect(kuja.confidence, AnalysisConfidence.medium);
    expect(kuja.narrativeEn, contains('Possible mitigating evidence'));
    expect(kuja.narrativeEn, contains('not treated as automatic cancellation'));
    expect(kuja.narrativeEn, contains('must never be used alone'));
    expect(kuja.narrativeBn, contains('স্বয়ংক্রিয় সম্পূর্ণ খণ্ডন'));
    expect(kuja.evidence.any((value) => value.kind == EvidenceKind.dosha), isTrue);
  });

  test('labels second-house Kuja as an extended variant', () async {
    const engine = VedicLagnaJudgmentEngine();
    final analysis = await engine.analyze(
      _output(ascendantSign: 0, lordBody: 'mars', lordSign: 1),
    );
    final kuja = analysis.findings.firstWhere(
      (value) => value.code == 'vedic.dosha.kuja.lagna_screen.matched',
    );

    expect(kuja.narrativeEn, contains('extended 2nd-house variant'));
    expect(
      kuja.evidence.first.ruleId,
      'vedic.dosha.kuja.lagna_house.extended.v1',
    );
  });

  test('establishes BPHS Gajakesari only when qualifiers pass', () async {
    const engine = VedicLagnaJudgmentEngine();
    final analysis = await engine.analyze(
      _output(
        ascendantSign: 0,
        lordBody: 'mars',
        lordSign: 0,
        planetSigns: const {
          'jupiter': 3,
          'venus': 9,
        },
      ),
    );
    final gajakesari = analysis.findings.firstWhere(
      (value) => value.code == 'vedic.yoga.gajakesari.bphs.established',
    );

    expect(gajakesari.polarity, AnalysisPolarity.supportive);
    expect(gajakesari.confidence, AnalysisConfidence.high);
    expect(gajakesari.narrativeEn, contains('not guaranteed'));
    expect(gajakesari.narrativeBn, contains('নিশ্চিত নয়'));
    expect(
      gajakesari.evidence.any(
        (value) => value.ruleId.contains('benefic_support'),
      ),
      isTrue,
    );
  });

  test('keeps incomplete Gajakesari geometry as a candidate', () async {
    const engine = VedicLagnaJudgmentEngine();
    final analysis = await engine.analyze(
      _output(
        ascendantSign: 0,
        lordBody: 'mars',
        lordSign: 0,
        planetSigns: const {'jupiter': 3},
      ),
    );
    final candidate = analysis.findings.firstWhere(
      (value) => value.code == 'vedic.yoga.gajakesari.bphs.candidate',
    );

    expect(candidate.polarity, AnalysisPolarity.mixed);
    expect(candidate.confidence, AnalysisConfidence.medium);
    expect(candidate.narrativeEn, contains('profile is not established'));
    expect(candidate.narrativeBn, contains('candidate'));
  });

  test('detects Lagna-lord and fifth-lord Raja Yoga formation', () async {
    const engine = VedicLagnaJudgmentEngine();
    final analysis = await engine.analyze(
      _output(
        ascendantSign: 0,
        lordBody: 'mars',
        lordSign: 4,
        planetLongitudes: const {
          'sun': 121,
          'mars': 149,
        },
      ),
    );
    final raja = analysis.findings.firstWhere(
      (value) =>
          value.code ==
          'vedic.yoga.raja.lagna_fifth_lord_conjunction.v1',
    );

    expect(raja.polarity, AnalysisPolarity.supportive);
    expect(raja.confidence, AnalysisConfidence.high);
    expect(raja.evidence, hasLength(2));
    expect(raja.narrativeEn, contains('not a promise'));
  });

  test('detects fifth and eleventh lords in own houses Dhana Yoga',
      () async {
    const engine = VedicLagnaJudgmentEngine();
    final analysis = await engine.analyze(
      _output(
        ascendantSign: 0,
        lordBody: 'mars',
        lordSign: 0,
        planetSigns: const {'saturn': 10},
      ),
    );
    final dhana = analysis.findings.firstWhere(
      (value) =>
          value.code ==
          'vedic.yoga.dhana.fifth_eleventh_lords_own_houses.v1',
    );

    expect(dhana.polarity, AnalysisPolarity.supportive);
    expect(dhana.confidence, AnalysisConfidence.high);
    expect(dhana.evidence, hasLength(2));
    expect(dhana.narrativeEn, contains('not guaranteed wealth'));
    expect(dhana.narrativeBn, contains('নিশ্চিত সম্পদ নয়'));
  });

  test('builds seven D1-D9 dignity agreement findings', () async {
    const engine = VedicLagnaJudgmentEngine();
    final analysis = await engine.analyze(
      _output(ascendantSign: 0, lordBody: 'mars', lordSign: 0),
    );
    final divisional = analysis.findings
        .where((value) => value.code.startsWith('vedic.divisional.d1_d9.'))
        .toList(growable: false);
    final sun = divisional.firstWhere(
      (value) => value.code == 'vedic.divisional.d1_d9.sun',
    );
    final moon = divisional.firstWhere(
      (value) => value.code == 'vedic.divisional.d1_d9.moon',
    );

    expect(divisional, hasLength(7));
    expect(sun.polarity, AnalysisPolarity.supportive);
    expect(sun.confidence, AnalysisConfidence.high);
    expect(sun.narrativeEn, contains('Vargottama'));
    expect(sun.narrativeBn, contains('বর্গোত্তম'));
    expect(moon.polarity, AnalysisPolarity.mixed);
    expect(moon.narrativeEn, contains('opposite directions'));
    expect(moon.evidence, hasLength(2));
  });

  test('rejects inconsistent supplied Navamsha sign', () async {
    const engine = VedicLagnaJudgmentEngine();
    final output = _output(
      ascendantSign: 0,
      lordBody: 'mars',
      lordSign: 0,
      includeInvalidNavamsa: true,
    );

    await expectLater(engine.analyze(output), throwsStateError);
  });

  test('builds twelve occupancy records and thirteen Parashari full aspects',
      () async {
    const engine = VedicLagnaJudgmentEngine();
    final analysis = await engine.analyze(
      _output(ascendantSign: 0, lordBody: 'mars', lordSign: 0),
    );
    final occupancies = analysis.findings
        .where((value) => value.code.startsWith('vedic.occupancy.'))
        .toList(growable: false);
    final aspects = analysis.findings
        .where((value) => value.code.startsWith('vedic.aspect.'))
        .toList(growable: false);

    expect(occupancies, hasLength(12));
    expect(aspects, hasLength(13));
    expect(
      aspects.any((value) => value.code == 'vedic.aspect.mars.4th.house_4'),
      isTrue,
    );
    expect(
      aspects.any((value) => value.code == 'vedic.aspect.jupiter.9th.house_5'),
      isTrue,
    );
    expect(
      aspects.any((value) => value.code == 'vedic.aspect.saturn.10th.house_7'),
      isTrue,
    );
  });

  test('flags versioned combustion and keeps retrograde interpretation mixed',
      () async {
    const engine = VedicLagnaJudgmentEngine();
    final analysis = await engine.analyze(
      _output(
        ascendantSign: 0,
        lordBody: 'mars',
        lordSign: 0,
        planetSigns: const {
          'sun': 0,
          'mercury': 0,
        },
        planetLongitudes: const {
          'sun': 10,
          'mercury': 21,
        },
        retrogradePlanets: const {'mercury'},
      ),
    );
    final combustion = analysis.findings.firstWhere(
      (value) => value.code == 'vedic.condition.combust.mercury',
    );
    final retrograde = analysis.findings.firstWhere(
      (value) => value.code == 'vedic.condition.retrograde.mercury',
    );

    expect(combustion.polarity, AnalysisPolarity.challenging);
    expect(combustion.narrativeEn, contains('12.0° combustion threshold'));
    expect(retrograde.polarity, AnalysisPolarity.mixed);
    expect(retrograde.narrativeEn, contains('not as automatically'));
  });

  test('combustion distance wraps across zero degrees and includes boundary',
      () async {
    const engine = VedicLagnaJudgmentEngine();
    final analysis = await engine.analyze(
      _output(
        ascendantSign: 0,
        lordBody: 'mars',
        lordSign: 0,
        planetSigns: const {
          'sun': 11,
          'saturn': 0,
        },
        planetLongitudes: const {
          'sun': 359,
          'saturn': 15,
        },
      ),
    );
    final saturn = analysis.findings.firstWhere(
      (value) => value.code == 'vedic.condition.combust.saturn',
    );

    expect(saturn.narrativeEn, contains('16.000°'));
    expect(saturn.narrativeEn, contains('16.0° combustion threshold'));
  });

  test('detects degree-specific Moolatrikona independently of broad dignity',
      () async {
    const engine = VedicLagnaJudgmentEngine();
    final analysis = await engine.analyze(
      _output(
        ascendantSign: 0,
        lordBody: 'mars',
        lordSign: 0,
        planetSigns: const {'sun': 4},
        planetLongitudes: const {'sun': 130},
      ),
    );
    final finding = analysis.findings.firstWhere(
      (value) => value.code == 'vedic.moolatrikona.sun',
    );

    expect(finding.polarity, AnalysisPolarity.supportive);
    expect(finding.narrativeEn, contains('10.000°'));
    expect(finding.narrativeEn, contains('[0°, 20°)'));
  });

  test('classifies permanent natural relationship to the sign dispositor',
      () async {
    const engine = VedicLagnaJudgmentEngine();
    final analysis = await engine.analyze(
      _output(
        ascendantSign: 0,
        lordBody: 'mars',
        lordSign: 2,
      ),
    );
    final finding = analysis.findings.firstWhere(
      (value) => value.code == 'vedic.friendship.mars.mercury',
    );

    expect(finding.polarity, AnalysisPolarity.challenging);
    expect(finding.narrativeEn, contains('permanent natural relationship'));
    expect(finding.narrativeEn, contains('enemy'));
    expect(finding.narrativeEn, contains('Temporary and compound'));
  });

  test('synthesizes same-sign conjunction and conflicting house aspects',
      () async {
    const engine = VedicLagnaJudgmentEngine();
    final analysis = await engine.analyze(
      _output(
        ascendantSign: 0,
        lordBody: 'mars',
        lordSign: 0,
        planetSigns: const {'sun': 4, 'mercury': 4},
        planetLongitudes: const {'sun': 130, 'mercury': 137},
      ),
    );
    final conjunction = analysis.findings.firstWhere(
      (value) => value.code == 'vedic.conjunction.sun.mercury',
    );
    final synthesis = analysis.findings.firstWhere(
      (value) => value.code == 'vedic.aspect_synthesis.house_11',
    );

    expect(conjunction.narrativeEn, contains('7.000°'));
    expect(conjunction.narrativeEn, contains('planetary war'));
    expect(synthesis.polarity, AnalysisPolarity.mixed);
    expect(synthesis.evidence, hasLength(2));
    expect(synthesis.narrativeEn, contains('Sun, Mercury'));
  });

  test('combines natural and temporary relations into five-fold friendship',
      () async {
    const engine = VedicLagnaJudgmentEngine();
    final analysis = await engine.analyze(
      _output(
        ascendantSign: 0,
        lordBody: 'mars',
        lordSign: 2,
        planetLongitudes: const {'mars': 65, 'mercury': 75},
      ),
    );
    final finding = analysis.findings.firstWhere(
      (value) => value.code ==
          'vedic.compound_friendship.mars.mercury',
    );

    expect(finding.polarity, AnalysisPolarity.challenging);
    expect(finding.titleEn, contains('great enemy'));
    expect(finding.narrativeEn, contains('temporary relationship enemy'));
    expect(finding.evidence, hasLength(2));
  });

  test('flags five-planet war proximity but does not invent a victor',
      () async {
    const engine = VedicLagnaJudgmentEngine();
    final analysis = await engine.analyze(
      _output(
        ascendantSign: 0,
        lordBody: 'mars',
        lordSign: 3,
        planetSigns: const {
          'sun': 3,
          'mars': 3,
          'mercury': 3,
        },
        planetLongitudes: const {
          'sun': 100.5,
          'mars': 100,
          'mercury': 101,
        },
      ),
    );
    final finding = analysis.findings.firstWhere(
      (value) => value.code == 'vedic.planetary_war.mars.mercury',
    );

    expect(finding.polarity, AnalysisPolarity.mixed);
    expect(finding.narrativeEn, contains('1.000°'));
    expect(finding.narrativeEn, contains('does not declare a victor'));
    expect(
      analysis.findings.any(
        (value) => value.code.startsWith('vedic.planetary_war.sun.'),
      ),
      isFalse,
    );
  });
}

CalculationOutputSnapshot _output({
  required int ascendantSign,
  required String lordBody,
  required int lordSign,
  Map<String, int> planetSigns = const {},
  Map<String, double> planetLongitudes = const {},
  Set<String> retrogradePlanets = const {},
  String schema = 'vedic-chart-v1',
  bool includeInvalidNavamsa = false,
  bool includeVimshottari = false,
}) {
  final signs = <String, int>{
    'sun': 4,
    'moon': 3,
    'mars': 0,
    'mercury': 2,
    'jupiter': 8,
    'venus': 1,
    'saturn': 9,
    ...planetSigns,
    lordBody: lordSign,
    if (includeVimshottari) 'rahu': 10,
    if (includeVimshottari) 'ketu': 4,
  };
  final birthUtc = DateTime.utc(1984, 3, 12, 18, 42);
  final moonLongitude =
      planetLongitudes['moon'] ?? signs['moon']! * 30.0 + 15.0;
  final planetMaps = signs.entries
      .map((entry) {
        final longitude = planetLongitudes[entry.key] ??
            entry.value * 30.0 + 15.0;
        final calculatedNavamsa = ((longitude * 9.0) ~/ 30.0) % 12;
        return <String, Object?>{
          'body': entry.key,
          'signIndex': entry.value,
          'siderealLongitude': longitude,
          'tropicalLongitude': longitude,
          'navamsaSignIndex':
              includeInvalidNavamsa && entry.key == 'sun'
                  ? 0
                  : calculatedNavamsa,
          'retrograde': retrogradePlanets.contains(entry.key),
        };
      })
      .toList(growable: false);
  final explicitD9 = schema != 'vedic-chart-v1'
      ? <String, Object?>{
          'division': 9,
          'ascendant': {'signIndex': ascendantSign},
          'planets': [
            for (final planet in planetMaps)
              {
                'body': planet['body'],
                'signIndex': planet['navamsaSignIndex'],
              },
          ],
        }
      : null;
  return CalculationOutputSnapshot(
      id: 1,
      consultationId: 1,
      inputSnapshotId: 1,
      engineId: 'fixture-vedic',
      engineVersion: '1',
      outputSchemaVersion: schema,
      output: {
        'metadata': {'utcDateTime': birthUtc.toIso8601String()},
        'ascendant': {
          'signIndex': ascendantSign,
          'siderealLongitude': ascendantSign * 30.0 + 15.0,
          if (explicitD9 != null) 'navamsaSignIndex': ascendantSign,
        },
        'planets': planetMaps,
        if (explicitD9 != null)
          'divisionalCharts': {'d9': explicitD9},
        if (includeVimshottari)
          'vimshottari': VimshottariDashaEngine.calculate(
            moonSiderealLongitude: moonLongitude,
            birthUtc: birthUtc,
          ),
      },
      outputHash: List.filled(64, 'a').join(),
      createdAt: DateTime.utc(2026, 8, 5),
    );
}
