import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:talktive_client/talktive_client.dart';
import 'client_provider.dart';
import 'social_relationships_provider.dart';

part 'user_profile_provider.g.dart';

/// Provider for user profile data (cached and reactive)
@riverpod
class UserProfile extends _$UserProfile {
  @override
  FutureOr<UserProfileView?> build(String userId) async {
    // Watch social relationships to rebuild when they change
    ref.watch(socialRelationshipsStateProvider);

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

    final socialNotifier = ref.read(socialRelationshipsStateProvider.notifier);
    if (currentProfile.isBlocked) {
      await socialNotifier.unblockUser(userId);
    } else {
      await socialNotifier.blockUser(userId);
    }
  }

  /// Toggles the like status of the user
  Future<void> toggleLike() async {
    final currentProfile = state.value;
    if (currentProfile == null) return;

    final socialNotifier = ref.read(socialRelationshipsStateProvider.notifier);
    final socialState = ref.read(socialRelationshipsStateProvider).value;

    if (socialState?.isLiked(userId) ?? false) {
      await socialNotifier.unlikeUser(userId);
    } else {
      await socialNotifier.likeUser(userId);
    }
  }
}
