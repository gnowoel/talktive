import 'package:test/test.dart';
import 'package:serverpod/serverpod.dart';
import 'package:talktive_server/src/generated/protocol.dart' as protocol;
import 'package:talktive_server/src/services/content_ephemerality_service.dart';
import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Given ContentEphemeralityService', (sessionBuilder, endpoints) {
    late protocol.Resident testUser;
    late protocol.Channel privateChannel;

    setUp(() async {
      final session = sessionBuilder.build();

      // Create a test user (Regular)
      final resident = protocol.Resident(
        userInfoId: UuidValue.fromString('a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d'),
        userName: 'Test User',
        trustScore: 100,
        role: protocol.ResidentRole.user,
        keepPrivateChats: false,
        isPremium: false,
      );
      testUser = await protocol.Resident.db.insertRow(session, resident);

      // Create a test Private channel
      final channel = protocol.Channel(
        type: protocol.ChannelType.private,
        name: 'Test Private',
        isPersistent: false,
        createdAt: DateTime.now().subtract(const Duration(days: 40)),
      );
      privateChannel = await protocol.Channel.db.insertRow(session, channel);

      // Add user to channel
      await protocol.ChannelMember.db.insertRow(
        session,
        protocol.ChannelMember(
          channelId: privateChannel.id!,
          userInfoId: testUser.userInfoId,
          joinedAt: DateTime.now().subtract(const Duration(days: 40)),
          status: protocol.ChannelMemberStatus.joined,
        ),
      );
    });

    group('_cleanupPrivateMessages', () {
      test('cleans up old messages for regular users', () async {
        final session = sessionBuilder.build();

        // Create an old message
        await protocol.Message.db.insertRow(
          session,
          protocol.Message(
            channelId: privateChannel.id!,
            senderId: testUser.userInfoId,
            senderName: testUser.userName ?? 'Test',
            senderFloor: 1,
            senderTrustScore: 100,
            content: 'Old message',
            createdAt: DateTime.now().subtract(const Duration(days: 35)),
            isSystem: false,
          ),
        );

        final result = await ContentEphemeralityService.runCleanup(session);
        expect(result['private_messages'], 1);

        final count = await protocol.Message.db.count(session);
        expect(count, 0);
      });

      test('retains old messages for users with keepPrivateChats = true', () async {
        final session = sessionBuilder.build();

        // Enable keepPrivateChats
        testUser.keepPrivateChats = true;
        await protocol.Resident.db.updateRow(session, testUser);

        // Create an old message
        await protocol.Message.db.insertRow(
          session,
          protocol.Message(
            channelId: privateChannel.id!,
            senderId: testUser.userInfoId,
            senderName: testUser.userName ?? 'Test',
            senderFloor: 1,
            senderTrustScore: 100,
            content: 'Old message',
            createdAt: DateTime.now().subtract(const Duration(days: 35)),
            isSystem: false,
          ),
        );

        final result = await ContentEphemeralityService.runCleanup(session);
        expect(result['private_messages'], 0);

        final count = await protocol.Message.db.count(session);
        expect(count, 1);
      });

      test('retains old messages for users in grace period (expired < 14 days ago)', () async {
        final session = sessionBuilder.build();

        // Premium expired 5 days ago (within 14-day grace period)
        testUser.keepPrivateChats = false;
        testUser.isPremium = false;
        testUser.premiumTrialExpires = DateTime.now().subtract(const Duration(days: 5));
        await protocol.Resident.db.updateRow(session, testUser);

        // Create an old message
        await protocol.Message.db.insertRow(
          session,
          protocol.Message(
            channelId: privateChannel.id!,
            senderId: testUser.userInfoId,
            senderName: testUser.userName ?? 'Test',
            senderFloor: 1,
            senderTrustScore: 100,
            content: 'Old message',
            createdAt: DateTime.now().subtract(const Duration(days: 35)),
            isSystem: false,
          ),
        );

        final result = await ContentEphemeralityService.runCleanup(session);
        expect(result['private_messages'], 0);

        final count = await protocol.Message.db.count(session);
        expect(count, 1);
      });

      test('cleans up old messages for users whose grace period expired (> 14 days ago)', () async {
        final session = sessionBuilder.build();

        // Premium expired 15 days ago (outside 14-day grace period)
        testUser.keepPrivateChats = false;
        testUser.isPremium = false;
        testUser.premiumTrialExpires = DateTime.now().subtract(const Duration(days: 15));
        await protocol.Resident.db.updateRow(session, testUser);

        // Create an old message
        await protocol.Message.db.insertRow(
          session,
          protocol.Message(
            channelId: privateChannel.id!,
            senderId: testUser.userInfoId,
            senderName: testUser.userName ?? 'Test',
            senderFloor: 1,
            senderTrustScore: 100,
            content: 'Old message',
            createdAt: DateTime.now().subtract(const Duration(days: 35)),
            isSystem: false,
          ),
        );

        final result = await ContentEphemeralityService.runCleanup(session);
        expect(result['private_messages'], 1);

        final count = await protocol.Message.db.count(session);
        expect(count, 0);
      });
    });
  });
}
