enum AnalysisPolarity { supportive, challenging, mixed }

enum AnalysisConfidence { low, medium, high }

enum LifeArea {
  overall,
  self,
  family,
  communication,
  siblings,
  career,
  finance,
  marriage,
  health,
  obstacles,
  longevity,
  fortune,
  gains,
  expenses,
  education,
  property,
  children,
  spirituality,
}

enum EvidenceKind {
  placement,
  lordship,
  aspect,
  yoga,
  dosha,
  strength,
  divisional,
  dasha,
  transit,
  ashtakavarga,
}

enum AnalysisRemedyKind { gemstone, mantra, charity, ritual, behavioral }

class ChartEvidence {
  const ChartEvidence({
    required this.ruleId,
    required this.outputPath,
    required this.kind,
    required this.descriptionEn,
    required this.descriptionBn,
  });

  final String ruleId;
  final String outputPath;
  final EvidenceKind kind;
  final String descriptionEn;
  final String descriptionBn;

  Map<String, Object?> toJson() => {
        'ruleId': ruleId,
        'outputPath': outputPath,
        'kind': kind.name,
        'descriptionEn': descriptionEn,
        'descriptionBn': descriptionBn,
      };
}

class ChartFinding {
  const ChartFinding({
    required this.code,
    required this.area,
    required this.polarity,
    required this.confidence,
    required this.titleEn,
    required this.titleBn,
    required this.narrativeEn,
    required this.narrativeBn,
    required this.evidence,
  });

  final String code;
  final LifeArea area;
  final AnalysisPolarity polarity;
  final AnalysisConfidence confidence;
  final String titleEn;
  final String titleBn;
  final String narrativeEn;
  final String narrativeBn;
  final List<ChartEvidence> evidence;

  Map<String, Object?> toJson() => {
        'code': code,
        'area': area.name,
        'polarity': polarity.name,
        'confidence': confidence.name,
        'titleEn': titleEn,
        'titleBn': titleBn,
        'narrativeEn': narrativeEn,
        'narrativeBn': narrativeBn,
        'evidence': evidence.map((value) => value.toJson()).toList(),
      };
}

class AnalysisTimingWindow {
  const AnalysisTimingWindow({
    required this.code,
    required this.area,
    required this.start,
    required this.end,
    required this.polarity,
    required this.confidence,
    required this.narrativeEn,
    required this.narrativeBn,
    required this.evidence,
  });

  final String code;
  final LifeArea area;
  final DateTime start;
  final DateTime end;
  final AnalysisPolarity polarity;
  final AnalysisConfidence confidence;
  final String narrativeEn;
  final String narrativeBn;
  final List<ChartEvidence> evidence;

  Map<String, Object?> toJson() => {
        'code': code,
        'area': area.name,
        'start': start.toUtc().toIso8601String(),
        'end': end.toUtc().toIso8601String(),
        'polarity': polarity.name,
        'confidence': confidence.name,
        'narrativeEn': narrativeEn,
        'narrativeBn': narrativeBn,
        'evidence': evidence.map((value) => value.toJson()).toList(),
      };
}


class NavamsaHouseInterpretation {
  const NavamsaHouseInterpretation({
    required this.code,
    required this.ruleVersion,
    required this.houseNumber,
    required this.signIndex,
    required this.houseLord,
    required this.lordHouse,
    required this.lordDignity,
    required this.occupants,
    required this.aspectors,
    required this.lordPlacementScore,
    required this.lordDignityScore,
    required this.occupantScore,
    required this.aspectScore,
    required this.netScore,
    required this.polarity,
    required this.confidence,
    required this.contradictorySignals,
    required this.titleEn,
    required this.titleBn,
    required this.narrativeEn,
    required this.narrativeBn,
    required this.evidence,
  });

  final String code;
  final String ruleVersion;
  final int houseNumber;
  final int signIndex;
  final String houseLord;
  final int lordHouse;
  final String lordDignity;
  final List<String> occupants;
  final List<String> aspectors;
  final int lordPlacementScore;
  final int lordDignityScore;
  final int occupantScore;
  final int aspectScore;
  final int netScore;
  final AnalysisPolarity polarity;
  final AnalysisConfidence confidence;
  final bool contradictorySignals;
  final String titleEn;
  final String titleBn;
  final String narrativeEn;
  final String narrativeBn;
  final List<ChartEvidence> evidence;

  Map<String, Object?> toJson() => {
        'code': code,
        'ruleVersion': ruleVersion,
        'houseNumber': houseNumber,
        'signIndex': signIndex,
        'houseLord': houseLord,
        'lordHouse': lordHouse,
        'lordDignity': lordDignity,
        'occupants': occupants,
        'aspectors': aspectors,
        'lordPlacementScore': lordPlacementScore,
        'lordDignityScore': lordDignityScore,
        'occupantScore': occupantScore,
        'aspectScore': aspectScore,
        'netScore': netScore,
        'polarity': polarity.name,
        'confidence': confidence.name,
        'contradictorySignals': contradictorySignals,
        'titleEn': titleEn,
        'titleBn': titleBn,
        'narrativeEn': narrativeEn,
        'narrativeBn': narrativeBn,
        'evidence': evidence.map((value) => value.toJson()).toList(),
      };
}


