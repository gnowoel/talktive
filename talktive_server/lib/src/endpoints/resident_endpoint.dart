import 'package:serverpod/serverpod.dart';
import 'package:talktive_server/src/generated/protocol.dart' as protocol;
import '../services/input_validation_service.dart';
import '../services/legacy_migration_service.dart';
import '../services/resident_service.dart';
import '../services/report_service.dart';
import '../services/notification_service.dart';
import '../services/apartment_service.dart';
import '../utils/endpoint_auth_mixin.dart';

class ResidentEndpoint extends Endpoint with EndpointAuthMixin {
  /// Checks if the authenticated user has a Resident profile and
  /// performs standard background tasks (daily login bonus, etc.).
  Future<protocol.Resident?> getResident(Session session) async {
    final auth = session.authenticated;
    if (auth == null) return null;

    final senderUuid = UuidValue.fromString(auth.userIdentifier);
    return await ResidentService.getActiveResident(session, senderUuid);
  }

  /// Returns sanitized legacy profile data for the authenticated user, if any.
  Future<protocol.LegacyMigrationData?> getLegacyMigrationData(
    Session session,
  ) async {
    final auth = session.authenticated;
    if (auth == null) return null;
    return LegacyMigrationService.fetchForUser(session, auth.userIdentifier);
  }

  /// Fetches a Resident profile by their user ID.
  Future<protocol.Resident?> getResidentById(
    Session session,
    String userId,
  ) async {
    InputValidationService.validateUuid(userId).throwIfInvalid();
    final userUuid = UuidValue.fromString(userId);
    final resident = await ResidentService.getResident(session, userUuid);
    if (resident == null) return null;

    final viewer = await getAuthenticatedResident(session);
    return ResidentService.gateResident(resident, viewer: viewer);
  }

  /// Initializes a Resident profile for an authenticated user.
  Future<protocol.Resident> initializeResident(
    Session session, {
    required String name,
    required String avatar,
    required String gender,
    required String country,
    required String bio,
    String? ageRange,
    List<String>? interests,
    List<String>? languages,
    String? mood,
    String? customAvatarUrl,
  }) async {
    // Input validation
    InputValidationService.validateName(name).throwIfInvalid();
    InputValidationService.validateGender(gender).throwIfInvalid();
    InputValidationService.validateBio(bio).throwIfInvalid();
    InputValidationService.validateStringList(
      interests,
      'Interests',
    ).throwIfInvalid();
    InputValidationService.validateStringList(
      languages,
      'Languages',
    ).throwIfInvalid();

    final senderUuid = await getUserId(session);

    // 1. Check if resident already exists
    var resident = await ResidentService.getResident(session, senderUuid);
    if (resident != null) {
      session.log(
        'Resident: User $senderUuid already has a profile. Returning existing.',
      );
      return resident;
    }

    final legacyMigration = await LegacyMigrationService.fetchForUser(
      session,
      senderUuid.uuid,
    );

    // 2. Create Resident via service
    return await ResidentService.createResident(
      session,
      userId: senderUuid,
      name: name,
      avatar: avatar,
      gender: gender,
      country: country,
      bio: bio,
      ageRange: ageRange,
      interests: interests,
      languages: languages,
      mood: mood,
      customAvatarUrl: customAvatarUrl,
      xp: legacyMigration?.xp ?? 0,
      level: legacyMigration?.level ?? 1,
      role: legacyMigration?.role ?? protocol.ResidentRole.user,
    );
  }

  /// Updates an existing Resident's profile details.
  Future<protocol.Resident> updateResident(
    Session session, {
    required String name,
    required String avatar,
    required String gender,
    required String country,
    required String bio,
    String? ageRange,
    List<String>? interests,
    List<String>? languages,
    String? mood,
    String? customAvatarUrl,
  }) async {
    // Input validation
    InputValidationService.validateName(name).throwIfInvalid();
    InputValidationService.validateGender(gender).throwIfInvalid();
    InputValidationService.validateBio(bio).throwIfInvalid();
    InputValidationService.validateStringList(
      interests,
      'Interests',
    ).throwIfInvalid();
    InputValidationService.validateStringList(
      languages,
      'Languages',
    ).throwIfInvalid();

    final resident = await getAuthenticatedResident(session);

    // Sync name with auth profile
    await ResidentService.syncAuthProfile(session, resident.userInfoId, name);

    // Update basic fields
    resident.userName = name;
    resident.avatar = avatar;
    resident.gender = gender;
    resident.country = country;
    resident.bio = bio;
    resident.ageRange = ageRange ?? resident.ageRange;
    resident.mood = mood ?? resident.mood;
    resident.interests = interests ?? resident.interests;
    resident.languages = languages ?? resident.languages;

    // Premium check for custom avatar
    if (customAvatarUrl != null &&
        !ResidentService.canUseCustomAvatar(resident)) {
      throw protocol.TalktiveException(
        message: 'Custom avatars are a Premium feature.',
        code: 'PREMIUM_REQUIRED',
      );
    }
    resident.customAvatarUrl = customAvatarUrl;

    // ResidentService.updateResident handles old avatar cleanup internally.
    return await ResidentService.updateResident(session, resident);
  }

