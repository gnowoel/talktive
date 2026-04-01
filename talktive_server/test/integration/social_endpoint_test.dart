import 'package:test/test.dart';
import 'package:serverpod/serverpod.dart';
import 'package:talktive_server/src/generated/protocol.dart' as protocol;
import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Given Social endpoint', (sessionBuilder, endpoints) {
    late protocol.Resident user1;
    late protocol.Resident user2;

    setUp(() async {
      final session = sessionBuilder.build();

      // Create two users
      user1 = protocol.Resident(
        userInfoId: UuidValue.fromString(
          'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d',
        ),
        level: 1,
        trustScore: 100,
        role: protocol.ResidentRole.user,
      );
      user1 = await protocol.Resident.db.insertRow(session, user1);

      user2 = protocol.Resident(
        userInfoId: UuidValue.fromString(
          'b2c3d4e5-f6a7-4b5c-9d0e-1f2a3b4c5d6e',
        ),
        level: 1,
        trustScore: 100,
        role: protocol.ResidentRole.user,
      );
      user2 = await protocol.Resident.db.insertRow(session, user2);
    });

    group('Blocking', () {
      test('can block another user', () async {
        final session = sessionBuilder.copyWith(
          authentication: AuthenticationOverride.authenticationInfo(
            user1.userInfoId.uuid,
            {},
          ),
        );

        final result = await endpoints.social.blockUser(
          session,
          user2.userInfoId.uuid,
        );
        expect(result, true);

        final isBlocked = await endpoints.social.isUserBlocked(
          session,
          user2.userInfoId.uuid,
        );
        expect(isBlocked, true);
      });

      test('cannot block yourself', () async {
        final session = sessionBuilder.copyWith(
          authentication: AuthenticationOverride.authenticationInfo(
            user1.userInfoId.uuid,
            {},
          ),
        );

        expect(
          () => endpoints.social.blockUser(session, user1.userInfoId.uuid),
          throwsA(
            isA<protocol.TalktiveException>().having(
              (e) => e.message,
              'message',
              contains('cannot block yourself'),
            ),
          ),
        );
      });

      test('can unblock a user', () async {
        final session = sessionBuilder.copyWith(
          authentication: AuthenticationOverride.authenticationInfo(
            user1.userInfoId.uuid,
            {},
          ),
        );

        await endpoints.social.blockUser(session, user2.userInfoId.uuid);
        final result = await endpoints.social.unblockUser(
          session,
          user2.userInfoId.uuid,
        );
        expect(result, true);

        final isBlocked = await endpoints.social.isUserBlocked(
          session,
          user2.userInfoId.uuid,
        );
        expect(isBlocked, false);
      });
    });

    group('Reporting', () {
      test('can report another user', () async {
        final session = sessionBuilder.copyWith(
          authentication: AuthenticationOverride.authenticationInfo(
            user1.userInfoId.uuid,
            {},
          ),
        );

        await endpoints.social.reportUser(
          session,
          targetUserId: user2.userInfoId.uuid,
          reason: 'Spamming',
        );

        // Verify report exists in DB
        final s = sessionBuilder.build();
        final count = await protocol.Report.db.count(s);
        expect(count, 1);
      });

      test('cannot report yourself', () async {
        final session = sessionBuilder.copyWith(
          authentication: AuthenticationOverride.authenticationInfo(
            user1.userInfoId.uuid,
            {},
          ),
        );

        expect(
          () => endpoints.social.reportUser(
            session,
            targetUserId: user1.userInfoId.uuid,
            reason: 'I am annoying myself',
          ),
          throwsA(
            isA<protocol.TalktiveException>().having(
              (e) => e.message,
              'message',
              contains('cannot report yourself'),
            ),
          ),
        );
      });
    });

    group('Liking', () {
      test('can like another user', () async {
        final session = sessionBuilder.copyWith(
          authentication: AuthenticationOverride.authenticationInfo(
            user1.userInfoId.uuid,
            {},
          ),
        );

        await endpoints.social.likeUser(session, user2.userInfoId.uuid);

        final likedIds = await endpoints.social.getMyLikedUserIds(session);
        expect(likedIds, contains(user2.userInfoId.uuid));
      });

      test('cannot like yourself', () async {
        final session = sessionBuilder.copyWith(
          authentication: AuthenticationOverride.authenticationInfo(
            user1.userInfoId.uuid,
            {},
          ),
        );

        expect(
          () => endpoints.social.likeUser(session, user1.userInfoId.uuid),
          throwsA(
            isA<protocol.TalktiveException>().having(
              (e) => e.message,
              'message',
              contains('cannot vouch for yourself'),
            ),
          ),
        );
      });
    });
  });
}