class DashamsaHouseInterpretation {
  const DashamsaHouseInterpretation({
    required this.code,
    required this.ruleVersion,
    required this.houseNumber,
    required this.signIndex,
    required this.houseLord,
    required this.lordHouse,
    required this.lordDignity,
    required this.occupants,
    required this.aspectors,
    required this.lordPlacementScore,
    required this.lordDignityScore,
    required this.occupantScore,
    required this.aspectScore,
    required this.netScore,
    required this.polarity,
    required this.confidence,
    required this.contradictorySignals,
    required this.careerRelevance,
    required this.titleEn,
    required this.titleBn,
    required this.narrativeEn,
    required this.narrativeBn,
    required this.evidence,
  });

  final String code;
  final String ruleVersion;
  final int houseNumber;
  final int signIndex;
  final String houseLord;
  final int lordHouse;
  final String lordDignity;
  final List<String> occupants;
  final List<String> aspectors;
  final int lordPlacementScore;
  final int lordDignityScore;
  final int occupantScore;
  final int aspectScore;
  final int netScore;
  final AnalysisPolarity polarity;
  final AnalysisConfidence confidence;
  final bool contradictorySignals;
  final bool careerRelevance;
  final String titleEn;
  final String titleBn;
  final String narrativeEn;
  final String narrativeBn;
  final List<ChartEvidence> evidence;

  Map<String, Object?> toJson() => {
        'code': code,
        'ruleVersion': ruleVersion,
        'houseNumber': houseNumber,
        'signIndex': signIndex,
        'houseLord': houseLord,
        'lordHouse': lordHouse,
        'lordDignity': lordDignity,
        'occupants': occupants,
        'aspectors': aspectors,
        'lordPlacementScore': lordPlacementScore,
        'lordDignityScore': lordDignityScore,
        'occupantScore': occupantScore,
        'aspectScore': aspectScore,
        'netScore': netScore,
        'polarity': polarity.name,
        'confidence': confidence.name,
        'contradictorySignals': contradictorySignals,
        'careerRelevance': careerRelevance,
        'titleEn': titleEn,
        'titleBn': titleBn,
        'narrativeEn': narrativeEn,
        'narrativeBn': narrativeBn,
        'evidence': evidence.map((value) => value.toJson()).toList(),
      };
}

class DashamsaCareerSynthesis {
  const DashamsaCareerSynthesis({
    required this.code,
    required this.ruleVersion,
    required this.d1TenthLord,
    required this.d1TenthLordD10House,
    required this.d1TenthLordD10Dignity,
    required this.d10TenthLord,
    required this.d10TenthLordHouse,
    required this.d10TenthLordDignity,
    required this.d10TenthOccupants,
    required this.d10TenthAspectors,
    required this.d1LordScore,
    required this.d10TenthScore,
    required this.netScore,
    required this.polarity,
    required this.confidence,
    required this.contradictorySignals,
    required this.titleEn,
    required this.titleBn,
    required this.narrativeEn,
    required this.narrativeBn,
    required this.evidence,
  });

  final String code;
  final String ruleVersion;
  final String d1TenthLord;
  final int d1TenthLordD10House;
  final String d1TenthLordD10Dignity;
  final String d10TenthLord;
  final int d10TenthLordHouse;
  final String d10TenthLordDignity;
  final List<String> d10TenthOccupants;
  final List<String> d10TenthAspectors;
  final int d1LordScore;
  final int d10TenthScore;
  final int netScore;
  final AnalysisPolarity polarity;
  final AnalysisConfidence confidence;
  final bool contradictorySignals;
  final String titleEn;
  final String titleBn;
  final String narrativeEn;
  final String narrativeBn;
  final List<ChartEvidence> evidence;

  Map<String, Object?> toJson() => {
        'code': code,
        'ruleVersion': ruleVersion,
        'd1TenthLord': d1TenthLord,
        'd1TenthLordD10House': d1TenthLordD10House,
        'd1TenthLordD10Dignity': d1TenthLordD10Dignity,
        'd10TenthLord': d10TenthLord,
        'd10TenthLordHouse': d10TenthLordHouse,
        'd10TenthLordDignity': d10TenthLordDignity,
        'd10TenthOccupants': d10TenthOccupants,
        'd10TenthAspectors': d10TenthAspectors,
        'd1LordScore': d1LordScore,
        'd10TenthScore': d10TenthScore,
        'netScore': netScore,
        'polarity': polarity.name,
        'confidence': confidence.name,
        'contradictorySignals': contradictorySignals,
        'titleEn': titleEn,
        'titleBn': titleBn,
        'narrativeEn': narrativeEn,
        'narrativeBn': narrativeBn,
        'evidence': evidence.map((value) => value.toJson()).toList(),
      };
}

class ShadbalaVargaContribution {
  const ShadbalaVargaContribution({
    required this.division,
    required this.signIndex,
    required this.hostPlanet,
    required this.relationship,
    required this.virupas,
  });

  final int division;
  final int signIndex;
  final String hostPlanet;
  final String relationship;
  final double virupas;

  Map<String, Object?> toJson() => {
        'division': division,
        'signIndex': signIndex,
        'hostPlanet': hostPlanet,
        'relationship': relationship,
        'virupas': virupas,
      };
}


