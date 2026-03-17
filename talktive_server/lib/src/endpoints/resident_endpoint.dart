import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart';
import '../generated/protocol.dart' as protocol;
import '../services/apartment_service.dart';
import '../services/input_validation_service.dart';
import '../services/resident_service.dart';
import '../services/gamification_service.dart';
import '../utils/endpoint_auth_mixin.dart';
import 'dart:math';

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
    List<String>? interests,
    List<String>? languages,
    String mood = '😊',
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

    // 2. Fetch/Update User Profile (Force Anonymous Identity)
    try {
      await ResidentService.syncAuthProfile(session, senderUuid, name);
    } catch (e) {
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
    resident = protocol.Resident(
      userInfoId: senderUuid,
      xp: 0,
      level: 1,
      currentStreak: 0,
      longestStreak: 0,
      trustScore: ApartmentService.TRUST_SCORE_START,
      suspended: false,
      experienceMessageCount: 0,
      userName: name,
      gender: gender,
      country: country,
      bio: bio,
      mood: mood,
      avatar: avatar,
      interests: interests ?? [],
      languages: languages ?? ['en'],
      role: protocol.ResidentRole.user,
    );

    await protocol.Resident.db.insertRow(session, resident);
    return resident;
  }

  /// Updates an existing Resident's profile details.
  Future<protocol.Resident> updateResident(
    Session session, {
    required String name,
    required String avatar,
    required String gender,
    required String country,
    required String bio,
    List<String>? interests,
    List<String>? languages,
    String? mood,
  }) async {
    InputValidationService.validateName(name).throwIfInvalid();
    InputValidationService.validateGender(gender).throwIfInvalid();
    InputValidationService.validateBio(bio).throwIfInvalid();
    InputValidationService.validateStringList(interests, 'Interests').throwIfInvalid();
    InputValidationService.validateStringList(languages, 'Languages').throwIfInvalid();

    final resident = await getAuthenticatedResident(session);
    final senderUuid = resident.userInfoId;

    await ResidentService.syncAuthProfile(session, senderUuid, name);

    resident.userName = name;
    resident.avatar = avatar;
    resident.gender = gender;
    resident.country = country;
    resident.bio = bio;
    resident.mood = mood ?? resident.mood;
    resident.interests = interests ?? resident.interests;
    resident.languages = languages ?? resident.languages;

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
    final callerId = await getUserId(session);
    final targetId = UuidValue.fromString(targetUserId);

    if (callerId == targetId) throw protocol.TalktiveException(message: 'You cannot like yourself.');

    final target = await ResidentService.getResident(session, targetId);
    if (target == null) throw protocol.TalktiveException(message: 'Target user not found');

    // One-Vote Rule
    final existingLike = await protocol.UserLike.db.findFirstRow(
      session,
      where: (t) => t.senderId.equals(callerId) & t.receiverId.equals(targetId),
    );
    if (existingLike != null) throw protocol.TalktiveException(message: 'You have already vouched for this user.');

    final isBlocked = await ResidentService.isBlocked(session, blockerId: callerId, blockedId: targetId);
    final hasBlockedMe = await ResidentService.isBlocked(session, blockerId: targetId, blockedId: callerId);
    if (isBlocked || hasBlockedMe) {
      throw protocol.TalktiveException(message: 'You cannot vouch for this resident due to privacy settings.');
    }

    final existingReport = await protocol.Report.db.findFirstRow(
      session,
      where: (t) => t.reporterId.equals(callerId) & t.targetId.equals(targetId),
    );
    if (existingReport != null) throw protocol.TalktiveException(message: 'You cannot vouch for a user you have reported.');

    await protocol.UserLike.db.insertRow(session, protocol.UserLike(senderId: callerId, receiverId: targetId, createdAt: DateTime.now()));

    // Trust Score Increase & XP Reward
    ApartmentService.awardVouch(target: target);
    await GamificationService.awardXP(
      session,
      target,
      GamificationService.XP_USER_VOUCH,
      'Vouched by another resident',
      save: false,
    );
    await protocol.Resident.db.updateRow(session, target);
  }

  /// Remove a Vouch/Like.
  Future<void> unlikeUser(Session session, String targetUserId) async {
    InputValidationService.validateUuid(targetUserId).throwIfInvalid();
    final callerId = await getUserId(session);
    final targetId = UuidValue.fromString(targetUserId);

    final target = await ResidentService.getResident(session, targetId);
    if (target == null) throw protocol.TalktiveException(message: 'Target user not found');

    final existingLike = await protocol.UserLike.db.findFirstRow(
      session,
      where: (t) => t.senderId.equals(callerId) & t.receiverId.equals(targetId),
    );
    if (existingLike == null) throw protocol.TalktiveException(message: 'Like not found');

    await protocol.UserLike.db.deleteRow(session, existingLike);

    ApartmentService.removeVouch(target: target);
    await protocol.Resident.db.updateRow(session, target);
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

    final existing = await protocol.Block.db.findFirstRow(session, where: (t) => t.blockerId.equals(blockerId) & t.blockedId.equals(targetId));
    if (existing != null) return true;

    await protocol.Block.db.insertRow(session, protocol.Block(blockerId: blockerId, blockedId: targetId, createdAt: DateTime.now()));
    return true;
  }

  Future<bool> unblockUser(Session session, String userId) async {
    InputValidationService.validateUuid(userId).throwIfInvalid();
    final blockerId = await getUserId(session);
    final targetId = UuidValue.fromString(userId);

    final block = await protocol.Block.db.findFirstRow(session, where: (t) => t.blockerId.equals(blockerId) & t.blockedId.equals(targetId));
    if (block == null) return true;

    await protocol.Block.db.deleteRow(session, block);
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
    final resident = await getAuthenticatedResident(session);
    resident.isPremium = true;
    // In a real app, we'd update a subscription table or verify with App Store/Play Store.
    return await protocol.Resident.db.updateRow(session, resident);
  }
}
