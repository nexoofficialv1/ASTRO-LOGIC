import '../ephemeris/ephemeris_provider.dart';
import '../models/astrology_settings.dart';
import '../models/calculation_output_snapshot.dart';
import '../models/kundli_analysis.dart';
import '../models/vedic_transit_analysis.dart';
import 'vedic_math.dart';

class VedicTransitEngine {
  const VedicTransitEngine(this._ephemeris);

  final EphemerisProvider _ephemeris;

  static const _classicalMoonGochara = <String, _MoonGocharaRule>{
    'sun': _MoonGocharaRule(
      supportiveHouses: {3, 6, 10, 11},
      challengingHouses: {1, 2, 4, 5, 7, 8, 9},
    ),
    'moon': _MoonGocharaRule(
      supportiveHouses: {1, 3, 6, 7, 10, 11},
      challengingHouses: {2, 5, 8, 9, 12},
    ),
    'mars': _MoonGocharaRule(
      supportiveHouses: {3, 6, 10, 11},
      challengingHouses: {1, 2, 4, 5, 7, 8, 9, 12},
    ),
    'mercury': _MoonGocharaRule(
      supportiveHouses: {2, 4, 6, 8, 10, 11},
      challengingHouses: {1, 5, 7, 9, 12},
    ),
    'jupiter': _MoonGocharaRule(
      supportiveHouses: {2, 5, 7, 9, 11},
      challengingHouses: {1, 3, 4, 6, 8, 10, 12},
    ),
    'venus': _MoonGocharaRule(
      supportiveHouses: {1, 2, 3, 4, 5, 8, 9, 11},
      challengingHouses: {6, 7, 10},
    ),
    'saturn': _MoonGocharaRule(
      supportiveHouses: {3, 6, 11},
      challengingHouses: {4, 5, 7, 8, 9},
    ),
    'rahu': _MoonGocharaRule(
      supportiveHouses: {3, 6, 10, 11},
      challengingHouses: {1, 2, 4, 5, 7, 8, 9, 12},
      sourceRuleId: 'phaladeepika26.24.v1',
      sourceNameEn: 'Phaladeepika Chapter 26, verse 24',
      sourceNameBn: 'Phaladeepika অধ্যায় 26, শ্লোক 24',
    ),
  };

  static const _classicalPlanetOrder = <String>[
    'sun',
    'moon',
    'mars',
    'mercury',
    'jupiter',
    'venus',
    'saturn',
    'rahu',
  ];

  String get engineId => 'astro-logic-vedic-transit/${_ephemeris.engineId}';

  String get engineVersion => '3.0.0+${_ephemeris.engineVersion}';

  String get schemaVersion => 'vedic-transit-analysis-v3';

