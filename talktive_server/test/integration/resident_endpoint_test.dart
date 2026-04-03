import 'package:test/test.dart';
import 'package:serverpod/serverpod.dart';
import 'package:talktive_server/src/generated/protocol.dart';
import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Given Resident endpoint', (sessionBuilder, endpoints) {
    group('getResident', () {
      test('returns null for unauthenticated user', () async {
        final resident = await endpoints.resident.getResident(sessionBuilder);

        expect(resident, isNull);
      });

      test('returns null when resident does not exist', () async {
        final resident = await endpoints.resident.getResident(
          sessionBuilder.copyWith(
            authentication: AuthenticationOverride.authenticationInfo(
              'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d',
              {},
            ),
          ),
        );

        expect(resident, isNull);
      });

      test('returns resident when exists', () async {
        final session = sessionBuilder.build();

        // Create resident with proper UUID
        final testResident = Resident(
          userInfoId: UuidValue.fromString(
            'b2c3d4e5-f6a7-4b5c-9d0e-1f2a3b4c5d6e',
          ),
          level: 1,
          trustScore: 100,
          gender: 'male',
          country: 'US',
          bio: 'Test bio',
          mood: '😊',
          avatar: '👨',
          role: ResidentRole.user,
          interests: ['coding', 'music'],
          languages: ['en'],
        );
        await Resident.db.insertRow(session, testResident);

        // Get resident
        final resident = await endpoints.resident.getResident(
          sessionBuilder.copyWith(
            authentication: AuthenticationOverride.authenticationInfo(
              testResident.userInfoId.uuid,
              {},
            ),
          ),
        );

        expect(resident, isNotNull);
        expect(resident!.userInfoId, testResident.userInfoId);
        expect(resident.level, 1);
        expect(resident.trustScore, 100);
        expect(resident.gender, 'male');
        expect(resident.country, 'US');
        expect(resident.bio, 'Test bio');
        expect(resident.avatar, '👨');
        expect(resident.mood, '😊');
        expect(resident.interests, ['coding', 'music']);
        expect(resident.languages, ['en']);
      });

      test('handles residents with minimal data', () async {
        final session = sessionBuilder.build();

        // Create resident with minimal fields
        final testResident = Resident(
          userInfoId: UuidValue.fromString(
            'c3d4e5f6-a7b8-4c5d-8e1f-2a3b4c5d6e7f',
          ),
          level: 1,
          trustScore: 100,
        );
        await Resident.db.insertRow(session, testResident);

        // Get resident
        final resident = await endpoints.resident.getResident(
          sessionBuilder.copyWith(
            authentication: AuthenticationOverride.authenticationInfo(
              testResident.userInfoId.uuid,
              {},
            ),
          ),
        );

        expect(resident, isNotNull);
        expect(resident!.gender, isNull);
        expect(resident.country, isNull);
        expect(resident.bio, isNull);
        expect(resident.avatar, isNull);
      });
    });

    group('Credit System', () {
      test('new residents have correct initial values', () async {
        final session = sessionBuilder.build();

        final resident = Resident(
          userInfoId: UuidValue.fromString(
            'd4e5f6a7-b8c9-4d5e-9f2a-3b4c5d6e7f8a',
          ),
          level: 1,
          trustScore: 100,
          gender: 'other',
          country: 'US',
          bio: 'Testing',
          avatar: '💰',
          role: ResidentRole.user,
        );
        await Resident.db.insertRow(session, resident);

        expect(resident.level, 1);
        expect(resident.trustScore, 100);

        expect(resident.role, ResidentRole.user);
        expect(resident.suspended, false);
      });

      test('residents can have different floor levels', () async {
        final session = sessionBuilder.build();

        final floorUuids = [
          'e5f6a7b8-c9d0-4e5f-8a3b-4c5d6e7f8a90',
          'e5f6a7b8-c9d0-4e5f-8a3b-4c5d6e7f8a91',
          'e5f6a7b8-c9d0-4e5f-8a3b-4c5d6e7f8a92',
          'e5f6a7b8-c9d0-4e5f-8a3b-4c5d6e7f8a93',
          'e5f6a7b8-c9d0-4e5f-8a3b-4c5d6e7f8a94',
          'e5f6a7b8-c9d0-4e5f-8a3b-4c5d6e7f8a95',
        ];

        for (var floor = 0; floor <= 5; floor++) {
          final resident = Resident(
            userInfoId: UuidValue.fromString(floorUuids[floor]),
            level: floor,
            trustScore: 100,
          );
          await Resident.db.insertRow(session, resident);

          final retrieved = await Resident.db.findFirstRow(
            session,
            where: (t) => t.userInfoId.equals(resident.userInfoId),
          );

          expect(retrieved!.level, floor);
        }
      });

      test('credit scores can be positive or negative', () async {
        final session = sessionBuilder.build();

        final testCases = [-50, -10, 0, 50, 100, 200];
        final creditUuids = [
          'f6a7b8c9-d0e1-4f5a-9b4c-5d6e7f8a9b00',
          'f6a7b8c9-d0e1-4f5a-9b4c-5d6e7f8a9b01',
          'f6a7b8c9-d0e1-4f5a-9b4c-5d6e7f8a9b02',
          'f6a7b8c9-d0e1-4f5a-9b4c-5d6e7f8a9b03',
          'f6a7b8c9-d0e1-4f5a-9b4c-5d6e7f8a9b04',
          'f6a7b8c9-d0e1-4f5a-9b4c-5d6e7f8a9b05',
        ];

        for (var i = 0; i < testCases.length; i++) {
          final resident = Resident(
            userInfoId: UuidValue.fromString(creditUuids[i]),
            level: 1,
            trustScore: testCases[i],
          );
          await Resident.db.insertRow(session, resident);

          final retrieved = await Resident.db.findFirstRow(
            session,
            where: (t) => t.userInfoId.equals(resident.userInfoId),
          );

          expect(retrieved!.trustScore, testCases[i]);
        }
      });
    });

    group('Profile Data', () {
      test(
        'initializeResident ignores privileged client-provided migration fields',
        () async {
          final authUserId = '0c3d4e5f-6a7b-4890-8c1d-2e3f4a5b6c7d';

          final resident = await endpoints.resident.initializeResident(
            sessionBuilder.copyWith(
              authentication: AuthenticationOverride.authenticationInfo(
                authUserId,
                {},
              ),
            ),
            name: 'Secure User',
            avatar: '🙂',
            gender: 'male',
            country: 'US',
            bio: 'Testing privileged fields are ignored',
          );

          expect(resident.xp, 0);
          expect(resident.level, 1);
          expect(resident.role, ResidentRole.user);
        },
      );

      test('supports various gender values', () async {
        final session = sessionBuilder.build();

        final genders = [
          'male',
          'female',
          'non-binary',
          'prefer-not-to-say',
          'other',
        ];
        final genderUuids = [
          'a7b8c9d0-e1f2-4a5b-8c5d-6e7f8a9b0c10',
          'a7b8c9d0-e1f2-4a5b-8c5d-6e7f8a9b0c11',
          'a7b8c9d0-e1f2-4a5b-8c5d-6e7f8a9b0c12',
          'a7b8c9d0-e1f2-4a5b-8c5d-6e7f8a9b0c13',
          'a7b8c9d0-e1f2-4a5b-8c5d-6e7f8a9b0c14',
        ];

        for (var i = 0; i < genders.length; i++) {
          final resident = Resident(
            userInfoId: UuidValue.fromString(genderUuids[i]),
            level: 1,
            trustScore: 100,
            gender: genders[i],
          );
          await Resident.db.insertRow(session, resident);

          final retrieved = await Resident.db.findFirstRow(
            session,
            where: (t) => t.userInfoId.equals(resident.userInfoId),
          );

          expect(retrieved!.gender, genders[i]);
        }
      });

      test('supports multiple interests and languages', () async {
        final session = sessionBuilder.build();

        final resident = Resident(
          userInfoId: UuidValue.fromString(
            'b8c9d0e1-f2a3-4b5c-9d6e-7f8a9b0c1d2e',
          ),
          level: 1,
          trustScore: 100,
          interests: [
            'travel',
            'languages',
            'culture',
            'food',
            'music',
            'art',
          ],
          languages: ['en', 'es', 'fr', 'de', 'it', 'pt', 'ja', 'zh'],
        );
        await Resident.db.insertRow(session, resident);

        final retrieved = await Resident.db.findFirstRow(
          session,
          where: (t) => t.userInfoId.equals(resident.userInfoId),
        );

        expect(retrieved!.interests!.length, 6);
        expect(retrieved.languages!.length, 8);
        expect(retrieved.interests, contains('travel'));
        expect(retrieved.languages, contains('ja'));
      });

      test('handles long bio text', () async {
        final session = sessionBuilder.build();

        final longBio = 'A' * 500;

        final resident = Resident(
          userInfoId: UuidValue.fromString(
            'c9d0e1f2-a3b4-4c5d-8e7f-8a9b0c1d2e3f',
          ),
          level: 1,
          trustScore: 100,
          bio: longBio,
        );
        await Resident.db.insertRow(session, resident);

        final retrieved = await Resident.db.findFirstRow(
          session,
          where: (t) => t.userInfoId.equals(resident.userInfoId),
        );

        expect(retrieved!.bio, longBio);
        expect(retrieved.bio!.length, 500);
      });

      test('handles special characters and emojis', () async {
        final session = sessionBuilder.build();

        final resident = Resident(
          userInfoId: UuidValue.fromString(
            'd0e1f2a3-b4c5-4d5e-9f8a-9b0c1d2e3f4a',
          ),
          level: 1,
          trustScore: 100,
          bio: 'Hello! 你好! مرحبا! Привет! 🎉',
          avatar: '🌟',
        );
        await Resident.db.insertRow(session, resident);

        final retrieved = await Resident.db.findFirstRow(
          session,
          where: (t) => t.userInfoId.equals(resident.userInfoId),
        );

        expect(retrieved!.bio, contains('你好'));
        expect(retrieved.bio, contains('🎉'));
        expect(retrieved.avatar, '🌟');
      });
    });

    group('Admin and Ban Flags', () {
      test('role defaults to user', () async {
        final session = sessionBuilder.build();

        final resident = Resident(
          userInfoId: UuidValue.fromString(
            'e1f2a3b4-c5d6-4e5f-8a9b-0c1d2e3f4a5b',
          ),
          level: 1,
          trustScore: 100,
        );
        await Resident.db.insertRow(session, resident);

        expect(resident.role, ResidentRole.user);
      });

      test('suspended defaults to false', () async {
        final session = sessionBuilder.build();

        final resident = Resident(
          userInfoId: UuidValue.fromString(
            'f2a3b4c5-d6e7-4f5a-9b0c-1d2e3f4a5b6c',
          ),
          level: 1,
          trustScore: 100,
        );
        await Resident.db.insertRow(session, resident);

        expect(resident.suspended, false);
      });

      test('can set admin role', () async {
        final session = sessionBuilder.build();

        final resident = Resident(
          userInfoId: UuidValue.fromString(
            'a3b4c5d6-e7f8-4a5b-8c1d-2e3f4a5b6c7d',
          ),
          level: 1,
          role: ResidentRole.admin,
        );
        await Resident.db.insertRow(session, resident);

        expect(resident.role, ResidentRole.admin);
      });

      test('can set banned flag', () async {
        final session = sessionBuilder.build();

        final resident = Resident(
          userInfoId: UuidValue.fromString(
            'b4c5d6e7-f8a9-4b5c-9d2e-3f4a5b6c7d8e',
          ),
          level: 1,
          trustScore: -100,
          suspended: true,
        );
        await Resident.db.insertRow(session, resident);

        expect(resident.suspended, true);
      });
    });
  });
}