class DrikBalaContribution {
  const DrikBalaContribution({
    required this.aspector,
    required this.aspectAngleDegrees,
    required this.aspectVirupas,
    required this.nature,
    required this.baseQuarterContributionVirupas,
    required this.superAddedVirupas,
    required this.netContributionVirupas,
  });

  final String aspector;
  final double aspectAngleDegrees;
  final double aspectVirupas;
  final String nature;
  final double baseQuarterContributionVirupas;
  final double superAddedVirupas;
  final double netContributionVirupas;

  Map<String, Object?> toJson() => {
        'aspector': aspector,
        'aspectAngleDegrees': aspectAngleDegrees,
        'aspectVirupas': aspectVirupas,
        'nature': nature,
        'baseQuarterContributionVirupas': baseQuarterContributionVirupas,
        'superAddedVirupas': superAddedVirupas,
        'netContributionVirupas': netContributionVirupas,
      };
}

class ShadbalaPlanetProfile {
  const ShadbalaPlanetProfile({
    required this.code,
    required this.ruleVersion,
    required this.planet,
    required this.ucchaBalaVirupas,
    required this.saptavargajaBalaVirupas,
    required this.ojayugmaBalaVirupas,
    required this.kendradiBalaVirupas,
    required this.drekkanaBalaVirupas,
    required this.sthanaBalaVirupas,
    required this.digBalaVirupas,
    required this.nathonnataBalaVirupas,
    required this.sunHourAngleHours,
    required this.tribhagaBalaVirupas,
    required this.tribhagaPeriod,
    required this.tribhagaThird,
    required this.tribhagaPeriodStartUtc,
    required this.tribhagaPeriodEndUtc,
    required this.pakshaBalaVirupas,
    required this.varshaBalaVirupas,
    required this.masaBalaVirupas,
    required this.dinaBalaVirupas,
    required this.horaBalaVirupas,
    required this.varshaLord,
    required this.masaLord,
    required this.dinaLord,
    required this.horaLord,
    required this.horaNumber,
    required this.varshaMasaDinaHoraProfile,
    required this.ayanaBalaVirupas,
    required this.yuddhaBalaVirupas,
    required this.yuddhaProfile,
    required this.yuddhaRole,
    required this.yuddhaWarPartner,
    required this.yuddhaSeparationDegrees,
    required this.yuddhaLatitudeDegrees,
    required this.yuddhaPartnerLatitudeDegrees,
    required this.yuddhaPreWarStrengthDifferenceVirupas,
    required this.kalaBalaPartialVirupas,
    required this.kalaBalaVirupas,
    required this.kalaComputedSubcomponents,
    required this.kalaMissingSubcomponents,
    required this.kalaBalaComplete,
    required this.cheshtaBalaVirupas,
    required this.cheshtaMethod,
    required this.cheshtaMotionState,
    required this.longitudeSpeedPerDay,
    required this.naisargikaBalaVirupas,
    required this.drikBalaVirupas,
    required this.drikProfile,
    required this.drikContributions,
    required this.vargaContributions,
    required this.computedComponents,
    required this.missingComponents,
    required this.aggregateAvailable,
    required this.totalShadbalaVirupas,
    required this.totalShadbalaRupas,
    required this.requiredShadbalaVirupas,
    required this.requiredShadbalaRupas,
    required this.requiredStrengthRatio,
    required this.surplusDeficitVirupas,
    required this.thresholdStatus,
    required this.thresholdProfile,
    required this.narrativeEn,
    required this.narrativeBn,
    required this.evidence,
  });

  final String code;
  final String ruleVersion;
  final String planet;
  final double ucchaBalaVirupas;
  final double saptavargajaBalaVirupas;
  final double ojayugmaBalaVirupas;
  final double kendradiBalaVirupas;
  final double drekkanaBalaVirupas;
  final double sthanaBalaVirupas;
  final double digBalaVirupas;
  final double? nathonnataBalaVirupas;
  final double? sunHourAngleHours;
  final double? tribhagaBalaVirupas;
  final String? tribhagaPeriod;
  final int? tribhagaThird;
  final String? tribhagaPeriodStartUtc;
  final String? tribhagaPeriodEndUtc;
  final double pakshaBalaVirupas;
  final double? varshaBalaVirupas;
  final double? masaBalaVirupas;
  final double? dinaBalaVirupas;
  final double? horaBalaVirupas;
  final String? varshaLord;
  final String? masaLord;
  final String? dinaLord;
  final String? horaLord;
  final int? horaNumber;
  final String? varshaMasaDinaHoraProfile;
  final double ayanaBalaVirupas;
  final double? yuddhaBalaVirupas;
  final String yuddhaProfile;
  final String yuddhaRole;
  final String? yuddhaWarPartner;
  final double? yuddhaSeparationDegrees;
  final double? yuddhaLatitudeDegrees;
  final double? yuddhaPartnerLatitudeDegrees;
  final double? yuddhaPreWarStrengthDifferenceVirupas;
  final double kalaBalaPartialVirupas;
  final double? kalaBalaVirupas;
  final List<String> kalaComputedSubcomponents;
  final List<String> kalaMissingSubcomponents;
  final bool kalaBalaComplete;
  final double? cheshtaBalaVirupas;
  final String cheshtaMethod;
  final String? cheshtaMotionState;
  final double? longitudeSpeedPerDay;
  final double naisargikaBalaVirupas;
  final double drikBalaVirupas;
  final String drikProfile;
  final List<DrikBalaContribution> drikContributions;
  final List<ShadbalaVargaContribution> vargaContributions;
  final List<String> computedComponents;
  final List<String> missingComponents;
  final bool aggregateAvailable;
  final double? totalShadbalaVirupas;
  final double? totalShadbalaRupas;
  final double requiredShadbalaVirupas;
  final double requiredShadbalaRupas;
  final double? requiredStrengthRatio;
  final double? surplusDeficitVirupas;
  final String thresholdStatus;
  final String thresholdProfile;
  final String narrativeEn;
  final String narrativeBn;
  final List<ChartEvidence> evidence;

