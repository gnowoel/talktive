import 'package:flutter/foundation.dart';
import 'package:serverpod_auth_core_flutter/serverpod_auth_core_flutter.dart';
import 'package:serverpod_flutter/serverpod_flutter.dart';
import 'package:talktive_client/talktive_client.dart';
import 'providers/client_provider.dart';

/// Sets up a global client object that can be used to talk to the server from
/// anywhere in our app.
late final Client client;

/// Global session manager for authentication
late final FlutterAuthSessionManager sessionManager;

/// Initializes the global Serverpod client.
Future<void> initializeServerpodClient() async {
  // The server URL is fetched from the assets/config.json file.
  // final serverUrl = await getServerUrl();
  // Hardcoded for emulator/web loopback
  final serverUrl = kIsWeb ? 'http://localhost:8080' : 'http://10.0.2.2:8080';

  client = Client(serverUrl)
    ..connectivityMonitor = FlutterConnectivityMonitor();

  sessionManager = FlutterAuthSessionManager();
  client.authSessionManager = sessionManager;
  await sessionManager.initialize();
  initializeClient(client);
}
