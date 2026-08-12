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
    expect(find.text('Cast native KP chart'), findsOneWidget);
    expect(find.text('Sidereal longitude (0°–<360°)'), findsOneWidget);
    expect(find.text('Ruling planets — review profile'), findsOneWidget);
    expect(find.text('12-cusp classification framework'), findsOneWidget);
  });

  testWidgets('manual point classifier remains available as cross-check', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(locale: Locale('en'), home: KpWorkspaceScreen()),
    );

    await tester.enterText(
      find.widgetWithText(TextField, 'Sidereal longitude (0°–<360°)'),
      '0.5',
    );
    await tester.tap(find.text('Classify sign / star / sub'));
    await tester.pump();

    expect(find.textContaining('Ashwini'), findsOneWidget);
    expect(find.textContaining('Sub lord: KETU'), findsOneWidget);
  });
}
