import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';
import 'package:talktive_server/src/generated/protocol.dart' as protocol;
import 'package:uuid/uuid.dart';

import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod(
    'Given Moment endpoint',
    (sessionBuilder, endpoints) {
      const uuid = Uuid();
      late protocol.Resident author;
      late protocol.Resident blockedAuthor;
      late protocol.Resident viewer;
      late protocol.Resident liker;

      AuthenticationOverride authFor(protocol.Resident resident) {
        return AuthenticationOverride.authenticationInfo(
          resident.userInfoId.uuid,
          {},
        );
      }

      Future<protocol.Moment> createMoment(
        protocol.Resident resident, {
        String caption = '',
        String imageUrl = 'https://cdn.example.com/moments/test.jpg',
      }) async {
        return endpoints.moment.postMoment(
          sessionBuilder.copyWith(authentication: authFor(resident)),
          imageUrl: imageUrl,
          caption: caption,
        );
      }

      setUp(() async {
        final session = sessionBuilder.build();

        author = await protocol.Resident.db.insertRow(
          session,
          protocol.Resident(
            userInfoId: UuidValue.fromString(
              uuid.v4(),
            ),
            userName: 'Author',
            avatar: 'A',
            xp: 500,
            level: 2,
            trustScore: 120,
          ),
        );

        blockedAuthor = await protocol.Resident.db.insertRow(
          session,
          protocol.Resident(
            userInfoId: UuidValue.fromString(
              uuid.v4(),
            ),
            userName: 'Blocked Author',
            avatar: 'B',
            xp: 500,
            level: 3,
            trustScore: 110,
          ),
        );

        viewer = await protocol.Resident.db.insertRow(
          session,
          protocol.Resident(
            userInfoId: UuidValue.fromString(
              uuid.v4(),
            ),
            userName: 'Viewer',
            avatar: 'V',
            xp: 500,
            level: 3,
            trustScore: 100,
          ),
        );

        liker = await protocol.Resident.db.insertRow(
          session,
          protocol.Resident(
            userInfoId: UuidValue.fromString(
              uuid.v4(),
            ),
            userName: 'Liker',
            avatar: 'L',
            xp: 500,
            level: 3,
            trustScore: 105,
          ),
        );
      });

      tearDown(() async {
        final session = sessionBuilder.build();
        final residentIds = {
          author.userInfoId,
          blockedAuthor.userInfoId,
          viewer.userInfoId,
          liker.userInfoId,
        };

        final moments = await protocol.Moment.db.find(
          session,
          where: (t) => t.authorId.inSet(residentIds),
        );
        final momentIds = moments.map((moment) => moment.id!).toSet();

        if (momentIds.isNotEmpty) {
          await protocol.MomentLike.db.deleteWhere(
            session,
            where: (t) => t.momentId.inSet(momentIds),
          );
          await protocol.MomentComment.db.deleteWhere(
            session,
            where: (t) => t.momentId.inSet(momentIds),
          );
          await protocol.Moment.db.deleteWhere(
            session,
            where: (t) => t.id.inSet(momentIds),
          );
        }

        await protocol.Block.db.deleteWhere(
          session,
          where: (t) =>
              t.blockerId.inSet(residentIds) | t.blockedId.inSet(residentIds),
        );
        await protocol.UserNotification.db.deleteWhere(
          session,
          where: (t) => t.userId.inSet(residentIds),
        );
        await protocol.Resident.db.deleteWhere(
          session,
          where: (t) => t.userInfoId.inSet(residentIds),
        );
      });

      group('postMoment', () {
        test('rejects Floor 1 residents', () async {
          final session = sessionBuilder.build();
          final floorOneResident = await protocol.Resident.db.insertRow(
            session,
            protocol.Resident(
              userInfoId: UuidValue.fromString(
                uuid.v4(),
              ),
              userName: 'Floor One',
              level: 1,
              trustScore: 100,
            ),
          );

          expect(
            () => endpoints.moment.postMoment(
              sessionBuilder.copyWith(
                authentication: authFor(floorOneResident),
              ),
              imageUrl: 'https://cdn.example.com/moments/floor-one.jpg',
              caption: 'Blocked',
            ),
            throwsA(
              isA<protocol.TalktiveException>().having(
                (e) => e.code,
                'code',
                'FLOOR_TOO_LOW',
              ),
            ),
          );
        });

        test('persists a moment for eligible residents', () async {
          final savedMoment = await createMoment(
            author,
            caption: 'Sunrise in the plaza',
            imageUrl: 'https://cdn.example.com/moments/sunrise.jpg',
          );

          expect(savedMoment.id, isNotNull);
          expect(savedMoment.authorId, author.userInfoId);
          expect(savedMoment.caption, 'Sunrise in the plaza');
          expect(savedMoment.likesCount, 0);
          expect(savedMoment.commentsCount, 0);

          final session = sessionBuilder.build();
          final storedMoment = await protocol.Moment.db.findById(
            session,
            savedMoment.id!,
          );

          expect(storedMoment, isNotNull);
          expect(storedMoment!.authorName, 'Author');
        });
      });

      group('listMoments', () {
        test('filters out blocked residents from the feed', () async {
          final visibleMoment = await createMoment(
            author,
            caption: 'Visible moment',
            imageUrl: 'https://cdn.example.com/moments/visible.jpg',
          );
          final blockedMoment = await createMoment(
            blockedAuthor,
            caption: 'Blocked moment',
            imageUrl: 'https://cdn.example.com/moments/blocked.jpg',
          );

          final session = sessionBuilder.build();
          await protocol.Block.db.insertRow(
            session,
            protocol.Block(
              blockerId: viewer.userInfoId,
              blockedId: blockedAuthor.userInfoId,
              createdAt: DateTime.now(),
            ),
          );

          final moments = await endpoints.moment.listMoments(
            sessionBuilder.copyWith(authentication: authFor(viewer)),
            limit: 20,
          );

          final momentIds = moments.map((moment) => moment.id).toList();
          expect(momentIds, contains(visibleMoment.id));
          expect(momentIds, isNot(contains(blockedMoment.id)));
        });
      });

      group('likes', () {
        test('tracks like state and updates aggregate counts', () async {
          final moment = await createMoment(
            author,
            caption: 'Likeable moment',
            imageUrl: 'https://cdn.example.com/moments/likeable.jpg',
          );
          final likerSession = sessionBuilder.copyWith(
            authentication: authFor(liker),
          );

          await endpoints.moment.likeMoment(likerSession, moment.id!);

          expect(
            await endpoints.moment.hasLikedMoment(likerSession, moment.id!),
            isTrue,
          );
          expect(
            await endpoints.moment.hasLikedMoments(likerSession, [moment.id!]),
            {moment.id!: true},
          );

          final session = sessionBuilder.build();
          final storedMoment = await protocol.Moment.db.findById(
            session,
            moment.id!,
          );
          final likes = await protocol.MomentLike.db.find(
            session,
            where: (t) =>
                t.momentId.equals(moment.id!) &
                t.userId.equals(liker.userInfoId),
          );

          expect(storedMoment!.likesCount, 1);
          expect(likes, hasLength(1));

          await endpoints.moment.unlikeMoment(likerSession, moment.id!);

          final unlikedMoment = await protocol.Moment.db.findById(
            session,
            moment.id!,
          );
          final remainingLikes = await protocol.MomentLike.db.find(
            session,
            where: (t) =>
                t.momentId.equals(moment.id!) &
                t.userId.equals(liker.userInfoId),
          );

          expect(unlikedMoment!.likesCount, 0);
          expect(remainingLikes, isEmpty);
        });
      });

      group('comments', () {
        test('enforces ownership when deleting a comment', () async {
          final moment = await createMoment(
            author,
            caption: 'Commentable moment',
            imageUrl: 'https://cdn.example.com/moments/commentable.jpg',
          );
          final authorSession = sessionBuilder.copyWith(
            authentication: authFor(author),
          );

          final comment = await endpoints.moment.addComment(
            authorSession,
            moment.id!,
            'Looks good',
          );

          final session = sessionBuilder.build();
          final storedMoment = await protocol.Moment.db.findById(
            session,
            moment.id!,
          );
          expect(storedMoment!.commentsCount, 1);

          expect(
            () => endpoints.moment.deleteComment(
              sessionBuilder.copyWith(authentication: authFor(viewer)),
              comment.id!,
            ),
            throwsA(
              isA<protocol.TalktiveException>().having(
                (e) => e.message,
                'message',
                contains('Not your comment'),
              ),
            ),
          );

          await endpoints.moment.deleteComment(authorSession, comment.id!);

          final comments = await endpoints.moment.getMomentComments(
            authorSession,
            moment.id!,
            limit: 50,
          );
          final updatedMoment = await protocol.Moment.db.findById(
            session,
            moment.id!,
          );

          expect(comments, isEmpty);
          expect(updatedMoment!.commentsCount, 0);
        });
      });

      group('deleteMoment', () {
        test('removes the moment and its associations', () async {
          final moment = await createMoment(
            author,
            caption: 'Disposable moment',
            imageUrl: 'https://cdn.example.com/moments/disposable.jpg',
          );
          final likerSession = sessionBuilder.copyWith(
            authentication: authFor(liker),
          );

          await endpoints.moment.likeMoment(likerSession, moment.id!);
          await endpoints.moment.addComment(
            likerSession,
            moment.id!,
            'Temporary comment',
          );

          await endpoints.moment.deleteMoment(
            sessionBuilder.copyWith(authentication: authFor(author)),
            moment.id!,
          );

          final session = sessionBuilder.build();
          final storedMoment = await protocol.Moment.db.findById(
            session,
            moment.id!,
          );
          final likes = await protocol.MomentLike.db.find(
            session,
            where: (t) => t.momentId.equals(moment.id!),
          );
          final comments = await protocol.MomentComment.db.find(
            session,
            where: (t) => t.momentId.equals(moment.id!),
          );

          expect(storedMoment, isNull);
          expect(likes, isEmpty);
          expect(comments, isEmpty);
        });
      });
    },
    rollbackDatabase: RollbackDatabase.disabled,
  );
}