  Map<String, Object?> toJson() => {
        'code': code,
        'ruleVersion': ruleVersion,
        'planet': planet,
        'ucchaBalaVirupas': ucchaBalaVirupas,
        'saptavargajaBalaVirupas': saptavargajaBalaVirupas,
        'ojayugmaBalaVirupas': ojayugmaBalaVirupas,
        'kendradiBalaVirupas': kendradiBalaVirupas,
        'drekkanaBalaVirupas': drekkanaBalaVirupas,
        'sthanaBalaVirupas': sthanaBalaVirupas,
        'digBalaVirupas': digBalaVirupas,
        'nathonnataBalaVirupas': nathonnataBalaVirupas,
        'sunHourAngleHours': sunHourAngleHours,
        'tribhagaBalaVirupas': tribhagaBalaVirupas,
        'tribhagaPeriod': tribhagaPeriod,
        'tribhagaThird': tribhagaThird,
        'tribhagaPeriodStartUtc': tribhagaPeriodStartUtc,
        'tribhagaPeriodEndUtc': tribhagaPeriodEndUtc,
        'pakshaBalaVirupas': pakshaBalaVirupas,
        'varshaBalaVirupas': varshaBalaVirupas,
        'masaBalaVirupas': masaBalaVirupas,
        'dinaBalaVirupas': dinaBalaVirupas,
        'horaBalaVirupas': horaBalaVirupas,
        'varshaLord': varshaLord,
        'masaLord': masaLord,
        'dinaLord': dinaLord,
        'horaLord': horaLord,
        'horaNumber': horaNumber,
        'varshaMasaDinaHoraProfile': varshaMasaDinaHoraProfile,
        'ayanaBalaVirupas': ayanaBalaVirupas,
        'yuddhaBalaVirupas': yuddhaBalaVirupas,
        'yuddhaProfile': yuddhaProfile,
        'yuddhaRole': yuddhaRole,
        'yuddhaWarPartner': yuddhaWarPartner,
        'yuddhaSeparationDegrees': yuddhaSeparationDegrees,
        'yuddhaLatitudeDegrees': yuddhaLatitudeDegrees,
        'yuddhaPartnerLatitudeDegrees': yuddhaPartnerLatitudeDegrees,
        'yuddhaPreWarStrengthDifferenceVirupas':
            yuddhaPreWarStrengthDifferenceVirupas,
        'kalaBalaPartialVirupas': kalaBalaPartialVirupas,
        'kalaBalaVirupas': kalaBalaVirupas,
        'kalaComputedSubcomponents': kalaComputedSubcomponents,
        'kalaMissingSubcomponents': kalaMissingSubcomponents,
        'kalaBalaComplete': kalaBalaComplete,
        'cheshtaBalaVirupas': cheshtaBalaVirupas,
        'cheshtaMethod': cheshtaMethod,
        'cheshtaMotionState': cheshtaMotionState,
        'longitudeSpeedPerDay': longitudeSpeedPerDay,
        'naisargikaBalaVirupas': naisargikaBalaVirupas,
        'drikBalaVirupas': drikBalaVirupas,
        'drikProfile': drikProfile,
        'drikContributions':
            drikContributions.map((value) => value.toJson()).toList(),
        'vargaContributions':
            vargaContributions.map((value) => value.toJson()).toList(),
        'computedComponents': computedComponents,
        'missingComponents': missingComponents,
        'aggregateAvailable': aggregateAvailable,
        'totalShadbalaVirupas': totalShadbalaVirupas,
        'totalShadbalaRupas': totalShadbalaRupas,
        'requiredShadbalaVirupas': requiredShadbalaVirupas,
        'requiredShadbalaRupas': requiredShadbalaRupas,
        'requiredStrengthRatio': requiredStrengthRatio,
        'surplusDeficitVirupas': surplusDeficitVirupas,
        'thresholdStatus': thresholdStatus,
        'thresholdProfile': thresholdProfile,
        'narrativeEn': narrativeEn,
        'narrativeBn': narrativeBn,
        'evidence': evidence.map((value) => value.toJson()).toList(),
      };
}


class AshtakavargaContribution {
  const AshtakavargaContribution({
    required this.reference,
    required this.referenceSignIndex,
    required this.relativeHouse,
  });

  final String reference;
  final int referenceSignIndex;
  final int relativeHouse;

