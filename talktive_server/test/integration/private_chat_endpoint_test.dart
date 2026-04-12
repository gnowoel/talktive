import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';
import 'package:talktive_server/src/generated/protocol.dart' as protocol;
import 'package:uuid/uuid.dart';

import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod(
    'Given PrivateChat endpoint',
    (sessionBuilder, endpoints) {
      const uuid = Uuid();

      late protocol.Resident inviter;
      late protocol.Resident invitee;
      late protocol.Resident outsider;

      AuthenticationOverride authFor(protocol.Resident resident) {
        return AuthenticationOverride.authenticationInfo(
          resident.userInfoId.uuid,
          {},
        );
      }

      setUp(() async {
        final session = sessionBuilder.build();

        inviter = await protocol.Resident.db.insertRow(
          session,
          protocol.Resident(
            userInfoId: UuidValue.fromString(uuid.v4()),
            userName: 'Inviter',
            xp: 500,
            level: 3,
            trustScore: 100,
          ),
        );

        invitee = await protocol.Resident.db.insertRow(
          session,
          protocol.Resident(
            userInfoId: UuidValue.fromString(uuid.v4()),
            userName: 'Invitee',
            xp: 500,
            level: 3,
            trustScore: 100,
          ),
        );

        outsider = await protocol.Resident.db.insertRow(
          session,
          protocol.Resident(
            userInfoId: UuidValue.fromString(uuid.v4()),
            userName: 'Outsider',
            xp: 500,
            level: 3,
            trustScore: 100,
          ),
        );
      });

      tearDown(() async {
        final session = sessionBuilder.build();
        final residentIds = {
          inviter.userInfoId,
          invitee.userInfoId,
          outsider.userInfoId,
        };

        final chats = await protocol.PrivateChat.db.find(
          session,
          where: (t) =>
              t.participant1Id.inSet(residentIds) |
              t.participant2Id.inSet(residentIds),
        );
        final channelIds = chats.map((chat) => chat.channelId).toSet();

        if (channelIds.isNotEmpty) {
          await protocol.Message.db.deleteWhere(
            session,
            where: (t) => t.channelId.inSet(channelIds),
          );
          await protocol.ChannelMember.db.deleteWhere(
            session,
            where: (t) => t.channelId.inSet(channelIds),
          );
          await protocol.PrivateChat.db.deleteWhere(
            session,
            where: (t) => t.channelId.inSet(channelIds),
          );
          await protocol.Channel.db.deleteWhere(
            session,
            where: (t) => t.id.inSet(channelIds),
          );
        }

        await protocol.UserNotification.db.deleteWhere(
          session,
          where: (t) => t.userId.inSet(residentIds),
        );
        await protocol.Resident.db.deleteWhere(
          session,
          where: (t) => t.userInfoId.inSet(residentIds),
        );
      });

      test('requires authentication to list chats', () async {
        expect(
          () => endpoints.privateChat.listPrivateChats(sessionBuilder),
          throwsA(
            isA<protocol.TalktiveException>().having(
              (e) => e.code,
              'code',
              'NOT_AUTHENTICATED',
            ),
          ),
        );
      });

      test(
        'creates a private chat invite and exposes it to both residents',
        () async {
          final inviterSession = sessionBuilder.copyWith(
            authentication: authFor(inviter),
          );
          final inviteeSession = sessionBuilder.copyWith(
            authentication: authFor(invitee),
          );

          final chat = await endpoints.privateChat.getOrCreatePrivateChat(
            inviterSession,
            invitee.userInfoId.uuid,
            initialMessage: 'Knock knock',
          );

          expect(chat.channelId, isPositive);

          final inviterChats = await endpoints.privateChat.listPrivateChats(
            inviterSession,
          );
          final inviteeChats = await endpoints.privateChat.listPrivateChats(
            inviteeSession,
          );

          expect(inviterChats, hasLength(1));
          expect(inviteeChats, hasLength(1));
          expect(inviterChats.first.chat.channelId, chat.channelId);
          expect(
            inviterChats.first.currentMemberStatus,
            protocol.ChannelMemberStatus.joined,
          );
          expect(
            inviterChats.first.otherMemberStatus,
            protocol.ChannelMemberStatus.invited,
          );
          expect(
            inviteeChats.first.currentMemberStatus,
            protocol.ChannelMemberStatus.invited,
          );
          expect(
            inviteeChats.first.otherResident.userInfoId,
            inviter.userInfoId,
          );

          final details = await endpoints.privateChat.getPrivateChatDetails(
            inviteeSession,
            chat.channelId,
          );
          expect(details, isNotNull);
          expect(details!.chat.channelId, chat.channelId);
          expect(details.otherResident.userInfoId, inviter.userInfoId);
        },
      );

      test('prevents non-participants from reading chat details', () async {
        final chat = await endpoints.privateChat.getOrCreatePrivateChat(
          sessionBuilder.copyWith(authentication: authFor(inviter)),
          invitee.userInfoId.uuid,
        );

        expect(
          () => endpoints.privateChat.getPrivateChatDetails(
            sessionBuilder.copyWith(authentication: authFor(outsider)),
            chat.channelId,
          ),
          throwsA(
            isA<protocol.TalktiveException>().having(
              (e) => e.code,
              'code',
              'ACCESS_DENIED',
            ),
          ),
        );
      });

      test('accepting an invite updates membership state', () async {
        final inviterSession = sessionBuilder.copyWith(
          authentication: authFor(inviter),
        );
        final inviteeSession = sessionBuilder.copyWith(
          authentication: authFor(invitee),
        );

        final chat = await endpoints.privateChat.getOrCreatePrivateChat(
          inviterSession,
          invitee.userInfoId.uuid,
        );

        await endpoints.privateChat.respondToChatInvite(
          inviteeSession,
          chat.channelId,
          true,
        );

        final details = await endpoints.privateChat.getPrivateChatDetails(
          inviteeSession,
          chat.channelId,
        );

        expect(details, isNotNull);
        expect(
          details!.currentMemberStatus,
          protocol.ChannelMemberStatus.joined,
        );
      });
    },
    rollbackDatabase: RollbackDatabase.disabled,
  );
}
