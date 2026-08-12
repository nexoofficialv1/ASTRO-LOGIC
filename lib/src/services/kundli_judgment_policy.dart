import '../models/kundli_analysis.dart';

class KundliJudgmentPolicy {
  const KundliJudgmentPolicy._();

  static void validate(
    KundliAnalysis analysis, {
    required bool preciseBirthTime,
  }) {
    if (!analysis.professionalReviewRequired || analysis.findings.isEmpty) {
      throw StateError(
        'A non-empty analysis requiring professional review is mandatory',
      );
    }
    for (final finding in analysis.findings) {
      _requireBilingual(
        finding.titleEn,
        finding.titleBn,
        finding.narrativeEn,
        finding.narrativeBn,
      );
      _validateEvidence(finding.evidence, finding.confidence);
    }
    for (final timing in analysis.timingWindows) {
      if (!timing.end.isAfter(timing.start)) {
        throw ArgumentError('Timing window end must be after start');
      }
      if (!preciseBirthTime &&
          timing.confidence == AnalysisConfidence.high) {
        throw StateError(
          'High-confidence timing requires exact or recorded birth time',
        );
      }
      _requireBilingual(
        timing.narrativeEn,
        timing.narrativeBn,
      );
      _validateEvidence(timing.evidence, timing.confidence);
    }
    final dashaLords = <String>{};
    for (final profile in analysis.dashaActivationProfiles) {
      if (profile.lord.trim().isEmpty || !dashaLords.add(profile.lord)) {
        throw StateError('Dasha activation lords must be non-empty and unique');
      }
      if (profile.lifeAreas.isEmpty) {
        throw StateError('Every Dasha activation requires a life area');
      }
      final expectedPolarity = profile.score >= 2
          ? AnalysisPolarity.supportive
          : profile.score <= -2
              ? AnalysisPolarity.challenging
              : AnalysisPolarity.mixed;
      if (profile.polarity != expectedPolarity) {
        throw StateError('Dasha activation score and polarity disagree');
      }
      _requireBilingual(profile.summaryEn, profile.summaryBn);
      _validateEvidence(profile.evidence, AnalysisConfidence.medium);
    }
    if (analysis.pratyantardashaInterpretations.isNotEmpty) {
      if (dashaLords.length != 9) {
        throw StateError(
          'Pratyantardasha interpretations require all nine Dasha activation profiles',
        );
      }
      if (analysis.pratyantardashaInterpretations.length != 729) {
        throw StateError(
          'A current Pratyantardasha interpretation set must contain exactly 729 periods',
        );
      }
      final codes = <String>{};
      for (final period in analysis.pratyantardashaInterpretations) {
        if (period.code.trim().isEmpty || !codes.add(period.code)) {
          throw StateError(
            'Pratyantardasha interpretation codes must be non-empty and unique',
          );
        }
        if (period.ruleVersion != 'pratyantardasha-interpretation-v1') {
          throw StateError('Unsupported Pratyantardasha interpretation version');
        }
        if (!period.startUtc.isUtc ||
            !period.endUtc.isUtc ||
            !period.endUtc.isAfter(period.startUtc)) {
          throw StateError(
            'Pratyantardasha interpretation boundaries must be valid UTC',
          );
        }
        if (period.lifeAreas.isEmpty) {
          throw StateError(
            'Every Pratyantardasha interpretation requires a life area',
          );
        }
        final expectedWeighted = (period.mahadashaScore * 3) +
            (period.antardashaScore * 2) +
            period.pratyantardashaScore;
        if (period.weightedScore != expectedWeighted) {
          throw StateError('Pratyantardasha weighted score is inconsistent');
        }
        final signs = <int>{
          for (final score in <int>[
            period.mahadashaScore,
            period.antardashaScore,
            period.pratyantardashaScore,
          ])
            if (score != 0) score.sign,
        };
        final contradiction = signs.length > 1;
        if (period.contradictorySignals != contradiction) {
          throw StateError(
            'Pratyantardasha contradiction flag is inconsistent',
          );
        }
        final expectedPolarity = contradiction
            ? AnalysisPolarity.mixed
            : expectedWeighted >= 6
                ? AnalysisPolarity.supportive
                : expectedWeighted <= -6
                    ? AnalysisPolarity.challenging
                    : AnalysisPolarity.mixed;
        if (period.polarity != expectedPolarity) {
          throw StateError('Pratyantardasha polarity is inconsistent');
        }
        final expectedConfidence = expectedPolarity == AnalysisPolarity.mixed
            ? AnalysisConfidence.low
            : AnalysisConfidence.medium;
        if (period.confidence != expectedConfidence) {
          throw StateError('Pratyantardasha confidence is inconsistent');
        }
        final parentScore =
            (period.mahadashaScore * 3) + (period.antardashaScore * 2);
        final expectedTrigger = parentScore == 0 ||
                period.pratyantardashaScore == 0
            ? PratyantardashaTriggerRelation.neutral
            : parentScore.sign == period.pratyantardashaScore.sign
                ? PratyantardashaTriggerRelation.reinforcing
                : PratyantardashaTriggerRelation.countertrend;
        if (period.triggerRelation != expectedTrigger) {
          throw StateError(
            'Pratyantardasha trigger relation is inconsistent',
          );
        }
        _requireBilingual(
          period.titleEn,
          period.titleBn,
          period.narrativeEn,
          period.narrativeBn,
        );
        _validateEvidence(period.evidence, period.confidence);
      }
    }

    if (analysis.navamsaHouseInterpretations.isNotEmpty) {
      if (analysis.navamsaHouseInterpretations.length != 12) {
        throw StateError(
          'A current Navamsha house interpretation set must contain exactly 12 houses',
        );
      }
      final houses = <int>{};
      final codes = <String>{};
      for (final house in analysis.navamsaHouseInterpretations) {
        if (house.ruleVersion != 'navamsa-house-interpretation-v1') {
          throw StateError('Unsupported Navamsha house interpretation version');
        }
        if (house.houseNumber < 1 ||
            house.houseNumber > 12 ||
            !houses.add(house.houseNumber)) {
          throw StateError('Navamsha house numbers must be unique from 1 to 12');
        }
        if (house.code.trim().isEmpty || !codes.add(house.code)) {
          throw StateError('Navamsha interpretation codes must be unique');
        }
        if (house.signIndex < 0 ||
            house.signIndex > 11 ||
            house.lordHouse < 1 ||
            house.lordHouse > 12 ||
            house.houseLord.trim().isEmpty ||
            house.lordDignity.trim().isEmpty) {
          throw StateError('Navamsha house structure is invalid');
        }
        final expectedNet = house.lordPlacementScore +
            house.lordDignityScore +
            house.occupantScore +
            house.aspectScore;
        if (house.netScore != expectedNet) {
          throw StateError('Navamsha component scores are inconsistent');
        }
        if (house.polarity == AnalysisPolarity.mixed &&
            house.confidence != AnalysisConfidence.low) {
          throw StateError('Mixed Navamsha synthesis must remain low confidence');
        }
        if (house.confidence == AnalysisConfidence.high) {
          throw StateError('Navamsha interpretation v1 cannot emit high confidence');
        }
        _requireBilingual(
          house.titleEn,
          house.titleBn,
          house.narrativeEn,
          house.narrativeBn,
        );
        _validateEvidence(house.evidence, house.confidence);
      }
      if (houses.length != 12) {
        throw StateError('Navamsha interpretation must cover all 12 houses');
      }
    }

    if (analysis.dashamsaHouseInterpretations.isNotEmpty ||
        analysis.dashamsaCareerSynthesis != null) {
      if (analysis.dashamsaHouseInterpretations.length != 12 ||
          analysis.dashamsaCareerSynthesis == null) {
        throw StateError(
          'A current Dashamsa career set must contain 12 houses and one career synthesis',
        );
      }
      final houses = <int>{};
      final codes = <String>{};
      for (final house in analysis.dashamsaHouseInterpretations) {
        if (house.ruleVersion != 'dashamsa-career-interpretation-v1') {
          throw StateError('Unsupported Dashamsa house interpretation version');
        }
        if (house.houseNumber < 1 ||
            house.houseNumber > 12 ||
            !houses.add(house.houseNumber)) {
          throw StateError('Dashamsa house numbers must be unique from 1 to 12');
        }
        if (house.code.trim().isEmpty || !codes.add(house.code)) {
          throw StateError('Dashamsa interpretation codes must be unique');
        }
        if (house.signIndex < 0 ||
            house.signIndex > 11 ||
            house.lordHouse < 1 ||
            house.lordHouse > 12 ||
            house.houseLord.trim().isEmpty ||
            house.lordDignity.trim().isEmpty) {
          throw StateError('Dashamsa house structure is invalid');
        }
        final expectedNet = house.lordPlacementScore +
            house.lordDignityScore +
            house.occupantScore +
            house.aspectScore;
        if (house.netScore != expectedNet) {
          throw StateError('Dashamsa component scores are inconsistent');
        }
        if (house.polarity == AnalysisPolarity.mixed &&
            house.confidence != AnalysisConfidence.low) {
          throw StateError('Mixed Dashamsa synthesis must remain low confidence');
        }
        if (house.confidence == AnalysisConfidence.high) {
          throw StateError('Dashamsa interpretation v1 cannot emit high confidence');
        }
        _requireBilingual(
          house.titleEn,
          house.titleBn,
          house.narrativeEn,
          house.narrativeBn,
        );
        _validateEvidence(house.evidence, house.confidence);
      }
      if (houses.length != 12) {
        throw StateError('Dashamsa interpretation must cover all 12 houses');
      }

      final synthesis = analysis.dashamsaCareerSynthesis!;
      if (synthesis.ruleVersion != 'dashamsa-career-interpretation-v1' ||
          synthesis.code != 'vedic.divisional.d10.career_synthesis' ||
          synthesis.d1TenthLord.trim().isEmpty ||
          synthesis.d10TenthLord.trim().isEmpty ||
          synthesis.d1TenthLordD10House < 1 ||
          synthesis.d1TenthLordD10House > 12 ||
          synthesis.d10TenthLordHouse < 1 ||
          synthesis.d10TenthLordHouse > 12 ||
          synthesis.netScore != synthesis.d1LordScore + synthesis.d10TenthScore) {
        throw StateError('Dashamsa career synthesis structure is invalid');
      }
      if (synthesis.polarity == AnalysisPolarity.mixed &&
          synthesis.confidence != AnalysisConfidence.low) {
        throw StateError('Mixed D1-D10 career synthesis must remain low confidence');
      }
      if (synthesis.confidence == AnalysisConfidence.high) {
        throw StateError('D1-D10 career synthesis v1 cannot emit high confidence');
      }
      _requireBilingual(
        synthesis.titleEn,
        synthesis.titleBn,
        synthesis.narrativeEn,
        synthesis.narrativeBn,
      );
      _validateEvidence(synthesis.evidence, synthesis.confidence);
    }

    if (analysis.shadbalaProfiles.isNotEmpty) {
      const requiredPlanets = {
        'sun',
        'moon',
        'mars',
        'mercury',
        'jupiter',
        'venus',
        'saturn',
      };
      if (analysis.shadbalaProfiles.length != 7 ||
          analysis.shadbalaProfiles.map((value) => value.planet).toSet()
              .difference(requiredPlanets)
              .isNotEmpty ||
          requiredPlanets.difference(
            analysis.shadbalaProfiles.map((value) => value.planet).toSet(),
          ).isNotEmpty) {
        throw StateError(
          'Shadbala foundation must contain the seven classical planets only',
        );
      }
      final codes = <String>{};
      bool? tribhagaAvailability;
      String? tribhagaWindowKey;
      String? temporalContextKey;
      for (final profile in analysis.shadbalaProfiles) {
        if (profile.ruleVersion != 'shadbala-foundation-v10' ||
            profile.code.trim().isEmpty ||
            !codes.add(profile.code)) {
          throw StateError('Unsupported or duplicate Shadbala foundation record');
        }
        final components = <double>[
          profile.ucchaBalaVirupas,
          profile.saptavargajaBalaVirupas,
          profile.ojayugmaBalaVirupas,
          profile.kendradiBalaVirupas,
          profile.drekkanaBalaVirupas,
          profile.sthanaBalaVirupas,
          profile.digBalaVirupas,
          if (profile.nathonnataBalaVirupas != null)
            profile.nathonnataBalaVirupas!,
          if (profile.tribhagaBalaVirupas != null)
            profile.tribhagaBalaVirupas!,
          profile.pakshaBalaVirupas,
          if (profile.varshaBalaVirupas != null) profile.varshaBalaVirupas!,
          if (profile.masaBalaVirupas != null) profile.masaBalaVirupas!,
          if (profile.dinaBalaVirupas != null) profile.dinaBalaVirupas!,
          if (profile.horaBalaVirupas != null) profile.horaBalaVirupas!,
          profile.ayanaBalaVirupas,
          profile.kalaBalaPartialVirupas,
          if (profile.cheshtaBalaVirupas != null) profile.cheshtaBalaVirupas!,
          profile.naisargikaBalaVirupas,
        ];
        if (components.any((value) => !value.isFinite || value < 0)) {
          throw StateError('Shadbala foundation strengths must be finite and non-negative');
        }
        final expectedSthana = profile.ucchaBalaVirupas +
            profile.saptavargajaBalaVirupas +
            profile.ojayugmaBalaVirupas +
            profile.kendradiBalaVirupas +
            profile.drekkanaBalaVirupas;
        if ((profile.sthanaBalaVirupas - expectedSthana).abs() > 1e-9) {
          throw StateError('Shadbala Sthana components are inconsistent');
        }
        if (profile.vargaContributions.length != 7 ||
            profile.vargaContributions.map((value) => value.division).toSet()
                .difference({1, 2, 3, 7, 9, 12, 30})
                .isNotEmpty ||
            profile.vargaContributions
                    .map((value) => value.division)
                    .toSet()
                    .length !=
                7) {
          throw StateError('Saptavargaja must cover D1/D2/D3/D7/D9/D12/D30');
        }
        if (profile.vargaContributions.any(
          (value) =>
              value.signIndex < 0 ||
              value.signIndex > 11 ||
              value.hostPlanet.trim().isEmpty ||
              value.relationship.trim().isEmpty ||
              !{45.0, 30.0, 20.0, 15.0, 10.0, 4.0, 2.0}
                  .contains(value.virupas),
        )) {
          throw StateError('Saptavargaja contribution is invalid');
        }
        if (profile.digBalaVirupas < 0 || profile.digBalaVirupas > 60) {
          throw StateError('Shadbala Dig Bala must stay within 0..60 virupas');
        }
        if ((profile.nathonnataBalaVirupas != null &&
                (profile.nathonnataBalaVirupas! < 0 ||
                    profile.nathonnataBalaVirupas! > 60)) ||
            (profile.sunHourAngleHours != null &&
                (!profile.sunHourAngleHours!.isFinite ||
                    profile.sunHourAngleHours! < 0 ||
                    profile.sunHourAngleHours! >= 24)) ||
            ((profile.nathonnataBalaVirupas == null) !=
                (profile.sunHourAngleHours == null)) ||
            profile.pakshaBalaVirupas < 0 ||
            profile.pakshaBalaVirupas > 60 ||
            profile.ayanaBalaVirupas < 0 ||
            profile.ayanaBalaVirupas > 60) {
          throw StateError('Shadbala Nathonnata/Paksha/Ayana contract is invalid');
        }
        final tribhagaFields = <Object?>[
          profile.tribhagaBalaVirupas,
          profile.tribhagaPeriod,
          profile.tribhagaThird,
          profile.tribhagaPeriodStartUtc,
          profile.tribhagaPeriodEndUtc,
        ];
        final hasTribhaga = profile.tribhagaBalaVirupas != null;
        tribhagaAvailability ??= hasTribhaga;
        if (tribhagaAvailability != hasTribhaga) {
          throw StateError('Shadbala Tribhaga availability must match across planets');
        }
        if (tribhagaFields.any((value) => value != null) != hasTribhaga ||
            (hasTribhaga && tribhagaFields.any((value) => value == null))) {
          throw StateError('Shadbala Tribhaga availability contract is invalid');
        }
        if (hasTribhaga) {
          if (!{0.0, 60.0}.contains(profile.tribhagaBalaVirupas) ||
              !{'day', 'night'}.contains(profile.tribhagaPeriod) ||
              profile.tribhagaThird! < 1 ||
              profile.tribhagaThird! > 3) {
            throw StateError('Shadbala Tribhaga value contract is invalid');
          }
          final start = DateTime.tryParse(profile.tribhagaPeriodStartUtc!);
          final end = DateTime.tryParse(profile.tribhagaPeriodEndUtc!);
          if (start == null || end == null || !end.isAfter(start)) {
            throw StateError('Shadbala Tribhaga UTC period is invalid');
          }
          final windowKey =
              '${profile.tribhagaPeriod}|${profile.tribhagaThird}|${profile.tribhagaPeriodStartUtc}|${profile.tribhagaPeriodEndUtc}';
          tribhagaWindowKey ??= windowKey;
          if (tribhagaWindowKey != windowKey) {
            throw StateError('Shadbala Tribhaga solar period must match across planets');
          }
          const dayLords = <int, String>{
            1: 'mercury',
            2: 'sun',
            3: 'saturn',
          };
          const nightLords = <int, String>{
            1: 'moon',
            2: 'venus',
            3: 'mars',
          };
          final expectedTribhaga = profile.planet == 'jupiter' ||
                  profile.planet ==
                      (profile.tribhagaPeriod == 'day'
                          ? dayLords[profile.tribhagaThird]
                          : nightLords[profile.tribhagaThird])
              ? 60.0
              : 0.0;
          if ((profile.tribhagaBalaVirupas! - expectedTribhaga).abs() > 1e-9) {
            throw StateError('Shadbala Tribhaga lord assignment is invalid');
          }
        }
        const temporalAllocations = <String, double>{
          'varsha': 15.0,
          'masa': 30.0,
          'dina': 45.0,
          'hora': 60.0,
        };
        final temporalValues = <String, double?>{
          'varsha': profile.varshaBalaVirupas,
          'masa': profile.masaBalaVirupas,
          'dina': profile.dinaBalaVirupas,
          'hora': profile.horaBalaVirupas,
        };
        final temporalLords = <String, String?>{
          'varsha': profile.varshaLord,
          'masa': profile.masaLord,
          'dina': profile.dinaLord,
          'hora': profile.horaLord,
        };
        if (profile.varshaMasaDinaHoraProfile != null &&
            profile.varshaMasaDinaHoraProfile !=
                'siderealSolarIngressAstrologicalDayV1') {
          throw StateError('Shadbala temporal-lord profile is invalid');
        }
        for (final key in temporalAllocations.keys) {
          final value = temporalValues[key];
          final lord = temporalLords[key];
          if ((value == null) != (lord == null)) {
            throw StateError('Shadbala $key availability contract is invalid');
          }
          if (lord != null) {
            if (!requiredPlanets.contains(lord)) {
              throw StateError('Shadbala $key lord is invalid');
            }
            final expected = profile.planet == lord
                ? temporalAllocations[key]!
                : 0.0;
            if ((value! - expected).abs() > 1e-9) {
              throw StateError('Shadbala $key allocation is invalid');
            }
          }
        }
        if (profile.horaBalaVirupas == null) {
          if (profile.horaNumber != null) {
            throw StateError('Shadbala Hora number must be absent when Hora is unavailable');
          }
        } else if (profile.horaNumber == null ||
            profile.horaNumber! < 1 ||
            profile.horaNumber! > 24) {
          throw StateError('Shadbala Hora number must stay within 1..24');
        }
        final currentTemporalContextKey =
            '${profile.varshaMasaDinaHoraProfile}|${profile.varshaLord}|${profile.masaLord}|${profile.dinaLord}|${profile.horaLord}|${profile.horaNumber}';
        temporalContextKey ??= currentTemporalContextKey;
        if (temporalContextKey != currentTemporalContextKey) {
          throw StateError('Shadbala temporal-lord context must match across planets');
        }
        if ((profile.kalaBalaPartialVirupas -
                    ((profile.nathonnataBalaVirupas ?? 0.0) +
                        (profile.tribhagaBalaVirupas ?? 0.0) +
                        profile.pakshaBalaVirupas +
                        (profile.varshaBalaVirupas ?? 0.0) +
                        (profile.masaBalaVirupas ?? 0.0) +
                        (profile.dinaBalaVirupas ?? 0.0) +
                        (profile.horaBalaVirupas ?? 0.0) +
                        profile.ayanaBalaVirupas))
                .abs() >
            1e-9) {
          throw StateError('Pre-war Kala Bala components are inconsistent');
        }
        if (profile.yuddhaProfile != 'bphs27_20NorthernLatitudeYuddhaV1' ||
            !{
              'notEligible',
              'legacyOutputWithoutLatitude',
              'noWar',
              'ambiguousMultiplePartners',
              'latitudeTie',
              'preWarStrengthUnavailable',
              'winner',
              'loser',
            }.contains(profile.yuddhaRole)) {
          throw StateError('Shadbala Yuddha profile is invalid');
        }
        if (profile.yuddhaLatitudeDegrees != null &&
            (!profile.yuddhaLatitudeDegrees!.isFinite ||
                profile.yuddhaLatitudeDegrees! < -90 ||
                profile.yuddhaLatitudeDegrees! > 90)) {
          throw StateError('Shadbala Yuddha latitude is invalid');
        }
        if (profile.yuddhaPartnerLatitudeDegrees != null &&
            (!profile.yuddhaPartnerLatitudeDegrees!.isFinite ||
                profile.yuddhaPartnerLatitudeDegrees! < -90 ||
                profile.yuddhaPartnerLatitudeDegrees! > 90)) {
          throw StateError('Shadbala Yuddha partner latitude is invalid');
        }
        if (profile.yuddhaSeparationDegrees != null &&
            (!profile.yuddhaSeparationDegrees!.isFinite ||
                profile.yuddhaSeparationDegrees! < 0 ||
                profile.yuddhaSeparationDegrees! > 1.0)) {
          throw StateError('Shadbala Yuddha separation is invalid');
        }
        if (profile.yuddhaRole == 'notEligible') {
          if (!{'sun', 'moon'}.contains(profile.planet) ||
              profile.yuddhaBalaVirupas != 0.0 ||
              profile.yuddhaWarPartner != null) {
            throw StateError('Non-eligible Yuddha contract is invalid');
          }
        } else if (profile.yuddhaRole == 'noWar') {
          if (profile.yuddhaBalaVirupas != 0.0 ||
              profile.yuddhaWarPartner != null ||
              profile.yuddhaSeparationDegrees != null ||
              profile.yuddhaPreWarStrengthDifferenceVirupas != 0.0) {
            throw StateError('No-war Yuddha contract is invalid');
          }
        } else if (profile.yuddhaRole == 'winner' ||
            profile.yuddhaRole == 'loser') {
          final magnitude = profile.yuddhaPreWarStrengthDifferenceVirupas;
          if (profile.yuddhaBalaVirupas == null ||
              profile.yuddhaWarPartner == null ||
              !{'mars', 'mercury', 'jupiter', 'venus', 'saturn'}
                  .contains(profile.yuddhaWarPartner) ||
              profile.yuddhaSeparationDegrees == null ||
              profile.yuddhaLatitudeDegrees == null ||
              profile.yuddhaPartnerLatitudeDegrees == null ||
              magnitude == null ||
              !magnitude.isFinite ||
              magnitude < 0 ||
              (profile.yuddhaBalaVirupas!.abs() - magnitude).abs() > 1e-9 ||
              (profile.yuddhaRole == 'winner' &&
                  (profile.yuddhaBalaVirupas! < 0 ||
                      profile.yuddhaLatitudeDegrees! <=
                          profile.yuddhaPartnerLatitudeDegrees!)) ||
              (profile.yuddhaRole == 'loser' &&
                  (profile.yuddhaBalaVirupas! > 0 ||
                      profile.yuddhaLatitudeDegrees! >=
                          profile.yuddhaPartnerLatitudeDegrees!))) {
            throw StateError('Winner/loser Yuddha contract is invalid');
          }
          final partnerProfile = analysis.shadbalaProfiles.firstWhere(
            (value) => value.planet == profile.yuddhaWarPartner,
          );
          final expectedPartnerRole =
              profile.yuddhaRole == 'winner' ? 'loser' : 'winner';
          if (partnerProfile.yuddhaRole != expectedPartnerRole ||
              partnerProfile.yuddhaWarPartner != profile.planet ||
              partnerProfile.yuddhaBalaVirupas == null ||
              (partnerProfile.yuddhaBalaVirupas! + profile.yuddhaBalaVirupas!)
                      .abs() >
                  1e-9 ||
              partnerProfile.yuddhaSeparationDegrees == null ||
              (partnerProfile.yuddhaSeparationDegrees! -
                          profile.yuddhaSeparationDegrees!)
                      .abs() >
                  1e-9 ||
              partnerProfile.yuddhaPreWarStrengthDifferenceVirupas == null ||
              (partnerProfile.yuddhaPreWarStrengthDifferenceVirupas! -
                          magnitude)
                      .abs() >
                  1e-9) {
            throw StateError('Yuddha pair reciprocity contract is invalid');
          }
        } else {
          if (profile.yuddhaBalaVirupas != null ||
              profile.yuddhaPreWarStrengthDifferenceVirupas != null) {
            throw StateError('Unavailable Yuddha correction must remain null');
          }
        }
        final temporalKalaReady = profile.nathonnataBalaVirupas != null &&
            hasTribhaga &&
            profile.varshaBalaVirupas != null &&
            profile.masaBalaVirupas != null &&
            profile.dinaBalaVirupas != null &&
            profile.horaBalaVirupas != null;
        final expectedKalaComplete =
            temporalKalaReady && profile.yuddhaBalaVirupas != null;
        if (profile.kalaBalaComplete != expectedKalaComplete ||
            (profile.kalaBalaVirupas != null) != expectedKalaComplete ||
            (profile.kalaBalaVirupas != null &&
                !profile.kalaBalaVirupas!.isFinite) ||
            (expectedKalaComplete &&
                (profile.kalaBalaVirupas! -
                            (profile.kalaBalaPartialVirupas +
                                profile.yuddhaBalaVirupas!))
                        .abs() >
                    1e-9)) {
          throw StateError('Complete Kala Bala contract is invalid');
        }
        if (profile.cheshtaBalaVirupas != null &&
            (profile.cheshtaBalaVirupas! < 0 ||
                profile.cheshtaBalaVirupas! > 60)) {
          throw StateError('Shadbala Cheshta Bala must stay within 0..60 virupas');
        }
        if (profile.planet == 'sun') {
          if (profile.cheshtaMethod != 'sunAyanaBala' ||
              profile.cheshtaMotionState != 'derivedFromAyana' ||
              profile.cheshtaBalaVirupas == null ||
              (profile.cheshtaBalaVirupas! - profile.ayanaBalaVirupas).abs() >
                  1e-9) {
            throw StateError('Sun Cheshta must equal Ayana Bala under BPHS 27.18');
          }
        } else if (profile.planet == 'moon') {
          if (profile.cheshtaMethod != 'moonPakshaBala' ||
              profile.cheshtaMotionState != 'derivedFromPaksha' ||
              profile.cheshtaBalaVirupas == null ||
              (profile.cheshtaBalaVirupas! - profile.pakshaBalaVirupas).abs() >
                  1e-9) {
            throw StateError('Moon Cheshta must equal Paksha Bala under BPHS 27.18');
          }
        } else if (profile.cheshtaBalaVirupas == null) {
          if (profile.cheshtaMethod != 'legacyOutputWithoutSpeed' ||
              profile.cheshtaMotionState != null ||
              profile.longitudeSpeedPerDay != null) {
            throw StateError('Legacy Cheshta gating contract is invalid');
          }
        } else {
          const allowedStates = {
            'vakra': 60.0,
            'anuvakra': 30.0,
            'vikala': 15.0,
            'mandatara': 15.0,
            'manda': 30.0,
            'sama': 7.5,
            'chara': 45.0,
            'atichara': 30.0,
          };
          if (profile.cheshtaMethod != 'bphsMotionStateSpeedProfileV1' ||
              profile.longitudeSpeedPerDay == null ||
              !profile.longitudeSpeedPerDay!.isFinite ||
              !allowedStates.containsKey(profile.cheshtaMotionState) ||
              (profile.cheshtaBalaVirupas! -
                          allowedStates[profile.cheshtaMotionState]!)
                      .abs() >
                  1e-9) {
            throw StateError('Mars-through-Saturn Cheshta motion-state contract is invalid');
          }
        }
        if (!profile.drikBalaVirupas.isFinite ||
            profile.drikProfile != 'bphsSphutaDrishtiDrikV1' ||
            profile.drikContributions.length > 6) {
          throw StateError('Shadbala Drik Bala profile is invalid');
        }
        var drikSum = 0.0;
        final drikAspectors = <String>{};
        for (final contribution in profile.drikContributions) {
          if (!requiredPlanets.contains(contribution.aspector) ||
              contribution.aspector == profile.planet ||
              !drikAspectors.add(contribution.aspector) ||
              !contribution.aspectAngleDegrees.isFinite ||
              contribution.aspectAngleDegrees < 0 ||
              contribution.aspectAngleDegrees >= 360 ||
              !contribution.aspectVirupas.isFinite ||
              contribution.aspectVirupas <= 0 ||
              contribution.aspectVirupas > 60 ||
              !{'benefic', 'malefic'}.contains(contribution.nature) ||
              !contribution.baseQuarterContributionVirupas.isFinite ||
              !contribution.superAddedVirupas.isFinite ||
              !contribution.netContributionVirupas.isFinite) {
            throw StateError('Shadbala Drik contribution is invalid');
          }
          final expectedBase = contribution.aspectVirupas *
              (contribution.nature == 'benefic' ? 0.25 : -0.25);
          final expectedSuper =
              (contribution.aspector == 'mercury' ||
                      contribution.aspector == 'jupiter')
                  ? contribution.aspectVirupas
                  : 0.0;
          if ((contribution.baseQuarterContributionVirupas - expectedBase).abs() >
                  1e-9 ||
              (contribution.superAddedVirupas - expectedSuper).abs() > 1e-9 ||
              (contribution.netContributionVirupas -
                          (expectedBase + expectedSuper))
                      .abs() >
                  1e-9) {
            throw StateError('Shadbala Drik weighting contract is invalid');
          }
          drikSum += contribution.netContributionVirupas;
        }
        if ((profile.drikBalaVirupas - drikSum).abs() > 1e-9) {
          throw StateError('Shadbala Drik contribution sum is inconsistent');
        }
        final hasNathonnata = profile.nathonnataBalaVirupas != null;
        final expectedKalaComputed = <String>[
          if (hasNathonnata) 'nathonnata',
          'paksha',
          if (hasTribhaga) 'tribhaga',
          if (profile.varshaBalaVirupas != null) 'varsha',
          if (profile.masaBalaVirupas != null) 'masa',
          if (profile.dinaBalaVirupas != null) 'dina',
          if (profile.horaBalaVirupas != null) 'hora',
          if (profile.yuddhaBalaVirupas != null) 'yuddha',
          'ayana',
        ].join(',');
        final expectedKalaMissing = <String>[
          if (!hasNathonnata) 'nathonnata',
          if (!hasTribhaga) 'tribhaga',
          if (profile.varshaBalaVirupas == null) 'varsha',
          if (profile.masaBalaVirupas == null) 'masa',
          if (profile.dinaBalaVirupas == null) 'dina',
          if (profile.horaBalaVirupas == null) 'hora',
          if (profile.yuddhaBalaVirupas == null) 'yuddha',
        ].join(',');
        if (profile.kalaComputedSubcomponents.join(',') != expectedKalaComputed ||
            profile.kalaMissingSubcomponents.join(',') != expectedKalaMissing) {
          throw StateError('Shadbala v10 Kala foundation contract is invalid');
        }
        final hasCheshta = profile.cheshtaBalaVirupas != null;
        final expectedAggregateAvailable =
            profile.kalaBalaComplete && hasCheshta;
        const requiredTotals = <String, double>{
          'sun': 390.0,
          'moon': 360.0,
          'mars': 300.0,
          'mercury': 420.0,
          'jupiter': 390.0,
          'venus': 330.0,
          'saturn': 300.0,
        };
        final expectedRequired = requiredTotals[profile.planet]!;
        final expectedTotal = expectedAggregateAvailable
            ? profile.sthanaBalaVirupas +
                profile.digBalaVirupas +
                profile.kalaBalaVirupas! +
                profile.cheshtaBalaVirupas! +
                profile.naisargikaBalaVirupas +
                profile.drikBalaVirupas
            : null;
        final expectedRatio =
            expectedTotal == null ? null : expectedTotal / expectedRequired;
        final expectedDelta =
            expectedTotal == null ? null : expectedTotal - expectedRequired;
        final expectedStatus = expectedTotal == null
            ? 'unavailable'
            : expectedTotal + 1e-9 >= expectedRequired
                ? 'meetsRequired'
                : 'belowRequired';
        final expectedComputed = <String>[
          'sthana',
          'dig',
          profile.kalaBalaComplete ? 'kala' : 'kalaPartial',
          if (hasCheshta) 'cheshta',
          'naisargika',
          'drik',
          if (expectedAggregateAvailable) 'aggregateThresholdEvaluation',
        ].join(',');
        final expectedMissing = <String>[
          if (!profile.kalaBalaComplete) 'kalaRemaining',
          if (!hasCheshta) 'cheshta',
          if (!expectedAggregateAvailable) 'aggregateThresholdEvaluation',
        ].join(',');
        if (profile.thresholdProfile != 'bphs27_32_33RequiredTotalV1' ||
            (profile.requiredShadbalaVirupas - expectedRequired).abs() > 1e-9 ||
            (profile.requiredShadbalaRupas - expectedRequired / 60.0).abs() >
                1e-9 ||
            profile.aggregateAvailable != expectedAggregateAvailable ||
            (profile.totalShadbalaVirupas != null) !=
                expectedAggregateAvailable ||
            (profile.totalShadbalaRupas != null) !=
                expectedAggregateAvailable ||
            (profile.requiredStrengthRatio != null) !=
                expectedAggregateAvailable ||
            (profile.surplusDeficitVirupas != null) !=
                expectedAggregateAvailable ||
            profile.thresholdStatus != expectedStatus ||
            (expectedTotal != null &&
                ((profile.totalShadbalaVirupas! - expectedTotal).abs() > 1e-9 ||
                    (profile.totalShadbalaRupas! - expectedTotal / 60.0).abs() >
                        1e-9 ||
                    (profile.requiredStrengthRatio! - expectedRatio!).abs() >
                        1e-9 ||
                    (profile.surplusDeficitVirupas! - expectedDelta!).abs() >
                        1e-9)) ||
            profile.computedComponents.join(',') != expectedComputed ||
            profile.missingComponents.join(',') != expectedMissing) {
          throw StateError(
            'Shadbala v10 sixfold aggregate/required-strength contract is invalid',
          );
        }
        _requireBilingual(profile.narrativeEn, profile.narrativeBn);
        _validateEvidence(profile.evidence, AnalysisConfidence.medium);
      }
    }


    final ashtakavarga = analysis.ashtakavargaProfile;
    if (ashtakavarga != null) {
      const fixedTotals = <String, int>{
        'sun': 48,
        'moon': 49,
        'mars': 39,
        'mercury': 54,
        'jupiter': 56,
        'venus': 52,
        'saturn': 39,
      };
      if (ashtakavarga.ruleVersion != 'ashtakavarga-foundation-v3' ||
          ashtakavarga.rulesetProfile !=
              'receivedStandardParashariPositivePlacesV1' ||
          !ashtakavarga.notationConvention.contains('positiveMark1') ||
          ashtakavarga.bhinnashtakavarga.length != 7 ||
          ashtakavarga.sarvashtakavarga.length != 12) {
        throw StateError('Unsupported Ashtakavarga foundation v3 contract');
      }
      final planets = <String>{};
      for (final bav in ashtakavarga.bhinnashtakavarga) {
        if (!fixedTotals.containsKey(bav.planet) || !planets.add(bav.planet) ||
            bav.fixedTotalPositiveMarks != fixedTotals[bav.planet] ||
            bav.signs.length != 12 ||
            bav.totalPositiveMarks != fixedTotals[bav.planet]) {
          throw StateError('Ashtakavarga BAV checksum/profile is invalid');
        }
        final signIndexes = <int>{};
        for (final sign in bav.signs) {
          if (sign.signIndex < 0 ||
              sign.signIndex > 11 ||
              !signIndexes.add(sign.signIndex) ||
              sign.positiveMarks < 0 ||
              sign.positiveMarks > 8 ||
              sign.contributors.length != sign.positiveMarks) {
            throw StateError('Ashtakavarga BAV sign record is invalid');
          }
          final contributorRefs = <String>{};
          for (final contribution in sign.contributors) {
            if (!contributorRefs.add(contribution.reference) ||
                contribution.referenceSignIndex < 0 ||
                contribution.referenceSignIndex > 11 ||
                contribution.relativeHouse < 1 ||
                contribution.relativeHouse > 12) {
              throw StateError('Ashtakavarga contributor record is invalid');
            }
          }
        }
        if (signIndexes.length != 12) {
          throw StateError('Ashtakavarga BAV must cover all twelve signs');
        }
      }
      if (planets.length != 7) {
        throw StateError('Ashtakavarga must cover seven classical planets');
      }
      final houses = <int>{};
      final signs = <int>{};
      var savTotal = 0;
      for (final sav in ashtakavarga.sarvashtakavarga) {
        if (sav.signIndex < 0 ||
            sav.signIndex > 11 ||
            !signs.add(sav.signIndex) ||
            sav.houseNumber < 1 ||
            sav.houseNumber > 12 ||
            !houses.add(sav.houseNumber) ||
            sav.positiveMarks < 0 ||
            sav.positiveMarks > 56 ||
            sav.confidence == AnalysisConfidence.high) {
          throw StateError('Ashtakavarga SAV sign/house record is invalid');
        }
        final expectedByBav = ashtakavarga.bhinnashtakavarga.fold<int>(
          0,
          (sum, bav) => sum + bav.signs
              .firstWhere((value) => value.signIndex == sav.signIndex)
              .positiveMarks,
        );
        if (sav.positiveMarks != expectedByBav) {
          throw StateError('Ashtakavarga SAV does not match seven BAV tables');
        }
        final expectedBand = sav.positiveMarks > 30
            ? 'favourable'
            : sav.positiveMarks >= 25
                ? 'medium'
                : 'adverse';
        final expectedPolarity = sav.positiveMarks > 30
            ? AnalysisPolarity.supportive
            : sav.positiveMarks >= 25
                ? AnalysisPolarity.mixed
                : AnalysisPolarity.challenging;
        if (sav.band != expectedBand || sav.polarity != expectedPolarity) {
          throw StateError('Ashtakavarga SAV band/polarity is inconsistent');
        }
        _requireBilingual(sav.narrativeEn, sav.narrativeBn);
        _validateEvidence(sav.evidence, sav.confidence);
        savTotal += sav.positiveMarks;
      }
      if (savTotal != 337 ||
          ashtakavarga.totalPositiveMarks != 337 ||
          (ashtakavarga.averagePositiveMarks - (337 / 12.0)).abs() > 1e-9 ||
          houses.length != 12 ||
          signs.length != 12) {
        throw StateError('Ashtakavarga SAV grand-total contract is invalid');
      }
      final reductions = ashtakavarga.reductionProfile;
      if (reductions == null ||
          reductions.ruleVersion != 'ashtakavarga-reductions-v1' ||
          reductions.rulesetProfile !=
              'bphs67Trikona_bphs68Ekadhipatya_classicalOccupancyV1' ||
          !reductions.occupancyConvention.contains('Sun through Saturn') ||
          reductions.planets.length != 7 ||
          reductions.reducedAggregateMarks.length != 12) {
        throw StateError('Ashtakavarga reduction contract is invalid');
      }
      const trikonaGroups = <List<int>>[
        [0, 4, 8], [1, 5, 9], [2, 6, 10], [3, 7, 11],
      ];
      const dualPairs = <String, List<int>>{
        'mars': [0, 7],
        'mercury': [2, 5],
        'jupiter': [8, 11],
        'venus': [1, 6],
        'saturn': [9, 10],
      };
      final reducedPlanetNames = <String>{};
      for (final reduced in reductions.planets) {
        if (!fixedTotals.containsKey(reduced.planet) ||
            !reducedPlanetNames.add(reduced.planet) ||
            reduced.rawMarks.length != 12 ||
            reduced.trikonaReducedMarks.length != 12 ||
            reduced.ekadhipatyaReducedMarks.length != 12 ||
            reduced.trikonaAudits.length != 4 ||
            reduced.ekadhipatyaAudits.length != 5 ||
            reduced.rawMarks.any((value) => value < 0 || value > 8) ||
            reduced.trikonaReducedMarks.any((value) => value < 0 || value > 8) ||
            reduced.ekadhipatyaReducedMarks.any((value) => value < 0 || value > 8) ||
            reduced.trikonaReducedTotal > reduced.rawTotal ||
            reduced.ekadhipatyaReducedTotal > reduced.trikonaReducedTotal) {
          throw StateError('Ashtakavarga reduced planet record is invalid');
        }
        final rawBav = ashtakavarga.bhinnashtakavarga
            .firstWhere((value) => value.planet == reduced.planet);
        final expectedRaw = List<int>.generate(
          12,
          (index) => rawBav.signs
              .firstWhere((value) => value.signIndex == index)
              .positiveMarks,
        );
        if (reduced.rawMarks.join(',') != expectedRaw.join(',')) {
          throw StateError('Ashtakavarga reduction raw stage does not match BAV');
        }
        for (var index = 0; index < 4; index += 1) {
          final audit = reduced.trikonaAudits[index];
          final group = trikonaGroups[index];
          if (audit.signIndexes.join(',') != group.join(',') ||
              audit.inputMarks.length != 3 ||
              audit.outputMarks.length != 3 ||
              audit.inputMarks.join(',') !=
                  group.map((value) => reduced.rawMarks[value]).join(',') ||
              audit.outputMarks.join(',') !=
                  group.map((value) => reduced.trikonaReducedMarks[value]).join(',')) {
            throw StateError('Ashtakavarga Trikona audit is inconsistent');
          }
          final values = audit.inputMarks;
          final expected = List<int>.from(values);
          String expectedAction;
          if (values.any((value) => value == 0)) {
            expectedAction = 'zero_present_no_reduction';
          } else if (values.toSet().length == 1) {
            for (var i = 0; i < 3; i += 1) {
              expected[i] = 0;
            }
            expectedAction = 'all_equal_reduce_all_to_zero';
          } else {
            final minimum = values.reduce((a, b) => a < b ? a : b);
            for (var i = 0; i < 3; i += 1) {
              expected[i] = values[i] - minimum;
            }
            expectedAction = 'subtract_group_minimum';
          }
          if (audit.action != expectedAction ||
              audit.outputMarks.join(',') != expected.join(',')) {
            throw StateError('Ashtakavarga Trikona rule application is invalid');
          }
        }
        final seenLords = <String>{};
        for (final audit in reduced.ekadhipatyaAudits) {
          final pair = dualPairs[audit.lord];
          if (pair == null ||
              !seenLords.add(audit.lord) ||
              audit.signIndexes.join(',') != pair.join(',') ||
              audit.inputMarks.length != 2 ||
              audit.outputMarks.length != 2 ||
              audit.occupied.length != 2 ||
              audit.inputMarks.join(',') !=
                  pair.map((value) => reduced.trikonaReducedMarks[value]).join(',') ||
              audit.outputMarks.join(',') !=
                  pair.map((value) => reduced.ekadhipatyaReducedMarks[value]).join(',')) {
            throw StateError('Ashtakavarga Ekadhipatya audit is inconsistent');
          }
          final a = audit.inputMarks[0];
          final b = audit.inputMarks[1];
          var expectedA = a;
          var expectedB = b;
          late final String expectedAction;
          if (a == 0 || b == 0) {
            expectedAction = 'zero_present_no_reduction';
          } else if (audit.occupied[0] && audit.occupied[1]) {
            expectedAction = 'both_occupied_no_reduction';
          } else if (!audit.occupied[0] && !audit.occupied[1]) {
            if (a == b) {
              expectedA = 0;
              expectedB = 0;
              expectedAction = 'both_empty_equal_reduce_both_to_zero';
            } else {
              final minimum = a < b ? a : b;
              expectedA = minimum;
              expectedB = minimum;
              expectedAction = 'both_empty_unequal_set_both_to_smaller';
            }
          } else if (audit.occupied[0]) {
            expectedB = a < b ? b - a : 0;
            expectedAction = a < b
                ? 'occupied_smaller_subtract_from_empty'
                : 'occupied_greater_or_equal_reduce_empty_to_zero';
          } else {
            expectedA = b < a ? a - b : 0;
            expectedAction = b < a
                ? 'occupied_smaller_subtract_from_empty'
                : 'occupied_greater_or_equal_reduce_empty_to_zero';
          }
          if (audit.action != expectedAction ||
              audit.outputMarks[0] != expectedA ||
              audit.outputMarks[1] != expectedB) {
            throw StateError('Ashtakavarga Ekadhipatya rule application is invalid');
          }
        }
        if (seenLords.length != 5) {
          throw StateError('Ashtakavarga Ekadhipatya must cover five dual lords');
        }
      }
      if (reducedPlanetNames.length != 7) {
        throw StateError('Ashtakavarga reductions must cover seven planets');
      }
      final expectedReducedAggregate = List<int>.generate(
        12,
        (index) => reductions.planets.fold<int>(
          0,
          (sum, planet) => sum + planet.ekadhipatyaReducedMarks[index],
        ),
      );
      if (reductions.reducedAggregateMarks.join(',') !=
              expectedReducedAggregate.join(',') ||
          reductions.reducedAggregateTotal > 337) {
        throw StateError('Ashtakavarga reduced aggregate is inconsistent');
      }
      _validateEvidence(reductions.evidence, AnalysisConfidence.medium);

      final pinda = ashtakavarga.pindaProfile;
      const expectedRashiMultipliers = <int>[7, 10, 8, 4, 10, 5, 7, 8, 9, 5, 11, 12];
      const expectedGrahaMultipliers = <String, int>{
        'sun': 5,
        'moon': 5,
        'mars': 8,
        'mercury': 5,
        'jupiter': 10,
        'venus': 7,
        'saturn': 5,
      };
      if (pinda == null ||
          pinda.ruleVersion != 'ashtakavarga-pinda-v1' ||
          pinda.rulesetProfile !=
              'phaladeepika24_postShodhana_rashiGrahaMultipliersV1' ||
          pinda.rashiMultipliers.join(',') !=
              expectedRashiMultipliers.join(',') ||
          pinda.grahaMultipliers.length != 7 ||
          expectedGrahaMultipliers.entries.any(
            (entry) => pinda.grahaMultipliers[entry.key] != entry.value,
          ) ||
          pinda.planets.length != 7) {
        throw StateError('Ashtakavarga Pinda contract is invalid');
      }
      final pindaPlanets = <String>{};
      final occupiedSignsByReference = <String, int>{};
      for (final planetPinda in pinda.planets) {
        if (!fixedTotals.containsKey(planetPinda.planet) ||
            !pindaPlanets.add(planetPinda.planet) ||
            planetPinda.rashiContributions.length != 12 ||
            planetPinda.grahaContributions.length != 7) {
          throw StateError('Ashtakavarga planet Pinda record is invalid');
        }
        final reduced = reductions.planets
            .firstWhere((value) => value.planet == planetPinda.planet);
        var expectedRashiPinda = 0;
        final rashiSigns = <int>{};
        for (final contribution in planetPinda.rashiContributions) {
          if (contribution.signIndex < 0 ||
              contribution.signIndex > 11 ||
              !rashiSigns.add(contribution.signIndex) ||
              contribution.reducedMarks !=
                  reduced.ekadhipatyaReducedMarks[contribution.signIndex] ||
              contribution.multiplier !=
                  expectedRashiMultipliers[contribution.signIndex] ||
              contribution.product !=
                  contribution.reducedMarks * contribution.multiplier) {
            throw StateError('Ashtakavarga Rashi Pinda contribution is invalid');
          }
          expectedRashiPinda += contribution.product;
        }
        var expectedGrahaPinda = 0;
        final grahaRefs = <String>{};
        for (final contribution in planetPinda.grahaContributions) {
          final multiplier = expectedGrahaMultipliers[contribution.referencePlanet];
          if (multiplier == null ||
              !grahaRefs.add(contribution.referencePlanet) ||
              contribution.occupiedSignIndex < 0 ||
              contribution.occupiedSignIndex > 11 ||
              contribution.multiplier != multiplier ||
              contribution.reducedMarks !=
                  reduced.ekadhipatyaReducedMarks[contribution.occupiedSignIndex] ||
              contribution.product !=
                  contribution.reducedMarks * contribution.multiplier) {
            throw StateError('Ashtakavarga Graha Pinda contribution is invalid');
          }
          final knownSign =
              occupiedSignsByReference[contribution.referencePlanet];
          if (knownSign != null && knownSign != contribution.occupiedSignIndex) {
            throw StateError('Ashtakavarga Graha Pinda occupancy is inconsistent');
          }
          occupiedSignsByReference[contribution.referencePlanet] =
              contribution.occupiedSignIndex;
          expectedGrahaPinda += contribution.product;
        }
        if (rashiSigns.length != 12 ||
            grahaRefs.length != 7 ||
            planetPinda.rashiPinda != expectedRashiPinda ||
            planetPinda.grahaPinda != expectedGrahaPinda ||
            planetPinda.shodhyaPinda !=
                expectedRashiPinda + expectedGrahaPinda) {
          throw StateError('Ashtakavarga Pinda total identity is invalid');
        }
      }
      if (pindaPlanets.length != 7 || occupiedSignsByReference.length != 7) {
        throw StateError('Ashtakavarga Pinda must cover seven planets');
      }
      _validateEvidence(pinda.evidence, AnalysisConfidence.medium);
      _validateEvidence(ashtakavarga.evidence, AnalysisConfidence.medium);
    }

    if (analysis.gemstoneCandidateReviews.isNotEmpty) {
      final planets = <String>{};
      for (final review in analysis.gemstoneCandidateReviews) {
        if (!planets.add(review.planet) ||
            review.code.trim().isEmpty ||
            review.ruleVersion != 'vedic-gemstone-candidate-v1' ||
            review.mappingProfile != 'astro-logic-navaratna-mapping-v1' ||
            review.primaryGemstone.trim().isEmpty ||
            review.primaryGemstoneBn.trim().isEmpty ||
            review.rationaleEn.trim().isEmpty ||
            review.rationaleBn.trim().isEmpty ||
            review.cautionEn.trim().isEmpty ||
            review.cautionBn.trim().isEmpty ||
            review.functionalOwnedHouses.isEmpty ||
            review.functionalOwnedHouses.any((house) => house < 1 || house > 12) ||
            !const {'meetsRequired', 'belowRequired', 'unavailable'}
                .contains(review.shadbalaThresholdStatus)) {
          throw StateError('Gemstone candidate review contract is invalid');
        }
        if (review.shadbalaAvailable &&
            (review.requiredStrengthRatio == null ||
                !review.requiredStrengthRatio!.isFinite ||
                review.requiredStrengthRatio! < 0)) {
          throw StateError('Gemstone review Shadbala ratio is invalid');
        }
        if (!review.shadbalaAvailable && review.requiredStrengthRatio != null) {
          throw StateError('Unavailable Gemstone review cannot publish Shadbala ratio');
        }
        if (review.status == GemstoneCandidateStatus.eligible &&
            (review.functionalScore < 2 ||
                !review.shadbalaAvailable ||
                review.shadbalaThresholdStatus != 'belowRequired' ||
                review.activeDashaRole == 'inactive' ||
                review.activeDashaRole == 'unavailable' ||
                review.nodeContacts.isNotEmpty ||
                const {'ambiguousMultiplePartners', 'latitudeTie', 'preWarStrengthUnavailable'}
                    .contains(review.planetaryWarRole))) {
          throw StateError('Eligible gemstone review violates conservative gate');
        }
        if (review.status == GemstoneCandidateStatus.contraindicated &&
            review.functionalScore > -2) {
          throw StateError('Gemstone contraindication requires challenging functional role');
        }
        _validateEvidence(review.evidence, AnalysisConfidence.medium);
      }
      if (planets.length != 7 ||
          !planets.containsAll(const {
            'sun', 'moon', 'mars', 'mercury', 'jupiter', 'venus', 'saturn'
          })) {
        throw StateError('Gemstone candidate review must cover seven classical planets');
      }
    }

    for (final remedy in analysis.remedyCandidates) {
      _requireBilingual(
        remedy.actionEn,
        remedy.actionBn,
        remedy.rationaleEn,
        remedy.rationaleBn,
        remedy.cautionEn,
        remedy.cautionBn,
      );
      _validateEvidence(remedy.evidence, AnalysisConfidence.medium);
    }
    if (analysis.warningsEn.isEmpty ||
        analysis.warningsBn.isEmpty ||
        analysis.warningsEn.any((value) => value.trim().isEmpty) ||
        analysis.warningsBn.any((value) => value.trim().isEmpty)) {
      throw StateError('Bilingual analysis warnings are mandatory');
    }
  }

  static void _validateEvidence(
    List<ChartEvidence> evidence,
    AnalysisConfidence confidence,
  ) {
    if (evidence.isEmpty ||
        evidence.any((value) =>
            value.ruleId.trim().isEmpty ||
            value.outputPath.trim().isEmpty ||
            value.descriptionEn.trim().isEmpty ||
            value.descriptionBn.trim().isEmpty)) {
      throw StateError('Every conclusion requires bilingual chart evidence');
    }
    final independentRules = evidence.map((value) => value.ruleId).toSet();
    if (confidence == AnalysisConfidence.high && independentRules.length < 2) {
      throw StateError('High confidence requires two independent rules');
    }
  }

  static void _requireBilingual(String en, String bn, [
    String? en2,
    String? bn2,
    String? en3,
    String? bn3,
  ]) {
    final values = [en, bn, en2, bn2, en3, bn3].whereType<String>();
    if (values.any((value) => value.trim().isEmpty)) {
      throw StateError('Bengali and English analysis text is mandatory');
    }
  }
}
