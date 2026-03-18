import 'package:serverpod/serverpod.dart';
import 'package:talktive_server/src/generated/protocol.dart';
import 'gamification_service.dart';

/// Service for managing Lounge logic and discovery.
class LoungeService {
  /// Creates a new lounge and its associated channel and members.
  static Future<Lounge> createLounge(
    Session session, {
    required String name,
    required UuidValue creatorId,
    String? description,
    String? emoji,
    bool isPublic = false,
    int maxMembers = 50,
    List<String>? interests,
  }) async {
    // 1. Create a new channel for this lounge
    final channel = Channel(
      name: name,
      type: ChannelType.lounge,
      createdAt: DateTime.now(),
    );

    final savedChannel = await Channel.db.insertRow(session, channel);

    // 2. Create the lounge record
    final lounge = Lounge(
      channelId: savedChannel.id!,
      name: name,
      description: description,
      emoji: emoji,
      creatorId: creatorId,
      createdAt: DateTime.now(),
      memberCount: 1,
      isPublic: isPublic,
      maxMembers: maxMembers,
      interests: interests,
    );

    final savedLounge = await Lounge.db.insertRow(session, lounge);

    // 3. Add creator as first member with admin role
    await ChannelMember.db.insertRow(
      session,
      ChannelMember(
        channelId: savedChannel.id!,
        userInfoId: creatorId,
        status: ChannelMemberStatus.joined,
        joinedAt: DateTime.now(),
        role: 'admin',
      ),
    );

    // 4. Track achievement
    await GamificationService.trackProgress(
      session,
      creatorId,
      'community_builder',
    );

    return savedLounge;
  }

  /// Searches for public lounges by name or description.
  static Future<List<Lounge>> searchLounges(
    Session session,
    String query, {
    int limit = 20,
    int offset = 0,
  }) async {
    if (query.trim().isEmpty) return [];

    return await Lounge.db.find(
      session,
      where: (t) =>
          t.isPublic.equals(true) &
          (t.name.ilike('%$query%') | t.description.ilike('%$query%')),
      orderBy: (t) => t.memberCount,
      orderDescending: true,
      limit: limit,
      offset: offset,
    );
  }

  /// Gets popular lounges (most members).
  static Future<List<Lounge>> getPopularLounges(
    Session session, {
    int limit = 10,
  }) async {
    return await Lounge.db.find(
      session,
      where: (t) => t.isPublic.equals(true),
      orderBy: (t) => t.memberCount,
      orderDescending: true,
      limit: limit,
    );
  }

  /// Gets personalized lounge recommendations based on resident interests.
  static Future<List<Lounge>> getRecommendedLounges(
    Session session,
    Resident resident, {
    int limit = 10,
    int offset = 0,
  }) async {
    if (resident.interests == null || resident.interests!.isEmpty) {
      return await getPopularLounges(session, limit: limit);
    }

    // Find public lounges
    final allPublicLounges = await Lounge.db.find(
      session,
      where: (t) => t.isPublic.equals(true),
      limit: 100, // Reasonable scan limit for personalization
    );

    // Sort by interest match count
    allPublicLounges.sort((a, b) {
      final aMatch =
          a.interests?.where((i) => resident.interests!.contains(i)).length ??
          0;
      final bMatch =
          b.interests?.where((i) => resident.interests!.contains(i)).length ??
          0;
      if (aMatch != bMatch) return bMatch.compareTo(aMatch);
      return b.memberCount.compareTo(a.memberCount);
    });

    return allPublicLounges.skip(offset).take(limit).toList();
  }
}
