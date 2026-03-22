import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:talktive_client/talktive_client.dart';
import 'client_provider.dart';
import 'blocked_users_provider.dart';
import 'user_likes_provider.dart';

part 'user_profile_provider.g.dart';

/// Provider for user profile data (cached and reactive)
@riverpod
class UserProfile extends _$UserProfile {
  @override
  FutureOr<UserProfileView?> build(String userId) async {
    // Watch blocked users and likes to rebuild when they change
    // This makes the profile view reactive to blocking/liking actions
    ref.watch(blockedUsersProvider);
    ref.watch(userLikesProvider);

    try {
      final client = ref.read(clientProvider);
      return await client.resident.getUserProfile(userId);
    } catch (e) {
      debugPrint('Error loading user profile for $userId: $e');
      return null;
    }
  }

  /// Refreshes the profile data from the server.
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final client = ref.read(clientProvider);
      return await client.resident.getUserProfile(userId);
    });
  }

  /// Toggles the blocked status of the user
  Future<void> toggleBlock() async {
    final currentProfile = state.value;
    if (currentProfile == null) return;

    final blockedNotifier = ref.read(blockedUsersProvider.notifier);
    if (currentProfile.isBlocked) {
      await blockedNotifier.unblock(userId);
    } else {
      await blockedNotifier.block(userId);
    }

    // The provider will automatically rebuild because it watches blockedUsersProvider
  }

  /// Toggles the like status of the user
  Future<void> toggleLike() async {
    final currentProfile = state.value;
    if (currentProfile == null) return;

    final likesNotifier = ref.read(userLikesProvider.notifier);
    if (ref.read(userLikesProvider).value?.contains(userId) ?? false) {
      await likesNotifier.unlikeUser(userId);
    } else {
      await likesNotifier.likeUser(userId);
    }

    // The provider will automatically rebuild because it watches userLikesProvider
  }
}