  Future<VedicTransitAnalysis> analyze({
    required CalculationOutputSnapshot natalOutput,
    required DateTime asOfUtc,
    required double latitude,
    required double longitude,
  }) async {
    _validateInput(
      natalOutput: natalOutput,
      asOfUtc: asOfUtc,
      latitude: latitude,
      longitude: longitude,
    );

    final metadata = _requiredMap(natalOutput.output, 'metadata');
    final ayanamshaName = _requiredString(metadata, 'ayanamsha');
    final lunarNodeModeName = _requiredString(metadata, 'lunarNodeMode');
    final ayanamsha = _enumByName(
      Ayanamsha.values,
      ayanamshaName,
      'ayanamsha',
    );
    final lunarNodeMode = _enumByName(
      LunarNodeMode.values,
      lunarNodeModeName,
      'lunarNodeMode',
    );

    final natalAscendant = _requiredMap(natalOutput.output, 'ascendant');
    final ascendantSign = _requiredSignIndex(natalAscendant, 'ascendant');
    final natalMoon = _natalPlanet(natalOutput.output, 'moon');
    final moonSign = _requiredSignIndex(natalMoon, 'natal Moon');

    final frame = await _ephemeris.calculate(
      EphemerisRequest(
        utcDateTime: asOfUtc,
        latitude: latitude,
        longitude: longitude,
        ayanamsha: ayanamsha,
        lunarNodeMode: lunarNodeMode,
      ),
    );
    _validateFrame(frame);

    final positions = <VedicTransitPosition>[];
    for (final body in CelestialBody.values) {
      final source = frame.positions[body]!;
      final sidereal = VedicMath.siderealLongitude(
        source.tropicalLongitude,
        frame.ayanamshaDegrees,
      );
      positions.add(
        _position(
          body: body.name,
          siderealLongitude: sidereal,
          retrograde: source.longitudeSpeed < 0,
          ascendantSign: ascendantSign,
          moonSign: moonSign,
        ),
      );
    }

    final rahu = positions.firstWhere((value) => value.body == 'rahu');
    positions.add(
      _position(
        body: 'ketu',
        siderealLongitude: VedicMath.normalize(
          rahu.siderealLongitude + 180.0,
        ),
        retrograde: rahu.retrograde,
        ascendantSign: ascendantSign,
        moonSign: moonSign,
      ),
    );

    final positionByBody = <String, VedicTransitPosition>{
      for (final position in positions) position.body: position,
    };
    final findings = <VedicTransitFinding>[
      for (final body in _classicalPlanetOrder)
        _moonGocharaFinding(positionByBody[body]!),
    ];

    return VedicTransitAnalysis(
      asOfUtc: asOfUtc,
      engineId: engineId,
      engineVersion: engineVersion,
      schemaVersion: schemaVersion,
      ayanamsha: ayanamshaName,
      lunarNodeMode: lunarNodeModeName,
      positions: List.unmodifiable(positions),
      findings: List.unmodifiable(findings),
      warningsEn: const [
        'Transit findings are source-bounded traditional astrological review signals, not guaranteed events.',
        'The v3 directional Moon-gochara profile covers the seven classical planets plus Rahu. Rahu uses the separate Phaladeepika XXVI.24 house sequence; Ketu position is calculated but Ketu transit-result polarity remains disabled because no equivalent v1 source rule is enabled.',
        'Confirm transit signals against the natal chart, active Dasha and other enabled rule families before using them in a consultation conclusion.',
        'Sade Sati is detected as a review phase and is not automatically classified as a harmful outcome.',
        'Do not infer medical, legal, financial, mortality or other high-stakes outcomes from transit alone.',
      ],
      warningsBn: const [
        'গোচর-ফল এখানে source-bounded প্রথাগত জ্যোতিষীয় review signal; এটি নিশ্চিত ঘটনার ঘোষণা নয়।',
        'v3 directional Moon-gochara profile সাতটি classical planet-এর সঙ্গে Rahu-ও কভার করে। Rahu-এর জন্য আলাদা Phaladeepika XXVI.24 house sequence ব্যবহার হয়; Ketu-এর অবস্থান calculate হলেও সমমানের v1 source rule enabled না থাকায় Ketu transit-result polarity disabled থাকে।',
        'Consultation conclusion দেওয়ার আগে জন্মছক, চলমান দশা এবং অন্য enabled rule family-এর সঙ্গে গোচর signal মিলিয়ে দেখতে হবে।',
        'সাড়ে সাতি review phase হিসেবে শনাক্ত হয়; এটিকে automatic ক্ষতিকর ফল হিসেবে classify করা হয় না।',
        'শুধু গোচর দেখে চিকিৎসা, আইন, অর্থ, মৃত্যু বা অন্য high-stakes ফল নির্ধারণ করা যাবে না।',
      ],
      professionalReviewRequired: true,
    );
  }

  VedicTransitPosition _position({
    required String body,
    required double siderealLongitude,
    required bool retrograde,
    required int ascendantSign,
    required int moonSign,
  }) {
    final signIndex = VedicMath.signIndex(siderealLongitude);
    return VedicTransitPosition(
      body: body,
      siderealLongitude: siderealLongitude,
      signIndex: signIndex,
      sign: VedicMath.rashiNames[signIndex],
      degreeInSign: VedicMath.degreeInSign(siderealLongitude),
      retrograde: retrograde,
      houseFromAscendant: _houseFrom(ascendantSign, signIndex),
      houseFromMoon: _houseFrom(moonSign, signIndex),
    );
  }