  Map<String, Object?> toJson() => {
        'reference': reference,
        'referenceSignIndex': referenceSignIndex,
        'relativeHouse': relativeHouse,
      };
}

class BhinnashtakavargaSignProfile {
  const BhinnashtakavargaSignProfile({
    required this.signIndex,
    required this.positiveMarks,
    required this.contributors,
  });

  final int signIndex;
  final int positiveMarks;
  final List<AshtakavargaContribution> contributors;

  Map<String, Object?> toJson() => {
        'signIndex': signIndex,
        'positiveMarks': positiveMarks,
        'contributors': contributors.map((value) => value.toJson()).toList(),
      };
}

class BhinnashtakavargaPlanetProfile {
  const BhinnashtakavargaPlanetProfile({
    required this.planet,
    required this.fixedTotalPositiveMarks,
    required this.signs,
  });

  final String planet;
  final int fixedTotalPositiveMarks;
  final List<BhinnashtakavargaSignProfile> signs;

  int get totalPositiveMarks =>
      signs.fold<int>(0, (sum, value) => sum + value.positiveMarks);

  Map<String, Object?> toJson() => {
        'planet': planet,
        'fixedTotalPositiveMarks': fixedTotalPositiveMarks,
        'totalPositiveMarks': totalPositiveMarks,
        'signs': signs.map((value) => value.toJson()).toList(),
      };
}

class SarvashtakavargaSignProfile {
  const SarvashtakavargaSignProfile({
    required this.signIndex,
    required this.houseNumber,
    required this.positiveMarks,
    required this.band,
    required this.polarity,
    required this.confidence,
    required this.narrativeEn,
    required this.narrativeBn,
    required this.evidence,
  });

  final int signIndex;
  final int houseNumber;
  final int positiveMarks;
  final String band;
  final AnalysisPolarity polarity;
  final AnalysisConfidence confidence;
  final String narrativeEn;
  final String narrativeBn;
  final List<ChartEvidence> evidence;

  Map<String, Object?> toJson() => {
        'signIndex': signIndex,
        'houseNumber': houseNumber,
        'positiveMarks': positiveMarks,
        'band': band,
        'polarity': polarity.name,
        'confidence': confidence.name,
        'narrativeEn': narrativeEn,
        'narrativeBn': narrativeBn,
        'evidence': evidence.map((value) => value.toJson()).toList(),
      };
}



class AshtakavargaTrikonaAudit {
  const AshtakavargaTrikonaAudit({
    required this.signIndexes,
    required this.inputMarks,
    required this.outputMarks,
    required this.action,
  });

  final List<int> signIndexes;
  final List<int> inputMarks;
  final List<int> outputMarks;
  final String action;

  Map<String, Object?> toJson() => {
        'signIndexes': signIndexes,
        'inputMarks': inputMarks,
        'outputMarks': outputMarks,
        'action': action,
      };
}

class AshtakavargaEkadhipatyaAudit {
  const AshtakavargaEkadhipatyaAudit({
    required this.lord,
    required this.signIndexes,
    required this.inputMarks,
    required this.outputMarks,
    required this.occupied,
    required this.action,
  });

  final String lord;
  final List<int> signIndexes;
  final List<int> inputMarks;
  final List<int> outputMarks;
  final List<bool> occupied;
  final String action;

  Map<String, Object?> toJson() => {
        'lord': lord,
        'signIndexes': signIndexes,
        'inputMarks': inputMarks,
        'outputMarks': outputMarks,
        'occupied': occupied,
        'action': action,
      };
}

class AshtakavargaReducedPlanetProfile {
  const AshtakavargaReducedPlanetProfile({
    required this.planet,
    required this.rawMarks,
    required this.trikonaReducedMarks,
    required this.ekadhipatyaReducedMarks,
    required this.trikonaAudits,
    required this.ekadhipatyaAudits,
  });

  final String planet;
  final List<int> rawMarks;
  final List<int> trikonaReducedMarks;
  final List<int> ekadhipatyaReducedMarks;
  final List<AshtakavargaTrikonaAudit> trikonaAudits;
  final List<AshtakavargaEkadhipatyaAudit> ekadhipatyaAudits;

  int get rawTotal => rawMarks.fold<int>(0, (sum, value) => sum + value);
  int get trikonaReducedTotal =>
      trikonaReducedMarks.fold<int>(0, (sum, value) => sum + value);
  int get ekadhipatyaReducedTotal =>
      ekadhipatyaReducedMarks.fold<int>(0, (sum, value) => sum + value);

  Map<String, Object?> toJson() => {
        'planet': planet,
        'rawMarks': rawMarks,
        'rawTotal': rawTotal,
        'trikonaReducedMarks': trikonaReducedMarks,
        'trikonaReducedTotal': trikonaReducedTotal,
        'ekadhipatyaReducedMarks': ekadhipatyaReducedMarks,
        'ekadhipatyaReducedTotal': ekadhipatyaReducedTotal,
        'trikonaAudits': trikonaAudits.map((value) => value.toJson()).toList(),
        'ekadhipatyaAudits':
            ekadhipatyaAudits.map((value) => value.toJson()).toList(),
      };
}

