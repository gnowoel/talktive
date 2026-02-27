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

  /// Posts a new moment
  Future<void> postMoment({
    required String imageUrl,
    required String caption,
  }) async {
    final client = ref.read(clientProvider);
    await client.moment.postMoment(imageUrl: imageUrl, caption: caption);
    await refresh();
  }

  /// Toggles like on a moment
  Future<void> toggleLike(int momentId, bool currentlyLiked) async {
    final client = ref.read(clientProvider);

    if (currentlyLiked) {
      await client.moment.unlikeMoment(momentId);
    } else {
      await client.moment.likeMoment(momentId);
    }

    // Optimistically update the UI
    await refresh();
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
    await client.moment.addComment(momentId, text);

    // Refresh comments
    state = const AsyncValue.loading();
    try {
      final comments = await fetchComments(momentId);
      state = AsyncValue.data(comments);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
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
