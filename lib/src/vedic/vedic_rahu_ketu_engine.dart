import '../models/calculation_output_snapshot.dart';
import '../models/kundli_analysis.dart';

/// Source-bounded Rahu/Ketu review.
///
/// v1 keeps four layers distinct:
/// 1) natal whole-sign house themes from Phaladeepika VIII.25-34,
/// 2) explicit same-sign association/dispositor context,
/// 3) bounded node-Dasha modifiers from Phaladeepika XX.39, 52-53,
/// 4) unsupported node dignity/aspect/exaltation conventions remain gated.
///
/// The engine never emits High confidence and does not infer medical,
/// mortality, legal, financial or relationship events from a node alone.
class VedicRahuKetuEngine {
  const VedicRahuKetuEngine();

  static const engineVersion = '1.0.0';
  static const ruleProfile = 'rahu-ketu-analysis-v1';

  List<ChartFinding> build(CalculationOutputSnapshot calculationOutput) {
    if (!calculationOutput.outputSchemaVersion.startsWith('vedic-chart-v')) {
      throw ArgumentError('Rahu/Ketu review requires a Vedic chart output');
    }
    final ascendant = _requiredMap(
      calculationOutput.output['ascendant'],
      'ascendant',
    );
    final ascendantSign = _requiredSignIndex(
      ascendant['signIndex'],
      'ascendant.signIndex',
    );
    final planets = _requiredPlanets(calculationOutput.output['planets']);
    for (final body in const ['rahu', 'ketu', ..._classicalPlanets]) {
      if (!planets.containsKey(body)) {
        throw StateError('Rahu/Ketu review is missing $body');
      }
    }

    final paksha = _paksha(calculationOutput.output['panchanga']);
    return [
      _natalFinding('rahu', ascendantSign, planets, paksha),
      _natalFinding('ketu', ascendantSign, planets, paksha),
    ];
  }

