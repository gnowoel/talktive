import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart';
import '../generated/protocol.dart';
import '../services/achievement_service.dart';
import '../services/streak_service.dart';
import '../services/notification_service.dart';
import '../services/input_validation_service.dart';
import '../services/apartment_service.dart';
import '../services/gamification_service.dart';

class MomentEndpoint extends Endpoint {
  /// Posts a new moment to the feed.
  /// Only residents on Floor 2+ can post moments (to prevent spam).
  Future<Moment> postMoment(
    Session session, {
    required String imageUrl,
    String caption = '',
  }) async {
    // Validate inputs
    InputValidationService.validateImageUrl(imageUrl).throwIfInvalid();
    InputValidationService.validateCaption(caption).throwIfInvalid();

    final authenticationInfo = session.authenticated;
    final senderIdentifier = authenticationInfo?.userIdentifier;

    if (senderIdentifier == null) {
      throw Exception('Not authenticated');
    }

    final senderUuid = UuidValue.fromString(senderIdentifier);

    // 1. Fetch Resident (for ID and Floor)
    final resident = await Resident.db.findFirstRow(
      session,
      where: (t) => t.userInfoId.equals(senderUuid),
    );

    if (resident == null) {
      throw Exception('Resident not found');
    }

    // 2. Level restriction: Only Level 10+ can post moments (prevent spam)
    if (resident.level < 10) {
      throw Exception(
        'You must be at least Level 10 to post moments. Keep chatting to level up! (Current level: ${resident.level})',
      );
    }

    // 3. Check if user is muted
    if (ApartmentService.isMuted(resident)) {
      throw Exception(ApartmentService.getMuteReason(resident));
    }

    // 4. Fetch User Profile
    final userProfile = await AuthServices.instance.userProfiles
        .findUserProfileByUserId(
          session,
          senderUuid,
        );

    // 5. Create Moment
    final moment = Moment(
      authorId: resident.id!,
      imageUrl: imageUrl,
      caption: caption,
      createdAt: DateTime.now(),
      likesCount: 0,
      commentsCount: 0,
      authorName: userProfile.userName ?? 'Anonymous',
      authorAvatar: userProfile.imageUrl?.toString() ?? '',
      authorReputation: ApartmentService.computeReputation(resident),
    );

    final savedMoment = await Moment.db.insertRow(session, moment);

    // Award XP for posting moment
    await GamificationService.awardXP(
      session,
      resident,
      GamificationService.XP_PER_MOMENT,
      'Posted moment',
    );

    // Track achievements
    await AchievementService.trackProgress(
      session,
      senderUuid,
      'first_moment',
    );
    await AchievementService.trackProgress(
      session,
      senderUuid,
      'photographer',
    );
    await AchievementService.trackProgress(
      session,
      senderUuid,
      'influencer',
    );

    // Update streak
    await StreakService.updateStreak(session, senderUuid);

    return savedMoment;
  }

  /// Lists the latest moments.
  Future<List<Moment>> listMoments(
    Session session, {
    int limit = 20,
    int? lastId,
  }) async {
    // Validate inputs
    InputValidationService.validatePagination(
      limit: limit,
      offset: 0,
    ).throwIfInvalid();
    if (lastId != null) {
      InputValidationService.validateId(lastId, 'Last ID').throwIfInvalid();
    }

    return await Moment.db.find(
      session,
      limit: limit,
      orderBy: (t) => t.id,
      orderDescending: true,
      where: lastId != null ? (t) => t.id < lastId : null,
    );
  }

