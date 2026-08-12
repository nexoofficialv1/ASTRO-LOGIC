import 'package:astro_logic/src/screens/numerology_workspace_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows controlled bilingual-ready Numerology inputs',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('en'),
        home: NumerologyWorkspaceScreen(),
      ),
    );

    expect(find.text('Numerology Consultation Workspace'), findsOneWidget);
    expect(find.text('Exact English / Latin name spelling'), findsOneWidget);
    expect(find.text('Alternate spellings to compare'), findsOneWidget);
    expect(find.text('Select birth date'), findsOneWidget);
    expect(find.text('Personal Year target'), findsOneWidget);
    expect(find.text('Calculate and review Numerology'), findsOneWidget);
    expect(find.byType(DropdownButtonFormField<int>), findsOneWidget);
  });

  testWidgets('alternate-spelling field enforces the governed eight-candidate cap',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('en'),
        home: NumerologyWorkspaceScreen(),
      ),
    );

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Exact English / Latin name spelling'),
      'Test Name',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Alternate spellings to compare'),
      'Name A\nName B\nName C\nName D\nName E\nName F\nName G\nName H\nName I',
    );
    await tester.tap(find.text('Calculate and review Numerology'));
    await tester.pump();

    expect(find.text('Maximum 8'), findsOneWidget);
  });

  testWidgets('rejects silent Bengali-name transliteration in the UI',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('en'),
        home: NumerologyWorkspaceScreen(),
      ),
    );

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Exact English / Latin name spelling'),
      'বাপ্পা রায়',
    );
    await tester.tap(find.text('Calculate and review Numerology'));
    await tester.pump();

    expect(
      find.text(
        'Use only English letters, spaces, period, hyphen or apostrophe.',
      ),
      findsOneWidget,
    );
  });
}