  NodeDashaAdjustment buildDashaAdjustment(NodeDashaContext context) {
    if (context.node != 'rahu' && context.node != 'ketu') {
      throw ArgumentError('Node Dasha adjustment requires Rahu or Ketu');
    }
    if (context.nodeSign < 0 || context.nodeSign > 11) {
      throw ArgumentError('nodeSign must be 0..11');
    }
    if (context.nodeHouse < 1 || context.nodeHouse > 12) {
      throw ArgumentError('nodeHouse must be 1..12');
    }

    final associations = context.classicalPlanets
        .where((value) => value.signIndex == context.nodeSign)
        .toList(growable: false);
    final evidence = <ChartEvidence>[];
    var modifier = 0;
    var internalConflict = false;
    final reasonsEn = <String>[];
    final reasonsBn = <String>[];

    if (associations.isNotEmpty) {
      evidence.add(
        ChartEvidence(
          ruleId: 'vedic.node.dasha.same_sign_association.v1.${context.node}',
          outputPath: r'$.planets[*].signIndex',
          kind: EvidenceKind.dasha,
          descriptionEn:
              '${_planetEn[context.node]} shares its sign with ${associations.map((value) => _planetEn[value.body]).join(', ')}; v1 treats only explicit same-sign contact as node association.',
          descriptionBn:
              '${_planetBn[context.node]} একই রাশিতে ${associations.map((value) => _planetBn[value.body]).join(', ')}-এর সঙ্গে রয়েছে; v1-এ শুধু explicit same-sign contact-কে node association ধরা হয়।',
        ),
      );
    }

    // Phaladeepika XX.39 explicitly assigns Rahu the good/bad nature of the
    // planet with which it associates. v1 deliberately does not extend that
    // exact statement to Ketu.
    if (context.node == 'rahu' && associations.isNotEmpty) {
      final positive = associations.where((value) => value.activationScore > 0);
      final negative = associations.where((value) => value.activationScore < 0);
      if (positive.isNotEmpty && negative.isNotEmpty) {
        internalConflict = true;
        reasonsEn.add('associated classical planets carry opposite Dasha directions');
        reasonsBn.add('যুক্ত classical গ্রহগুলো বিপরীত দশা-দিক বহন করছে');
      } else if (positive.isNotEmpty) {
        modifier += 1;
        reasonsEn.add('Rahu association is supported by a positive carrier profile');
        reasonsBn.add('রাহুর সংযোগে positive carrier profile রয়েছে');
      } else if (negative.isNotEmpty) {
        modifier -= 1;
        reasonsEn.add('Rahu association carries a challenging carrier profile');
        reasonsBn.add('রাহুর সংযোগ challenging carrier profile বহন করছে');
      }
      evidence.add(
        ChartEvidence(
          ruleId: 'vedic.node.dasha.rahu.associated_planet.phaladeepika20.39.v1',
          outputPath: r'$.planets[*]',
          kind: EvidenceKind.dasha,
          descriptionEn:
              'Phaladeepika XX.39 is applied conservatively: Rahu follows the enabled good/challenging direction of explicitly associated classical planets; conflicting carriers remain Mixed.',
          descriptionBn:
              'Phaladeepika XX.39 রক্ষণশীলভাবে প্রয়োগ করা হয়েছে: explicit associated classical গ্রহের enabled শুভ/চ্যালেঞ্জিং দিক রাহুর review-এ আসে; বিপরীত carrier থাকলে ফল Mixed থাকে।',
        ),
      );
    }

    final kendraTrikonaCandidate = _kendraTrikonaHouses.contains(context.nodeHouse) &&
        associations.any(
          (value) => value.ownedHouses.any((house) => _kendraTrikonaHouses.contains(house)),
        );
    if (kendraTrikonaCandidate) {
      modifier += 1;
      reasonsEn.add('node is in a Kendra/Trikona and explicitly associated with a Kendra/Trikona lord');
      reasonsBn.add('নোড কেন্দ্র/ত্রিকোণে থেকে কেন্দ্র/ত্রিকোণ অধিপতির সঙ্গে explicit যুক্ত');
      evidence.add(
        ChartEvidence(
          ruleId: 'vedic.node.dasha.kendra_trikona_connection.phaladeepika20.52.v1',
          outputPath: r'$.planets[*]',
          kind: EvidenceKind.dasha,
          descriptionEn:
              'Phaladeepika XX.52 node Yogakaraka potential is recorded only as a Medium-capped candidate using same-sign association as the v1 connection convention.',
          descriptionBn:
              'Phaladeepika XX.52-এর node Yogakaraka সম্ভাবনা v1 same-sign association convention ব্যবহার করে শুধু Medium-capped candidate হিসেবে রাখা হয়েছে।',
        ),
      );
    }

    final beneficOwnedConnected = _unconditionalBeneficOwners.contains(context.dispositor) &&
        associations.isNotEmpty;
    if (beneficOwnedConnected) {
      modifier += 1;
      reasonsEn.add('node occupies a sign owned by an enabled natural benefic and has explicit association');
      reasonsBn.add('নোড enabled natural benefic-এর রাশিতে থেকে explicit সংযোগে আছে');
      evidence.add(
        ChartEvidence(
          ruleId: 'vedic.node.dasha.benefic_sign_connection.phaladeepika20.53.v1',
          outputPath: r'$.planets[*]',
          kind: EvidenceKind.dasha,
          descriptionEn:
              'Phaladeepika XX.53 is enabled for Mercury/Jupiter/Venus-owned signs with explicit same-sign association. Moon-owned signs remain gated in v1 because waxing/waning benefic status is not folded into this Dasha helper.',
          descriptionBn:
              'Phaladeepika XX.53 v1-এ বুধ/বৃহস্পতি/শুক্র-অধিষ্ঠিত রাশি ও explicit same-sign association-এর জন্য সক্রিয়। চন্দ্রের waxing/waning benefic status এই Dasha helper-এ না থাকায় Moon-owned sign gated।',
        ),
      );
    }

    return NodeDashaAdjustment(
      scoreModifier: modifier,
      internalConflict: internalConflict,
      summaryEn: reasonsEn.isEmpty
          ? 'No additional source-bounded node-Dasha association modifier is enabled.'
          : 'Node-Dasha review: ${reasonsEn.join('; ')}.',
      summaryBn: reasonsBn.isEmpty
          ? 'অতিরিক্ত source-bounded node-Dasha association modifier সক্রিয় নয়।'
          : 'Node-Dasha review: ${reasonsBn.join('; ')}।',
      evidence: List.unmodifiable(evidence),
    );
  }

