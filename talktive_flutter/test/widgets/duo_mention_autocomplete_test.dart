import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:talktive/widgets/duo/duo_chat_input.dart';

void main() {
  setUpAll(() {
    Animate.defaultDuration = Duration.zero;
  });

  group('DuoChatInput Mention Autocomplete', () {
    late TextEditingController controller;

    setUp(() {
      controller = TextEditingController();
    });

    Widget buildTestWidget({List<String>? whitelist}) {
      return MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              const Spacer(),
              DuoChatInput(
                controller: controller,
                onSend: () {},
                mentionsWhitelist: whitelist,
              ),
            ],
          ),
        ),
      );
    }

    testWidgets('shows overlay when @ is typed', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestWidget(whitelist: ['Alice', 'Bob', 'Charlie']),
      );

      await tester.enterText(find.byType(TextField), '@');
      await tester.pumpAndSettle();

      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);
      expect(find.text('Charlie'), findsOneWidget);

      // Clear timers from animations
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('filters suggestions based on query', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildTestWidget(whitelist: ['Alice', 'Bob', 'Charlie']),
      );

      await tester.enterText(find.byType(TextField), '@Al');
      await tester.pumpAndSettle();

      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Bob'), findsNothing);
      expect(find.text('Charlie'), findsNothing);

      // Clear timers from animations
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('applies mention when selected', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestWidget(whitelist: ['Alice', 'Bob', 'Charlie']),
      );

      await tester.enterText(find.byType(TextField), 'Hello @Ali');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Alice'));
      await tester.pumpAndSettle();

      expect(controller.text, 'Hello @Alice ');
      expect(find.text('Alice'), findsNothing); // Overlay should be hidden

      // Clear timers from animations
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('hides overlay when space is typed and no match', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestWidget(whitelist: ['Alice', 'Bob']));

      await tester.enterText(find.byType(TextField), '@Unknown ');
      await tester.pumpAndSettle();

      expect(find.text('Alice'), findsNothing);
      expect(find.text('Bob'), findsNothing);

      // Clear timers from animations
      await tester.pump(const Duration(seconds: 1));
    });
  });
}