  VedicTransitFinding _moonGocharaFinding(VedicTransitPosition position) {
    if (position.body == 'saturn' &&
        const {12, 1, 2}.contains(position.houseFromMoon)) {
      return _sadeSatiFinding(position);
    }

    final rule = _classicalMoonGochara[position.body];
    if (rule == null) {
      throw StateError(
        'No governed classical Moon-gochara rule for ${position.body}',
      );
    }

    final polarity = rule.supportiveHouses.contains(position.houseFromMoon)
        ? AnalysisPolarity.supportive
        : rule.challengingHouses.contains(position.houseFromMoon)
            ? AnalysisPolarity.challenging
            : AnalysisPolarity.mixed;
    final confidence = polarity == AnalysisPolarity.mixed
        ? AnalysisConfidence.low
        : AnalysisConfidence.medium;
    final planetEn = _planetEn(position.body);
    final planetBn = _planetBn(position.body);
    final directionEn = switch (polarity) {
      AnalysisPolarity.supportive => 'supportive',
      AnalysisPolarity.challenging => 'challenging',
      AnalysisPolarity.mixed => 'mixed/review-only',
    };
    final directionBn = switch (polarity) {
      AnalysisPolarity.supportive => 'সহায়ক',
      AnalysisPolarity.challenging => 'চ্যালেঞ্জিং',
      AnalysisPolarity.mixed => 'Mixed/review-only',
    };
    final evidence = ChartEvidence(
      ruleId: 'vedic.transit.${position.body}.moon_gochara.${rule.sourceRuleId}',
      outputPath: 'transit.planets.${position.body}.houseFromMoon',
      kind: EvidenceKind.transit,
      descriptionEn:
          '$planetEn is transiting house ${position.houseFromMoon} from the natal Moon under the governed ${rule.sourceNameEn} profile.',
      descriptionBn:
          'Governed ${rule.sourceNameBn} profile অনুযায়ী জন্মচন্দ্র থেকে $planetBn ${position.houseFromMoon}তম ঘরে গোচর করছে।',
    );

    return VedicTransitFinding(
      code:
          'vedic.transit.${position.body}.moon.${position.houseFromMoon}.${polarity.name}',
      planet: position.body,
      houseFromMoon: position.houseFromMoon,
      polarity: polarity,
      confidence: confidence,
      titleEn: '$planetEn Moon-transit $directionEn signal',
      titleBn: '$planetBn গোচরে $directionBn signal',
      narrativeEn: polarity == AnalysisPolarity.mixed
          ? '$planetEn is in the ${position.houseFromMoon}th house from the natal Moon. The source-bounded v3 matrix intentionally leaves this house non-directional because the classical passage is mixed, limited, or not suitable for a simple supportive/challenging classification. Review the natal chart and active Dasha before interpretation.'
          : '$planetEn is in the ${position.houseFromMoon}th house from the natal Moon. The source-bounded v3 matrix classifies this as a $directionEn Moon-gochara condition. This is a directional confirmation signal only; it does not by itself establish that a specific event will occur.',
      narrativeBn: polarity == AnalysisPolarity.mixed
          ? 'জন্মচন্দ্র থেকে $planetBn ${position.houseFromMoon}তম ঘরে আছে। Classical passage mixed, সীমিত বা simple supportive/challenging classification-এর উপযুক্ত না হওয়ায় source-bounded v3 matrix এই ঘরকে non-directional রেখেছে। ব্যাখ্যার আগে natal chart ও active Dasha দেখতে হবে।'
          : 'জন্মচন্দ্র থেকে $planetBn ${position.houseFromMoon}তম ঘরে আছে। Source-bounded v3 matrix এটিকে $directionBn Moon-gochara condition হিসেবে classify করে। এটি শুধু directional confirmation signal; কোনো নির্দিষ্ট ঘটনা ঘটবেই—এমন প্রমাণ নয়।',
      evidence: [evidence],
    );
  }

  VedicTransitFinding _sadeSatiFinding(VedicTransitPosition saturn) {
    final phase = switch (saturn.houseFromMoon) {
      12 => 'rising',
      1 => 'middle',
      2 => 'setting',
      _ => throw StateError('Sade Sati requires Saturn in house 12, 1 or 2'),
    };
    final phaseBn = switch (saturn.houseFromMoon) {
      12 => 'প্রথম',
      1 => 'মধ্য',
      2 => 'শেষ',
      _ => throw StateError('Sade Sati requires Saturn in house 12, 1 or 2'),
    };
    final evidence = ChartEvidence(
      ruleId: 'vedic.transit.saturn.sade_sati.v2',
      outputPath: 'transit.planets.saturn.houseFromMoon',
      kind: EvidenceKind.transit,
      descriptionEn:
          'Saturn is transiting house ${saturn.houseFromMoon} from the natal Moon, corresponding to the traditional $phase Sade Sati phase.',
      descriptionBn:
          'জন্মচন্দ্র থেকে শনি ${saturn.houseFromMoon}তম ঘরে গোচর করছে, যা প্রথাগত সাড়ে সাতির $phaseBn পর্যায়ের সঙ্গে মেলে।',
    );

    return VedicTransitFinding(
      code: 'vedic.transit.saturn.sade_sati.$phase',
      planet: 'saturn',
      houseFromMoon: saturn.houseFromMoon,
      polarity: AnalysisPolarity.mixed,
      confidence: AnalysisConfidence.medium,
      titleEn: 'Saturn Sade Sati review — $phase phase',
      titleBn: 'শনি সাড়ে সাতি review — $phaseBn পর্যায়',
      narrativeEn:
          'Saturn is in the ${saturn.houseFromMoon}th from the natal Moon, placing this date in the traditional $phase Sade Sati phase. ASTRO LOGIC keeps the phase Mixed rather than converting it into an automatic adverse prediction; natal Saturn, Moon condition, Dasha and other confirmations remain required.',
      narrativeBn:
          'জন্মচন্দ্র থেকে শনি ${saturn.houseFromMoon}তম ঘরে থাকায় এই তারিখটি প্রথাগত সাড়ে সাতির $phaseBn পর্যায়ে পড়ে। ASTRO LOGIC এটিকে automatic adverse prediction না বানিয়ে Mixed রাখে; natal Saturn, Moon-এর অবস্থা, Dasha এবং অন্য confirmation আবশ্যক।',
      evidence: [evidence],
    );
  }

