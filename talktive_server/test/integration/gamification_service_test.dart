import 'package:test/test.dart';
import 'package:serverpod/serverpod.dart';
import 'package:talktive_server/src/generated/protocol.dart' as protocol;
import 'package:talktive_server/src/services/gamification_service.dart';
import 'package:uuid/uuid.dart';
import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Given GamificationService', (sessionBuilder, endpoints) {
    late protocol.Resident testUser;
    const uuid = Uuid();

    setUp(() async {
      final session = sessionBuilder.build();

      // Create a test user
      final res = protocol.Resident(
        userInfoId: UuidValue.fromString(uuid.v4()),
        level: 1,
        xp: 0,
        trustScore: 100,
        role: protocol.ResidentRole.user,
      );
      testUser = await protocol.Resident.db.insertRow(session, res);
      
      // Seed achievements
      await GamificationService.seedAchievements(session);
    });

    group('awardXP and Leveling', () {
      test('increases XP and level correctly', () async {
        final session = sessionBuilder.build();
        
        // Award 50 XP (should reach Level 2: sqrt(50/50)+1 = 2)
        await GamificationService.awardXP(session, testUser, 50, 'Test XP');

        final updated = await protocol.Resident.db.findById(session, testUser.id!);
        expect(updated!.xp, 50);
        expect(updated.level, 2);
      });

      test('requires exponential XP for higher floors', () async {
        final session = sessionBuilder.build();
        
        // Level 3 requires: 50 * (3-1)^2 = 200 XP
        await GamificationService.awardXP(session, testUser, 199, 'Almost Level 3');
        var updated = await protocol.Resident.db.findById(session, testUser.id!);
        expect(updated!.level, 2);

        await GamificationService.awardXP(session, testUser, 1, 'Reach Level 3');
        updated = await protocol.Resident.db.findById(session, testUser.id!);
        expect(updated!.level, 3);
      });

      test('caps Base Floor at 50', () async {
        final session = sessionBuilder.build();
        
        // A huge amount of XP
        await GamificationService.awardXP(session, testUser, 1000000, 'God Mode');

        final updated = await protocol.Resident.db.findById(session, testUser.id!);
        expect(updated!.level, 50);
      });
    });

    group('Login Streaks', () {
      test('initializes streak on first login', () async {
        final session = sessionBuilder.build();
        
        await GamificationService.checkDailyLogin(session, testUser);

        final updated = await protocol.Resident.db.findById(session, testUser.id!);
        expect(updated!.currentStreak, 1);
        expect(updated.lastLoginDate, isNotNull);
      });

      test('increments streak on consecutive login', () async {
        final session = sessionBuilder.build();
        final now = DateTime.now();
        final yesterday = now.subtract(const Duration(days: 1));

        // Set last login to yesterday
        testUser.lastLoginDate = yesterday;
        testUser.currentStreak = 1;
        await protocol.Resident.db.updateRow(session, testUser);

        await GamificationService.checkDailyLogin(session, testUser);

        final updated = await protocol.Resident.db.findById(session, testUser.id!);
        expect(updated!.currentStreak, 2);
      });

      test('resets streak if a day is missed', () async {
        final session = sessionBuilder.build();
        final now = DateTime.now();
        final twoDaysAgo = now.subtract(const Duration(days: 2));

        // Set last login to 2 days ago
        testUser.lastLoginDate = twoDaysAgo;
        testUser.currentStreak = 5;
        await protocol.Resident.db.updateRow(session, testUser);

        await GamificationService.checkDailyLogin(session, testUser);

        final updated = await protocol.Resident.db.findById(session, testUser.id!);
        expect(updated!.currentStreak, 1);
      });

      test('awards bonus XP for 3-day streak', () async {
        final session = sessionBuilder.build();
        final now = DateTime.now();
        final yesterday = now.subtract(const Duration(days: 1));

        // Set to 2-day streak as of yesterday
        testUser.lastLoginDate = yesterday;
        testUser.currentStreak = 2;
        testUser.xp = 0;
        await protocol.Resident.db.updateRow(session, testUser);

        await GamificationService.checkDailyLogin(session, testUser);

        final updated = await protocol.Resident.db.findById(session, testUser.id!);
        expect(updated!.currentStreak, 3);
        // 5 XP (login) + 50 XP (3-day bonus) = 55 XP
        expect(updated.xp, 55);
      });
    });

    group('Achievements', () {
      test('tracks achievement progress and unlocks', () async {
        final session = sessionBuilder.build();
        
        // 'first_message' target is 1
        await GamificationService.trackProgress(session, testUser.userInfoId, 'first_message');

        final progress = await protocol.UserAchievement.db.findFirstRow(
          session,
          where: (t) => t.userId.equals(testUser.userInfoId),
        );

        expect(progress, isNotNull);
        expect(progress!.progress, 1);
        expect(progress.unlockedAt, isNotNull);
      });

      test('triggers floor achievements automatically', () async {
        final session = sessionBuilder.build();
        
        // Reach Floor 2 (requires 50 XP)
        await GamificationService.awardXP(session, testUser, 50, 'Reach Floor 2');

        // Should have 'rising_star' (Floor 1) and 'high_rise' (Floor 2)
        final userAchievements = await protocol.UserAchievement.db.find(
          session,
          where: (t) => t.userId.equals(testUser.userInfoId),
        );

        expect(userAchievements.length, greaterThanOrEqualTo(2));
        
        final achievementIds = userAchievements.map((ua) => ua.achievementId).toList();
        final risingStar = await protocol.Achievement.db.findFirstRow(session, where: (t) => t.key.equals('rising_star'));
        final highRise = await protocol.Achievement.db.findFirstRow(session, where: (t) => t.key.equals('high_rise'));

        expect(achievementIds, contains(risingStar!.id!));
        expect(achievementIds, contains(highRise!.id!));
      });
    });

    group('Daily Rewards', () {
      test('can claim daily reward and receives bonuses', () async {
        final session = sessionBuilder.build();
        
        final canClaim = await GamificationService.canClaimDailyReward(session, testUser.userInfoId);
        expect(canClaim, true);

        final reward = await GamificationService.claimDailyReward(session, testUser);
        expect(reward.rewardAmount, 10); // Base reward for 1-day streak

        final updated = await protocol.Resident.db.findById(session, testUser.id!);
        expect(updated!.trustScore, 110); // 100 + 10
        
        final canClaimAgain = await GamificationService.canClaimDailyReward(session, testUser.userInfoId);
        expect(canClaimAgain, false);
      });

      test('throws exception if claiming twice in a day', () async {
        final session = sessionBuilder.build();
        
        await GamificationService.claimDailyReward(session, testUser);

        expect(
          () => GamificationService.claimDailyReward(session, testUser),
          throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('already claimed'))),
        );
      });
    });
  });
}
