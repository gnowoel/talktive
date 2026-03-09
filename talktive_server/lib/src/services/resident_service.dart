import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart';
import '../generated/protocol.dart';
import 'apartment_service.dart';
import 'gamification_service.dart';

/// Service for managing Resident profiles and synchronization with AuthUser.
class ResidentService {
  /// Fetches a Resident by their userInfoId.
  static Future<Resident?> getResident(Session session, UuidValue userId) async {
    return await Resident.db.findFirstRow(
      session,
      where: (t) => t.userInfoId.equals(userId),
    );
  }

  /// Fetches a Resident and performs passive updates (Trust Score, Daily Login).
  static Future<Resident?> getActiveResident(Session session, UuidValue userId) async {
    final resident = await getResident(session, userId);
    if (resident == null) return null;

    bool needsSave = false;

    // Passively restore trustScore
    if (await ApartmentService.restoreTrustScore(session, resident, save: false)) {
      needsSave = true;
    }

    // Check daily login
    if (await GamificationService.checkDailyLogin(session, resident, save: false)) {
      needsSave = true;
    }

    if (needsSave) {
      await Resident.db.updateRow(session, resident);
    }

    return resident;
  }

  /// Synchronizes the AuthUser profile name with the Resident persona name.
  static Future<void> syncAuthProfile(
    Session session,
    UuidValue userId,
    String name,
  ) async {
    try {
      final userProfile = await AuthServices.instance.userProfiles
          .findUserProfileByUserId(session, userId);

      if (userProfile.userName != name) {
        await AuthServices.instance.userProfiles.changeUserName(
          session,
          userId,
          name,
        );
      }
      if (userProfile.fullName != name) {
        await AuthServices.instance.userProfiles.changeFullName(
          session,
          userId,
          name,
        );
      }
    } catch (_) {
      // User profile might not exist yet during initialization
    }
  }

  /// Checks if a user is blocked by another user.
  static Future<bool> isBlocked(
    Session session, {
    required UuidValue blockerId,
    required UuidValue blockedId,
  }) async {
    final block = await Block.db.findFirstRow(
      session,
      where: (t) =>
          t.blockerId.equals(blockerId) & t.blockedId.equals(blockedId),
    );
    return block != null;
  }
}
