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
  });
}
