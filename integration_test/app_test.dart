import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talktive/app.dart';
import 'package:talktive/widgets/bubble.dart';

import 'setup.dart';

Future<void> main() async {
  await setup();

  final messageContent = DateTime.now().toIso8601String();

  group('App', () {
    testWidgets('walkthrough of Write, History & Read', (tester) async {
      await tester.pumpWidget(const App());
      await tester.pumpAndSettle();

      // Write

      final writeButtonFinder = find.widgetWithText(OutlinedButton, 'Write');
      expect(writeButtonFinder, findsOneWidget);

      await tester.tap(writeButtonFinder);
      await tester.pump(const Duration(seconds: 5));

      final textFieldFinder = find.byType(TextField);
      final sendButtonFinder = find.byIcon(Icons.send);
      expect(textFieldFinder, findsOneWidget);
      expect(sendButtonFinder, findsOneWidget);

      await tester.enterText(textFieldFinder, messageContent);
      await tester.tap(sendButtonFinder);
      await tester.pump(const Duration(seconds: 5));

      final bubbleFinder1 = find.widgetWithText(Bubble, messageContent);
      expect(bubbleFinder1, findsOneWidget);

      final backButtonFinder1 = find.byType(BackButton);
      expect(backButtonFinder1, findsOneWidget);

      await tester.tap(backButtonFinder1);
      await tester.pump(const Duration(seconds: 5));

      // History

      final historyButtonFinder = find.byIcon(Icons.history);
      expect(historyButtonFinder, findsOneWidget);

      await tester.tap(historyButtonFinder);
      await tester.pump(const Duration(seconds: 5));

      final listTileFinder = find.byType(ListTile);
      expect(listTileFinder, findsWidgets);

      await tester.tap(listTileFinder.first);
      await tester.pump(const Duration(seconds: 5));

      final bubbleFinder2 = find.widgetWithText(Bubble, messageContent);
      expect(bubbleFinder2, findsOneWidget);

      final backButtonFinder2 = find.byType(BackButton);
      expect(backButtonFinder2, findsOneWidget);

      await tester.tap(backButtonFinder2);
      await tester.pump(const Duration(seconds: 5));

      final backButtonFinder3 = find.byType(BackButton);
      expect(backButtonFinder3, findsOneWidget);

      await tester.tap(backButtonFinder3);
      await tester.pump(const Duration(seconds: 5));

      // Read

      final readButtonFinder = find.widgetWithText(FilledButton, 'Read');
      expect(readButtonFinder, findsOneWidget);

      await tester.tap(readButtonFinder);
      await tester.pump(const Duration(seconds: 5));

      final bubbleFinder3 = find.widgetWithText(Bubble, messageContent);
      expect(bubbleFinder3, findsNothing);

      final backButtonFinder4 = find.byType(BackButton);
      expect(backButtonFinder4, findsOneWidget);

      await tester.tap(backButtonFinder4);
      await tester.pump(const Duration(seconds: 5));
    });
  });
}
