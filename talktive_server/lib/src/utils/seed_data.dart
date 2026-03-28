import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';

class SeedData {
  static Future<void> seedAchievements(Session session) async {
    final existing = await Achievement.db.count(session);
    if (existing > 0) return;

    session.log('Seeding: Initializing Achievements');

    final achievements = [
      Achievement(
        key: 'first_login',
        name: 'Welcome Home',
        description: 'Signed in to Talktive for the first time.',
        emoji: '🏠',
        category: 'Identity',
        points: 10,
      ),
      Achievement(
        key: 'social_butterfly',
        name: 'Social Butterfly',
        description: 'Joined your first community lounge.',
        emoji: '🦋',
        category: 'Social',
        points: 20,
      ),
      Achievement(
        key: 'lounge_owner',
        name: 'Architect',
        description: 'Created your own community lounge.',
        emoji: '🏗️',
        category: 'Social',
        points: 50,
      ),
      Achievement(
        key: 'conversationalist',
        name: 'Chatterbox',
        description: 'Sent 100 messages across the platform.',
        emoji: '💬',
        category: 'Social',
        targetValue: 100,
        points: 100,
      ),
      Achievement(
        key: 'creator_milestone',
        name: 'Community Pillar',
        description: 'Earned for growing your lounge to 10 members.',
        emoji: '💎',
        category: 'Creator',
        points: 25,
      ),
      Achievement(
        key: 'rising_star',
        name: 'Rising Star',
        description: 'Reached Floor 1.',
        emoji: '⭐',
        category: 'Progress',
        points: 50,
      ),
      Achievement(
        key: 'high_rise',
        name: 'High Rise',
        description: 'Reached Floor 2.',
        emoji: '🏙️',
        category: 'Progress',
        points: 100,
      ),
      Achievement(
        key: 'penthouse',
        name: 'Penthouse',
        description: 'Reached Floor 3.',
        emoji: '👑',
        category: 'Progress',
        points: 250,
      ),
    ];

    await Achievement.db.insert(session, achievements);
    session.log('Seeding: ${achievements.length} achievements created.');
  }
}
