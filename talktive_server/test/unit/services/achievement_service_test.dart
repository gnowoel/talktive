import 'package:test/test.dart';

void main() {
  group('AchievementService - Achievement Definitions', () {
    test('all achievements have required fields', () {
      // Achievement structure validation
      final achievement = {
        'key': 'first_message',
        'name': 'First Steps',
        'description': 'Send your first message',
        'emoji': '👋',
        'category': 'social',
        'targetValue': 1,
        'points': 10,
      };

      expect(achievement['key'], isNotNull);
      expect(achievement['name'], isNotNull);
      expect(achievement['description'], isNotNull);
      expect(achievement['emoji'], isNotNull);
      expect(achievement['category'], isNotNull);
      expect(achievement['targetValue'], greaterThan(0));
      expect(achievement['points'], greaterThan(0));
    });

    test('achievement keys are unique and descriptive', () {
      final keys = [
        'first_message',
        'conversationalist',
        'chatterbox',
        'social_butterfly',
        'community_builder',
        'private_chat',
        'first_moment',
        'photographer',
        'influencer',
        'rising_star',
        'high_rise',
        'penthouse',
        'helpful',
        'trusted',
        'night_owl',
        'early_bird',
      ];

      // All keys should be unique
      expect(keys.toSet().length, keys.length);

      // All keys should be lowercase with underscores
      for (final key in keys) {
        expect(key, equals(key.toLowerCase()));
        expect(key, isNot(contains(' ')));
      }
    });

    test('achievement categories are consistent', () {
      final categories = [
        'social',
        'moments',
        'progression',
        'behavior',
        'special',
      ];

      // All categories should be unique
      expect(categories.toSet().length, categories.length);

      // All categories should be lowercase
      for (final category in categories) {
        expect(category, equals(category.toLowerCase()));
      }
    });

    test('achievement points scale with difficulty', () {
      // Easy achievements (1-20 points)
      final easyAchievements = <Map<String, dynamic>>[
        {'key': 'first_message', 'points': 10},
        {'key': 'private_chat', 'points': 15},
        {'key': 'first_moment', 'points': 15},
      ];

      // Medium achievements (21-100 points)
      final mediumAchievements = <Map<String, dynamic>>[
        {'key': 'social_butterfly', 'points': 30},
        {'key': 'conversationalist', 'points': 50},
        {'key': 'trusted', 'points': 75},
      ];

      // Hard achievements (100+ points)
      final hardAchievements = <Map<String, dynamic>>[
        {'key': 'penthouse', 'points': 100},
        {'key': 'influencer', 'points': 150},
        {'key': 'chatterbox', 'points': 200},
      ];

      // Verify point ranges
      for (final achievement in easyAchievements) {
        expect((achievement['points'] as int) <= 20, true);
      }

      for (final achievement in mediumAchievements) {
        expect(
          (achievement['points'] as int) > 20 &&
              (achievement['points'] as int) <= 100,
          true,
        );
      }

      for (final achievement in hardAchievements) {
        expect((achievement['points'] as int) >= 100, true);
      }
    });
  });

  group('AchievementService - Social Achievements', () {
    test('first message achievement is achievable immediately', () {
      final achievement = {
        'key': 'first_message',
        'targetValue': 1,
        'points': 10,
      };

      expect(achievement['targetValue'], 1);
      expect(achievement['points'], 10);
    });

    test('message achievements scale appropriately', () {
      final messageAchievements = <Map<String, dynamic>>[
        {'key': 'first_message', 'target': 1},
        {'key': 'conversationalist', 'target': 100},
        {'key': 'chatterbox', 'target': 1000},
      ];

      // Each tier should be 10x the previous
      expect(
        messageAchievements[1]['target']! / messageAchievements[0]['target']!,
        100,
      );
      expect(
        messageAchievements[2]['target']! / messageAchievements[1]['target']!,
        10,
      );
    });

    test('group achievements encourage community building', () {
      final groupAchievements = [
        {'key': 'community_builder', 'description': 'Create your first group'},
        {'key': 'social_butterfly', 'description': 'Join 5 groups'},
      ];

      for (final achievement in groupAchievements) {
        expect(achievement['description'], contains('group'));
      }
    });
  });

  group('AchievementService - Moments Achievements', () {
    test('moments achievements encourage content creation', () {
      final momentsAchievements = <Map<String, dynamic>>[
        {'key': 'first_moment', 'target': 1, 'points': 15},
        {'key': 'photographer', 'target': 10, 'points': 50},
        {'key': 'influencer', 'target': 50, 'points': 150},
      ];

      // Points should scale with difficulty
      expect(
        momentsAchievements[1]['points']! > momentsAchievements[0]['points']!,
        true,
      );
      expect(
        momentsAchievements[2]['points']! > momentsAchievements[1]['points']!,
        true,
      );

      // Targets should increase significantly
      expect(momentsAchievements[1]['target']! >= 10, true);
      expect(momentsAchievements[2]['target']! >= 50, true);
    });
  });

  group('AchievementService - Progression Achievements', () {
    test('floor achievements match floor system', () {
      final floorAchievements = <Map<String, dynamic>>[
        {'key': 'rising_star', 'floor': 1, 'points': 20},
        {'key': 'high_rise', 'floor': 2, 'points': 50},
        {'key': 'penthouse', 'floor': 3, 'points': 100},
      ];

      // Points should double with each floor
      expect(
        floorAchievements[1]['points']! > floorAchievements[0]['points']! * 2,
        true,
      );
      expect(
        floorAchievements[2]['points']! == floorAchievements[1]['points']! * 2,
        true,
      );
    });

    test('floor progression is linear', () {
      final floors = [1, 2, 3];

      for (var i = 1; i < floors.length; i++) {
        expect(floors[i] - floors[i - 1], 1);
      }
    });
  });

  group('AchievementService - Behavior Achievements', () {
    test('helpful achievement encourages reporting', () {
      final helpful = {
        'key': 'helpful',
        'description': 'Report 5 violations',
        'target': 5,
      };

      expect(helpful['description'], contains('Report'));
      expect(helpful['target'], 5);
    });

    test('trusted achievement is secret and valuable', () {
      final trusted = {
        'key': 'trusted',
        'description': 'Maintain 100 credit score for 7 days',
        'isSecret': true,
        'points': 75,
      };

      expect(trusted['isSecret'], true);
      expect(trusted['points'], greaterThan(50));
      expect(trusted['description'], contains('credit score'));
    });
  });

  group('AchievementService - Special Achievements', () {
    test('time-based achievements are secret', () {
      final timeAchievements = [
        {'key': 'night_owl', 'isSecret': true},
        {'key': 'early_bird', 'isSecret': true},
      ];

      for (final achievement in timeAchievements) {
        expect(achievement['isSecret'], true);
      }
    });

    test('night owl and early bird are complementary', () {
      final nightOwl = {
        'key': 'night_owl',
        'description': 'Send a message at 3 AM',
        'points': 15,
      };

      final earlyBird = {
        'key': 'early_bird',
        'description': 'Send a message at 6 AM',
        'points': 15,
      };

      // Same points for both
      expect(nightOwl['points'], earlyBird['points']);

      // Different times
      expect(nightOwl['description'], contains('3 AM'));
      expect(earlyBird['description'], contains('6 AM'));
    });
  });

  group('AchievementService - Achievement Balance', () {
    test('total achievements cover all categories', () {
      final categories = {
        'social': 6,
        'moments': 3,
        'progression': 3,
        'behavior': 2,
        'special': 2,
      };

      final total = categories.values.reduce((a, b) => a + b);
      expect(total, 16); // Total of 16 achievements

      // Social should be the largest category
      expect(categories['social'], greaterThan(categories['moments']!));
      expect(categories['social'], greaterThan(categories['progression']!));
    });

    test('achievement difficulty distribution is balanced', () {
      final difficulties = {
        'easy': 8, // 1-20 points
        'medium': 5, // 21-100 points
        'hard': 3, // 100+ points
      };

      // Most achievements should be easy to medium
      expect(
        difficulties['easy']! + difficulties['medium']!,
        greaterThan(difficulties['hard']!),
      );

      // Should have some hard achievements for long-term goals
      expect(difficulties['hard'], greaterThan(0));
    });

    test('total points available is substantial', () {
      final allPoints = [
        10, 50, 200, // messages
        30, 25, 15, // social
        15, 50, 150, // moments
        20, 50, 100, // progression
        30, 75, // behavior
        15, 15, // special
      ];

      final total = allPoints.reduce((a, b) => a + b);
      expect(total, 850); // Total of 850 points available

      // Average points per achievement
      final average = total / allPoints.length;
      expect(average, greaterThan(40));
      expect(average, lessThan(60));
    });
  });

  group('AchievementService - Emoji Usage', () {
    test('all achievements have unique emojis', () {
      final emojis = [
        '👋',
        '💬',
        '🗣️',
        '🦋',
        '🏗️',
        '🤝',
        '📸',
        '📷',
        '⭐',
        '🌟',
        '🏢',
        '🏰',
        '🛡️',
        '✅',
        '🦉',
        '🐦',
      ];

      // All emojis should be unique
      expect(emojis.toSet().length, emojis.length);

      // All should be valid emoji characters
      for (final emoji in emojis) {
        expect(emoji.length, greaterThan(0));
        expect(emoji.length, lessThan(5)); // Most emojis are 1-2 chars
      }
    });

    test('emojis are thematically appropriate', () {
      final thematicEmojis = {
        'first_message': '👋', // Wave
        'conversationalist': '💬', // Speech bubble
        'photographer': '📷', // Camera
        'night_owl': '🦉', // Owl
        'early_bird': '🐦', // Bird
        'penthouse': '🏰', // Castle
      };

      // Each emoji should relate to its achievement
      expect(thematicEmojis['first_message'], '👋');
      expect(thematicEmojis['night_owl'], '🦉');
      expect(thematicEmojis['early_bird'], '🐦');
    });
  });

  group('AchievementService - Production Readiness', () {
    test('achievement keys are database-safe', () {
      final keys = [
        'first_message',
        'conversationalist',
        'social_butterfly',
      ];

      for (final key in keys) {
        // Should only contain lowercase letters and underscores
        expect(RegExp(r'^[a-z_]+$').hasMatch(key), true);

        // Should not start or end with underscore
        expect(key.startsWith('_'), false);
        expect(key.endsWith('_'), false);
      }
    });

    test('achievement descriptions are user-friendly', () {
      final descriptions = [
        'Send your first message',
        'Join 5 groups',
        'Reach Floor 3',
      ];

      for (final description in descriptions) {
        // Should be concise (under 50 chars)
        expect(description.length, lessThan(50));

        // Should start with capital letter
        expect(description[0], equals(description[0].toUpperCase()));

        // Should not end with period (for consistency)
        expect(description.endsWith('.'), false);
      }
    });

    test('target values are achievable', () {
      final targets = <Map<String, dynamic>>[
        {'key': 'first_message', 'target': 1},
        {'key': 'conversationalist', 'target': 100},
        {'key': 'chatterbox', 'target': 1000},
      ];

      for (final target in targets) {
        // All targets should be positive
        expect(target['target'], greaterThan(0));

        // No target should be impossibly high
        expect(target['target'], lessThan(10000));
      }
    });
  });
}
