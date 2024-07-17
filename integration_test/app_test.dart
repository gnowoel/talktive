import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talktive/app.dart';
import 'package:talktive/widgets/bubble.dart';

import 'setup.dart';

Future<void> main() async {
  await setup();

  group('Talktive', () {
    testWidgets('walkthrough', (tester) async {
      await tester.pumpWidget(const App());
      await tester.pumpAndSettle();

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

      final bubbleFinder = find.widgetWithText(Bubble, 'Hi!');
      expect(bubbleFinder, findsOneWidget);
    });
  });
}
