import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'client_provider.dart';

part 'achievement_provider.g.dart';

/// Provider for user achievements.
@riverpod
class UserAchievements extends _$UserAchievements {
  @override
  FutureOr<List<Map<String, dynamic>>> build() async {
    return fetchAchievements();
  }

  Future<List<Map<String, dynamic>>> fetchAchievements() async {
    final client = ref.read(clientProvider);
    try {
      return await client.achievement.getUserAchievements();
    } catch (e) {
      rethrow;
    }
  }

  /// Marks achievements as notified (user has seen them).
  Future<void> markAsNotified(List<int> achievementIds) async {
    final client = ref.read(clientProvider);
    try {
      await client.achievement.markAchievementsAsNotified(achievementIds);
      // Refresh to update the notified status
      ref.invalidateSelf();
    } catch (e) {
      rethrow;
    }
  }

  /// Refreshes the achievements list.
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final achievements = await fetchAchievements();
      state = AsyncValue.data(achievements);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}
