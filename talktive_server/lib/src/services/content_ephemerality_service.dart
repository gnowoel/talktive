import 'package:serverpod/serverpod.dart';
import 'package:talktive_server/src/generated/protocol.dart' as protocol;

/// Service for implementing Talktive's ephemerality and content management solution.
/// This service automates the deletion of old user-generated content (GGC)
/// to maintain privacy, save server resources, and improve application performance.
///
/// Refactored from the previous [DataArchivalService] for better robustness.
class ContentEphemeralityService {
  /// DURATIONS (Policy)
  /// These can be moved to a configuration file in the future.
  static const plazaMessageLifetime = Duration(hours: 24);
  static const loungeMessageLifetime = Duration(days: 14);
  static const privateChatMessageLifetime = Duration(days: 30);
  static const momentLifetime = Duration(days: 7);
  static const readNotificationLifetime = Duration(days: 1);
  static const unreadNotificationLifetime = Duration(days: 30);
  static const resolvedReportLifetime = Duration(days: 30);

  /// Run all scheduled cleanup tasks.
  static Future<Map<String, int>> runCleanup(Session session) async {
    session.log('TALKTIVE: Starting scheduled content ephemerality cleanup...', level: LogLevel.info);
    final results = <String, int>{};

    try {
      // 1. Clean up messages based on channel type
      results['plaza_messages'] = await _cleanupPlazaMessages(session);
      results['lounge_messages'] = await _cleanupLoungeMessages(session);
      results['private_messages'] = await _cleanupPrivateMessages(session);

      // 2. Clean up moments (and linked likes/comments)
      results['moments'] = await _cleanupMoments(session);

      // 3. Clean up notifications
      results['notifications'] = await _cleanupNotifications(session);

      // 4. Clean up resolved reports
      results['reports'] = await _cleanupReports(session);

      final totalCleaned = results.values.fold(0, (prev, element) => prev + element);
      session.log('TALKTIVE: Content cleanup completed. Total ephemeral items removed: $totalCleaned', level: LogLevel.info);
    } catch (e, stack) {
      session.log('TALKTIVE: CRITICAL ERROR during content cleanup: $e\n$stack', level: LogLevel.error);
    }

    return results;
  }

  // --- INTERNAL CLEANUP HELPERS ---

  static Future<int> _cleanupPlazaMessages(Session session) async {
    final cutoff = DateTime.now().subtract(plazaMessageLifetime);
    
    // Find Plaza Channel ID
    final plazaChannel = await protocol.Channel.db.findFirstRow(
      session,
      where: (t) => t.type.equals(protocol.ChannelType.plaza),
    );
    
    if (plazaChannel == null) return 0;

    final deleted = await protocol.Message.db.deleteWhere(
      session,
      where: (t) => (t.channelId.equals(plazaChannel.id!)) & (t.createdAt < cutoff),
    );

    return deleted.length;
  }

  static Future<int> _cleanupLoungeMessages(Session session) async {
    final cutoff = DateTime.now().subtract(loungeMessageLifetime);
    
    // Get all Lounge Channel IDs (excluding persistent ones)
    final loungeChannels = await protocol.Channel.db.find(
      session,
      where: (t) => t.type.equals(protocol.ChannelType.lounge) & t.isPersistent.equals(false),
    );
    
    if (loungeChannels.isEmpty) return 0;
    
    final ids = loungeChannels.map((c) => c.id!).toSet();
    final deleted = await protocol.Message.db.deleteWhere(
      session,
      where: (t) => (t.channelId.inSet(ids)) & (t.createdAt < cutoff),
    );

    return deleted.length;
  }

  static Future<int> _cleanupPrivateMessages(Session session) async {
    final cutoff = DateTime.now().subtract(privateChatMessageLifetime);
    
    // 1. Get all non-persistent Private Channels
    final privateChannels = await protocol.Channel.db.find(
      session,
      where: (t) => t.type.equals(protocol.ChannelType.private) & t.isPersistent.equals(false),
    );
    
    if (privateChannels.isEmpty) return 0;
    
    final candidateIds = privateChannels.map((c) => c.id!).toSet();

    // 2. Identify which ones should be kept due to Resident.keepPrivateChats == true
    final memberships = await protocol.ChannelMember.db.find(
      session,
      where: (t) => t.channelId.inSet(candidateIds),
    );

    final userUuids = memberships.map((m) => m.userInfoId).toSet();
    final residentsWithPersistence = await protocol.Resident.db.find(
      session,
      where: (t) => t.userInfoId.inSet(userUuids) & t.keepPrivateChats.equals(true),
    );

    final persistentUserIds = residentsWithPersistence.map((r) => r.userInfoId).toSet();
    
    // Map channels to their members' persistence status
    final channelIdsWithPersistence = <int>{};
    for (final m in memberships) {
      if (persistentUserIds.contains(m.userInfoId)) {
        channelIdsWithPersistence.add(m.channelId);
      }
    }

    // 3. Final cleanup set: candidates MINUS those with persistence
    final cleanupSet = candidateIds.where((id) => !channelIdsWithPersistence.contains(id)).toSet();

    if (cleanupSet.isEmpty) return 0;

    final deleted = await protocol.Message.db.deleteWhere(
      session,
      where: (t) => (t.channelId.inSet(cleanupSet)) & (t.createdAt < cutoff),
    );

    return deleted.length;
  }

