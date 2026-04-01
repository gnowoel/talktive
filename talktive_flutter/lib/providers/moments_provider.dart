import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:talktive_client/talktive_client.dart';
import 'client_provider.dart';

part 'moments_provider.g.dart';

/// Provider for the moments feed
@riverpod
class Moments extends _$Moments {
  @override
  FutureOr<List<Moment>> build() async {
    return fetchMoments();
  }

  Future<List<Moment>> fetchMoments({int limit = 20}) async {
    final client = ref.read(clientProvider);
    return await client.moment.listMoments(limit: limit);
  }

  /// Refreshes the moments list
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final moments = await fetchMoments();
      state = AsyncValue.data(moments);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Updates a moment in the local state without re-fetching
  void updateMomentLocally(int momentId, Moment Function(Moment) update) {
    state.whenData((moments) {
      final index = moments.indexWhere((m) => m.id == momentId);
      if (index != -1) {
        final newList = List<Moment>.from(moments);
        newList[index] = update(newList[index]);
        state = AsyncValue.data(newList);
      }
    });
  }

  /// Toggles like on a moment
  Future<void> toggleLike(int momentId, bool currentlyLiked) async {
    final client = ref.read(clientProvider);

    // Optimistically update the count in the local list
    updateMomentLocally(momentId, (moment) {
      return moment.copyWith(
        likesCount: currentlyLiked
            ? (moment.likesCount > 0 ? moment.likesCount - 1 : 0)
            : moment.likesCount + 1,
      );
    });

    try {
      if (currentlyLiked) {
        await client.moment.unlikeMoment(momentId);
      } else {
        await client.moment.likeMoment(momentId);
      }
    } catch (e) {
      // Revert the local count change if the backend call fails
      updateMomentLocally(momentId, (moment) {
        return moment.copyWith(
          likesCount: currentlyLiked
              ? moment.likesCount + 1
              : (moment.likesCount > 0 ? moment.likesCount - 1 : 0),
        );
      });
      rethrow;
    }
  }
}

/// Provider for tracking which moments are liked by the current user
@riverpod
class MomentLikes extends _$MomentLikes {
  @override
  FutureOr<Set<int>> build() async {
    return fetchLikedMoments();
  }

  Future<Set<int>> fetchLikedMoments() async {
    final client = ref.read(clientProvider);
    final moments = await ref.read(momentsProvider.future);

    // Extract moment IDs
    final momentIds = moments
        .where((m) => m.id != null)
        .map((m) => m.id!)
        .toList();

    if (momentIds.isEmpty) {
      return {};
    }

    try {
      // Use batch endpoint to check all likes in one query (solves N+1 problem)
      final likeMap = await client.moment.hasLikedMoments(momentIds);

      // Return set of liked moment IDs
      return likeMap.entries
          .where((entry) => entry.value)
          .map((entry) => entry.key)
          .toSet();
    } catch (e) {
      // If batch endpoint fails, fall back to empty set
      debugPrint('Error fetching liked moments: $e');
      return {};
    }
  }

  /// Optimistically updates the like state
  void toggleLike(int momentId) {
    state.whenData((likedMoments) {
      final newSet = Set<int>.from(likedMoments);
      if (newSet.contains(momentId)) {
        newSet.remove(momentId);
      } else {
        newSet.add(momentId);
      }
      state = AsyncValue.data(newSet);
    });
  }

  /// Refreshes the liked moments
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final likedMoments = await fetchLikedMoments();
      state = AsyncValue.data(likedMoments);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

/// Provider for comments on a specific moment
@riverpod
class MomentComments extends _$MomentComments {
  @override
  FutureOr<List<MomentComment>> build(int momentId) async {
    return fetchComments(momentId);
  }

  Future<List<MomentComment>> fetchComments(int momentId) async {
    final client = ref.read(clientProvider);
    return await client.moment.getMomentComments(momentId, limit: 50);
  }

  /// Adds a comment to the moment
  Future<void> addComment(int momentId, String text) async {
    final client = ref.read(clientProvider);

    // Optimistically update the comments count in the moments list
    ref.read(momentsProvider.notifier).updateMomentLocally(momentId, (moment) {
      return moment.copyWith(commentsCount: moment.commentsCount + 1);
    });

    try {
      await client.moment.addComment(momentId, text);

      // Refresh comments to get the permanent ID and full comment data
      final comments = await fetchComments(momentId);
      state = AsyncValue.data(comments);
    } catch (e) {
      // Revert the local count change if the backend call fails
      ref.read(momentsProvider.notifier).updateMomentLocally(momentId, (
        moment,
      ) {
        return moment.copyWith(
          commentsCount: moment.commentsCount > 0
              ? moment.commentsCount - 1
              : 0,
        );
      });
      rethrow;
    }
  }

  /// Refreshes the comments
  Future<void> refresh(int momentId) async {
    state = const AsyncValue.loading();
    try {
      final comments = await fetchComments(momentId);
      state = AsyncValue.data(comments);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

/// Provider for a specific user's moments
@riverpod
class UserMoments extends _$UserMoments {
  @override
  FutureOr<List<Moment>> build(String userId) async {
    return fetchUserMoments(userId);
  }

  Future<List<Moment>> fetchUserMoments(String userId, {int limit = 50}) async {
    final client = ref.read(clientProvider);
    return await client.moment.listUserMoments(
      userId: UuidValue.fromString(userId),
      limit: limit,
    );
  }

  /// Refreshes the user's moments list
  Future<void> refresh(String userId) async {
    state = const AsyncValue.loading();
    try {
      final moments = await fetchUserMoments(userId);
      state = AsyncValue.data(moments);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}
