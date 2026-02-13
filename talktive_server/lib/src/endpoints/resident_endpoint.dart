import 'dart:convert';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart';
import '../generated/protocol.dart';

class ResidentEndpoint extends Endpoint {
  /// Checks if the authenticated user has a Resident profile.
  Future<Resident?> getResident(Session session) async {
    final authenticationInfo = session.authenticated;

    final senderIdentifier = authenticationInfo?.userIdentifier;

    if (senderIdentifier == null) {
      return null;
    }

    final senderUuid = UuidValue.fromString(senderIdentifier);

    return await Resident.db.findFirstRow(
      session,
      where: (t) => t.userInfoId.equals(senderUuid),
    );
  }

  /// Initializes a Resident profile for an authenticated user.
  /// This overwrites any existing UserProfile data (e.g. from Google) with
  /// the chosen anonymous persona.
  Future<Resident> initializeResident(
    Session session, {
    required String name,
    required String avatar,
    required String gender,
    required String country,
    required String bio,
    List<String>? interests,
  }) async {
    final authenticationInfo = session.authenticated;
    final senderIdentifier = authenticationInfo?.userIdentifier;

    if (senderIdentifier == null) {
      throw Exception('Not authenticated');
    }

    final senderUuid = UuidValue.fromString(senderIdentifier);

    // 1. Check if resident already exists
    var resident = await Resident.db.findFirstRow(
      session,
      where: (t) => t.userInfoId.equals(senderUuid),
    );

    if (resident != null) {
      return resident; // Already initialized
    }

    // 2. Fetch/Update User Profile (Force Anonymous Identity)
    try {
      final userProfile = await AuthServices.instance.userProfiles
          .findUserProfileByUserId(
            session,
            senderUuid,
          );

      // Overwrite Google name with Anonymous name
      if (userProfile.userName != name) {
        await AuthServices.instance.userProfiles.changeUserName(
          session,
          senderUuid,
          name,
        );
      }

      // We also update full name to keep it consistent
      if (userProfile.fullName != name) {
        await AuthServices.instance.userProfiles.changeFullName(
          session,
          senderUuid,
          name,
        );
      }

      // Note: We don't wipe the email here to allow account recovery/admin lookup if needed,
      // but we ensure the public facing 'userName' is the anonymous one.
    } catch (e) {
      // User profile might not exist (though getting here means we are authenticated)
      // If so, we create one.
      await AuthServices.instance.userProfiles.createUserProfile(
        session,
        senderUuid,
        UserProfileData(
          userName: name,
          fullName: name,
          email: 'anon-$senderUuid@anonymous.talktive.com',
        ),
      );
    }

    // 3. Create Resident
    resident = Resident(
      userInfoId: senderUuid,
      floor: 1,
      creditScore: 100,
      experienceMessageCount: 0,
      gender: gender,
      country: country,
      bio: bio,
      avatar: avatar, // Store the emoji/avatar string here
      role: 'resident',
      interests: interests,
    );

    await Resident.db.insertRow(session, resident);

    return resident;
  }
}