  void _validateInput({
    required CalculationOutputSnapshot natalOutput,
    required DateTime asOfUtc,
    required double latitude,
    required double longitude,
  }) {
    if (!natalOutput.outputSchemaVersion.startsWith('vedic-chart-v')) {
      throw ArgumentError.value(
        natalOutput.outputSchemaVersion,
        'natalOutput.outputSchemaVersion',
        'Vedic transit analysis requires a Vedic natal calculation output',
      );
    }
    if (!asOfUtc.isUtc) {
      throw ArgumentError.value(
        asOfUtc,
        'asOfUtc',
        'Transit date-time must be explicitly converted to UTC',
      );
    }
    if (!latitude.isFinite || latitude < -90.0 || latitude > 90.0) {
      throw ArgumentError.value(latitude, 'latitude');
    }
    if (!longitude.isFinite || longitude < -180.0 || longitude > 180.0) {
      throw ArgumentError.value(longitude, 'longitude');
    }
  }

  void _validateFrame(EphemerisFrame frame) {
    final missing = CelestialBody.values
        .where((body) => !frame.positions.containsKey(body))
        .map((body) => body.name)
        .toList(growable: false);
    if (missing.isNotEmpty) {
      throw StateError('Transit ephemeris frame is missing: ${missing.join(', ')}');
    }
    final values = <double>[
      frame.ayanamshaDegrees,
      for (final position in frame.positions.values)
        position.tropicalLongitude,
      for (final position in frame.positions.values) position.longitudeSpeed,
    ];
    if (values.any((value) => !value.isFinite)) {
      throw StateError('Transit ephemeris returned a non-finite value');
    }
  }

  Map<String, Object?> _requiredMap(
    Map<String, Object?> source,
    String key,
  ) {
    final value = source[key];
    if (value is! Map) {
      throw StateError('Natal calculation output is missing $key');
    }
    return Map<String, Object?>.from(value);
  }

  String _requiredString(Map<String, Object?> source, String key) {
    final value = source[key];
    if (value is! String || value.isEmpty) {
      throw StateError('Natal calculation output is missing $key');
    }
    return value;
  }

  T _enumByName<T extends Enum>(
    List<T> values,
    String name,
    String field,
  ) {
    for (final value in values) {
      if (value.name == name) return value;
    }
    throw StateError('Unsupported natal $field: $name');
  }

  Map<String, Object?> _natalPlanet(
    Map<String, Object?> output,
    String body,
  ) {
    final raw = output['planets'];
    if (raw is! List) {
      throw StateError('Natal calculation output is missing planets');
    }
    for (final value in raw) {
      if (value is Map && value['body'] == body) {
        return Map<String, Object?>.from(value);
      }
    }
    throw StateError('Natal calculation output is missing $body');
  }

  int _requiredSignIndex(Map<String, Object?> source, String label) {
    final value = source['signIndex'];
    if (value is! int || value < 0 || value > 11) {
      throw StateError('$label has an invalid signIndex');
    }
    return value;
  }

  int _houseFrom(int referenceSign, int targetSign) =>
      ((targetSign - referenceSign + 12) % 12) + 1;

  String _planetEn(String body) => switch (body) {
        'sun' => 'Sun',
        'moon' => 'Moon',
        'mars' => 'Mars',
        'mercury' => 'Mercury',
        'jupiter' => 'Jupiter',
        'venus' => 'Venus',
        'saturn' => 'Saturn',
        'rahu' => 'Rahu',
        'ketu' => 'Ketu',
        _ => body,
      };

  String _planetBn(String body) => switch (body) {
        'sun' => 'সূর্য',
        'moon' => 'চন্দ্র',
        'mars' => 'মঙ্গল',
        'mercury' => 'বুধ',
        'jupiter' => 'বৃহস্পতি',
        'venus' => 'শুক্র',
        'saturn' => 'শনি',
        'rahu' => 'রাহু',
        'ketu' => 'কেতু',
        _ => body,
      };
}

class _MoonGocharaRule {
  const _MoonGocharaRule({
    required this.supportiveHouses,
    required this.challengingHouses,
    this.sourceRuleId = 'brihat_samhita.v2',
    this.sourceNameEn = 'Brihat Samhita Chapter 104',
    this.sourceNameBn = 'Brihat Samhita অধ্যায় 104',
  });

  final Set<int> supportiveHouses;
  final Set<int> challengingHouses;
  final String sourceRuleId;
  final String sourceNameEn;
  final String sourceNameBn;
}
