import 'package:test/test.dart';
import 'package:serverpod/serverpod.dart';
import 'package:talktive_server/src/generated/protocol.dart' as protocol;
import 'package:talktive_server/src/services/search_service.dart';
import 'package:uuid/uuid.dart';
import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Given SearchService', (sessionBuilder, endpoints) {
    late protocol.Resident currentUser;
    const uuid = Uuid();

    setUp(() async {
      final session = sessionBuilder.build();

      // Create a premium user for advanced search
      currentUser = await protocol.Resident.db.insertRow(
        session,
        protocol.Resident(
          userInfoId: UuidValue.fromString(uuid.v4()),
          level: 10,
          trustScore: 100,
          isPremium: true,
        ),
      );

      // Helper to create channel
      Future<int> createChannel() async {
        final channel = await protocol.Channel.db.insertRow(
          session,
          protocol.Channel(
            type: protocol.ChannelType.lounge,
            createdAt: DateTime.now(),
          ),
        );
        return channel.id!;
      }

      // Create some lounges
      // Global lounge
      await protocol.Lounge.db.insertRow(
        session,
        protocol.Lounge(
          name: 'Global Chess',
          channelId: await createChannel(),
          creatorId: currentUser.userInfoId,
          isPublic: true,
          country: null,
          memberCount: 10,
          createdAt: DateTime.now(),
        ),
      );

      // US lounge
      await protocol.Lounge.db.insertRow(
        session,
        protocol.Lounge(
          name: 'US Chess',
          channelId: await createChannel(),
          creatorId: currentUser.userInfoId,
          isPublic: true,
          country: 'US',
          memberCount: 5,
          createdAt: DateTime.now(),
        ),
      );

      // PH lounge
      await protocol.Lounge.db.insertRow(
        session,
        protocol.Lounge(
          name: 'PH Chess',
          channelId: await createChannel(),
          creatorId: currentUser.userInfoId,
          isPublic: true,
          country: 'PH',
          memberCount: 2,
          createdAt: DateTime.now(),
        ),
      );
    });

    group('Triple-Scope Region Filtering', () {
      test('country: null returns both global and local lounges', () async {
        final session = sessionBuilder.build();
        final results = await SearchService.searchLounges(
          session,
          'Chess',
          country: null,
          currentUser: currentUser,
        );

        // Should return all 3
        expect(results.length, 3);
        final names = results.map((l) => l.name).toList();
        expect(names, contains('Global Chess'));
        expect(names, contains('US Chess'));
        expect(names, contains('PH Chess'));
      });

      test('country: "GLOBAL" returns only global lounges', () async {
        final session = sessionBuilder.build();
        final results = await SearchService.searchLounges(
          session,
          'Chess',
          country: 'GLOBAL',
          currentUser: currentUser,
        );

        expect(results.length, 1);
        expect(results.first.name, 'Global Chess');
        expect(results.first.country, isNull);
      });

      test('country: "US" returns only US lounges', () async {
        final session = sessionBuilder.build();
        final results = await SearchService.searchLounges(
          session,
          'Chess',
          country: 'US',
          currentUser: currentUser,
        );

        expect(results.length, 1);
        expect(results.first.name, 'US Chess');
        expect(results.first.country, 'US');
      });

      test('getPopularLounges also respects triple-scope (null)', () async {
        final session = sessionBuilder.build();
        final results = await SearchService.getPopularLounges(
          session,
          country: null,
        );

        expect(results.length, 3);
      });

      test('getPopularLounges also respects triple-scope ("GLOBAL")', () async {
        final session = sessionBuilder.build();
        final results = await SearchService.getPopularLounges(
          session,
          country: 'GLOBAL',
        );

        expect(results.length, 1);
        expect(results.first.name, 'Global Chess');
      });

      test('getRecommendedLounges also respects triple-scope ("US")', () async {
        final session = sessionBuilder.build();
        final results = await SearchService.getRecommendedLounges(
          session,
          currentUser,
          country: 'US',
        );

        expect(results.length, 1);
        expect(results.first.name, 'US Chess');
      });

      test(
        'getRecommendedLounges also respects triple-scope ("GLOBAL")',
        () async {
          final session = sessionBuilder.build();
          final results = await SearchService.getRecommendedLounges(
            session,
            currentUser,
            country: 'GLOBAL',
          );

          expect(results.length, 1);
          expect(results.first.name, 'Global Chess');
        },
      );
    });

    group('Resident Advanced Search', () {
      late protocol.Resident resident1;
      late protocol.Resident resident2;
      late protocol.Resident nonPremiumUser;

      setUp(() async {
        final session = sessionBuilder.build();

        // Create a non-premium user
        nonPremiumUser = await protocol.Resident.db.insertRow(
          session,
          protocol.Resident(
            userInfoId: UuidValue.fromString(uuid.v4()),
            userName: 'Free User',
            isPremium: false,
          ),
        );

        // Create test residents
        resident1 = await protocol.Resident.db.insertRow(
          session,
          protocol.Resident(
            userInfoId: UuidValue.fromString(uuid.v4()),
            userName: 'Alice Smith',
            gender: 'female',
            ageRange: '25-34',
            country: 'US',
            languages: ['en', 'es'],
            interests: ['Chess', 'Coding'],
            lastSeen: DateTime.now(),
            isPremium: true,
          ),
        );

        resident2 = await protocol.Resident.db.insertRow(
          session,
          protocol.Resident(
            userInfoId: UuidValue.fromString(uuid.v4()),
            userName: 'Bob Jones',
            gender: 'male',
            ageRange: '35-44',
            country: 'UK',
            languages: ['en', 'fr'],
            interests: ['Chess', 'Music'],
            lastSeen: DateTime.now(),
            isPremium: false,
          ),
        );
      });

      test('searchUsers filters by gender', () async {
        final session = sessionBuilder.build();
        final results = await SearchService.searchUsers(
          session,
          'Chess',
          gender: 'female',
          currentUser: currentUser,
        );

        expect(results.length, 1);
        expect(results.first.userName, 'Alice Smith');
      });

      test('searchUsers filters by country', () async {
        final session = sessionBuilder.build();
        final results = await SearchService.searchUsers(
          session,
          'Chess',
          country: 'UK',
          currentUser: currentUser,
        );

        expect(results.length, 1);
        expect(results.first.userName, 'Bob Jones');
      });

      test('searchUsers filters by ageRange', () async {
        final session = sessionBuilder.build();
        final results = await SearchService.searchUsers(
          session,
          'Chess',
          ageRange: '25-34',
          currentUser: currentUser,
        );

        expect(results.length, 1);
        expect(results.first.userName, 'Alice Smith');
      });

      test('searchUsers filters by premium status', () async {
        final session = sessionBuilder.build();
        final results = await SearchService.searchUsers(
          session,
          'Chess',
          isPremium: true,
          currentUser: currentUser,
        );

        expect(results.length, 1);
        expect(results.first.userName, 'Alice Smith');
      });

      test('searchUsers throws exception for non-premium filtering', () async {
        final session = sessionBuilder.build();

        expect(
          () => SearchService.searchUsers(
            session,
            'Chess',
            gender: 'female',
            currentUser: nonPremiumUser,
          ),
          throwsA(
            isA<protocol.TalktiveException>().having(
              (e) => e.code,
              'code',
              'PREMIUM_REQUIRED',
            ),
          ),
        );
      });

      test(
        'searchUsers allows search without filters for non-premium',
        () async {
          final session = sessionBuilder.build();
          final results = await SearchService.searchUsers(
            session,
            'Alice',
            currentUser: nonPremiumUser,
          );

          expect(results.length, 1);
          expect(results.first.userName, 'Alice Smith');
        },
      );

      test('searchUsers respects discovery settings', () async {
        final session = sessionBuilder.build();

        // Disable discovery for currentUser
        final updatedUser = currentUser.copyWith(showAdvancedDiscovery: false);
        await protocol.Resident.db.updateRow(session, updatedUser);

        expect(
          () => SearchService.searchUsers(
            session,
            'Chess',
            gender: 'female',
            currentUser: updatedUser,
          ),
          throwsA(
            isA<protocol.TalktiveException>().having(
              (e) => e.code,
              'code',
              'FEATURE_DISABLED',
            ),
          ),
        );
      });

      test('searchUsers excludes blocked users', () async {
        final session = sessionBuilder.build();

        // Alice blocks Bob
        await protocol.Block.db.insertRow(
          session,
          protocol.Block(
            blockerId: resident1.userInfoId,
            blockedId: resident2.userInfoId,
            createdAt: DateTime.now(),
          ),
        );

        final results = await SearchService.searchUsers(
          session,
          'Chess',
          currentUser: resident1,
        );

        // Bob should be excluded
        expect(results.any((r) => r.userName == 'Bob Jones'), isFalse);
      });

      test('searchUsers excludes self', () async {
        final session = sessionBuilder.build();
        final results = await SearchService.searchUsers(
          session,
          'Alice',
          currentUser: resident1,
        );

        expect(results.any((r) => r.userName == 'Alice Smith'), isFalse);
      });

      test('searchUsers without query still excludes self and blocked', () async {
        final session = sessionBuilder.build();

        await protocol.Block.db.insertRow(
          session,
          protocol.Block(
            blockerId: resident1.userInfoId,
            blockedId: resident2.userInfoId,
            createdAt: DateTime.now(),
          ),
        );

        final results = await SearchService.searchUsers(
          session,
          null,
          currentUser: resident1,
        );

        expect(results.any((r) => r.userName == 'Alice Smith'), isFalse);
        expect(results.any((r) => r.userName == 'Bob Jones'), isFalse);
      });

      test('searchUsers does not leak suspended residents by interest match', () async {
        final session = sessionBuilder.build();

        await protocol.Resident.db.insertRow(
          session,
          protocol.Resident(
            userInfoId: UuidValue.fromString(uuid.v4()),
            userName: 'Hidden Chess',
            bio: 'Hidden resident',
            interests: ['Chess'],
            suspended: true,
            lastSeen: DateTime.now(),
          ),
        );

        final results = await SearchService.searchUsers(
          session,
          'Chess',
          currentUser: currentUser,
        );

        expect(results.any((r) => r.userName == 'Hidden Chess'), isFalse);
      });
    });

    group('Lounge Search Safety', () {
      test('searchLounges does not leak staff locked lounges by interest match', () async {
        final session = sessionBuilder.build();

        await protocol.Lounge.db.insertRow(
          session,
          protocol.Lounge(
            name: 'Hidden Lounge',
            channelId: await (() async {
              final channel = await protocol.Channel.db.insertRow(
                session,
                protocol.Channel(
                  type: protocol.ChannelType.lounge,
                  createdAt: DateTime.now(),
                ),
              );
              return channel.id!;
            })(),
            creatorId: currentUser.userInfoId,
            isPublic: true,
            isStaffLocked: true,
            interests: ['Chess'],
            memberCount: 99,
            createdAt: DateTime.now(),
          ),
        );

        final results = await SearchService.searchLounges(
          session,
          'Chess',
          currentUser: currentUser,
        );

        expect(results.any((l) => l.name == 'Hidden Lounge'), isFalse);
      });

      test('getPopularLounges excludes staff locked lounges', () async {
        final session = sessionBuilder.build();

        await protocol.Lounge.db.insertRow(
          session,
          protocol.Lounge(
            name: 'Locked Popular',
            channelId: await (() async {
              final channel = await protocol.Channel.db.insertRow(
                session,
                protocol.Channel(
                  type: protocol.ChannelType.lounge,
                  createdAt: DateTime.now(),
                ),
              );
              return channel.id!;
            })(),
            creatorId: currentUser.userInfoId,
            isPublic: true,
            isStaffLocked: true,
            memberCount: 999,
            createdAt: DateTime.now(),
          ),
        );

        final results = await SearchService.getPopularLounges(session);

        expect(results.any((l) => l.name == 'Locked Popular'), isFalse);
      });
    });
  });
}
