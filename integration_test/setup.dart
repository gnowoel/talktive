import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:integration_test/integration_test.dart';
import 'package:talktive/services/firedata.dart';
import 'package:talktive/services/history.dart';

Future<void> setup() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  const host = 'localhost';

  await FirebaseAuth.instance.useAuthEmulator(host, 9099);
  FirebaseDatabase.instance.useDatabaseEmulator(host, 9000);

  await History().loadRecords();
  Firedata().syncTime();
}
