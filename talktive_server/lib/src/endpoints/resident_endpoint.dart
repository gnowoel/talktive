import 'package:serverpod/serverpod.dart';
import 'package:talktive_server/src/generated/protocol.dart' as protocol;
import '../services/input_validation_service.dart';
import '../services/resident_service.dart';
import '../services/file_storage_service.dart';
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
    final oldAvatarUrl = resident.customAvatarUrl;
    resident.customAvatarUrl = customAvatarUrl;

    final updated = await ResidentService.updateResident(session, resident);

    // Clean up old avatar file if it's different and exists
    if (customAvatarUrl != oldAvatarUrl && oldAvatarUrl != null) {
      await FileStorageService.deleteMedia(session, oldAvatarUrl);
    }

    return updated;
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

    final oldAvatarUrl = resident.customAvatarUrl;
    resident.customAvatarUrl = customAvatarUrl;

    final updated = await ResidentService.updateResident(session, resident);

    if (customAvatarUrl != oldAvatarUrl && oldAvatarUrl != null) {
      await FileStorageService.deleteMedia(session, oldAvatarUrl);
    }

    return updated;
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
}