class AshtakavargaReductionProfile {
  const AshtakavargaReductionProfile({
    required this.code,
    required this.ruleVersion,
    required this.rulesetProfile,
    required this.occupancyConvention,
    required this.planets,
    required this.reducedAggregateMarks,
    required this.evidence,
  });

  final String code;
  final String ruleVersion;
  final String rulesetProfile;
  final String occupancyConvention;
  final List<AshtakavargaReducedPlanetProfile> planets;
  final List<int> reducedAggregateMarks;
  final List<ChartEvidence> evidence;

  int get reducedAggregateTotal =>
      reducedAggregateMarks.fold<int>(0, (sum, value) => sum + value);

  Map<String, Object?> toJson() => {
        'code': code,
        'ruleVersion': ruleVersion,
        'rulesetProfile': rulesetProfile,
        'occupancyConvention': occupancyConvention,
        'planets': planets.map((value) => value.toJson()).toList(),
        'reducedAggregateMarks': reducedAggregateMarks,
        'reducedAggregateTotal': reducedAggregateTotal,
        'evidence': evidence.map((value) => value.toJson()).toList(),
      };
}

class AshtakavargaRashiPindaContribution {
  const AshtakavargaRashiPindaContribution({
    required this.signIndex,
    required this.reducedMarks,
    required this.multiplier,
    required this.product,
  });

  final int signIndex;
  final int reducedMarks;
  final int multiplier;
  final int product;

  Map<String, Object?> toJson() => {
        'signIndex': signIndex,
        'reducedMarks': reducedMarks,
        'multiplier': multiplier,
        'product': product,
      };
}

class AshtakavargaGrahaPindaContribution {
  const AshtakavargaGrahaPindaContribution({
    required this.referencePlanet,
    required this.occupiedSignIndex,
    required this.reducedMarks,
    required this.multiplier,
    required this.product,
  });

  final String referencePlanet;
  final int occupiedSignIndex;
  final int reducedMarks;
  final int multiplier;
  final int product;

  Map<String, Object?> toJson() => {
        'referencePlanet': referencePlanet,
        'occupiedSignIndex': occupiedSignIndex,
        'reducedMarks': reducedMarks,
        'multiplier': multiplier,
        'product': product,
      };
}

class AshtakavargaPlanetPindaProfile {
  const AshtakavargaPlanetPindaProfile({
    required this.planet,
    required this.rashiPinda,
    required this.grahaPinda,
    required this.shodhyaPinda,
    required this.rashiContributions,
    required this.grahaContributions,
  });

  final String planet;
  final int rashiPinda;
  final int grahaPinda;
  final int shodhyaPinda;
  final List<AshtakavargaRashiPindaContribution> rashiContributions;
  final List<AshtakavargaGrahaPindaContribution> grahaContributions;

  Map<String, Object?> toJson() => {
        'planet': planet,
        'rashiPinda': rashiPinda,
        'grahaPinda': grahaPinda,
        'shodhyaPinda': shodhyaPinda,
        'rashiContributions':
            rashiContributions.map((value) => value.toJson()).toList(),
        'grahaContributions':
            grahaContributions.map((value) => value.toJson()).toList(),
      };
}

class AshtakavargaPindaProfile {
  const AshtakavargaPindaProfile({
    required this.code,
    required this.ruleVersion,
    required this.rulesetProfile,
    required this.rashiMultipliers,
    required this.grahaMultipliers,
    required this.planets,
    required this.evidence,
  });

  final String code;
  final String ruleVersion;
  final String rulesetProfile;
  final List<int> rashiMultipliers;
  final Map<String, int> grahaMultipliers;
  final List<AshtakavargaPlanetPindaProfile> planets;
  final List<ChartEvidence> evidence;

  Map<String, Object?> toJson() => {
        'code': code,
        'ruleVersion': ruleVersion,
        'rulesetProfile': rulesetProfile,
        'rashiMultipliers': rashiMultipliers,
        'grahaMultipliers': grahaMultipliers,
        'planets': planets.map((value) => value.toJson()).toList(),
        'evidence': evidence.map((value) => value.toJson()).toList(),
      };
}

class AshtakavargaAnalysisProfile {
  const AshtakavargaAnalysisProfile({
    required this.code,
    required this.ruleVersion,
    required this.rulesetProfile,
    required this.notationConvention,
    required this.bhinnashtakavarga,
    required this.sarvashtakavarga,
    required this.totalPositiveMarks,
    required this.averagePositiveMarks,
    required this.evidence,
    this.reductionProfile,
    this.pindaProfile,
  });

  final String code;
  final String ruleVersion;
  final String rulesetProfile;
  final String notationConvention;
  final List<BhinnashtakavargaPlanetProfile> bhinnashtakavarga;
  final List<SarvashtakavargaSignProfile> sarvashtakavarga;
  final int totalPositiveMarks;
  final double averagePositiveMarks;
  final List<ChartEvidence> evidence;
  final AshtakavargaReductionProfile? reductionProfile;
  final AshtakavargaPindaProfile? pindaProfile;

