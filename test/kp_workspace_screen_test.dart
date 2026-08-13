import 'package:astro_logic/src/screens/kp_workspace_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('KP native workspace exposes native and manual review tools', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('en'),
        home: KpWorkspaceScreen(),
      ),
    );

    expect(find.text('KP Native Chart Workspace'), findsOneWidget);
    expect(find.text('Native KP chart casting'), findsOneWidget);

    for (final label in const [
      'Cast native KP chart',
      'Sidereal longitude (0°–<360°)',
      'Ruling planets — review profile',
      '12-cusp classification framework',
    ]) {
      await tester.scrollUntilVisible(
        find.text(label),
        240,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text(label), findsOneWidget);
    }
  });

  testWidgets('manual point classifier remains available as cross-check', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(locale: Locale('en'), home: KpWorkspaceScreen()),
    );

    final longitudeField =
        find.widgetWithText(TextField, 'Sidereal longitude (0°–<360°)');
    await tester.scrollUntilVisible(
      longitudeField,
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(longitudeField, '0.5');
    final classifyButton = find.text('Classify sign / star / sub');
    await tester.scrollUntilVisible(
      classifyButton,
      160,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(classifyButton);
    await tester.pump();

    final ashvini = find.textContaining('Ashwini');
    await tester.scrollUntilVisible(
      ashvini,
      120,
      scrollable: find.byType(Scrollable).first,
    );
    expect(ashvini, findsOneWidget);
    expect(find.textContaining('Sub lord: KETU'), findsOneWidget);
  });
}
