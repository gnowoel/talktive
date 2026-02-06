import 'dart:convert';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_server/serverpod_auth_server.dart';
import '../generated/protocol.dart';

class ResidentEndpoint extends Endpoint {
  /// Creates a new anonymous resident/user and returns the authentication key as JSON string
  Future<String> createResident(
    Session session, {
    required String name,
    required String avatar,
    required String gender,
    required String country,
    required String bio,
  }) async {
    // Simplified ID generation
    final randomId = DateTime.now().microsecondsSinceEpoch.toString();
    final email = 'user_$randomId@anonymous.talktive.com';

    final userInfo = await Users.createUser(
      session,
      UserInfo(
        userIdentifier: email,
        email: email,
        userName: name,
        created: DateTime.now(),
        scopeNames: [],
        blocked: false,
      ),
    );

    if (userInfo == null) {
      throw Exception('Failed to create user');
    }

    // 2. Create Resident (Our Logic)
    final resident = Resident(
      userInfoId: userInfo.id!,
      floor: 1, // Default to Floor 1
      creditScore: 100, // Default Credit
      experienceMessageCount: 0,
    );
    // Check for orphan resident (zombie data from previous DB wipes)
    final existing = await Resident.db.findFirstRow(
      session,
      where: (t) => t.userInfoId.equals(userInfo.id!),
    );
    if (existing != null) {
      print('Found orphan resident for user ${userInfo.id!}. Deleting...');
      await Resident.db.deleteRow(session, existing);
    }

    try {
      print('Attempting to insert resident for user: ${userInfo.id}');
      await Resident.db.insertRow(session, resident);
      print('Resident inserted successfully');
    } catch (e, stack) {
      print('FAILED to insert resident: $e');
      print(stack);
      rethrow;
    }

    // 3. Create Session / Auth Key
    final authKey = await UserAuthentication.signInUser(
      session,
      userInfo.id!,
      'default', // method
      scopes: {Scope.admin},
    );

    if (authKey == null) {
      throw Exception('Failed to generate auth token');
    }

    // Serialize to JSON using local userInfo variable as authKey might not contain it
    final map = {
      'key': authKey.key,
      'keyId': authKey.id,
      'userInfoId': userInfo.id,
      'userInfoName': userInfo.userName,
      'userInfoEmail': userInfo.email,
      'created': userInfo.created.toIso8601String(),
    };

    return jsonEncode(map);
  }
}
