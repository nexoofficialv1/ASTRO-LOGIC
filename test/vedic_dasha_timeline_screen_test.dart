import 'package:astro_logic/src/models/kundli_analysis.dart';
import 'package:astro_logic/src/screens/vedic_dasha_timeline_screen.dart';
import 'package:astro_logic/src/vedic/pratyantardasha_interpretation_engine.dart';
import 'package:astro_logic/src/vedic/vimshottari_dasha_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows current, past and future Pratyantardasha filters',
      (tester) async {
    final vimshottari = VimshottariDashaEngine.calculate(
      moonSiderealLongitude: 354.0,
      birthUtc: DateTime.utc(1984, 3, 12, 18, 42),
    );

    final interpretations = PratyantardashaInterpretationEngine.build(
      rawVimshottari: vimshottari,
      profiles: _typedProfiles,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: VedicDashaTimelineScreen(
          vimshottari: vimshottari,
          timingWindows: const [],
          dashaActivationProfiles: _profiles,
          pratyantardashaInterpretations:
              interpretations.map((value) => value.toJson()).toList(),
        ),
      ),
    );

    expect(find.text('Vimshottari Dasha timeline'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) => widget is ChoiceChip &&
            (widget.label as Text).data!.startsWith('Current ('),
      ),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate(
        (widget) => widget is ChoiceChip &&
            (widget.label as Text).data!.startsWith('Past ('),
      ),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate(
        (widget) => widget is ChoiceChip &&
            (widget.label as Text).data!.startsWith('Future ('),
      ),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.play_circle_outline), findsOneWidget);

    await tester.tap(find.byIcon(Icons.account_tree_outlined).first);
    await tester.pumpAndSettle();
    expect(find.textContaining('Pratyantardasha own tendency'), findsOneWidget);
    expect(find.textContaining('Three-level Dasha synthesis'), findsOneWidget);
    expect(find.textContaining('Reinforced life areas'), findsOneWidget);
    expect(
      find.text('Detailed Pratyantardasha interpretation'),
      findsOneWidget,
    );
    expect(find.textContaining('Immediate trigger relation'), findsOneWidget);
  });
}

final _typedProfiles = <DashaActivationProfile>[
  for (final lord in <String>[
    'ketu',
    'venus',
    'sun',
    'moon',
    'mars',
    'rahu',
    'jupiter',
    'saturn',
    'mercury',
  ])
    DashaActivationProfile(
      lord: lord,
      score: 2,
      polarity: AnalysisPolarity.supportive,
      lifeAreas: const [LifeArea.career, LifeArea.finance],
      summaryEn: 'Chart-specific activation profile.',
      summaryBn: 'চার্টভিত্তিক সক্রিয়তা প্রোফাইল।',
      evidence: [
        ChartEvidence(
          ruleId: 'fixture.$lord',
          outputPath: r'$.fixture',
          kind: EvidenceKind.dasha,
          descriptionEn: '$lord fixture',
          descriptionBn: '$lord fixture',
        ),
      ],
    ),
];

final _profiles = <Map<String, Object?>>[
  for (final lord in <String>[
    'ketu',
    'venus',
    'sun',
    'moon',
    'mars',
    'rahu',
    'jupiter',
    'saturn',
    'mercury',
  ])
    {
      'lord': lord,
      'score': 2,
      'polarity': 'supportive',
      'lifeAreas': ['career', 'finance'],
      'summaryEn': 'Chart-specific activation profile.',
      'summaryBn': 'চার্টভিত্তিক সক্রিয়তা প্রোফাইল।',
      'evidence': <Object?>[],
    },
];