  Map<String, Object?> toJson() => {
        'code': code,
        'ruleVersion': ruleVersion,
        'rulesetProfile': rulesetProfile,
        'notationConvention': notationConvention,
        'bhinnashtakavarga':
            bhinnashtakavarga.map((value) => value.toJson()).toList(),
        'sarvashtakavarga':
            sarvashtakavarga.map((value) => value.toJson()).toList(),
        'totalPositiveMarks': totalPositiveMarks,
        'averagePositiveMarks': averagePositiveMarks,
        'reductionProfile': reductionProfile?.toJson(),
        'pindaProfile': pindaProfile?.toJson(),
        'evidence': evidence.map((value) => value.toJson()).toList(),
      };
}

class DashaActivationProfile {
  const DashaActivationProfile({
    required this.lord,
    required this.score,
    required this.polarity,
    required this.lifeAreas,
    required this.summaryEn,
    required this.summaryBn,
    required this.evidence,
  });

  final String lord;
  final int score;
  final AnalysisPolarity polarity;
  final List<LifeArea> lifeAreas;
  final String summaryEn;
  final String summaryBn;
  final List<ChartEvidence> evidence;

  Map<String, Object?> toJson() => {
        'lord': lord,
        'score': score,
        'polarity': polarity.name,
        'lifeAreas': lifeAreas.map((value) => value.name).toList(),
        'summaryEn': summaryEn,
        'summaryBn': summaryBn,
        'evidence': evidence.map((value) => value.toJson()).toList(),
      };
}

enum PratyantardashaTriggerRelation { reinforcing, countertrend, neutral }

class PratyantardashaInterpretation {
  const PratyantardashaInterpretation({
    required this.code,
    required this.ruleVersion,
    required this.mahadashaLord,
    required this.antardashaLord,
    required this.pratyantardashaLord,
    required this.startUtc,
    required this.endUtc,
    required this.mahadashaScore,
    required this.antardashaScore,
    required this.pratyantardashaScore,
    required this.weightedScore,
    required this.polarity,
    required this.confidence,
    required this.contradictorySignals,
    required this.triggerRelation,
    required this.lifeAreas,
    required this.titleEn,
    required this.titleBn,
    required this.narrativeEn,
    required this.narrativeBn,
    required this.evidence,
  });

  final String code;
  final String ruleVersion;
  final String mahadashaLord;
  final String antardashaLord;
  final String pratyantardashaLord;
  final DateTime startUtc;
  final DateTime endUtc;
  final int mahadashaScore;
  final int antardashaScore;
  final int pratyantardashaScore;
  final int weightedScore;
  final AnalysisPolarity polarity;
  final AnalysisConfidence confidence;
  final bool contradictorySignals;
  final PratyantardashaTriggerRelation triggerRelation;
  final List<LifeArea> lifeAreas;
  final String titleEn;
  final String titleBn;
  final String narrativeEn;
  final String narrativeBn;
  final List<ChartEvidence> evidence;

  Map<String, Object?> toJson() => {
        'code': code,
        'ruleVersion': ruleVersion,
        'mahadashaLord': mahadashaLord,
        'antardashaLord': antardashaLord,
        'pratyantardashaLord': pratyantardashaLord,
        'startUtc': startUtc.toUtc().toIso8601String(),
        'endUtc': endUtc.toUtc().toIso8601String(),
        'mahadashaScore': mahadashaScore,
        'antardashaScore': antardashaScore,
        'pratyantardashaScore': pratyantardashaScore,
        'weightedScore': weightedScore,
        'polarity': polarity.name,
        'confidence': confidence.name,
        'contradictorySignals': contradictorySignals,
        'triggerRelation': triggerRelation.name,
        'lifeAreas': lifeAreas.map((value) => value.name).toList(),
        'titleEn': titleEn,
        'titleBn': titleBn,
        'narrativeEn': narrativeEn,
        'narrativeBn': narrativeBn,
        'evidence': evidence.map((value) => value.toJson()).toList(),
      };
}



enum GemstoneCandidateStatus { eligible, contraindicated, insufficientEvidence }

class GemstoneCandidateReview {
  const GemstoneCandidateReview({
    required this.code,
    required this.ruleVersion,
    required this.mappingProfile,
    required this.planet,
    required this.primaryGemstone,
    required this.primaryGemstoneBn,
    required this.status,
    required this.functionalOwnedHouses,
    required this.functionalScore,
    required this.yogaKaraka,
    required this.shadbalaAvailable,
    required this.requiredStrengthRatio,
    required this.shadbalaThresholdStatus,
    required this.d1Dignity,
    required this.d9Dignity,
    required this.combust,
    required this.planetaryWarRole,
    required this.nodeContacts,
    required this.activeDashaRole,
    required this.activeDashaPolarity,
    required this.rationaleEn,
    required this.rationaleBn,
    required this.cautionEn,
    required this.cautionBn,
    required this.evidence,
  });

  final String code;
  final String ruleVersion;
  final String mappingProfile;
  final String planet;
  final String primaryGemstone;
  final String primaryGemstoneBn;
  final GemstoneCandidateStatus status;
  final List<int> functionalOwnedHouses;
  final int functionalScore;
  final bool yogaKaraka;
  final bool shadbalaAvailable;
  final double? requiredStrengthRatio;
  final String shadbalaThresholdStatus;
  final String d1Dignity;
  final String d9Dignity;
  final bool combust;
  final String planetaryWarRole;
  final List<String> nodeContacts;
  final String activeDashaRole;
  final AnalysisPolarity? activeDashaPolarity;
  final String rationaleEn;
  final String rationaleBn;
  final String cautionEn;
  final String cautionBn;
  final List<ChartEvidence> evidence;

