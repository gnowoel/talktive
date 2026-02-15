import 'package:test/test.dart';
import 'package:talktive_server/src/generated/protocol.dart';
import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Given Moment endpoint', (sessionBuilder, endpoints) {
    group('listMoments', () {
      test('returns empty list when no moments exist', () async {
        final moments = await endpoints.moment.listMoments(
          sessionBuilder,
          limit: 20,
        );

        expect(moments, isEmpty);
      });

      test('respects limit parameter', () async {
        final session = await sessionBuilder.build();

        // Create test user
        final resident = Resident(
          userInfoId: UuidValue.fromString(
            '00000000-0000-0000-0000-000000000101',
          ),
          floor: 2, // Floor 2+ can post moments
          creditScore: 100,
          experience: 0,
          totalMessages: 0,
        );
        await Resident.db.insertRow(session, resident);

        // Create multiple moments
        for (var i = 0; i < 15; i++) {
          final moment = Moment(
            authorId: resident.userInfoId!,
            imageUrl: 'https://example.com/image$i.jpg',
            caption: 'Test moment $i',
            likesCount: 0,
            commentsCount: 0,
            createdAt: DateTime.now(),
          );
          await Moment.db.insertRow(session, moment);
        }

        // Test with limit of 10
        final moments = await endpoints.moment.listMoments(
          sessionBuilder,
          limit: 10,
        );

        expect(moments.length, lessThanOrEqualTo(10));
      });

      test('returns moments in reverse chronological order', () async {
        final session = await sessionBuilder.build();

        // Create test user
        final resident = Resident(
          userInfoId: UuidValue.fromString(
            '00000000-0000-0000-0000-000000000102',
          ),
          floor: 2,
          creditScore: 100,
          experience: 0,
          totalMessages: 0,
        );
        await Resident.db.insertRow(session, resident);

        // Create moments with different timestamps
        final now = DateTime.now();
        for (var i = 0; i < 5; i++) {
          final moment = Moment(
            authorId: resident.userInfoId!,
            imageUrl: 'https://example.com/image$i.jpg',
            caption: 'Moment $i',
            likesCount: 0,
            commentsCount: 0,
            createdAt: now.add(Duration(minutes: i)),
          );
          await Moment.db.insertRow(session, moment);
        }

        final moments = await endpoints.moment.listMoments(
          sessionBuilder,
          limit: 20,
        );

        // Verify reverse chronological order (newest first)
        for (var i = 0; i < moments.length - 1; i++) {
          expect(
            moments[i].createdAt!.isAfter(moments[i + 1].createdAt!),
            true,
            reason: 'Moments should be in reverse chronological order',
          );
        }
      });

      test('includes like and comment counts', () async {
        final session = await sessionBuilder.build();

        // Create test user
        final resident = Resident(
          userInfoId: UuidValue.fromString(
            '00000000-0000-0000-0000-000000000103',
          ),
          floor: 2,
          creditScore: 100,
          experience: 0,
          totalMessages: 0,
        );
        await Resident.db.insertRow(session, resident);

        // Create moment with likes and comments
        final moment = Moment(
          authorId: resident.userInfoId!,
          imageUrl: 'https://example.com/image.jpg',
          caption: 'Test moment',
          likesCount: 5,
          commentsCount: 3,
          createdAt: DateTime.now(),
        );
        await Moment.db.insertRow(session, moment);

        final moments = await endpoints.moment.listMoments(
          sessionBuilder,
          limit: 20,
        );

        expect(moments.first.likesCount, 5);
        expect(moments.first.commentsCount, 3);
      });
    });

    group('postMoment', () {
      test('throws error when user is below floor 2', () async {
        final session = await sessionBuilder.build();

        // Create floor 1 user (cannot post moments)
        final resident = Resident(
          userInfoId: UuidValue.fromString(
            '00000000-0000-0000-0000-000000000104',
          ),
          floor: 1,
          creditScore: 100,
          experience: 0,
          totalMessages: 0,
        );
        await Resident.db.insertRow(session, resident);

        // Attempt to post moment should fail
        expect(
          () => endpoints.moment.postMoment(
            sessionBuilder.copyWith(
              authentication: AuthenticationOverride.authenticationInfo(
                resident.userInfoId!.uuid,
                {},
              ),
            ),
            imageUrl: 'https://example.com/image.jpg',
            caption: 'Test moment',
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('throws error when user has insufficient credit score', () async {
        final session = await sessionBuilder.build();

        // Create user with low credit score
        final resident = Resident(
          userInfoId: UuidValue.fromString(
            '00000000-0000-0000-0000-000000000105',
          ),
          floor: 2,
          creditScore: -10, // Below threshold
          experience: 0,
          totalMessages: 0,
        );
        await Resident.db.insertRow(session, resident);

        // Attempt to post moment should fail
        expect(
          () => endpoints.moment.postMoment(
            sessionBuilder.copyWith(
              authentication: AuthenticationOverride.authenticationInfo(
                resident.userInfoId!.uuid,
                {},
              ),
            ),
            imageUrl: 'https://example.com/image.jpg',
            caption: 'Test moment',
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('successfully creates moment with valid user', () async {
        final session = await sessionBuilder.build();

        // Create floor 2 user with good credit
        final resident = Resident(
          userInfoId: UuidValue.fromString(
            '00000000-0000-0000-0000-000000000106',
          ),
          floor: 2,
          creditScore: 100,
          experience: 0,
          totalMessages: 0,
        );
        await Resident.db.insertRow(session, resident);

        // Post moment
        final moment = await endpoints.moment.postMoment(
          sessionBuilder.copyWith(
            authentication: AuthenticationOverride.authenticationInfo(
              resident.userInfoId!.uuid,
              {},
            ),
          ),
          imageUrl: 'https://example.com/image.jpg',
          caption: 'My first moment',
        );

        expect(moment, isNotNull);
        expect(moment.imageUrl, 'https://example.com/image.jpg');
        expect(moment.caption, 'My first moment');
        expect(moment.authorId, resident.userInfoId);
        expect(moment.likesCount, 0);
        expect(moment.commentsCount, 0);
      });

      test('initializes like and comment counts to zero', () async {
        final session = await sessionBuilder.build();

        // Create user
        final resident = Resident(
          userInfoId: UuidValue.fromString(
            '00000000-0000-0000-0000-000000000107',
          ),
          floor: 2,
          creditScore: 100,
          experience: 0,
          totalMessages: 0,
        );
        await Resident.db.insertRow(session, resident);

        // Post moment
        final moment = await endpoints.moment.postMoment(
          sessionBuilder.copyWith(
            authentication: AuthenticationOverride.authenticationInfo(
              resident.userInfoId!.uuid,
              {},
            ),
          ),
          imageUrl: 'https://example.com/image.jpg',
          caption: 'Test',
        );

        expect(moment.likesCount, 0);
        expect(moment.commentsCount, 0);
      });

      test('allows empty caption', () async {
        final session = await sessionBuilder.build();

        // Create user
        final resident = Resident(
          userInfoId: UuidValue.fromString(
            '00000000-0000-0000-0000-000000000108',
          ),
          floor: 2,
          creditScore: 100,
          experience: 0,
          totalMessages: 0,
        );
        await Resident.db.insertRow(session, resident);

        // Post moment without caption
        final moment = await endpoints.moment.postMoment(
          sessionBuilder.copyWith(
            authentication: AuthenticationOverride.authenticationInfo(
              resident.userInfoId!.uuid,
              {},
            ),
          ),
          imageUrl: 'https://example.com/image.jpg',
          caption: '',
        );

        expect(moment, isNotNull);
        expect(moment.caption, '');
      });
    });

    group('likeMoment', () {
      test('successfully likes a moment', () async {
        final session = await sessionBuilder.build();

        // Create author
        final author = Resident(
          userInfoId: UuidValue.fromString(
            '00000000-0000-0000-0000-000000000109',
          ),
          floor: 2,
          creditScore: 100,
          experience: 0,
          totalMessages: 0,
        );
        await Resident.db.insertRow(session, author);

        // Create moment
        final moment = Moment(
          authorId: author.userInfoId!,
          imageUrl: 'https://example.com/image.jpg',
          caption: 'Test',
          likesCount: 0,
          commentsCount: 0,
          createdAt: DateTime.now(),
        );
        await Moment.db.insertRow(session, moment);

        // Create liker
        final liker = Resident(
          userInfoId: UuidValue.fromString(
            '00000000-0000-0000-0000-000000000110',
          ),
          floor: 1,
          creditScore: 100,
          experience: 0,
          totalMessages: 0,
        );
        await Resident.db.insertRow(session, liker);

        // Like the moment
        await endpoints.moment.likeMoment(
          sessionBuilder.copyWith(
            authentication: AuthenticationOverride.authenticationInfo(
              liker.userInfoId!.uuid,
              {},
            ),
          ),
          momentId: moment.id!,
        );

        // Verify like count increased
        final updatedMoment = await Moment.db.findById(session, moment.id!);
        expect(updatedMoment!.likesCount, 1);
      });

      test('prevents duplicate likes from same user', () async {
        final session = await sessionBuilder.build();

        // Create author
        final author = Resident(
          userInfoId: UuidValue.fromString(
            '00000000-0000-0000-0000-000000000111',
          ),
          floor: 2,
          creditScore: 100,
          experience: 0,
          totalMessages: 0,
        );
        await Resident.db.insertRow(session, author);

        // Create moment
        final moment = Moment(
          authorId: author.userInfoId!,
          imageUrl: 'https://example.com/image.jpg',
          caption: 'Test',
          likesCount: 0,
          commentsCount: 0,
          createdAt: DateTime.now(),
        );
        await Moment.db.insertRow(session, moment);

        // Create liker
        final liker = Resident(
          userInfoId: UuidValue.fromString(
            '00000000-0000-0000-0000-000000000112',
          ),
          floor: 1,
          creditScore: 100,
          experience: 0,
          totalMessages: 0,
        );
        await Resident.db.insertRow(session, liker);

        final sessionWithAuth = sessionBuilder.copyWith(
          authentication: AuthenticationOverride.authenticationInfo(
            liker.userInfoId!.uuid,
            {},
          ),
        );

        // Like the moment
        await endpoints.moment.likeMoment(
          sessionWithAuth,
          momentId: moment.id!,
        );

        // Try to like again - should throw or be idempotent
        expect(
          () => endpoints.moment.likeMoment(
            sessionWithAuth,
            momentId: moment.id!,
          ),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('addComment', () {
      test('successfully adds comment to moment', () async {
        final session = await sessionBuilder.build();

        // Create author
        final author = Resident(
          userInfoId: UuidValue.fromString(
            '00000000-0000-0000-0000-000000000113',
          ),
          floor: 2,
          creditScore: 100,
          experience: 0,
          totalMessages: 0,
        );
        await Resident.db.insertRow(session, author);

        // Create moment
        final moment = Moment(
          authorId: author.userInfoId!,
          imageUrl: 'https://example.com/image.jpg',
          caption: 'Test',
          likesCount: 0,
          commentsCount: 0,
          createdAt: DateTime.now(),
        );
        await Moment.db.insertRow(session, moment);

        // Create commenter
        final commenter = Resident(
          userInfoId: UuidValue.fromString(
            '00000000-0000-0000-0000-000000000114',
          ),
          floor: 1,
          creditScore: 100,
          experience: 0,
          totalMessages: 0,
        );
        await Resident.db.insertRow(session, commenter);

        // Add comment
        final comment = await endpoints.moment.addComment(
          sessionBuilder.copyWith(
            authentication: AuthenticationOverride.authenticationInfo(
              commenter.userInfoId!.uuid,
              {},
            ),
          ),
          momentId: moment.id!,
          content: 'Nice photo!',
        );

        expect(comment, isNotNull);
        expect(comment.content, 'Nice photo!');
        expect(comment.momentId, moment.id);

        // Verify comment count increased
        final updatedMoment = await Moment.db.findById(session, moment.id!);
        expect(updatedMoment!.commentsCount, 1);
      });

      test('throws error for empty comment', () async {
        final session = await sessionBuilder.build();

        // Create author and moment
        final author = Resident(
          userInfoId: UuidValue.fromString(
            '00000000-0000-0000-0000-000000000115',
          ),
          floor: 2,
          creditScore: 100,
          experience: 0,
          totalMessages: 0,
        );
        await Resident.db.insertRow(session, author);

        final moment = Moment(
          authorId: author.userInfoId!,
          imageUrl: 'https://example.com/image.jpg',
          caption: 'Test',
          likesCount: 0,
          commentsCount: 0,
          createdAt: DateTime.now(),
        );
        await Moment.db.insertRow(session, moment);

        // Try to add empty comment
        expect(
          () => endpoints.moment.addComment(
            sessionBuilder.copyWith(
              authentication: AuthenticationOverride.authenticationInfo(
                author.userInfoId!.uuid,
                {},
              ),
            ),
            momentId: moment.id!,
            content: '',
          ),
          throwsA(isA<Exception>()),
        );
      });
    group('hasLikedMoments (batch)', () {
      test('returns correct like status for multiple moments', () async {
        final session = await sessionBuilder.build();

        // Create author
        final author = Resident(
          userInfoId: UuidValue.fromString(
            '00000000-0000-0000-0000-000000000201',
          ),
          floor: 2,
          creditScore: 100,
          experienceMessageCount: 0,
        );
        await Resident.db.insertRow(session, author);

        // Create liker
        final liker = Resident(
          userInfoId: UuidValue.fromString(
            '00000000-0000-0000-0000-000000000202',
          ),
          floor: 1,
          creditScore: 100,
          experienceMessageCount: 0,
        );
        await Resident.db.insertRow(session, liker);

        // Create 5 moments
        final momentIds = <int>[];
        for (var i = 0; i < 5; i++) {
          final moment = Moment(
            authorId: author.id!,
            imageUrl: 'https://example.com/image$i.jpg',
            caption: 'Test moment $i',
            likesCount: 0,
            commentsCount: 0,
            createdAt: DateTime.now(),
            authorName: 'Author',
            authorAvatar: '',
            authorFloor: 2,
          );
          final saved = await Moment.db.insertRow(session, moment);
          momentIds.add(saved.id!);
        }

        final sessionWithAuth = sessionBuilder.copyWith(
          authentication: AuthenticationOverride.authenticationInfo(
            liker.userInfoId.uuid,
            {},
          ),
        );

        // Like moments 0, 2, and 4
        await endpoints.moment.likeMoment(sessionWithAuth, momentIds[0]);
        await endpoints.moment.likeMoment(sessionWithAuth, momentIds[2]);
        await endpoints.moment.likeMoment(sessionWithAuth, momentIds[4]);

        // Check batch like status
        final likeMap = await endpoints.moment.hasLikedMoments(
          sessionWithAuth,
          momentIds,
        );

        expect(likeMap[momentIds[0]], true);
        expect(likeMap[momentIds[1]], false);
        expect(likeMap[momentIds[2]], true);
        expect(likeMap[momentIds[3]], false);
        expect(likeMap[momentIds[4]], true);
      });

      test('returns empty map for empty input', () async {
        final session = await sessionBuilder.build();

        // Create user
        final user = Resident(
          userInfoId: UuidValue.fromString(
            '00000000-0000-0000-0000-000000000203',
          ),
          floor: 1,
          creditScore: 100,
          experienceMessageCount: 0,
        );
        await Resident.db.insertRow(session, user);

        final sessionWithAuth = sessionBuilder.copyWith(
          authentication: AuthenticationOverride.authenticationInfo(
            user.userInfoId.uuid,
            {},
          ),
        );

        final likeMap = await endpoints.moment.hasLikedMoments(
          sessionWithAuth,
          [],
        );

        expect(likeMap, isEmpty);
      });

      test('returns all false for unauthenticated user', () async {
        final session = await sessionBuilder.build();

        // Create author and moments
        final author = Resident(
          userInfoId: UuidValue.fromString(
            '00000000-0000-0000-0000-000000000204',
          ),
          floor: 2,
          creditScore: 100,
          experienceMessageCount: 0,
        );
        await Resident.db.insertRow(session, author);

        final momentIds = <int>[];
        for (var i = 0; i < 3; i++) {
          final moment = Moment(
            authorId: author.id!,
            imageUrl: 'https://example.com/image$i.jpg',
            caption: 'Test',
            likesCount: 0,
            commentsCount: 0,
            createdAt: DateTime.now(),
            authorName: 'Author',
            authorAvatar: '',
            authorFloor: 2,
          );
          final saved = await Moment.db.insertRow(session, moment);
          momentIds.add(saved.id!);
        }

        // Check without authentication
        final likeMap = await endpoints.moment.hasLikedMoments(
          sessionBuilder, // No auth
          momentIds,
        );

        expect(likeMap[momentIds[0]], false);
        expect(likeMap[momentIds[1]], false);
        expect(likeMap[momentIds[2]], false);
      });

      test('handles large batch efficiently', () async {
        final session = await sessionBuilder.build();

        // Create author
        final author = Resident(
          userInfoId: UuidValue.fromString(
            '00000000-0000-0000-0000-000000000205',
          ),
          floor: 2,
          creditScore: 100,
          experienceMessageCount: 0,
        );
        await Resident.db.insertRow(session, author);

        // Create liker
        final liker = Resident(
          userInfoId: UuidValue.fromString(
            '00000000-0000-0000-0000-000000000206',
          ),
          floor: 1,
          creditScore: 100,
          experienceMessageCount: 0,
        );
        await Resident.db.insertRow(session, liker);

        // Create 50 moments
        final momentIds = <int>[];
        for (var i = 0; i < 50; i++) {
          final moment = Moment(
            authorId: author.id!,
            imageUrl: 'https://example.com/image$i.jpg',
            caption: 'Test moment $i',
            likesCount: 0,
            commentsCount: 0,
            createdAt: DateTime.now(),
            authorName: 'Author',
            authorAvatar: '',
            authorFloor: 2,
          );
          final saved = await Moment.db.insertRow(session, moment);
          momentIds.add(saved.id!);
        }

        final sessionWithAuth = sessionBuilder.copyWith(
          authentication: AuthenticationOverride.authenticationInfo(
            liker.userInfoId.uuid,
            {},
          ),
        );

        // Like every 5th moment
        for (var i = 0; i < momentIds.length; i += 5) {
          await endpoints.moment.likeMoment(sessionWithAuth, momentIds[i]);
        }

        // Check batch like status - should complete quickly
        final stopwatch = Stopwatch()..start();
        final likeMap = await endpoints.moment.hasLikedMoments(
          sessionWithAuth,
          momentIds,
        );
        stopwatch.stop();

        // Verify correctness
        expect(likeMap.length, 50);
        for (var i = 0; i < momentIds.length; i++) {
          expect(likeMap[momentIds[i]], i % 5 == 0);
        }

        // Performance check: should be much faster than 50 individual queries
        // With batch: ~1 query, without: 50 queries
        expect(stopwatch.elapsedMilliseconds, lessThan(1000));
      });
    });
  });
}
