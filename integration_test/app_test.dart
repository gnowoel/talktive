import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talktive/app.dart';
import 'package:talktive/widgets/bubble.dart';

import 'setup.dart';

Future<void> main() async {
  await setup();

  testWidgets('App', (tester) async {
    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();

    // Write

    final writeButtonFinder = find.widgetWithText(OutlinedButton, 'Write');
    expect(writeButtonFinder, findsOneWidget);

    await tester.tap(writeButtonFinder);
    await tester.pump(const Duration(seconds: 2));

    final textFieldFinder = find.byType(TextField);
    final sendButtonFinder = find.byIcon(Icons.send);
    expect(textFieldFinder, findsOneWidget);
    expect(sendButtonFinder, findsOneWidget);

    await tester.enterText(textFieldFinder, 'Hi!');
    await tester.tap(sendButtonFinder);
    await tester.pump(const Duration(seconds: 2));

    final bubbleFinder1 = find.widgetWithText(Bubble, 'Hi!');
    expect(bubbleFinder1, findsOneWidget);

    final backButtonFinder = find.byType(BackButton);
    expect(backButtonFinder, findsOneWidget);

    await tester.tap(backButtonFinder);
    await tester.pump(const Duration(seconds: 2));

    // Read

    final historyButtonFinder = find.byIcon(Icons.history);
    expect(historyButtonFinder, findsOneWidget);

    await tester.tap(historyButtonFinder);
    await tester.pump(const Duration(seconds: 2));

    final listTileFinder = find.byType(ListTile);
    expect(listTileFinder, findsWidgets);

    await tester.tap(listTileFinder.first);
    await tester.pump(const Duration(seconds: 2));

    final bubbleFinder2 = find.widgetWithText(Bubble, 'Hi!');
    expect(bubbleFinder2, findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
  });
}
