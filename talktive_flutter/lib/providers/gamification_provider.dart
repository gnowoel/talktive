import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:talktive_client/talktive_client.dart';
import 'client_provider.dart';

part 'gamification_provider.g.dart';

/// Data class combining resident (with streaks), reward status, and achievements.
class GamificationData {
  final Resident resident;
  final bool canClaimReward;
  final List<UserAchievementView> achievements;

  GamificationData({
    required this.resident,
    required this.canClaimReward,
    required this.achievements,
  });

  GamificationData copyWith({
    Resident? resident,
    bool? canClaimReward,
    List<UserAchievementView>? achievements,
  }) {
    return GamificationData(
      resident: resident ?? this.resident,
      canClaimReward: canClaimReward ?? this.canClaimReward,
      achievements: achievements ?? this.achievements,
    );
  }
}

@riverpod
class GamificationNotifier extends _$GamificationNotifier {
  @override
  FutureOr<GamificationData?> build() async {
    return fetchAll();
  }

  Future<GamificationData?> fetchAll() async {
    final client = ref.read(clientProvider);
    try {
      final status = await client.gamification.getGamificationStatus();
      if (status == null) return null;

      return GamificationData(
        resident: status.resident,
        canClaimReward: status.canClaimReward,
        achievements: status.achievements,
      );
    } catch (e) {
      return null;
    }
  }

  /// Claims the daily reward.
  Future<DailyReward?> claimDailyReward() async {
    final client = ref.read(clientProvider);
    try {
      final reward = await client.gamification.claimDailyReward();
      // Refresh to update streak and claim status
      ref.invalidateSelf();
      return reward;
    } catch (e) {
      rethrow;
    }
  }

  /// Marks achievements as notified (user has seen them).
  Future<void> markAsNotified(List<int> achievementIds) async {
    final client = ref.read(clientProvider);
    try {
      await client.gamification.markAchievementsAsNotified(achievementIds);
      // Refresh to update achievements status
      ref.invalidateSelf();
    } catch (e) {
      rethrow;
    }
  }

  /// Seeds achievements (admin only).
  Future<void> seedAchievements() async {
    final client = ref.read(clientProvider);
    try {
      await client.gamification.seedAchievements();
      ref.invalidateSelf();
    } catch (e) {
      rethrow;
    }
  }

  /// Refreshes the gamification data.
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final data = await fetchAll();
      state = AsyncValue.data(data);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}
