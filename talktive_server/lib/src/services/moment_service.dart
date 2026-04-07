import 'dart:async';
import 'package:serverpod/serverpod.dart';
import 'package:talktive_server/src/generated/protocol.dart';
import 'resident_service.dart';
import 'apartment_service.dart';
import 'gamification_service.dart';
import 'notification_service.dart';
import 'file_storage_service.dart';
import '../utils/task_utils.dart';

class MomentService {
  /// Posts a new moment to the feed.
  /// Handles validation, floor restrictions, and gamification rewards.
  static Future<Moment> postMoment(
    Session session, {
    required Resident author,
    required String imageUrl,
    String caption = '',
    int? fileSize,
  }) async {
    final effectiveFloor = ApartmentService.computeEffectiveFloor(author);

    // 1. Floor restriction: Only Floor 2+ can post moments (prevent spam)
    if (effectiveFloor < 2) {
      throw TalktiveException(
        message:
            'You must reach Floor 2 to post moments. Keep interacting to climb higher!',
        code: 'FLOOR_TOO_LOW',
      );
    }

    // 2. Check if user is muted
    if (ApartmentService.isMuted(author)) {
      throw TalktiveException(
        message: ApartmentService.getMuteReason(author),
        code: 'USER_MUTED',
      );
    }

    // 3. Create Moment
    final moment = Moment(
      authorId: author.userInfoId,
      imageUrl: imageUrl,
      caption: caption,
      mediaType: 'image',
      createdAt: DateTime.now(),
      likesCount: 0,
      commentsCount: 0,
      fileSize: fileSize,
      authorName: author.userName ?? 'Anonymous',
      authorAvatar: ResidentService.isPlusMember(author)
          ? (author.customAvatarUrl ?? author.avatar ?? '')
          : (author.avatar ?? ''),
      authorMood: author.mood,
      authorFloor: effectiveFloor,
      authorTrustScore: author.trustScore,
    );

    final savedMoment = await Moment.db.insertRow(session, moment);

    // 4. Award XP for posting moment
    await GamificationService.awardXP(
      session,
      author,
      GamificationService.xpPerMoment,
      'Posted moment',
      save: false,
    );

    await ResidentService.updateResident(session, author);

    // 5. Track achievement progress (Background)
    TaskUtils.runBackground(session, (backgroundSession) async {
      await GamificationService.trackMultipleProgress(
        backgroundSession,
        author.userInfoId,
        ['first_moment', 'photographer', 'influencer'],
      );
    });

    return savedMoment;
  }

  /// Lists the latest moments with pagination.
  static Future<List<Moment>> listMoments(
    Session session, {
    int limit = 20,
    int? lastId,
    UuidValue? viewerId,
  }) async {
    final blockedIds = viewerId != null
        ? await ResidentService.getBlocksByUser(session, viewerId)
        : <UuidValue>{};

    return await Moment.db.find(
      session,
      limit: limit,
      orderBy: (t) => t.id,
      orderDescending: true,
      where: (t) {
        var filter = (lastId != null ? t.id < lastId : Constant.bool(true));
        if (blockedIds.isNotEmpty) {
          filter &= t.authorId.notInSet(blockedIds);
        }
        return filter;
      },
    );
  }

  /// Lists the moments for a specific user.
  static Future<List<Moment>> listUserMoments(
    Session session, {
    required UuidValue userId,
    int limit = 20,
    int? lastId,
  }) async {
    return await Moment.db.find(
      session,
      limit: limit,
      orderBy: (t) => t.id,
      orderDescending: true,
      where: (t) {
        var filter = t.authorId.equals(userId);
        if (lastId != null) {
          filter &= t.id < lastId;
        }
        return filter;
      },
    );
  }

  /// Likes a moment and handles notifications/vouching for the author.
  static Future<void> likeMoment(
    Session session, {
    required int momentId,
    required Resident resident,
  }) async {
    final userId = resident.userInfoId;

    // Check if already liked
    final existingLike = await MomentLike.db.findFirstRow(
      session,
      where: (t) => t.momentId.equals(momentId) & t.userId.equals(userId),
    );

    if (existingLike != null) return;

    // Create like record
    final like = MomentLike(
      momentId: momentId,
      userId: userId,
      createdAt: DateTime.now(),
      userName: resident.userName ?? 'Anonymous',
      userAvatar: resident.customAvatarUrl ?? resident.avatar ?? '',
      userMood: resident.mood,
      userFloor: ApartmentService.computeEffectiveFloor(resident),
      userTrustScore: resident.trustScore,
    );

    await MomentLike.db.insertRow(session, like);

    // Update moment stats
    final moment = await Moment.db.findById(session, momentId);
    if (moment != null) {
      moment.likesCount += 1;
      await Moment.db.updateRow(session, moment);

      // Notify and reward moment author (if not self)
      if (moment.authorId != userId) {
        final momentAuthor = await Resident.db.findFirstRow(
          session,
          where: (t) => t.userInfoId.equals(moment.authorId),
        );
        if (momentAuthor != null) {
          // Reward author
          await GamificationService.awardXP(
            session,
            momentAuthor,
            GamificationService.xpUserVouch,
            'Moment liked',
            save: false,
          );
          ApartmentService.awardVouch(target: momentAuthor);
          await ResidentService.updateResident(session, momentAuthor);

          // Notify author (background to prevent UI delay and session closure errors)
          TaskUtils.runBackground(session, (backgroundSession) async {
            await NotificationService.sendMomentLikeNotification(
              backgroundSession,
              momentAuthor.userInfoId,
              resident.userName ?? 'Someone',
              momentId,
            );
          });
        }
      }
    }
  }