  static Future<int> _cleanupMoments(Session session) async {
    final cutoff = DateTime.now().subtract(momentLifetime);
    
    // Find old moments to fetch their IDs (for cleaning up likes and comments)
    final oldMoments = await protocol.Moment.db.find(
      session,
      where: (t) => t.createdAt < cutoff,
      limit: 500, // Safe batch limit
    );
    
    if (oldMoments.isEmpty) return 0;
    
    final ids = oldMoments.map((m) => m.id!).toSet();
    
    // 1. Clean up likes and comments associated with these moments
    await protocol.MomentLike.db.deleteWhere(session, where: (t) => t.momentId.inSet(ids));
    await protocol.MomentComment.db.deleteWhere(session, where: (t) => t.momentId.inSet(ids));
    
    // 2. Clear out the moments themselves
    final deleted = await protocol.Moment.db.deleteWhere(session, where: (t) => t.id.inSet(ids));
    return deleted.length;
  }

  static Future<int> _cleanupNotifications(Session session) async {
    final readCutoff = DateTime.now().subtract(readNotificationLifetime);
    final unreadCutoff = DateTime.now().subtract(unreadNotificationLifetime);
    
    // Delete old read notifications (very aggressive, 24h)
    final readDeleted = await protocol.UserNotification.db.deleteWhere(
      session, 
      where: (t) => (t.read.equals(true)) & (t.createdAt < readCutoff)
    );
    
    // Delete old unread notifications (30 days)
    final unreadDeleted = await protocol.UserNotification.db.deleteWhere(
      session, 
      where: (t) => (t.read.equals(false)) & (t.createdAt < unreadCutoff)
    );
    
    return readDeleted.length + unreadDeleted.length;
  }

  static Future<int> _cleanupReports(Session session) async {
    final cutoff = DateTime.now().subtract(resolvedReportLifetime);
    
    // Delete resolved reports older than 30 days
    final deleted = await protocol.Report.db.deleteWhere(
      session,
      where: (t) => (t.resolvedAt.notEquals(null)) & (t.resolvedAt < cutoff)
    );
    return deleted.length;
  }

  /// Get statistics about data that can be cleaned up.
  static Future<Map<String, int>> getCleanupStats(Session session) async {
    final stats = <String, int>{};
    final now = DateTime.now();

    // Plaza Channel
    final plazaChannel = await protocol.Channel.db.findFirstRow(
      session,
      where: (t) => t.type.equals(protocol.ChannelType.plaza),
    );
    if (plazaChannel != null) {
      stats['archivablePlazaMessages'] = await protocol.Message.db.count(
        session,
        where: (t) => (t.channelId.equals(plazaChannel.id!)) & (t.createdAt < now.subtract(plazaMessageLifetime)),
      );
    }

    // Lounge Messages
    final loungeChannels = await protocol.Channel.db.find(session, where: (t) => t.type.equals(protocol.ChannelType.lounge));
    if (loungeChannels.isNotEmpty) {
      stats['archivableLoungeMessages'] = await protocol.Message.db.count(
        session,
        where: (t) => (t.channelId.inSet(loungeChannels.map((c) => c.id!).toSet())) & (t.createdAt < now.subtract(loungeMessageLifetime)),
      );
    }

    // Moments
    stats['archivableMoments'] = await protocol.Moment.db.count(
      session,
      where: (t) => t.createdAt < now.subtract(momentLifetime),
    );

    // Notifications
    stats['archivableReadNotifications'] = await protocol.UserNotification.db.count(
      session,
      where: (t) => (t.read.equals(true)) & (t.createdAt < now.subtract(readNotificationLifetime)),
    );

    // Reports
    stats['archivableResolvedReports'] = await protocol.Report.db.count(
      session,
      where: (t) => (t.resolvedAt.notEquals(null)) & (t.resolvedAt < now.subtract(resolvedReportLifetime)),
    );

    return stats;
  }
}