  /// Likes a moment.
  Future<void> likeMoment(Session session, int momentId) async {
    // Validate inputs
    InputValidationService.validateId(momentId, 'Moment ID').throwIfInvalid();

    final authenticationInfo = session.authenticated;
    final userIdentifier = authenticationInfo?.userIdentifier;

    if (userIdentifier == null) {
      throw Exception('Not authenticated');
    }

    final userId = UuidValue.fromString(userIdentifier);

    // Fetch resident for denormalized data
    final resident = await Resident.db.findFirstRow(
      session,
      where: (t) => t.userInfoId.equals(userId),
    );

    if (resident == null) {
      throw Exception('Resident not found');
    }

    final userProfile = await AuthServices.instance.userProfiles
        .findUserProfileByUserId(session, userId);

    // Check if already liked
    final existingLike = await MomentLike.db.findFirstRow(
      session,
      where: (t) => t.momentId.equals(momentId) & t.userId.equals(userId),
    );

    if (existingLike != null) {
      // Already liked, do nothing (or could throw exception)
      return;
    }

    // Create like
    final like = MomentLike(
      momentId: momentId,
      userId: userId,
      createdAt: DateTime.now(),
      userName: userProfile.userName ?? 'Anonymous',
      userAvatar: userProfile.imageUrl?.toString() ?? '',
      userFloor: ApartmentService.computeReputation(resident),
    );

    await MomentLike.db.insertRow(session, like);

    // Increment likes count on moment
    final moment = await Moment.db.findById(session, momentId);
    if (moment != null) {
      moment.likesCount += 1;
      await Moment.db.updateRow(session, moment);

      // Send notification to moment author (if not liking own moment)
      final momentAuthor = await Resident.db.findById(session, moment.authorId);
      if (momentAuthor != null && momentAuthor.userInfoId != userId) {
        await NotificationService.sendMomentLikeNotification(
          session,
          momentAuthor.userInfoId,
          userProfile.userName ?? 'Someone',
          momentId,
        );
      }
    }
  }

  /// Unlikes a moment.
  Future<void> unlikeMoment(Session session, int momentId) async {
    // Validate inputs
    InputValidationService.validateId(momentId, 'Moment ID').throwIfInvalid();

    final authenticationInfo = session.authenticated;
    final userIdentifier = authenticationInfo?.userIdentifier;

    if (userIdentifier == null) {
      throw Exception('Not authenticated');
    }

    final userId = UuidValue.fromString(userIdentifier);

    // Find and delete like
    final existingLike = await MomentLike.db.findFirstRow(
      session,
      where: (t) => t.momentId.equals(momentId) & t.userId.equals(userId),
    );

    if (existingLike == null) {
      // Not liked, do nothing
      return;
    }

    await MomentLike.db.deleteRow(session, existingLike);

    // Decrement likes count on moment
    final moment = await Moment.db.findById(session, momentId);
    if (moment != null && moment.likesCount > 0) {
      moment.likesCount -= 1;
      await Moment.db.updateRow(session, moment);
    }
  }

  /// Gets likes for a moment.
  Future<List<MomentLike>> getMomentLikes(
    Session session,
    int momentId,
  ) async {
    return await MomentLike.db.find(
      session,
      where: (t) => t.momentId.equals(momentId),
      orderBy: (t) => t.createdAt,
      orderDescending: true,
    );
  }

  /// Checks if the current user has liked a moment.
  Future<bool> hasLikedMoment(Session session, int momentId) async {
    final authenticationInfo = session.authenticated;
    final userIdentifier = authenticationInfo?.userIdentifier;

    if (userIdentifier == null) {
      return false;
    }

    final userId = UuidValue.fromString(userIdentifier);

    final like = await MomentLike.db.findFirstRow(
      session,
      where: (t) => t.momentId.equals(momentId) & t.userId.equals(userId),
    );

    return like != null;
  }

