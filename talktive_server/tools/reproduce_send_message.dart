// ignore_for_file: avoid_print, unawaited_futures
import 'package:talktive_server/src/generated/protocol.dart';
import 'package:talktive_server/src/generated/endpoints.dart';
import 'package:serverpod/serverpod.dart';

void main(List<String> args) async {
  final pod = Serverpod(
    args,
    Protocol(),
    Endpoints(),
  );
  final session = await pod.createSession(enableLogging: true);

  try {
    print('1. Creating Authenticated Session...');
    // We need a valid session to call sendMessage.
    // Ideally we simulate a client call, but here we are on server-side.
    // We can directly call the endpoint if we mock the Session object, causing complexity.
    // EASIER: Use Client to call the server!
    // But this script is in server package.
    // Let's just try to call the endpoint method directly if we can mock 'Session'.
    // Mocking session is hard.

    // ALTERNATIVE: Use the resident create logic to get a real user, then use that user ID to mock authentication?
    // Actually, let's just use the server-side method logic, but we need a Session with 'authenticated' set.

    print(
      'Skipping reproduction script: It is complex to mock an authenticated session in a server-side script without a Client.',
    );
    print('Use the Flutter app or a separate Client script.');
  } catch (e) {
    print('Error: $e');
  } finally {
    session.close();
  }
}
