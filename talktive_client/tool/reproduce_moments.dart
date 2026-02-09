import 'dart:convert';
import 'package:talktive_client/talktive_client.dart';
import 'package:serverpod_client/serverpod_client.dart';

void main() async {
  // 1. Setup Client
  final keyManager = MyKeyManager();

  final client = Client(
    'http://localhost:8080/',
    authenticationKeyManager: keyManager,
  );

  print('1. Creating Resident...');
  try {
    // 2. Authenticate
    final jsonResult = await client.resident.createResident(
      name: 'MomentTester',
      avatar: 'https://i.pravatar.cc/150?u=moment',
      gender: 'robot',
      country: 'CA',
      bio: 'Testing moments',
    );

    final map = jsonDecode(jsonResult);
    final key = map['key'] as String;

    // Inject Key
    await keyManager.put(key);
    print('Authenticated as ${map['userInfoName']}');

    // 3. Post Moment
    print('2. Posting Moment...');
    final moment = await client.moment.postMoment(
      imageUrl: 'https://picsum.photos/seed/test/400/300',
      caption: 'Hello World from CLI!',
    );
    print('Moment Posted: ID ${moment.id}, Author: ${moment.authorName}');

    // 4. List Moments
    print('3. Listing Moments...');
    final moments = await client.moment.listMoments(limit: 20);
    print('Found ${moments.length} moments.');
    if (moments.isNotEmpty) {
      print(
        'Latest Moment: ${moments.first.caption} by ${moments.first.authorName}',
      );
    }
  } catch (e, st) {
    print('Error: $e');
    print(st);
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
  Future<String?> toHeaderValue(String? key) async {
    if (key == null) return null;
    return 'Bearer $key';
  }
}
