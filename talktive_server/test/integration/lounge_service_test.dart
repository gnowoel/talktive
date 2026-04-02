import 'package:test/test.dart';
import 'package:serverpod/serverpod.dart';
import 'package:talktive_server/src/generated/protocol.dart' as protocol;
import 'package:talktive_server/src/services/lounge_service.dart';
import 'package:uuid/uuid.dart';
import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Given LoungeService', (sessionBuilder, endpoints) {
    late protocol.Resident creator;
    late protocol.Resident joiner;
    const uuid = Uuid();

    setUp(() async {
      final session = sessionBuilder.build();

      // Create creator
      creator = await protocol.Resident.db.insertRow(
        session,
        protocol.Resident(
          userInfoId: UuidValue.fromString(uuid.v4()),
          level: 5,
          trustScore: 100,
        ),
      );

      // Create joiner
      joiner = await protocol.Resident.db.insertRow(
        session,
        protocol.Resident(
          userInfoId: UuidValue.fromString(uuid.v4()),
          level: 1,
          trustScore: 100,
        ),
      );
    });

    group('createLounge', () {
      test('creates lounge and makes creator an admin', () async {
        final session = sessionBuilder.build();

        final lounge = await LoungeService.createLounge(
          session,
          name: 'Chess Club',
          creatorId: creator.userInfoId,
          description: 'A place for grandmasters',
          isPublic: true,
        );

        expect(lounge.name, 'Chess Club');
        expect(lounge.creatorId, creator.userInfoId);

        // Verify membership
        final member = await protocol.ChannelMember.db.findFirstRow(
          session,
          where: (t) =>
              t.channelId.equals(lounge.channelId) &
              t.userInfoId.equals(creator.userInfoId),
        );
        expect(member, isNotNull);
        expect(member!.role, 'admin');
        expect(member.status, protocol.ChannelMemberStatus.joined);
      });
    });

    group('Membership Flow', () {
      late protocol.Lounge lounge;

      setUp(() async {
        final session = sessionBuilder.build();
        lounge = await LoungeService.createLounge(
          session,
          name: 'The Library',
          creatorId: creator.userInfoId,
          isPublic: true,
        );
      });

      test('applyToLounge sets status to applied', () async {
        final session = sessionBuilder.build();

        await LoungeService.applyToLounge(
          session,
          lounge: lounge,
          resident: joiner,
        );

        final member = await protocol.ChannelMember.db.findFirstRow(
          session,
          where: (t) =>
              t.channelId.equals(lounge.channelId) &
              t.userInfoId.equals(joiner.userInfoId),
        );
        expect(member!.status, protocol.ChannelMemberStatus.applied);
      });

      test('approveApplication joins user to the lounge', () async {
        final session = sessionBuilder.build();

        await LoungeService.applyToLounge(
          session,
          lounge: lounge,
          resident: joiner,
        );
        await LoungeService.approveApplication(
          session,
          loungeId: lounge.id!,
          creatorId: creator.userInfoId,
          targetId: joiner.userInfoId,
          approve: true,
        );

        final member = await protocol.ChannelMember.db.findFirstRow(
          session,
          where: (t) =>
              t.channelId.equals(lounge.channelId) &
              t.userInfoId.equals(joiner.userInfoId),
        );
        expect(member!.status, protocol.ChannelMemberStatus.joined);

        final updatedLounge = await protocol.Lounge.db.findById(
          session,
          lounge.id!,
        );
        expect(updatedLounge!.memberCount, 2); // Creator + Joiner
      });

      test('leaveLounge removes member from lounge', () async {
        final session = sessionBuilder.build();

        // Force join first
        await protocol.ChannelMember.db.insertRow(
          session,
          protocol.ChannelMember(
            channelId: lounge.channelId,
            userInfoId: joiner.userInfoId,
            status: protocol.ChannelMemberStatus.joined,
            joinedAt: DateTime.now(),
          ),
        );
        lounge.memberCount = 2;
        await protocol.Lounge.db.updateRow(session, lounge);

        await LoungeService.leaveLounge(
          session,
          loungeId: lounge.id!,
          userId: joiner.userInfoId,
        );

        final member = await protocol.ChannelMember.db.findFirstRow(
          session,
          where: (t) =>
              t.channelId.equals(lounge.channelId) &
              t.userInfoId.equals(joiner.userInfoId),
        );
        expect(member!.status, protocol.ChannelMemberStatus.left);

        final updatedLounge = await protocol.Lounge.db.findById(
          session,
          lounge.id!,
        );
        expect(updatedLounge!.memberCount, 1);
      });
    });

    group('Invitations', () {
      late protocol.Lounge lounge;

      setUp(() async {
        final session = sessionBuilder.build();
        lounge = await LoungeService.createLounge(
          session,
          name: 'VIP Club',
          creatorId: creator.userInfoId,
          isPublic: false,
        );
      });

      test('inviteUser creates invited status', () async {
        final session = sessionBuilder.build();

        await LoungeService.inviteUser(
          session,
          lounge: lounge,
          inviter: creator,
          target: joiner,
        );

        final member = await protocol.ChannelMember.db.findFirstRow(
          session,
          where: (t) =>
              t.channelId.equals(lounge.channelId) &
              t.userInfoId.equals(joiner.userInfoId),
        );
        expect(member!.status, protocol.ChannelMemberStatus.invited);
        expect(member.invitedBy, creator.userInfoId);
      });

      test(
        'respondToInvite (accept) joins user if invited by creator',
        () async {
          final session = sessionBuilder.build();

          await LoungeService.inviteUser(
            session,
            lounge: lounge,
            inviter: creator,
            target: joiner,
          );
          await LoungeService.respondToInvite(
            session,
            loungeId: lounge.id!,
            userId: joiner.userInfoId,
            accept: true,
          );

          final member = await protocol.ChannelMember.db.findFirstRow(
            session,
            where: (t) =>
                t.channelId.equals(lounge.channelId) &
                t.userInfoId.equals(joiner.userInfoId),
          );
          expect(member!.status, protocol.ChannelMemberStatus.joined);
        },
      );

      test('inviteUser respects blocking', () async {
        final session = sessionBuilder.build();

        // Joiner blocks creator
        await protocol.Block.db.insertRow(
          session,
          protocol.Block(
            blockerId: joiner.userInfoId,
            blockedId: creator.userInfoId,
            createdAt: DateTime.now(),
          ),
        );

        expect(
          () => LoungeService.inviteUser(
            session,
            lounge: lounge,
            inviter: creator,
            target: joiner,
          ),
          throwsA(
            isA<protocol.TalktiveException>().having(
              (e) => e.message,
              'message',
              contains('cannot invite this user'),
            ),
          ),
        );
      });
    });

    group('Lounge Gamification', () {
      test('awardLoungeXP levels up lounge and increases capacity', () async {
        final session = sessionBuilder.build();
        final lounge = await LoungeService.createLounge(
          session,
          name: 'Level Up Lab',
          creatorId: creator.userInfoId,
        );

        expect(lounge.level, 1);
        expect(lounge.maxMembers, 50);

        // Award 100 XP (enough for level 2: floor(100/100)+1 = 2)
        await LoungeService.awardLoungeXP(
          session,
          lounge.channelId,
          100,
          'Test XP',
        );

        final updated = await protocol.Lounge.db.findFirstRow(
          session,
          where: (t) => t.id.equals(lounge.id!),
        );

        expect(updated!.level, 2);
        // Base 50 + (2-1)*20 = 70
        expect(updated.maxMembers, 70);
      });
    });
  });
}