  /// Updates only the custom avatar URL (standalone method for overlay button).
  Future<protocol.Resident> updateCustomAvatar(
    Session session,
    String? customAvatarUrl, {
    int? avatarSize,
  }) async {
    if (avatarSize != null) {
      InputValidationService.validateFileSize(
        avatarSize,
        maxSize: InputValidationService.maxAvatarSizeBytes,
        fieldName: 'Avatar image',
      ).throwIfInvalid();
    }

    final resident = await getAuthenticatedResident(session);

    if (customAvatarUrl != null &&
        !ResidentService.canUseCustomAvatar(resident)) {
      throw protocol.TalktiveException(
        message: 'Custom avatars are a Premium feature.',
        code: 'PREMIUM_REQUIRED',
      );
    }

    resident.customAvatarUrl = customAvatarUrl;

    // ResidentService.updateResident handles old avatar cleanup internally.
    return await ResidentService.updateResident(session, resident);
  }

  /// Get a user's profile view (with stats)
  Future<protocol.UserProfileView?> getUserProfile(
    Session session,
    String userId,
  ) async {
    InputValidationService.validateUuid(userId).throwIfInvalid();
    final viewerId = await getUserId(session);
    final targetId = UuidValue.fromString(userId);

    return await ResidentService.getResidentProfileView(
      session,
      targetId,
      viewerId: viewerId,
    );
  }

  /// Updates privacy settings (Others, Voice, Search, etc).
  Future<protocol.Resident> updatePrivacy(
    Session session, {
    bool? hideAds,
    bool? showVoiceMessages,
    bool? showAdvancedDiscovery,
    bool? showCustomAvatar,
    bool? showOthersOnlineStatus,
    bool? showOthersReadReceipts,
    bool? showOthersTypingIndicators,
    bool? keepPrivateChats,
  }) async {
    final resident = await getAuthenticatedResident(session);

    // Tier Enforcement
    if (hideAds == true && !ResidentService.isPaidMember(resident)) {
      throw protocol.TalktiveException(
        message: 'Hiding ads is a Paid-only feature.',
        code: 'PREMIUM_REQUIRED',
      );
    }

    final isPlus = ResidentService.isPlusMember(resident);
    if (!isPlus) {
      if (showVoiceMessages == true ||
          showAdvancedDiscovery == true ||
          showCustomAvatar == true ||
          showOthersOnlineStatus == true ||
          showOthersReadReceipts == true ||
          showOthersTypingIndicators == true ||
          keepPrivateChats == true) {
        throw protocol.TalktiveException(
          message: 'Premium privacy settings require a Plus membership.',
          code: 'PREMIUM_REQUIRED',
        );
      }
    }

    return await ResidentService.updatePrivacy(
      session,
      resident: resident,
      hideAds: hideAds,
      showVoiceMessages: showVoiceMessages,
      showAdvancedDiscovery: showAdvancedDiscovery,
      showCustomAvatar: showCustomAvatar,
      showOthersOnlineStatus: showOthersOnlineStatus,
      showOthersReadReceipts: showOthersReadReceipts,
      showOthersTypingIndicators: showOthersTypingIndicators,
      keepPrivateChats: keepPrivateChats,
    );
  }

  /// Updates premium status (Mock for testing).
  Future<protocol.Resident> setPremiumStatus(
    Session session, {
    required bool isPremium,
  }) async {
    final senderUuid = await getUserId(session);
    return await ResidentService.setPremiumStatus(
      session,
      senderUuid,
      isPremium,
    );
  }

  /// Starts a 24-hour premium trial.
  Future<protocol.Resident> startPremiumTrial(Session session) async {
    final senderUuid = await getUserId(session);
    return await ResidentService.activatePremiumTrial(
      session,
      senderUuid,
      const Duration(hours: 24),
    );
  }

  // --- Social Actions (Likes, Blocks, Reports) ---

