import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talktive/app.dart';
import 'package:talktive/widgets/bubble.dart';

import 'setup.dart';

Future<void> main() async {
  await setup();

  final now = DateTime.now().toIso8601String();
  final firstLine = now.substring(0, 10);
  final secondLine = now.substring(11, 19);
  final newMessage = '$firstLine\n$secondLine';
  final newTopic = now.substring(now.length - 6);

  group('App', () {
    testWidgets('walkthrough of Write, History & Read', (tester) async {
      await tester.pumpWidget(const App());
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 2));

      // Avatar

      final refreshButtonFinder = find.byIcon(Icons.refresh);
      expect(refreshButtonFinder, findsOneWidget);

      await tester.tap(refreshButtonFinder);
      await tester.pumpFrames(const App(), const Duration(seconds: 2));

      // Write

      final writeButtonFinder = find.widgetWithText(OutlinedButton, 'Write');
      expect(writeButtonFinder, findsOneWidget);

      await tester.tap(writeButtonFinder);
      await tester.pumpFrames(const App(), const Duration(seconds: 2));

      final topicTextFinder1 = find.descendant(
        of: find.byType(AppBar),
        matching: find.byType(Text),
      );
      expect(topicTextFinder1, findsWidgets);

      await tester.tap(topicTextFinder1.first);
      await tester.pumpFrames(const App(), const Duration(seconds: 2));

      final topicFieldFinder = find.descendant(
        of: find.byType(AppBar),
        matching: find.byType(TextField),
      );
      final checkButtonFinder = find.byIcon(Icons.check);
      expect(topicFieldFinder, findsWidgets);
      expect(checkButtonFinder, findsOneWidget);

      await tester.enterText(topicFieldFinder.first, newTopic);
      await tester.pumpFrames(const App(), const Duration(seconds: 2));
      await tester.tap(checkButtonFinder);
      await tester.pumpFrames(const App(), const Duration(seconds: 2));

      final messageFieldFinder = find.byType(TextField);
      final sendButtonFinder = find.byIcon(Icons.send);
      expect(messageFieldFinder, findsOneWidget);
      expect(sendButtonFinder, findsOneWidget);

      await tester.enterText(messageFieldFinder, firstLine);
      await tester.pumpFrames(const App(), const Duration(seconds: 2));
      await tester.tap(sendButtonFinder);
      await tester.pumpFrames(const App(), const Duration(seconds: 2));

      await tester.enterText(messageFieldFinder, secondLine);
      await tester.pumpFrames(const App(), const Duration(seconds: 2));
      await tester.tap(sendButtonFinder);
      await tester.pumpFrames(const App(), const Duration(seconds: 2));

      final bubbleFinder1 = find.widgetWithText(Bubble, newMessage);
      expect(bubbleFinder1, findsOneWidget);

      final backButtonFinder1 = find.byType(BackButton);
      expect(backButtonFinder1, findsOneWidget);

      await tester.tap(backButtonFinder1);
      await tester.pumpFrames(const App(), const Duration(seconds: 2));

      // History

      final historyButtonFinder = find.byIcon(Icons.history);
      expect(historyButtonFinder, findsOneWidget);

      await tester.tap(historyButtonFinder);
      await tester.pumpFrames(const App(), const Duration(seconds: 2));

      final listTileFinder = find.byType(ListTile);
      final topicTextFinder2 = find.text(newTopic);
      expect(listTileFinder, findsWidgets);
      expect(topicTextFinder2, findsOneWidget);

      await tester.tap(listTileFinder.first);
      await tester.pumpFrames(const App(), const Duration(seconds: 2));

      final bubbleFinder2 = find.widgetWithText(Bubble, newMessage);
      expect(bubbleFinder2, findsOneWidget);

      final backButtonFinder2 = find.byType(BackButton);
      expect(backButtonFinder2, findsOneWidget);

      await tester.tap(backButtonFinder2);
      await tester.pumpFrames(const App(), const Duration(seconds: 2));

      final backButtonFinder3 = find.byType(BackButton);
      expect(backButtonFinder3, findsOneWidget);

      await tester.tap(backButtonFinder3);
      await tester.pumpFrames(const App(), const Duration(seconds: 2));

      // Read

      final readButtonFinder = find.widgetWithText(FilledButton, 'Read');
      expect(readButtonFinder, findsOneWidget);

      await tester.tap(readButtonFinder);
      await tester.pumpFrames(const App(), const Duration(seconds: 2));

      final bubbleFinder3 = find.widgetWithText(Bubble, newMessage);
      expect(bubbleFinder3, findsNothing);

      final backButtonFinder4 = find.byType(BackButton);
      expect(backButtonFinder4, findsOneWidget);

      await tester.tap(backButtonFinder4);
      await tester.pumpFrames(const App(), const Duration(seconds: 2));
    });
  });
}
