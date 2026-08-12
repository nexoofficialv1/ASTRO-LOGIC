import 'dart:convert';

enum RemedyPlanet {
  sun,
  moon,
  mars,
  mercury,
  jupiter,
  venus,
  saturn,
  rahu,
  ketu,
}

enum GemstoneWeightUnit { carat, ratti }

enum RemedyDecision { draft, approved, rejected }

class GemstoneRemedy {
  const GemstoneRemedy({
    this.id,
    required this.consultationId,
    required this.planet,
    required this.primaryGemstone,
    required this.substituteGemstone,
    required this.weightValue,
    required this.weightUnit,
    required this.metal,
    required this.finger,
    required this.wearingDay,
    required this.instructions,
    required this.astrologicalReason,
    required this.evidenceReferences,
    required this.cautions,
    required this.decision,
    required this.createdAt,
    required this.updatedAt,
  });

  final int? id;
  final int consultationId;
  final RemedyPlanet planet;
  final String primaryGemstone;
  final String substituteGemstone;
  final double weightValue;
  final GemstoneWeightUnit weightUnit;
  final String metal;
  final String finger;
  final String wearingDay;
  final String instructions;
  final String astrologicalReason;
  final List<String> evidenceReferences;
  final String cautions;
  final RemedyDecision decision;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, Object?> toDatabaseMap() => {
        'consultation_id': consultationId,
        'planet': planet.name,
        'primary_gemstone': primaryGemstone.trim(),
        'substitute_gemstone': substituteGemstone.trim(),
        'weight_value': weightValue,
        'weight_unit': weightUnit.name,
        'metal': metal.trim(),
        'finger': finger.trim(),
        'wearing_day': wearingDay.trim(),
        'instructions': instructions.trim(),
        'astrological_reason': astrologicalReason.trim(),
        'evidence_json': jsonEncode(evidenceReferences),
        'cautions': cautions.trim(),
        'decision': decision.name,
        'created_at': createdAt.toUtc().toIso8601String(),
        'updated_at': updatedAt.toUtc().toIso8601String(),
      };

  factory GemstoneRemedy.fromDatabaseMap(Map<String, Object?> map) =>
      GemstoneRemedy(
        id: map['id'] as int,
        consultationId: map['consultation_id'] as int,
        planet: RemedyPlanet.values.byName(map['planet'] as String),
        primaryGemstone: map['primary_gemstone'] as String,
        substituteGemstone: map['substitute_gemstone'] as String,
        weightValue: (map['weight_value'] as num).toDouble(),
        weightUnit:
            GemstoneWeightUnit.values.byName(map['weight_unit'] as String),
        metal: map['metal'] as String,
        finger: map['finger'] as String,
        wearingDay: map['wearing_day'] as String,
        instructions: map['instructions'] as String,
        astrologicalReason: map['astrological_reason'] as String,
        evidenceReferences:
            (jsonDecode(map['evidence_json'] as String) as List)
                .cast<String>(),
        cautions: map['cautions'] as String,
        decision: RemedyDecision.values.byName(map['decision'] as String),
        createdAt: DateTime.parse(map['created_at'] as String),
        updatedAt: DateTime.parse(map['updated_at'] as String),
      );
}
