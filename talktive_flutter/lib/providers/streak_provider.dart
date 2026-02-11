import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:talktive_client/talktive_client.dart';
import 'client_provider.dart';

part 'streak_provider.g.dart';

/// Provider for user streak data.
@riverpod
class UserStreak extends _$UserStreak {
  @override
  FutureOr<UserStreakData?> build() async {
    return fetchStreak();
  }

  Future<UserStreakData?> fetchStreak() async {
    final client = ref.read(clientProvider);
    try {
      final streak = await client.streak.getUserStreak();
      final canClaim = await client.streak.canClaimDailyReward();

      return UserStreakData(streak: streak, canClaimReward: canClaim);
    } catch (e) {
      return null;
    }
  }

  /// Claims the daily reward.
  Future<DailyReward?> claimReward() async {
    final client = ref.read(clientProvider);
    try {
      final reward = await client.streak.claimDailyReward();
      // Refresh streak data
      ref.invalidateSelf();
      return reward;
    } catch (e) {
      rethrow;
    }
  }

  /// Refreshes the streak data.
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final data = await fetchStreak();
      state = AsyncValue.data(data);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

/// Data class combining streak and reward claim status.
class UserStreakData {
  final UserStreak? streak;
  final bool canClaimReward;

  UserStreakData({required this.streak, required this.canClaimReward});
}