  Map<String, Object?> toJson() => {
        'code': code,
        'ruleVersion': ruleVersion,
        'mappingProfile': mappingProfile,
        'planet': planet,
        'primaryGemstone': primaryGemstone,
        'primaryGemstoneBn': primaryGemstoneBn,
        'status': status.name,
        'functionalOwnedHouses': functionalOwnedHouses,
        'functionalScore': functionalScore,
        'yogaKaraka': yogaKaraka,
        'shadbalaAvailable': shadbalaAvailable,
        'requiredStrengthRatio': requiredStrengthRatio,
        'shadbalaThresholdStatus': shadbalaThresholdStatus,
        'd1Dignity': d1Dignity,
        'd9Dignity': d9Dignity,
        'combust': combust,
        'planetaryWarRole': planetaryWarRole,
        'nodeContacts': nodeContacts,
        'activeDashaRole': activeDashaRole,
        'activeDashaPolarity': activeDashaPolarity?.name,
        'rationaleEn': rationaleEn,
        'rationaleBn': rationaleBn,
        'cautionEn': cautionEn,
        'cautionBn': cautionBn,
        'evidence': evidence.map((value) => value.toJson()).toList(),
      };
}

class AnalysisRemedyCandidate {
  const AnalysisRemedyCandidate({
    required this.code,
    required this.kind,
    required this.targetPlanet,
    required this.actionEn,
    required this.actionBn,
    required this.rationaleEn,
    required this.rationaleBn,
    required this.cautionEn,
    required this.cautionBn,
    required this.evidence,
  });

  final String code;
  final AnalysisRemedyKind kind;
  final String? targetPlanet;
  final String actionEn;
  final String actionBn;
  final String rationaleEn;
  final String rationaleBn;
  final String cautionEn;
  final String cautionBn;
  final List<ChartEvidence> evidence;

  Map<String, Object?> toJson() => {
        'code': code,
        'kind': kind.name,
        'targetPlanet': targetPlanet,
        'actionEn': actionEn,
        'actionBn': actionBn,
        'rationaleEn': rationaleEn,
        'rationaleBn': rationaleBn,
        'cautionEn': cautionEn,
        'cautionBn': cautionBn,
        'evidence': evidence.map((value) => value.toJson()).toList(),
      };
}

class KundliAnalysis {
  const KundliAnalysis({
    required this.findings,
    required this.timingWindows,
    this.dashaActivationProfiles = const [],
    this.pratyantardashaInterpretations = const [],
    this.navamsaHouseInterpretations = const [],
    this.dashamsaHouseInterpretations = const [],
    this.dashamsaCareerSynthesis,
    this.shadbalaProfiles = const [],
    this.ashtakavargaProfile,
    this.gemstoneCandidateReviews = const [],
    required this.remedyCandidates,
    required this.warningsEn,
    required this.warningsBn,
    required this.professionalReviewRequired,
  });

  final List<ChartFinding> findings;
  final List<AnalysisTimingWindow> timingWindows;
  final List<DashaActivationProfile> dashaActivationProfiles;
  final List<PratyantardashaInterpretation> pratyantardashaInterpretations;
  final List<NavamsaHouseInterpretation> navamsaHouseInterpretations;
  final List<DashamsaHouseInterpretation> dashamsaHouseInterpretations;
  final DashamsaCareerSynthesis? dashamsaCareerSynthesis;
  final List<ShadbalaPlanetProfile> shadbalaProfiles;
  final AshtakavargaAnalysisProfile? ashtakavargaProfile;
  final List<GemstoneCandidateReview> gemstoneCandidateReviews;
  final List<AnalysisRemedyCandidate> remedyCandidates;
  final List<String> warningsEn;
  final List<String> warningsBn;
  final bool professionalReviewRequired;

  Map<String, Object?> toJson() => {
        'findings': findings.map((value) => value.toJson()).toList(),
        'timingWindows':
            timingWindows.map((value) => value.toJson()).toList(),
        'dashaActivationProfiles':
            dashaActivationProfiles.map((value) => value.toJson()).toList(),
        'pratyantardashaInterpretations': pratyantardashaInterpretations
            .map((value) => value.toJson())
            .toList(),
        'navamsaHouseInterpretations': navamsaHouseInterpretations
            .map((value) => value.toJson())
            .toList(),
        'dashamsaHouseInterpretations': dashamsaHouseInterpretations
            .map((value) => value.toJson())
            .toList(),
        'dashamsaCareerSynthesis': dashamsaCareerSynthesis?.toJson(),
        'shadbalaProfiles':
            shadbalaProfiles.map((value) => value.toJson()).toList(),
        'ashtakavargaProfile': ashtakavargaProfile?.toJson(),
        'gemstoneCandidateReviews': gemstoneCandidateReviews.map((value) => value.toJson()).toList(),
        'remedyCandidates':
            remedyCandidates.map((value) => value.toJson()).toList(),
        'warningsEn': warningsEn,
        'warningsBn': warningsBn,
        'professionalReviewRequired': professionalReviewRequired,
      };
}
