import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talktive/widgets/heart_list.dart';

void main() {
  const fullHeartIcon = Icons.favorite;
  const halfHeartIcon = Icons.heart_broken;
  const emptyHeartIcon = Icons.favorite_outline;

  group('Health', () {
    testWidgets('3 hearts within 1 minute', (tester) async {
      const elapsed = Duration(seconds: 59);

      await tester.pumpWidget(
        const MaterialApp(
          home: HeartList(elapsed: elapsed),
        ),
      );
      await tester.pumpAndSettle();

      final fullHeartFinder = find.byIcon(fullHeartIcon);

      expect(fullHeartFinder, findsNWidgets(3));
    });

    testWidgets('2.5 hearts within 2 minutes', (tester) async {
      const elapsed = Duration(seconds: 60 + 59);

      await tester.pumpWidget(
        const MaterialApp(
          home: HeartList(elapsed: elapsed),
        ),
      );
      await tester.pumpAndSettle();

      final halfHeartFinder = find.byIcon(halfHeartIcon);
      final fullHeartFinder = find.byIcon(fullHeartIcon);

      expect(halfHeartFinder, findsNWidgets(1));
      expect(fullHeartFinder, findsNWidgets(2));
    });

    testWidgets('2 hearts within 3 minutes', (tester) async {
      const elapsed = Duration(seconds: 60 * 2 + 59);

      await tester.pumpWidget(
        const MaterialApp(
          home: HeartList(elapsed: elapsed),
        ),
      );
      await tester.pumpAndSettle();

      final emptyHeartFinder = find.byIcon(emptyHeartIcon);
      final fullHeartFinder = find.byIcon(fullHeartIcon);

      expect(emptyHeartFinder, findsNWidgets(1));
      expect(fullHeartFinder, findsNWidgets(2));
    });

    testWidgets('1.5 hearts within 4 minutes', (tester) async {
      const elapsed = Duration(seconds: 60 * 3 + 59);

      await tester.pumpWidget(
        const MaterialApp(
          home: HeartList(elapsed: elapsed),
        ),
      );
      await tester.pumpAndSettle();

      final emptyHeartFinder = find.byIcon(emptyHeartIcon);
      final halfHeartFinder = find.byIcon(halfHeartIcon);
      final fullHeartFinder = find.byIcon(fullHeartIcon);

      expect(emptyHeartFinder, findsNWidgets(1));
      expect(halfHeartFinder, findsNWidgets(1));
      expect(fullHeartFinder, findsNWidgets(1));
    });

    testWidgets('1 heart within 5 minutes', (tester) async {
      const elapsed = Duration(seconds: 60 * 4 + 59);

      await tester.pumpWidget(
        const MaterialApp(
          home: HeartList(elapsed: elapsed),
        ),
      );
      await tester.pumpAndSettle();

      final emptyHeartFinder = find.byIcon(emptyHeartIcon);
      final fullHeartFinder = find.byIcon(fullHeartIcon);

      expect(emptyHeartFinder, findsNWidgets(2));
      expect(fullHeartFinder, findsNWidgets(1));
    });

    testWidgets('0.5 hearts within 6 minutes', (tester) async {
      const elapsed = Duration(seconds: 60 * 5 + 59);

      await tester.pumpWidget(
        const MaterialApp(
          home: HeartList(elapsed: elapsed),
        ),
      );
      await tester.pumpAndSettle();

      final emptyHeartFinder = find.byIcon(emptyHeartIcon);
      final halfHeartFinder = find.byIcon(halfHeartIcon);

      expect(emptyHeartFinder, findsNWidgets(2));
      expect(halfHeartFinder, findsNWidgets(1));
    });

    testWidgets('0 hearts after 6 minutes', (tester) async {
      const elapsed = Duration(seconds: 60 * 6);

      await tester.pumpWidget(
        const MaterialApp(
          home: HeartList(elapsed: elapsed),
        ),
      );
      await tester.pumpAndSettle();

      final emptyHeartFinder = find.byIcon(emptyHeartIcon);

      expect(emptyHeartFinder, findsNWidgets(3));
    });
  });
}
