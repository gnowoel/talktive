import 'package:test/test.dart';
import 'package:serverpod/serverpod.dart';
import 'package:talktive_server/src/generated/protocol.dart' as protocol;
import 'package:talktive_server/src/services/gamification_service.dart';
import 'package:talktive_server/src/services/messaging_service.dart';
import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Given MessagingService', (sessionBuilder, endpoints) {
    late protocol.Resident testUser;
    late protocol.Channel plazaChannel;

    setUp(() async {
      final session = sessionBuilder.build();

      // Create a test user
      final resident = protocol.Resident(
        userInfoId: UuidValue.fromString(
          'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d',
        ),
        level: 1, // Floor 1
        trustScore: 100,
        role: protocol.ResidentRole.user,
      );
      testUser = await protocol.Resident.db.insertRow(session, resident);

      // Create a test Plaza channel
      final channel = protocol.Channel(
        type: protocol.ChannelType.plaza,
        name: 'Test Plaza',
        createdAt: DateTime.now(),
      );
      plazaChannel = await protocol.Channel.db.insertRow(session, channel);
    });

    group('getOrCreatePrivateChat', () {
      test(
        'throws SELF_CHAT_NOT_ALLOWED when creating chat with yourself',
        () async {
          final session = sessionBuilder.build();

          expect(
            () => MessagingService.getOrCreatePrivateChat(
              session,
              sender: testUser,
              otherUserId: testUser.userInfoId,
            ),
            throwsA(
              isA<protocol.TalktiveException>().having(
                (e) => e.code,
                'code',
                'SELF_CHAT_NOT_ALLOWED',
              ),
            ),
          );
        },
      );
    });

    group('validateMessage', () {
      test('allows a simple text message from valid user', () async {
        final session = sessionBuilder.build();

        final filteredContent = await MessagingService.validateMessage(
          session,
          sender: testUser,
          channel: plazaChannel,
          content: 'Hello world!',
        );

        expect(filteredContent, 'Hello world!');
      });

      test('throws TalktiveException when user is muted', () async {
        final session = sessionBuilder.build();

        // Mute user
        testUser.trustScore = 0;
        await protocol.Resident.db.updateRow(session, testUser);

        expect(
          () => MessagingService.validateMessage(
            session,
            sender: testUser,
            channel: plazaChannel,
            content: 'Hello!',
          ),
          throwsA(
            isA<protocol.TalktiveException>().having(
              (e) => e.code,
              'code',
              'USER_MUTED',
            ),
          ),
        );
      });

      test('throws FLOOR_RESTRICTION for media on Floor 1 in Plaza', () async {
        final session = sessionBuilder.build();

        expect(
          () => MessagingService.validateMessage(
            session,
            sender: testUser,
            channel: plazaChannel,
            content: 'Check this out',
            imageUrl: 'https://example.com/image.jpg',
          ),
          throwsA(
            isA<protocol.TalktiveException>().having(
              (e) => e.code,
              'code',
              'FLOOR_RESTRICTION',
            ),
          ),
        );
      });

      test('allows media for Floor 2 user in Plaza', () async {
        final session = sessionBuilder.build();

        // Elevate user to Floor 2
        testUser.level = 2;
        await protocol.Resident.db.updateRow(session, testUser);

        final result = await MessagingService.validateMessage(
          session,
          sender: testUser,
          channel: plazaChannel,
          content: 'I reached Floor 2!',
          imageUrl: 'https://example.com/image.jpg',
        );

        expect(result, isNotNull);
      });

      test(
        'throws PREMIUM_REQUIRED for voice message from non-premium user',
        () async {
          final session = sessionBuilder.build();

          // Elevate user to Floor 2 so they pass the floor check
          testUser.level = 2;
          testUser.isPremium = false;
          await protocol.Resident.db.updateRow(session, testUser);

          expect(
            () => MessagingService.validateMessage(
              session,
              sender: testUser,
              channel: plazaChannel,
              mediaType: 'voice',
              mediaUrl: 'https://example.com/voice.m4a',
              duration: 5,
            ),
            throwsA(
              isA<protocol.TalktiveException>().having(
                (e) => e.code,
                'code',
                'PREMIUM_REQUIRED',
              ),
            ),
          );
        },
      );

      test('allows voice message for trial Floor 2 user', () async {
        final session = sessionBuilder.build();

        testUser.level = 2;
        testUser.isPremium = false;
        testUser.premiumTrialExpires = DateTime.now().add(
          const Duration(days: 7),
        );
        await protocol.Resident.db.updateRow(session, testUser);

        final result = await MessagingService.validateMessage(
          session,
          sender: testUser,
          channel: plazaChannel,
          mediaType: 'voice',
          mediaUrl: 'https://example.com/voice.m4a',
          duration: 5,
          fileSize: 1024,
        );

        expect(result, isNull);
      });

      test('allows voice message for premium Floor 2 user', () async {
        final session = sessionBuilder.build();

        testUser.level = 2;
        testUser.isPremium = true;
        await protocol.Resident.db.updateRow(session, testUser);

        final result = await MessagingService.validateMessage(
          session,
          sender: testUser,
          channel: plazaChannel,
          mediaType: 'voice',
          mediaUrl: 'https://example.com/voice.m4a',
          duration: 5,
          fileSize: 1024,
        );

        expect(result, isNull);
      });
    });

    group('sendMessage', () {
      test('correctly saves a voice message', () async {
        final session = sessionBuilder.build();

        testUser.level = 2;
        testUser.isPremium = true;
        await protocol.Resident.db.updateRow(session, testUser);

        final savedMessage = await MessagingService.sendMessage(
          session,
          sender: testUser,
          channel: plazaChannel,
          mediaType: 'voice',
          mediaUrl: 'https://example.com/voice.m4a',
          duration: 10,
          fileSize: 2048,
        );

        expect(savedMessage.id, isNotNull);
        expect(savedMessage.mediaType, 'voice');

        // Verify it's actually in the database
        final retrievedMessage = await protocol.Message.db.findById(
          session,
          savedMessage.id!,
        );
        expect(retrievedMessage, isNotNull);
        expect(retrievedMessage!.mediaUrl, 'https://example.com/voice.m4a');
      });

      test('onMessagePostSave preserves newer resident fields', () async {
        final session = sessionBuilder.build();

        final staleSender = testUser.copyWith(bio: 'stale bio');
        final persistedSender = testUser.copyWith(bio: 'fresh bio');
        await protocol.Resident.db.updateRow(session, persistedSender);

        await MessagingService.onMessagePostSave(
          session,
          message: protocol.Message(
            channelId: plazaChannel.id!,
            senderId: testUser.userInfoId,
            createdAt: DateTime.now(),
            senderName: 'Resident',
            senderFloor: 1,
            senderTrustScore: 100,
            isSystem: false,
          ),
          channel: plazaChannel,
          sender: staleSender,
        );

        final updatedResident = await protocol.Resident.db.findById(
          session,
          testUser.id!,
        );
        expect(updatedResident, isNotNull);
        expect(updatedResident!.bio, 'fresh bio');
        expect(updatedResident.xp, GamificationService.xpPerMessage);
      });
    });

    group('Private Chat Privacy', () {
      test(
        'throws PRIVACY_RESTRICTED when sender is blocked by recipient',
        () async {
          final session = sessionBuilder.build();

          // 1. Create recipient
          final recipient = protocol.Resident(
            userInfoId: UuidValue.fromString(
              'b2c3d4e5-f6a7-4b5c-9d0e-1f2a3b4c5d6e',
            ),
            level: 1,
            trustScore: 100,
          );
          await protocol.Resident.db.insertRow(session, recipient);

          // 2. Create private channel
          final privateChannel = protocol.Channel(
            type: protocol.ChannelType.private,
            createdAt: DateTime.now(),
          );
          final savedChannel = await protocol.Channel.db.insertRow(
            session,
            privateChannel,
          );

          // 3. Add members
          await protocol.ChannelMember.db.insertRow(
            session,
            protocol.ChannelMember(
              channelId: savedChannel.id!,
              userInfoId: testUser.userInfoId,
              joinedAt: DateTime.now(),
              status: protocol.ChannelMemberStatus.joined,
            ),
          );
          await protocol.ChannelMember.db.insertRow(
            session,
            protocol.ChannelMember(
              channelId: savedChannel.id!,
              userInfoId: recipient.userInfoId,
              joinedAt: DateTime.now(),
              status: protocol.ChannelMemberStatus.joined,
            ),
          );

          // 4. Recipient blocks testUser
          await protocol.Block.db.insertRow(
            session,
            protocol.Block(
              blockerId: recipient.userInfoId,
              blockedId: testUser.userInfoId,
              createdAt: DateTime.now(),
            ),
          );

          // 5. Try to send message
          expect(
            () => MessagingService.validateMessage(
              session,
              sender: testUser,
              channel: savedChannel,
              content: 'Hello?',
            ),
            throwsA(
              isA<protocol.TalktiveException>().having(
                (e) => e.code,
                'code',
                'PRIVACY_RESTRICTED',
              ),
            ),
          );
        },
      );
    });
  });
}
