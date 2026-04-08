import 'package:test/test.dart';
import 'package:serverpod/serverpod.dart';
import 'package:talktive_server/src/generated/protocol.dart' as protocol;
import 'package:talktive_server/src/services/mention_service.dart';
import 'package:talktive_server/src/services/notification_service.dart';
import 'dart:convert';
import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('MentionService Integration', (sessionBuilder, endpoints) {
    late protocol.Resident userA;
    late protocol.Resident userB;
    late protocol.Resident userC;
    late protocol.Channel plazaChannel;
    late protocol.Channel loungeChannel;

    setUp(() async {
      final session = sessionBuilder.build();

      // Clear existing data
      await protocol.Message.db.deleteWhere(
        session,
        where: (_) => Constant.bool(true),
      );
      await protocol.ChannelMember.db.deleteWhere(
        session,
        where: (_) => Constant.bool(true),
      );
      await protocol.Channel.db.deleteWhere(
        session,
        where: (_) => Constant.bool(true),
      );
      await protocol.Resident.db.deleteWhere(
        session,
        where: (_) => Constant.bool(true),
      );

      // Create test users
      userA = await protocol.Resident.db.insertRow(
        session,
        protocol.Resident(
          userInfoId: UuidValue.fromString(
            '550e8400-e29b-41d4-a716-446655440000',
          ),
          userName: 'UserA',
          level: 1,
          trustScore: 100,
        ),
      );

      userB = await protocol.Resident.db.insertRow(
        session,
        protocol.Resident(
          userInfoId: UuidValue.fromString(
            '550e8400-e29b-41d4-a716-446655440001',
          ),
          userName: 'UserB',
          level: 1,
          trustScore: 100,
        ),
      );

      userC = await protocol.Resident.db.insertRow(
        session,
        protocol.Resident(
          userInfoId: UuidValue.fromString(
            '550e8400-e29b-41d4-a716-446655440002',
          ),
          userName: 'UserC',
          level: 1,
          trustScore: 100,
        ),
      );

      // Create channels
      plazaChannel = await protocol.Channel.db.insertRow(
        session,
        protocol.Channel(
          type: protocol.ChannelType.plaza,
          name: 'Plaza',
          createdAt: DateTime.now(),
        ),
      );

      loungeChannel = await protocol.Channel.db.insertRow(
        session,
        protocol.Channel(
          type: protocol.ChannelType.lounge,
          name: 'Lounge',
          createdAt: DateTime.now(),
        ),
      );

      // Link Channel to a Lounge record
      await protocol.Lounge.db.insertRow(
        session,
        protocol.Lounge(
          channelId: loungeChannel.id!,
          name: 'Lounge',
          creatorId: userA.userInfoId,
          createdAt: DateTime.now(),
          level: 1,
          memberCount: 0,
          isPublic: true,
        ),
      );

      // Add User A and User B to Lounge
      await protocol.ChannelMember.db.insertRow(
        session,
        protocol.ChannelMember(
          channelId: loungeChannel.id!,
          userInfoId: userA.userInfoId,
          status: protocol.ChannelMemberStatus.joined,
          role: 'member',
          joinedAt: DateTime.now(),
        ),
      );

      await protocol.ChannelMember.db.insertRow(
        session,
        protocol.ChannelMember(
          channelId: loungeChannel.id!,
          userInfoId: userB.userInfoId,
          status: protocol.ChannelMemberStatus.joined,
          role: 'member',
          joinedAt: DateTime.now(),
        ),
      );
    });

    group('getMentionedUserIds', () {
      test('Plaza: detects users who have messaged recently', () async {
        final session = sessionBuilder.build();

        // User B sends a message in Plaza
        await protocol.Message.db.insertRow(
          session,
          protocol.Message(
            channelId: plazaChannel.id!,
            senderId: userB.userInfoId,
            senderName: 'UserB',
            content: 'Hello Plaza!',
            createdAt: DateTime.now(),
            isSystem: false,
            senderFloor: 1,
            senderTrustScore: 100,
          ),
        );

        // User A sends a message mentioning User B
        final mentionedIds = await MentionService.getMentionedUserIds(
          session,
          plazaChannel.id!,
          'Hey @UserB how are you?',
        );

        expect(mentionedIds, contains(userB.userInfoId));
        expect(mentionedIds, isNot(contains(userC.userInfoId)));
      });

      test(
        'Plaza: does NOT detect users who have NOT messaged recently',
        () async {
          final session = sessionBuilder.build();

          // User C has NOT sent any messages in Plaza

          final mentionedIds = await MentionService.getMentionedUserIds(
            session,
            plazaChannel.id!,
            'Hey @UserC are you there?',
          );

          // Should be empty because User C is not in the dynamic whitelist
          expect(mentionedIds, isEmpty);
        },
      );

      test('Lounge: detects members even if they haven\'t messaged', () async {
        final session = sessionBuilder.build();

        // User B is a member of the lounge but hasn't sent any messages

        final mentionedIds = await MentionService.getMentionedUserIds(
          session,
          loungeChannel.id!,
          'Hey @UserB join the conversation!',
        );

        expect(mentionedIds, contains(userB.userInfoId));
      });

      test('Lounge: does NOT detect non-members', () async {
        final session = sessionBuilder.build();

        // User C is NOT a member of the lounge

        final mentionedIds = await MentionService.getMentionedUserIds(
          session,
          loungeChannel.id!,
          'Hey @UserC you are not here!',
        );

        expect(mentionedIds, isEmpty);
      });

      test('handles multiple mentions and case insensitivity', () async {
        final session = sessionBuilder.build();

        // User B sends a message in Plaza
        await protocol.Message.db.insertRow(
          session,
          protocol.Message(
            channelId: plazaChannel.id!,
            senderId: userB.userInfoId,
            senderName: 'UserB',
            content: 'I am here',
            createdAt: DateTime.now(),
            isSystem: false,
            senderFloor: 1,
            senderTrustScore: 100,
          ),
        );

        // User C also sends a message in Plaza
        await protocol.Message.db.insertRow(
          session,
          protocol.Message(
            channelId: plazaChannel.id!,
            senderId: userC.userInfoId,
            senderName: 'UserC',
            content: 'Me too',
            createdAt: DateTime.now(),
            isSystem: false,
            senderFloor: 1,
            senderTrustScore: 100,
          ),
        );

        final mentionedIds = await MentionService.getMentionedUserIds(
          session,
          plazaChannel.id!,
          'Calling @userb and @USERC!',
        );

        expect(mentionedIds, hasLength(2));
        expect(mentionedIds, containsAll([userB.userInfoId, userC.userInfoId]));
      });
    });

    group('Notification Routing Regression', () {
      test('Plaza: mention notification uses /plaza/chat route', () async {
        final session = sessionBuilder.build();

        // Trigger a mention notification
        await NotificationService.sendMentionNotification(
          session,
          userB.userInfoId,
          'UserA',
          'Hey @UserB!',
          plazaChannel.id!,
          'Plaza',
          channel: plazaChannel,
        );

        // Verify the notification record in DB
        final notifications = await protocol.UserNotification.db.find(
          session,
          where: (t) => t.userId.equals(userB.userInfoId),
          orderBy: (t) => t.createdAt,
          orderDescending: true,
        );

        expect(notifications, isNotEmpty);
        final latest = notifications.first;
        expect(latest.type, 'mention');

        final data = jsonDecode(latest.data!) as Map<String, dynamic>;
        expect(data['route'], '/plaza/chat');
      });

      test(
        'Lounge: mention notification uses /lounges/chat/ID route',
        () async {
          final session = sessionBuilder.build();

          await NotificationService.sendMentionNotification(
            session,
            userB.userInfoId,
            'UserA',
            'Hey @UserB!',
            loungeChannel.id!,
            'Lounge',
            channel: loungeChannel,
          );

          final notifications = await protocol.UserNotification.db.find(
            session,
            where: (t) => t.userId.equals(userB.userInfoId),
            orderBy: (t) => t.createdAt,
            orderDescending: true,
          );

          final latest = notifications.first;
          final data = jsonDecode(latest.data!) as Map<String, dynamic>;
          // Should contain /lounges/chat/
          expect(data['route'], startsWith('/lounges/chat/'));
        },
      );
    });
  });
}
