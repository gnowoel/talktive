import 'package:talktive_client/talktive_client.dart';
import 'package:serverpod_client/serverpod_client.dart';
import 'package:serverpod_auth_client/serverpod_auth_client.dart';
import 'dart:convert';

void main() async {
  // 1. Initialize Client
  final keyManager = MyKeyManager();
  final client = Client(
    'http://localhost:8080/',
    authenticationKeyManager: keyManager,
  );

  try {
    print('1. Creating Resident...');
    // Create resident
    final jsonResult = await client.resident.createResident(
      name: 'TestUser',
      avatar: 'default',
      gender: 'unknown',
      country: 'US',
      bio: 'Test Bio',
    );
    print('Resident created: $jsonResult');

    // Parse result
    final map = jsonDecode(jsonResult);
    final key = map['key'] as String;
    // final keyId = map['keyId']; // unused
    final userInfoId = map['userInfoId'] as String;

    print('Created Resident: $userInfoId');
    print('Token: ${key.substring(0, 20)}...');

    // 3. Inject Key
    // For JWT, we just need the token.
    await keyManager.put(key);

    print('2. Sending Message...');
    // Send message to Plaza (Channel 1)
    await client.message.sendMessage(1, 'Hello World from script!');
    print('Message sent successfully!');
  } catch (e) {
    print('FAILED: $e');
  } finally {
    client.close();
  }
}

class MyKeyManager extends AuthenticationKeyManager {
  String? _key;
  @override
  Future<String?> get() async => _key;
  @override
  Future<void> put(String key) async => _key = key;
  @override
  Future<void> remove() async => _key = null;
  @override
  Future<String?> toHeaderValue(String? key) async => 'Bearer $key';
}