  ChartFinding _natalFinding(
    String node,
    int ascendantSign,
    Map<String, _NodePlanet> planets,
    String? paksha,
  ) {
    final position = planets[node]!;
    final house = _houseFrom(ascendantSign, position.signIndex);
    final profile = (node == 'rahu' ? _rahuHouseProfiles : _ketuHouseProfiles)[house]!;
    final dispositor = _signLords[position.signIndex]!;
    final associates = _classicalPlanets
        .where((body) => planets[body]!.signIndex == position.signIndex)
        .toList(growable: false);
    final beneficOwner = _isBeneficOwner(dispositor, paksha);
    final kendraTrikonaConnection = _kendraTrikonaHouses.contains(house) &&
        associates.any(
          (body) => _ownedHouses(ascendantSign, body).any((house) => _kendraTrikonaHouses.contains(house)),
        );
    final beneficSignConnection = beneficOwner && associates.isNotEmpty;

    var polarity = profile.polarity;
    if ((kendraTrikonaConnection || beneficSignConnection) &&
        profile.polarity == AnalysisPolarity.challenging) {
      polarity = AnalysisPolarity.mixed;
    }
    final confidence = polarity == AnalysisPolarity.supportive
        ? AnalysisConfidence.medium
        : AnalysisConfidence.low;
    final nodeEn = _planetEn[node]!;
    final nodeBn = _planetBn[node]!;
    final sourceVerse = node == 'rahu' ? 'VIII.25-27' : 'VIII.28-33';

    final modifiersEn = <String>[
      'sign dispositor ${_planetEn[dispositor]}',
      if (associates.isNotEmpty)
        'same-sign association with ${associates.map((value) => _planetEn[value]).join(', ')}',
      if (kendraTrikonaConnection)
        'Phaladeepika XX.52 Kendra/Trikona connection candidate',
      if (beneficSignConnection)
        'Phaladeepika XX.53 benefic-sign association candidate',
    ];
    final modifiersBn = <String>[
      'রাশিপতি ${_planetBn[dispositor]}',
      if (associates.isNotEmpty)
        'একই রাশিতে ${associates.map((value) => _planetBn[value]).join(', ')}-এর সংযোগ',
      if (kendraTrikonaConnection)
        'Phaladeepika XX.52 কেন্দ্র/ত্রিকোণ সংযোগ candidate',
      if (beneficSignConnection)
        'Phaladeepika XX.53 benefic-sign association candidate',
    ];

    return ChartFinding(
      code: 'vedic.node.natal.$node.house$house.v1',
      area: _houseLifeAreas[house] ?? LifeArea.overall,
      polarity: polarity,
      confidence: confidence,
      titleEn: '$nodeEn natal house $house review',
      titleBn: '$nodeBn জন্মছকে $house নম্বর ভাব পর্যালোচনা',
      narrativeEn:
          '$nodeEn occupies whole-sign house $house. The enabled Phaladeepika $sourceVerse profile is paraphrased as: ${profile.themeEn}. Additional context: ${modifiersEn.join('; ')}. Rahu/Ketu dignity, exaltation/debilitation and node aspects are not invented in v1. This is a symbolic review layer only; no medical, mortality, legal, financial or relationship event is inferred from the node alone.',
      narrativeBn:
          '$nodeBn হোল-সাইন $house নম্বর ভাবে রয়েছে। সক্রিয় Phaladeepika $sourceVerse profile-এর সংক্ষিপ্ত ভাব: ${profile.themeBn}। অতিরিক্ত context: ${modifiersBn.join('; ')}। v1-এ Rahu/Ketu-এর dignity, exaltation/debilitation বা node aspect বানিয়ে নেওয়া হয়নি। এটি শুধু symbolic review layer; একা node দেখে চিকিৎসা, মৃত্যু, আইন, অর্থ বা সম্পর্কের ঘটনা নির্ধারণ করা হয় না।',
      evidence: [
        ChartEvidence(
          ruleId: 'vedic.node.natal.$node.phaladeepika8.house$house.v1',
          outputPath: r'$.planets[?(@.body=="' + node + r'")].signIndex',
          kind: EvidenceKind.placement,
          descriptionEn:
              '$nodeEn occupies house $house from Lagna under the source-bounded Phaladeepika VIII node-house profile.',
          descriptionBn:
              'Source-bounded Phaladeepika VIII node-house profile অনুযায়ী $nodeBn লগ্ন থেকে $house নম্বর ভাবে রয়েছে।',
        ),
        ChartEvidence(
          ruleId: 'vedic.node.natal.dispositor.v1.$node.$dispositor',
          outputPath: r'$.planets[?(@.body=="' + node + r'")].signIndex',
          kind: EvidenceKind.lordship,
          descriptionEn:
              '${_planetEn[dispositor]} is the sign dispositor; v1 records it as context, not as a fabricated node dignity.',
          descriptionBn:
              '${_planetBn[dispositor]} রাশিপতি; v1-এ এটি context হিসেবে থাকে, fabricated node dignity হিসেবে নয়।',
        ),
        if (kendraTrikonaConnection)
          ChartEvidence(
            ruleId: 'vedic.node.natal.kendra_trikona_connection.phaladeepika20.52.v1',
            outputPath: r'$.planets[*]',
            kind: EvidenceKind.yoga,
            descriptionEn:
                '$nodeEn is in a Kendra/Trikona and has an explicit same-sign connection with a Kendra/Trikona lord; this is recorded as candidate potential only.',
            descriptionBn:
                '$nodeBn কেন্দ্র/ত্রিকোণে থেকে কেন্দ্র/ত্রিকোণ অধিপতির সঙ্গে explicit same-sign সংযোগে আছে; এটি শুধু candidate সম্ভাবনা হিসেবে নথিভুক্ত।',
          ),
        if (beneficSignConnection)
          ChartEvidence(
            ruleId: 'vedic.node.natal.benefic_sign_connection.phaladeepika20.53.v1',
            outputPath: r'$.planets[*]',
            kind: EvidenceKind.yoga,
            descriptionEn:
                '$nodeEn occupies a sign whose owner is benefic under the enabled v1 condition and has explicit same-sign association; the result remains review-only.',
            descriptionBn:
                '$nodeBn enabled v1 condition অনুযায়ী benefic-owned রাশিতে থেকে explicit same-sign সংযোগে আছে; ফল review-only থাকে।',
          ),
      ],
    );
  }

