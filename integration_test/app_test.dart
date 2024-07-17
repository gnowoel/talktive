import 'package:flutter_test/flutter_test.dart';
import 'package:talktive/app.dart';

import 'setup.dart';

Future<void> main() async {
  await setup();

  group('app', () {
    testWidgets('Start the app', (tester) async {
      await tester.pumpWidget(const App());

      await tester.pumpAndSettle();

      expect(find.text('Read'), findsOneWidget);
      expect(find.text('Write'), findsOneWidget);
    });
  });
}
