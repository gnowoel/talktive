import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';
import 'package:serverpod_flutter/serverpod_flutter.dart';
import 'package:talktive_client/talktive_client.dart';
import 'providers/client_provider.dart';

/// Sets up a global client object that can be used to talk to the server from
/// anywhere in our app.
late final Client client;

/// Initializes the global Serverpod client.
Future<void> initializeServerpodClient() async {
  // The server URL is fetched from the assets/config.json file.
  final serverUrl = await getServerUrl();

  client = Client(serverUrl)
    ..connectivityMonitor = FlutterConnectivityMonitor()
    ..authSessionManager = FlutterAuthSessionManager();

  await client.auth.initialize();
  initializeClient(client);
}