  bool _isBeneficOwner(String owner, String? paksha) {
    if (_unconditionalBeneficOwners.contains(owner)) return true;
    return owner == 'moon' && paksha == 'shukla';
  }

  String? _paksha(Object? raw) {
    if (raw is! Map) return null;
    final value = raw['paksha'];
    return value == 'shukla' || value == 'krishna' ? value as String : null;
  }

  Map<String, _NodePlanet> _requiredPlanets(Object? raw) {
    if (raw is! List) throw StateError('Vedic output is missing planets');
    final result = <String, _NodePlanet>{};
    for (final item in raw) {
      if (item is! Map) continue;
      final body = item['body'];
      final signIndex = item['signIndex'];
      if (body is! String || signIndex is! int || signIndex < 0 || signIndex > 11) {
        continue;
      }
      result[body] = _NodePlanet(signIndex);
    }
    return result;
  }

  Map<String, Object?> _requiredMap(Object? raw, String label) {
    if (raw is! Map) throw StateError('Vedic output is missing $label');
    return Map<String, Object?>.from(raw);
  }

  int _requiredSignIndex(Object? raw, String label) {
    if (raw is! int || raw < 0 || raw > 11) {
      throw StateError('Vedic output has invalid $label');
    }
    return raw;
  }

  int _houseFrom(int referenceSign, int targetSign) =>
      ((targetSign - referenceSign + 12) % 12) + 1;

  List<int> _ownedHouses(int ascendantSign, String planet) {
    final result = <int>[];
    for (var sign = 0; sign < 12; sign += 1) {
      if (_signLords[sign] == planet) {
        result.add(_houseFrom(ascendantSign, sign));
      }
    }
    return result;
  }