  /// Batch checks if the current user has liked multiple moments.
  /// This solves the N+1 query problem when loading a feed of moments.
  /// Returns a Map of momentId -> isLiked.
  Future<Map<int, bool>> hasLikedMoments(
    Session session,
    List<int> momentIds,
  ) async {
    final authenticationInfo = session.authenticated;
    final userIdentifier = authenticationInfo?.userIdentifier;

    if (userIdentifier == null) {
      // Return all false if not authenticated
      return {for (var id in momentIds) id: false};
    }

    final userId = UuidValue.fromString(userIdentifier);

    // Fetch all likes for these moments by this user in one query
    final likes = await MomentLike.db.find(
      session,
      where: (t) =>
          t.momentId.inSet(momentIds.toSet()) & t.userId.equals(userId),
    );

    // Create a set of liked moment IDs for O(1) lookup
    final likedMomentIds = likes.map((like) => like.momentId).toSet();

    // Return map of momentId -> isLiked
    return {for (var id in momentIds) id: likedMomentIds.contains(id)};
  }

  /// Adds a comment to a moment.
  Future<MomentComment> addComment(
    Session session,
    int momentId,
    String text,
  ) async {
    // Validate inputs
    InputValidationService.validateId(momentId, 'Moment ID').throwIfInvalid();
    InputValidationService.validateComment(text).throwIfInvalid();

    final authenticationInfo = session.authenticated;
    final userIdentifier = authenticationInfo?.userIdentifier;

    if (userIdentifier == null) {
      throw Exception('Not authenticated');
    }

    final userId = UuidValue.fromString(userIdentifier);

    // Fetch resident for denormalized data
    final resident = await Resident.db.findFirstRow(
      session,
      where: (t) => t.userInfoId.equals(userId),
    );

    if (resident == null) {
      throw Exception('Resident not found');
    }

    final userProfile = await AuthServices.instance.userProfiles
        .findUserProfileByUserId(session, userId);

    // Create comment
    final comment = MomentComment(
      momentId: momentId,
      userId: userId,
      text: text,
      createdAt: DateTime.now(),
      userName: userProfile.userName ?? 'Anonymous',
      userAvatar: userProfile.imageUrl?.toString() ?? '',
      userFloor: ApartmentService.computeReputation(resident),
    );

    final savedComment = await MomentComment.db.insertRow(session, comment);

    // Increment comments count on moment
    final moment = await Moment.db.findById(session, momentId);
    if (moment != null) {
      moment.commentsCount += 1;
      await Moment.db.updateRow(session, moment);

      // Send notification to moment author (if not commenting on own moment)
      final momentAuthor = await Resident.db.findById(session, moment.authorId);
      if (momentAuthor != null && momentAuthor.userInfoId != userId) {
        await NotificationService.sendMomentCommentNotification(
          session,
          momentAuthor.userInfoId,
          userProfile.userName ?? 'Someone',
          text,
          momentId,
        );
      }
    }

    return savedComment;
  }

  /// Gets comments for a moment.
  Future<List<MomentComment>> getMomentComments(
    Session session,
    int momentId, {
    int limit = 50,
  }) async {
    return await MomentComment.db.find(
      session,
      where: (t) => t.momentId.equals(momentId),
      orderBy: (t) => t.createdAt,
      orderDescending: false, // Oldest first
      limit: limit,
    );
  }

  /// Deletes a comment (only by author).
  Future<void> deleteComment(Session session, int commentId) async {
    final authenticationInfo = session.authenticated;
    final userIdentifier = authenticationInfo?.userIdentifier;

    if (userIdentifier == null) {
      throw Exception('Not authenticated');
    }

    final userId = UuidValue.fromString(userIdentifier);

    final comment = await MomentComment.db.findById(session, commentId);

    if (comment == null) {
      throw Exception('Comment not found');
    }

    // Check if user is the author
    if (comment.userId != userId) {
      throw Exception('You can only delete your own comments');
    }

    await MomentComment.db.deleteRow(session, comment);

    // Decrement comments count on moment
    final moment = await Moment.db.findById(session, comment.momentId);
    if (moment != null && moment.commentsCount > 0) {
      moment.commentsCount -= 1;
      await Moment.db.updateRow(session, moment);
    }
  }
}
