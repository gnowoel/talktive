import 'dart:convert';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart';
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
    // 1. Create Auth User (New UUID-based Auth System)
    // We use generic 'admin' scope for now similar to legacy, or empty.
    final authUser = await AuthServices.instance.authUsers.create(
      session,
      scopes: {Scope.admin},
    );

    // 2. Create User Profile
    // We create a profile so the user has a name/email in the system.
    await AuthServices.instance.userProfiles.createUserProfile(
      session,
      authUser.id,
      UserProfileData(
        userName: name,
        fullName: name,
        email: 'anon-${authUser.id}@anonymous.talktive.com',
      ),
    );

    // 3. Create Resident
    final resident = Resident(
      userInfoId: authUser.id, // Now using UuidValue
      floor: 1,
      creditScore: 100,
      experienceMessageCount: 0,
    );

    // Check for orphan resident (unlikely with new UUIDs but safety check)
    final existing = await Resident.db.findFirstRow(
      session,
      where: (t) => t.userInfoId.equals(authUser.id),
    );
    if (existing != null) {
      await Resident.db.deleteRow(session, existing);
    }

    try {
      await Resident.db.insertRow(session, resident);
    } catch (e, stack) {
      print('FAILED to insert resident: $e');
      print(stack);
      rethrow;
    }

    // 4. Issue Token (JWT)
    final authSuccess = await AuthServices.instance.tokenManager.issueToken(
      session,
      authUserId: authUser.id,
      method: 'default',
      scopes: {Scope.admin},
    );

    // 5. Return JSON (Adapted for Client)
    final map = {
      'key': authSuccess.token, // JWT Token
      'keyId': 0, // JWT ID (optional or not used in JWT auth)
      'userInfoId': authUser.id.toString(),
      'userInfoName': name,
    };

    return jsonEncode(map);
  }
}
