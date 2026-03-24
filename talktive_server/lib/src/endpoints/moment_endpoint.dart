import 'package:serverpod/serverpod.dart';
import 'package:talktive_server/src/generated/protocol.dart';

import '../services/input_validation_service.dart';
import '../services/moment_service.dart';
import '../utils/endpoint_auth_mixin.dart';

class MomentEndpoint extends Endpoint with EndpointAuthMixin {
  /// Posts a new moment to the feed.
  /// Only residents on Floor 2+ can post moments (to prevent spam).
  /// Posts a new moment to the feed.
  /// Only residents on Floor 2+ can post moments (to prevent spam).
  Future<Moment> postMoment(
    Session session, {
    required String imageUrl,
    String caption = '',
    int? fileSize,
  }) async {
    // Validate inputs
    InputValidationService.validateImageUrl(imageUrl).throwIfInvalid();
    InputValidationService.validateCaption(caption).throwIfInvalid();
    if (fileSize != null) {
      InputValidationService.validateFileSize(fileSize, fieldName: 'Moment image').throwIfInvalid();
    }

    final resident = await getAuthenticatedResident(session);

    return await MomentService.postMoment(
      session,
      author: resident,
      imageUrl: imageUrl,
      caption: caption,
      fileSize: fileSize,
    );
  }

  /// Lists the latest moments.
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

    return await MomentService.listMoments(
      session,
      limit: limit,
      lastId: lastId,
    );
  }

  /// Lists the moments for a specific user.
  /// Lists the moments for a specific user.
  Future<List<Moment>> listUserMoments(
    Session session, {
    required UuidValue userId,
    int limit = 20,
    int? lastId,
  }) async {
    // Validate inputs
    InputValidationService.validatePagination(
      limit: limit,
      offset: 0,
    ).throwIfInvalid();

    return await MomentService.listUserMoments(
      session,
      userId: userId,
      limit: limit,
      lastId: lastId,
    );
  }

  /// Likes a moment.
  /// Likes a moment.
  Future<void> likeMoment(Session session, int momentId) async {
    // Validate inputs
    InputValidationService.validateId(momentId, 'Moment ID').throwIfInvalid();

    final resident = await getAuthenticatedResident(session);
    await MomentService.likeMoment(
      session,
      momentId: momentId,
      resident: resident,
    );
  }

  /// Unlikes a moment.
  /// Unlikes a moment.
  Future<void> unlikeMoment(Session session, int momentId) async {
    InputValidationService.validateId(momentId, 'Moment ID').throwIfInvalid();
    final userId = await getUserId(session);

    await MomentService.unlikeMoment(
      session,
      momentId: momentId,
      userId: userId,
    );
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
  /// Batch checks if the current user has liked multiple moments.
  /// Returns a Map of momentId -> isLiked.
  Future<Map<int, bool>> hasLikedMoments(
    Session session,
    List<int> momentIds,
  ) async {
    final userId = await getUserIdOptional(session);
    if (userId == null) {
      return {for (var id in momentIds) id: false};
    }

    return await MomentService.hasLikedMoments(
      session,
      momentIds,
      userId,
    );
  }

  /// Adds a comment to a moment.
  /// Adds a comment to a moment.
  Future<MomentComment> addComment(
    Session session,
    int momentId,
    String text,
  ) async {
    // Validate inputs
    InputValidationService.validateId(momentId, 'Moment ID').throwIfInvalid();
    InputValidationService.validateComment(text).throwIfInvalid();

    final resident = await getAuthenticatedResident(session);

    return await MomentService.addComment(
      session,
      momentId: momentId,
      resident: resident,
      text: text,
    );
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
  /// Deletes a comment (only by author).
  Future<void> deleteComment(Session session, int commentId) async {
    final userId = await getUserId(session);
    await MomentService.deleteComment(
      session,
      commentId: commentId,
      userId: userId,
    );
  }
}
