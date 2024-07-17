import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talktive/app.dart';
import 'package:talktive/services/firedata.dart';
import 'package:talktive/services/history.dart';

Future<void> main() async {
  TestWidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  const host = 'localhost';

  await FirebaseAuth.instance.useAuthEmulator(host, 9099);
  FirebaseDatabase.instance.useDatabaseEmulator(host, 9000);

  await History().loadRecords();
  Firedata().syncTime();

  group('app', () {
    testWidgets('Start the app', (tester) async {
      await tester.pumpWidget(const App());

      await tester.pumpAndSettle();

      expect(find.text('Read'), findsOneWidget);
      expect(find.text('Write'), findsOneWidget);
    });
  });
}
