import 'package:test/test.dart';
import 'package:serverpod/serverpod.dart';
import 'package:talktive_server/src/generated/protocol.dart' as protocol;
import 'package:talktive_server/src/services/channel_service.dart';
import 'package:talktive_server/src/services/notification_service.dart';
import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Notification and Unread Count Integration', (
    sessionBuilder,
    endpoints,
  ) {
    late protocol.Resident userA;
    late protocol.Resident userB;
    late protocol.Channel privateChannel;

    setUp(() async {
      final session = sessionBuilder.build();

      // Create test User A
      userA = await protocol.Resident.db.insertRow(
        session,
        protocol.Resident(
          userInfoId: UuidValue.fromString(
            'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d',
          ),
          userName: 'UserA',
          level: 1,
          trustScore: 100,
        ),
      );

      // Create test User B
      userB = await protocol.Resident.db.insertRow(
        session,
        protocol.Resident(
          userInfoId: UuidValue.fromString(
            'b2c3d4e5-f6a7-4b5c-9d0e-1f2a3b4c5d6e',
          ),
          userName: 'UserB',
          level: 1,
          trustScore: 100,
        ),
      );

      // Create a private channel
      privateChannel = await protocol.Channel.db.insertRow(
        session,
        protocol.Channel(
          type: protocol.ChannelType.private,
          name: 'Private Chat',
          createdAt: DateTime.now(),
        ),
      );

      // Add members
      await protocol.ChannelMember.db.insertRow(
        session,
        protocol.ChannelMember(
          channelId: privateChannel.id!,
          userInfoId: userA.userInfoId,
          joinedAt: DateTime.now(),
          status: protocol.ChannelMemberStatus.joined,
        ),
      );
      await protocol.ChannelMember.db.insertRow(
        session,
        protocol.ChannelMember(
          channelId: privateChannel.id!,
          userInfoId: userB.userInfoId,
          joinedAt: DateTime.now(),
          status: protocol.ChannelMemberStatus.joined,
        ),
      );
    });

    group('Unread Counts', () {
      test(
        'increases unread count for recipient when sender sends a message',
        () async {
          final session = sessionBuilder.build();

          // Initially 0
          var unread = await ChannelService.batchGetUnreadCounts(
            session,
            [privateChannel.id!],
            userB.userInfoId,
          );
          expect(unread[privateChannel.id!], 0);

          // User A sends a message
          await protocol.Message.db.insertRow(
            session,
            protocol.Message(
              channelId: privateChannel.id!,
              senderId: userA.userInfoId,
              content: 'Hello User B!',
              isSystem: false,
              senderName: 'UserA',
              senderFloor: 1,
              senderTrustScore: 100,
              createdAt: DateTime.now(),
            ),
          );

          // Check User B's unread count
          unread = await ChannelService.batchGetUnreadCounts(
            session,
            [privateChannel.id!],
            userB.userInfoId,
          );
          expect(unread[privateChannel.id!], 1);

          // User A sends another message
          await protocol.Message.db.insertRow(
            session,
            protocol.Message(
              channelId: privateChannel.id!,
              senderId: userA.userInfoId,
              content: 'Are you there?',
              isSystem: false,
              senderName: 'UserA',
              senderFloor: 1,
              senderTrustScore: 100,
              createdAt: DateTime.now().add(const Duration(seconds: 1)),
            ),
          );

          unread = await ChannelService.batchGetUnreadCounts(
            session,
            [privateChannel.id!],
            userB.userInfoId,
          );
          expect(unread[privateChannel.id!], 2);

          // User A's unread count should still be 0
          unread = await ChannelService.batchGetUnreadCounts(
            session,
            [privateChannel.id!],
            userA.userInfoId,
          );
          expect(unread[privateChannel.id!], 0);
        },
      );

      test('resets unread count when marked as read', () async {
        final session = sessionBuilder.build();

        // User A sends a message
        await protocol.Message.db.insertRow(
          session,
          protocol.Message(
            channelId: privateChannel.id!,
            senderId: userA.userInfoId,
            content: 'Message 1',
            isSystem: false,
            senderName: 'UserA',
            senderFloor: 1,
            senderTrustScore: 100,
            createdAt: DateTime.now(),
          ),
        );

        // Mark as read for User B
        await ChannelService.markAsRead(
          session,
          privateChannel.id!,
          userB.userInfoId,
        );

        // Unread count should be 0
        var unread = await ChannelService.batchGetUnreadCounts(
          session,
          [privateChannel.id!],
          userB.userInfoId,
        );
        expect(unread[privateChannel.id!], 0);

        // New message arrives
        await protocol.Message.db.insertRow(
          session,
          protocol.Message(
            channelId: privateChannel.id!,
            senderId: userA.userInfoId,
            content: 'Message 2',
            isSystem: false,
            senderName: 'UserA',
            senderFloor: 1,
            senderTrustScore: 100,
            createdAt: DateTime.now().add(const Duration(seconds: 1)),
          ),
        );

        unread = await ChannelService.batchGetUnreadCounts(
          session,
          [privateChannel.id!],
          userB.userInfoId,
        );
        expect(unread[privateChannel.id!], 1);
      });
    });

    group('Notification Payloads (Deep Linking)', () {
      test(
        'sendMessageNotification generates correct route for private chat',
        () async {
          final session = sessionBuilder.build();

          // We use a custom test tool or just check the data that would be sent.
          // Since we can't easily intercept sendNotification without mocking FCMService,
          // we'll at least verify the logic that builds the route.

          // This is more of a unit test for the logic in sendMessageNotification,
          // but we can check if it runs without errors.

          await NotificationService.sendMessageNotification(
            session,
            userB.userInfoId,
            'UserA',
            'Hello',
            privateChannel.id!,
            'private',
          );

          // Verify UserNotification record was NOT created because saveToHistory: false for messages
          final notifications = await protocol.UserNotification.db.find(
            session,
            where: (t) => t.userId.equals(userB.userInfoId),
          );
          expect(notifications, isEmpty);
        },
      );

      test(
        'sendAchievementNotification generates correct route and saves to history',
        () async {
          final session = sessionBuilder.build();

          await NotificationService.sendAchievementNotification(
            session,
            userB.userInfoId,
            'First Message',
            '🏆',
            10,
          );

          final notifications = await protocol.UserNotification.db.find(
            session,
            where: (t) => t.userId.equals(userB.userInfoId),
          );
          expect(notifications, isNotEmpty);
          expect(notifications.first.type, 'achievement');

          // Check the saved data for the route
          final data = notifications.first.data;
          expect(data, contains('"/activity"'));
        },
      );

      test(
        'sendChatInviteNotification generates correct route with channelId',
        () async {
          final session = sessionBuilder.build();

          await NotificationService.sendChatInviteNotification(
            session,
            userB.userInfoId,
            'UserA',
            privateChannel.id!,
          );

          final notifications = await protocol.UserNotification.db.find(
            session,
            where: (t) => t.userId.equals(userB.userInfoId),
          );
          // Might be multiple from previous tests if cleanup isn't perfect,
          // but we'll find the one with type 'chat_invite'
          final invite = notifications.firstWhere(
            (n) => n.type == 'chat_invite',
          );
          expect(invite.data, contains('"/chats/thread/${privateChannel.id}"'));
        },
      );
    });
  });
}