  /// Vouches for another resident.
  Future<void> vouchForResident(
    Session session,
    UuidValue targetUserId,
  ) async {
    final resident = await getAuthenticatedResident(session);
    await ResidentService.vouchForResident(
      session,
      targetId: targetUserId,
      sender: resident,
    );
  }

  /// Removes a vouch for another resident.
  Future<void> removeResidentVouch(
    Session session,
    UuidValue targetUserId,
  ) async {
    final userId = await getUserId(session);
    await ResidentService.removeResidentVouch(
      session,
      targetId: targetUserId,
      senderId: userId,
    );
  }

  /// Get list of resident IDs liked by current resident.
  Future<List<String>> getMyLikedResidentIds(Session session) async {
    final callerId = await getUserId(session);
    final likes = await protocol.UserLike.db.find(
      session,
      where: (t) => t.senderId.equals(callerId),
    );
    return likes.map((e) => e.receiverId.toString()).toList();
  }

  /// Blocks a resident.
  Future<bool> blockResident(Session session, String userId) async {
    InputValidationService.validateUuid(userId).throwIfInvalid();
    final blockerId = await getUserId(session);
    final targetId = UuidValue.fromString(userId);

    if (blockerId == targetId) {
      throw protocol.TalktiveException(message: 'You cannot block yourself.');
    }

    await ResidentService.setBlockStatus(
      session,
      blockerId: blockerId,
      targetId: targetId,
      block: true,
    );
    return true;
  }

  /// Unblocks a resident.
  Future<bool> unblockResident(Session session, String userId) async {
    InputValidationService.validateUuid(userId).throwIfInvalid();
    final blockerId = await getUserId(session);
    final targetId = UuidValue.fromString(userId);

    await ResidentService.setBlockStatus(
      session,
      blockerId: blockerId,
      targetId: targetId,
      block: false,
    );
    return true;
  }

  /// Checks if a resident is blocked.
  Future<bool> isResidentBlocked(Session session, String userId) async {
    InputValidationService.validateUuid(userId).throwIfInvalid();
    final blockerId = await getUserId(session);
    final targetId = UuidValue.fromString(userId);

    return await ResidentService.isBlocked(
      session,
      blockerId: blockerId,
      blockedId: targetId,
    );
  }

  /// Gets list of resident IDs blocked by current resident.
  Future<List<String>> getBlockedResidentIds(Session session) async {
    final blockerId = await getUserId(session);
    final blocks = await protocol.Block.db.find(
      session,
      where: (t) => t.blockerId.equals(blockerId),
    );
    return blocks.map((b) => b.blockedId.toString()).toList();
  }

  /// Reports a resident for inappropriate behavior.
  Future<void> reportResident(
    Session session, {
    required String targetUserId,
    required String reason,
    int? channelId,
    int? messageId,
  }) async {
    InputValidationService.validateUuid(targetUserId).throwIfInvalid();
    InputValidationService.validateReportReason(reason).throwIfInvalid();

    final reporterUuid = await getUserId(session);
    final targetUuid = UuidValue.fromString(targetUserId);

    if (reporterUuid == targetUuid) {
      throw protocol.TalktiveException(message: 'You cannot report yourself.');
    }

    final reporter = await getResidentProfile(session, reporterUuid);
    final target = await ResidentService.getResident(session, targetUuid);
    if (target == null) {
      throw protocol.TalktiveException(message: 'Target resident not found');
    }

    await ReportService.createReport(
      session,
      reporter: reporter,
      target: target,
      reason: reason,
      channelId: channelId,
      messageId: messageId,
    );

    // Side Effects (Background)
    runBackground(session, (backgroundSession) async {
      final currentTarget = await protocol.Resident.db.findFirstRow(
        backgroundSession,
        where: (t) => t.userInfoId.equals(targetUuid),
      );
      if (currentTarget == null) return;

      ApartmentService.applyReportPenalty(
        reporter: reporter,
        target: currentTarget,
      );

      // If Trust Score drops to 0, suspension/shadowban check
      if (currentTarget.trustScore <= 0) {
        currentTarget.suspended = true;
        backgroundSession.log(
          'Resident ${currentTarget.userInfoId} suspended automatically due to reports.',
        );
      }

      await ResidentService.updateResident(backgroundSession, currentTarget);

      try {
        await NotificationService.sendReportNotification(
          backgroundSession,
          targetUuid,
          reason,
        );
      } catch (e) {
        backgroundSession.log('Failed to send report notification: $e');
      }
    });
  }
}
