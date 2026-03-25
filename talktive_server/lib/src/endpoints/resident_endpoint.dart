import 'package:serverpod/serverpod.dart';
import 'package:talktive_server/src/generated/protocol.dart' as protocol;
import '../services/input_validation_service.dart';
import '../services/resident_service.dart';
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

  /// Fetches a Resident profile by their user ID.
  Future<protocol.Resident?> getResidentById(Session session, String userId) async {
    InputValidationService.validateUuid(userId).throwIfInvalid();
    final userUuid = UuidValue.fromString(userId);
    return await ResidentService.getResident(session, userUuid);
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
    InputValidationService.validateStringList(interests, 'Interests').throwIfInvalid();
    InputValidationService.validateStringList(languages, 'Languages').throwIfInvalid();

    final senderUuid = await getUserId(session);

    // 1. Check if resident already exists
    var resident = await ResidentService.getResident(session, senderUuid);
    if (resident != null) return resident;

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
    InputValidationService.validateStringList(interests, 'Interests').throwIfInvalid();
    InputValidationService.validateStringList(languages, 'Languages').throwIfInvalid();

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
    if (customAvatarUrl != null && !resident.isPremium) {
      throw protocol.TalktiveException(
        message: 'Custom avatars are a Premium feature.',
        code: 'PREMIUM_REQUIRED',
      );
    }
    resident.customAvatarUrl = customAvatarUrl;

    return await protocol.Resident.db.updateRow(session, resident);
  }

  /// Updates only the custom avatar URL (standalone method for overlay button).
  Future<protocol.Resident> updateCustomAvatar(Session session, String? customAvatarUrl, {int? avatarSize}) async {
    if (avatarSize != null) {
      InputValidationService.validateFileSize(
        avatarSize,
        maxSize: InputValidationService.maxAvatarSizeBytes,
        fieldName: 'Avatar image',
      ).throwIfInvalid();
    }
    
    final resident = await getAuthenticatedResident(session);
    
    if (customAvatarUrl != null && !resident.isPremium) {
      throw protocol.TalktiveException(
        message: 'Custom avatars are a Premium feature.',
        code: 'PREMIUM_REQUIRED',
      );
    }
    
    resident.customAvatarUrl = customAvatarUrl;
    return await protocol.Resident.db.updateRow(session, resident);
  }

  /// Get a user's profile view (with stats)
  Future<protocol.UserProfileView?> getUserProfile(Session session, String userId) async {
    InputValidationService.validateUuid(userId).throwIfInvalid();
    final viewerId = await getUserId(session);
    final targetId = UuidValue.fromString(userId);

    return await ResidentService.getResidentProfileView(
      session,
      targetId,
      viewerId: viewerId,
    );
  }

  // --- Liking / Vouching ---

  /// Vouch/Like a user.
  Future<void> likeUser(Session session, String targetUserId) async {
    InputValidationService.validateUuid(targetUserId).throwIfInvalid();
    final resident = await getAuthenticatedResident(session);
    final targetId = UuidValue.fromString(targetUserId);

    await ResidentService.vouchForUser(
      session,
      sender: resident,
      targetId: targetId,
    );
  }

  /// Remove a Vouch/Like.
  Future<void> unlikeUser(Session session, String targetUserId) async {
    InputValidationService.validateUuid(targetUserId).throwIfInvalid();
    final callerId = await getUserId(session);
    final targetId = UuidValue.fromString(targetUserId);

    await ResidentService.removeVouch(
      session,
      senderId: callerId,
      targetId: targetId,
    );
  }

  /// Get list of user IDs liked by current user.
  Future<List<String>> getMyLikedUserIds(Session session) async {
    final callerId = await getUserId(session);
    final likes = await protocol.UserLike.db.find(session, where: (t) => t.senderId.equals(callerId));
    return likes.map((e) => e.receiverId.toString()).toList();
  }

  // --- Blocking ---

  Future<bool> blockUser(Session session, String userId) async {
    InputValidationService.validateUuid(userId).throwIfInvalid();
    final blockerId = await getUserId(session);
    final targetId = UuidValue.fromString(userId);

    await ResidentService.setBlockStatus(session, blockerId: blockerId, targetId: targetId, block: true);
    return true;
  }

  Future<bool> unblockUser(Session session, String userId) async {
    InputValidationService.validateUuid(userId).throwIfInvalid();
    final blockerId = await getUserId(session);
    final targetId = UuidValue.fromString(userId);

    await ResidentService.setBlockStatus(session, blockerId: blockerId, targetId: targetId, block: false);
    return true;
  }

  Future<bool> isUserBlocked(Session session, String userId) async {
    InputValidationService.validateUuid(userId).throwIfInvalid();
    final blockerId = await getUserId(session);
    final targetId = UuidValue.fromString(userId);

    final block = await protocol.Block.db.findFirstRow(session, where: (t) => t.blockerId.equals(blockerId) & t.blockedId.equals(targetId));
    return block != null;
  }

  Future<List<String>> getBlockedUserIds(Session session) async {
    final blockerId = await getUserId(session);
    final blocks = await protocol.Block.db.find(session, where: (t) => t.blockerId.equals(blockerId));
    return blocks.map((b) => b.blockedId.toString()).toList();
  }

  /// Updates privacy settings for online status.
  Future<protocol.Resident> updateOnlineSettings(
    Session session, {
    required bool showOnlineStatus,
  }) async {
    final resident = await getAuthenticatedResident(session);
    resident.showOnlineStatus = showOnlineStatus;
    return await protocol.Resident.db.updateRow(session, resident);
  }

  /// Mocks a premium purchase.
  Future<protocol.Resident> purchasePremium(Session session) async {
    final senderUuid = await getUserId(session);
    return await ResidentService.setPremiumStatus(session, senderUuid, true);
  }

  /// Mocks a subscription cancellation (downgrade).
  Future<protocol.Resident> cancelPremium(Session session) async {
    final senderUuid = await getUserId(session);
    return await ResidentService.setPremiumStatus(session, senderUuid, false);
  }

  /// Updates privacy settings (Read Receipts, Typing Indicator, Voice, Search, etc).
  Future<protocol.Resident> updatePrivacySettings(
    Session session, {
    bool? showOnlineStatus,
    bool? showReadReceipts,
    bool? showTypingIndicator,
    bool? showVoiceMessages,
    bool? showNeighborsDiscovery,
    bool? showCustomAvatar,
    bool? showOthersOnlineStatus,
    bool? showOthersReadReceipts,
    bool? showOthersTypingIndicators,
    bool? allowDiscovery,
    bool? keepPrivateChats,
    bool? showImagesInPlaza,
    bool? showImagesInLounges,
    bool? showImagesInPrivateChats,
    bool? showImagesInMoments,
  }) async {
    final resident = await getAuthenticatedResident(session);

    return await ResidentService.updatePrivacy(
      session,
      resident: resident,
      showOnlineStatus: showOnlineStatus,
      showReadReceipts: showReadReceipts,
      showTypingIndicator: showTypingIndicator,
      showVoiceMessages: showVoiceMessages,
      showNeighborsDiscovery: showNeighborsDiscovery,
      showCustomAvatar: showCustomAvatar,
      showOthersOnlineStatus: showOthersOnlineStatus,
      showOthersReadReceipts: showOthersReadReceipts,
      showOthersTypingIndicators: showOthersTypingIndicators,
      allowDiscovery: allowDiscovery,
      keepPrivateChats: keepPrivateChats,
      showImagesInPlaza: showImagesInPlaza,
      showImagesInLounges: showImagesInLounges,
      showImagesInPrivateChats: showImagesInPrivateChats,
      showImagesInMoments: showImagesInMoments,
    );
  }
}