  static const _classicalPlanets = <String>[
    'sun',
    'moon',
    'mars',
    'mercury',
    'jupiter',
    'venus',
    'saturn',
  ];
  static const _kendraTrikonaHouses = <int>{1, 4, 5, 7, 9, 10};
  static const _unconditionalBeneficOwners = <String>{
    'mercury',
    'jupiter',
    'venus',
  };
  static const _signLords = <int, String>{
    0: 'mars',
    1: 'venus',
    2: 'mercury',
    3: 'moon',
    4: 'sun',
    5: 'mercury',
    6: 'venus',
    7: 'mars',
    8: 'jupiter',
    9: 'saturn',
    10: 'saturn',
    11: 'jupiter',
  };

  static const _planetEn = <String, String>{
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
  static const _planetBn = <String, String>{
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

  static const _houseLifeAreas = <int, LifeArea>{
    1: LifeArea.self,
    2: LifeArea.finance,
    3: LifeArea.communication,
    4: LifeArea.property,
    5: LifeArea.children,
    6: LifeArea.obstacles,
    7: LifeArea.marriage,
    8: LifeArea.longevity,
    9: LifeArea.fortune,
    10: LifeArea.career,
    11: LifeArea.gains,
    12: LifeArea.expenses,
  };

  static const _rahuHouseProfiles = <int, _NodeHouseProfile>{
    1: _NodeHouseProfile(AnalysisPolarity.challenging, 'identity and physical-stability themes require caution', 'স্ব-পরিচয় ও শারীরিক স্থিতির বিষয়ে সতর্ক review'),
    2: _NodeHouseProfile(AnalysisPolarity.mixed, 'speech/finance themes are mixed: strain can coexist with material access', 'বাক্/অর্থের ফল মিশ্র: চাপের সঙ্গে material access-ও থাকতে পারে'),
    3: _NodeHouseProfile(AnalysisPolarity.supportive, 'initiative, resolve and material-gain themes are comparatively supportive', 'উদ্যোগ, দৃঢ়তা ও material gain তুলনামূলক সহায়ক'),
    4: _NodeHouseProfile(AnalysisPolarity.mixed, 'home/happiness themes are unstable or mixed', 'গৃহ/সুখের ক্ষেত্র অস্থির বা মিশ্র'),
    5: _NodeHouseProfile(AnalysisPolarity.challenging, 'children/intellect/creative themes require caution', 'সন্তান/বুদ্ধি/সৃজনশীলতার ক্ষেত্রে সতর্কতা দরকার'),
    6: _NodeHouseProfile(AnalysisPolarity.mixed, 'competition and resilience can improve while health/conflict themes remain review points', 'প্রতিযোগিতা ও সহনশীলতা বাড়তে পারে, তবে স্বাস্থ্য/বিরোধ review point থাকে'),
    7: _NodeHouseProfile(AnalysisPolarity.challenging, 'partnership and relationship stability require caution', 'অংশীদারিত্ব ও সম্পর্কের স্থিতিতে সতর্কতা দরকার'),
    8: _NodeHouseProfile(AnalysisPolarity.challenging, 'disruption, vulnerability and transformation themes are emphasized', 'বিঘ্ন, দুর্বলতা ও রূপান্তরের থিম জোরালো'),
    9: _NodeHouseProfile(AnalysisPolarity.mixed, 'authority/leadership potential coexists with dharma/belief tension', 'কর্তৃত্ব/নেতৃত্বের সম্ভাবনার সঙ্গে ধর্ম/বিশ্বাসের টানাপোড়েন থাকতে পারে'),
    10: _NodeHouseProfile(AnalysisPolarity.mixed, 'visibility and fearlessness can coexist with questionable or diverted action', 'খ্যাতি ও নির্ভীকতার সঙ্গে কর্মে বিচ্যুতি/দ্বন্দ্ব থাকতে পারে'),
    11: _NodeHouseProfile(AnalysisPolarity.supportive, 'gains, longevity and prosperity themes are comparatively supportive', 'লাভ, স্থায়িত্ব ও সমৃদ্ধির থিম তুলনামূলক সহায়ক'),
    12: _NodeHouseProfile(AnalysisPolarity.challenging, 'expense, secrecy and withdrawal themes require caution', 'ব্যয়, গোপনতা ও বিচ্ছিন্নতার থিমে সতর্কতা দরকার'),
  };

  static const _ketuHouseProfiles = <int, _NodeHouseProfile>{
    1: _NodeHouseProfile(AnalysisPolarity.challenging, 'identity, belonging and physical-stability themes require caution', 'স্ব-পরিচয়, সামাজিক সংযুক্তি ও শারীরিক স্থিতিতে সতর্কতা দরকার'),
    2: _NodeHouseProfile(AnalysisPolarity.challenging, 'speech, learning and finance themes require caution', 'বাক্, শিক্ষা ও অর্থের ক্ষেত্রে সতর্কতা দরকার'),
    3: _NodeHouseProfile(AnalysisPolarity.supportive, 'courage, strength, recognition and resources are comparatively supported', 'সাহস, শক্তি, পরিচিতি ও সম্পদ তুলনামূলক সহায়ক'),
    4: _NodeHouseProfile(AnalysisPolarity.challenging, 'home, property and rootedness themes can be unsettled', 'গৃহ, সম্পত্তি ও স্থায়িত্বের ক্ষেত্রে অস্থিরতা থাকতে পারে'),
    5: _NodeHouseProfile(AnalysisPolarity.challenging, 'children, judgment and creative themes require caution', 'সন্তান, বিচারবোধ ও সৃজনশীলতার ক্ষেত্রে সতর্কতা দরকার'),
    6: _NodeHouseProfile(AnalysisPolarity.supportive, 'resilience, authority and overcoming-opposition themes are comparatively supportive', 'সহনশীলতা, কর্তৃত্ব ও বাধা অতিক্রমের থিম তুলনামূলক সহায়ক'),
    7: _NodeHouseProfile(AnalysisPolarity.challenging, 'partnership and relationship stability require caution', 'অংশীদারিত্ব ও সম্পর্কের স্থিতিতে সতর্কতা দরকার'),
    8: _NodeHouseProfile(AnalysisPolarity.challenging, 'disruption, conflict and setback themes are emphasized', 'বিঘ্ন, সংঘাত ও setback-এর থিম জোরালো'),
    9: _NodeHouseProfile(AnalysisPolarity.challenging, 'fortune, mentors and belief/dharma themes require caution', 'ভাগ্য, গুরু ও ধর্ম/বিশ্বাসের ক্ষেত্রে সতর্কতা দরকার'),
    10: _NodeHouseProfile(AnalysisPolarity.mixed, 'career action can be forceful/visible while ethical or procedural obstacles remain', 'কর্মে শক্তি/খ্যাতি থাকতে পারে, তবে নৈতিক বা প্রক্রিয়াগত বাধা review point'),
    11: _NodeHouseProfile(AnalysisPolarity.supportive, 'gains, resources and fulfilment themes are comparatively supportive', 'লাভ, সম্পদ ও প্রাপ্তির থিম তুলনামূলক সহায়ক'),
    12: _NodeHouseProfile(AnalysisPolarity.challenging, 'expense, secrecy and withdrawal themes require caution', 'ব্যয়, গোপনতা ও বিচ্ছিন্নতার ক্ষেত্রে সতর্কতা দরকার'),
  };
}

class NodeDashaContext {
  const NodeDashaContext({
    required this.node,
    required this.ascendantSign,
    required this.nodeSign,
    required this.nodeHouse,
    required this.dispositor,
    required this.classicalPlanets,
  });

  final String node;
  final int ascendantSign;
  final int nodeSign;
  final int nodeHouse;
  final String dispositor;
  final List<NodeDashaPlanetContext> classicalPlanets;
}

class NodeDashaPlanetContext {
  const NodeDashaPlanetContext({
    required this.body,
    required this.signIndex,
    required this.activationScore,
    required this.ownedHouses,
  });

  final String body;
  final int signIndex;
  final int activationScore;
  final List<int> ownedHouses;
}

class NodeDashaAdjustment {
  const NodeDashaAdjustment({
    required this.scoreModifier,
    required this.internalConflict,
    required this.summaryEn,
    required this.summaryBn,
    required this.evidence,
  });

  final int scoreModifier;
  final bool internalConflict;
  final String summaryEn;
  final String summaryBn;
  final List<ChartEvidence> evidence;
}

class _NodePlanet {
  const _NodePlanet(this.signIndex);
  final int signIndex;
}

class _NodeHouseProfile {
  const _NodeHouseProfile(this.polarity, this.themeEn, this.themeBn);
  final AnalysisPolarity polarity;
  final String themeEn;
  final String themeBn;
}
