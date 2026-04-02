import 'package:test/test.dart';
import 'package:serverpod/serverpod.dart';
import 'package:talktive_server/src/generated/protocol.dart' as protocol;
import 'package:talktive_server/src/services/messaging_service.dart';
import 'package:talktive_server/src/services/lounge_service.dart';
import 'package:talktive_server/src/services/private_chat_service.dart';
import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Messaging Recall Sync Integration', (
    sessionBuilder,
    endpoints,
  ) {
    late protocol.Resident testUser;

    setUp(() async {
      final session = sessionBuilder.build();
      // Use a consistent UUID for predictability
      final userUuid = UuidValue.fromString(
        'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d',
      );

      // Cleanup existing test user if any
      final existing = await protocol.Resident.db.findFirstRow(
        session,
        where: (t) => t.userInfoId.equals(userUuid),
      );
      if (existing != null) {
        await protocol.Resident.db.deleteRow(session, existing);
      }

      final resident = protocol.Resident(
        userInfoId: userUuid,
        userName: 'Test User',
        level: 1,
        trustScore: 100,
        role: protocol.ResidentRole.user,
      );
      testUser = await protocol.Resident.db.insertRow(session, resident);
    });

    test(
      'Lounge lastMessageAt syncs back to previous message after recall',
      () async {
        final session = sessionBuilder.build();

        // 1. Create a lounge
        final lounge = await LoungeService.createLounge(
          session,
          name: 'Sync Test Lounge',
          creatorId: testUser.userInfoId,
        );

        final channelId = lounge.channelId;

        // 2. Send Message 1 at T1
        final t1 = DateTime.now().subtract(const Duration(minutes: 10));
        final msg1 = protocol.Message(
          channelId: channelId,
          senderId: testUser.userInfoId,
          content: 'Historical Message',
          createdAt: t1,
          isSystem: false,
          senderName: 'Test User',
          senderFloor: 1,
          senderTrustScore: 100,
        );
        await protocol.Message.db.insertRow(session, msg1);

        // Manually trigger sync for msg1
        await MessagingService.onMessageSaved(
          session,
          message: msg1,
          channel: (await protocol.Channel.db.findById(session, channelId))!,
          sender: testUser,
        );

        final msg2 = await MessagingService.sendMessage(
          session,
          sender: testUser,
          channel: (await protocol.Channel.db.findById(session, channelId))!,
          content: 'Latest Message',
        );

        // Manually trigger sync for msg2 (since sendMessage backgrounds it)
        await MessagingService.onMessageSaved(
          session,
          message: msg2,
          channel: (await protocol.Channel.db.findById(session, channelId))!,
          sender: testUser,
        );

        // Check current state
        var currentLounge = await protocol.Lounge.db.findFirstRow(
          session,
          where: (t) => t.id.equals(lounge.id),
        );

        expect(currentLounge, isNotNull);
        final tLatest = currentLounge!.lastMessageAt!;
        expect(currentLounge.lastMessage, equals('Latest Message'));

        // 3. Find that latest message
        final latestMsg = await protocol.Message.db.findFirstRow(
          session,
          where: (t) => t.channelId.equals(channelId),
          orderBy: (t) => t.createdAt,
          orderDescending: true,
        );

        expect(latestMsg!.content, equals('Latest Message'));

        // 4. Recall the latest message
        await MessagingService.recallMessage(
          session,
          messageId: latestMsg.id!,
          resident: testUser,
        );

        // 5. Verify lounge sync
        currentLounge = await protocol.Lounge.db.findFirstRow(
          session,
          where: (t) => t.id.equals(lounge.id),
        );

        expect(currentLounge!.lastMessage, equals('Historical Message'));
        expect(
          currentLounge.lastMessageAt!.isBefore(tLatest),
          isTrue,
          reason:
              'lastMessageAt should have moved back to historical message time',
        );
      },
    );

    test('PrivateChat lastMessage syncs back after recall', () async {
      final session = sessionBuilder.build();

      // 1. Create a private chat
      final otherUserId = UuidValue.fromString(
        'b2c3d4e5-f6a7-4b8c-9d0e-1f2a3b4c5d6e',
      );

      // Cleanup existing other user if any
      final existingOther = await protocol.Resident.db.findFirstRow(
        session,
        where: (t) => t.userInfoId.equals(otherUserId),
      );
      if (existingOther != null) {
        await protocol.Resident.db.deleteRow(session, existingOther);
      }

      await protocol.Resident.db.insertRow(
        session,
        protocol.Resident(
          userInfoId: otherUserId,
          userName: 'Other User',
          level: 1,
          role: protocol.ResidentRole.user,
        ),
      );

      final chat = await PrivateChatService.getOrCreatePrivateChat(
        session,
        sender: testUser,
        otherUserId: otherUserId,
      );

      final channelId = chat.channelId;
      final channel = (await protocol.Channel.db.findById(session, channelId))!;

      // 2. Send 2 messages
      final msg1 = await MessagingService.sendMessage(
        session,
        sender: testUser,
        channel: channel,
        content: 'I want to talk',
      );
      // Wait for background tasks or manually trigger
      await MessagingService.onMessageSaved(
        session,
        message: msg1,
        channel: channel,
        sender: testUser,
      );

      final msg2 = await MessagingService.sendMessage(
        session,
        sender: testUser,
        channel: channel,
        content: 'Actually nevermind',
      );
      await MessagingService.onMessageSaved(
        session,
        message: msg2,
        channel: channel,
        sender: testUser,
      );

      // Verify current state
      var currentChat = await protocol.PrivateChat.db.findById(
        session,
        chat.id!,
      );
      expect(currentChat!.lastMessage, equals('Actually nevermind'));

      // 3. Recall msg2
      await MessagingService.recallMessage(
        session,
        messageId: msg2.id!,
        resident: testUser,
      );

      // 4. Verify private chat sync
      currentChat = await protocol.PrivateChat.db.findById(session, chat.id!);
      expect(currentChat!.lastMessage, equals('I want to talk'));

      // 5. Recall msg1 (all messages recalled)
      await MessagingService.recallMessage(
        session,
        messageId: msg1.id!,
        resident: testUser,
      );

      currentChat = await protocol.PrivateChat.db.findById(session, chat.id!);
      expect(currentChat!.lastMessage, isNull);
    });
  });
}