  /// Unlikes a moment.
  static Future<void> unlikeMoment(
    Session session, {
    required int momentId,
    required UuidValue userId,
  }) async {
    final existingLike = await MomentLike.db.findFirstRow(
      session,
      where: (t) => t.momentId.equals(momentId) & t.userId.equals(userId),
    );

    if (existingLike == null) return;

    await MomentLike.db.deleteRow(session, existingLike);

    // Decrement likes count
    final moment = await Moment.db.findById(session, momentId);
    if (moment != null && moment.likesCount > 0) {
      moment.likesCount -= 1;
      await Moment.db.updateRow(session, moment);
    }
  }

  /// Batch checks if a user has liked multiple moments.
  static Future<Map<int, bool>> hasLikedMoments(
    Session session,
    List<int> momentIds,
    UuidValue userId,
  ) async {
    if (momentIds.isEmpty) return {};

    final likes = await MomentLike.db.find(
      session,
      where: (t) =>
          t.momentId.inSet(momentIds.toSet()) & t.userId.equals(userId),
    );

    final likedSet = likes.map((l) => l.momentId).toSet();
    return {for (var id in momentIds) id: likedSet.contains(id)};
  }

  /// Adds a comment to a moment.
  static Future<MomentComment> addComment(
    Session session, {
    required int momentId,
    required Resident resident,
    required String text,
  }) async {
    final userId = resident.userInfoId;

    final comment = MomentComment(
      momentId: momentId,
      userId: userId,
      text: text,
      createdAt: DateTime.now(),
      userName: resident.userName ?? 'Anonymous',
      userAvatar: resident.customAvatarUrl ?? resident.avatar ?? '',
      userMood: resident.mood,
      userFloor: ApartmentService.computeEffectiveFloor(resident),
      userTrustScore: resident.trustScore,
    );

    final savedComment = await MomentComment.db.insertRow(session, comment);

    // Increment count on moment
    final moment = await Moment.db.findById(session, momentId);
    if (moment != null) {
      moment.commentsCount += 1;
      await Moment.db.updateRow(session, moment);

      // Notify author (background to prevent UI delay)
      if (moment.authorId != userId) {
        TaskUtils.runBackground(session, (backgroundSession) async {
          await NotificationService.sendMomentCommentNotification(
            backgroundSession,
            moment.authorId,
            resident.userName ?? 'Someone',
            text,
            momentId,
          );
        });
      }
    }

    return savedComment;
  }

  /// Deletes a comment (ensures ownership).
  static Future<void> deleteComment(
    Session session, {
    required int commentId,
    required UuidValue userId,
  }) async {
    final comment = await MomentComment.db.findById(session, commentId);
    if (comment == null) {
      throw TalktiveException(message: 'Comment not found');
    }

    if (comment.userId != userId) {
      throw TalktiveException(message: 'Permission denied: Not your comment');
    }

    await MomentComment.db.deleteRow(session, comment);

    // Decrement count on moment
    final moment = await Moment.db.findById(session, comment.momentId);
    if (moment != null && moment.commentsCount > 0) {
      moment.commentsCount -= 1;
      await Moment.db.updateRow(session, moment);
    }
  }

  /// Deletes a moment and cleans up all its associations and media.
  static Future<void> deleteMoment(
    Session session, {
    required int momentId,
    UuidValue? userId, // Optional, if provided ensures ownership unless admin
  }) async {
    final moment = await Moment.db.findById(session, momentId);
    if (moment == null) return;

    // 1. Authorization check (if userId provided)
    if (userId != null) {
      final resident = await ResidentService.getResident(session, userId);
      final isStaff =
          resident?.role == ResidentRole.admin ||
          resident?.role == ResidentRole.moderator;

      if (moment.authorId != userId && !isStaff) {
        throw TalktiveException(message: 'Permission denied: Not your moment');
      }
    }

    // 2. Clean up associations
    await MomentLike.db.deleteWhere(
      session,
      where: (t) => t.momentId.equals(momentId),
    );
    await MomentComment.db.deleteWhere(
      session,
      where: (t) => t.momentId.equals(momentId),
    );

    // 3. Clean up physical media
    await FileStorageService.deleteMedia(session, moment.imageUrl);

    // 4. Delete moment record
    await Moment.db.deleteRow(session, moment);
  }
}
