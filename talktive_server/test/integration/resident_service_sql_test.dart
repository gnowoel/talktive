import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';
import 'package:talktive_server/src/generated/protocol.dart' as protocol;
import 'package:talktive_server/src/services/resident_service.dart';
import 'package:uuid/uuid.dart';

import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Given ResidentService.getBatchUserCounts', (
    sessionBuilder,
    endpoints,
  ) {
    const uuid = Uuid();

    test('returns batched counts for messages, moments, and reports', () async {
      final session = sessionBuilder.build();
      final resident = await protocol.Resident.db.insertRow(
        session,
        protocol.Resident(
          userInfoId: UuidValue.fromString(uuid.v4()),
          userName: 'Count Resident',
          level: 2,
          trustScore: 100,
        ),
      );
      final reporter = await protocol.Resident.db.insertRow(
        session,
        protocol.Resident(
          userInfoId: UuidValue.fromString(uuid.v4()),
          userName: 'Reporter Resident',
          level: 2,
          trustScore: 100,
        ),
      );
      final channel = await protocol.Channel.db.insertRow(
        session,
        protocol.Channel(
          type: protocol.ChannelType.plaza,
          name: 'Counts Plaza',
          createdAt: DateTime.now(),
        ),
      );
      final message = await protocol.Message.db.insertRow(
        session,
        protocol.Message(
          channelId: channel.id!,
          senderId: resident.userInfoId,
          content: 'Hello Plaza',
          isSystem: false,
          createdAt: DateTime.now(),
          senderName: resident.userName ?? 'Resident',
          senderFloor: resident.level,
          senderTrustScore: resident.trustScore,
        ),
      );
      await protocol.Message.db.insertRow(
        session,
        protocol.Message(
          channelId: channel.id!,
          senderId: resident.userInfoId,
          content: 'Hello again',
          isSystem: false,
          createdAt: DateTime.now(),
          senderName: resident.userName ?? 'Resident',
          senderFloor: resident.level,
          senderTrustScore: resident.trustScore,
        ),
      );
      await protocol.Moment.db.insertRow(
        session,
        protocol.Moment(
          authorId: resident.userInfoId,
          imageUrl: 'https://example.com/moment.jpg',
          createdAt: DateTime.now(),
          likesCount: 0,
          commentsCount: 0,
          authorName: resident.userName ?? 'Resident',
          authorFloor: resident.level,
          authorTrustScore: resident.trustScore,
        ),
      );
      await protocol.Report.db.insertRow(
        session,
        protocol.Report(
          reporterId: reporter.userInfoId,
          targetId: resident.userInfoId,
          reason: 'Noise complaint',
          channelId: channel.id,
          messageId: message.id,
          createdAt: DateTime.now(),
        ),
      );

      final counts = await ResidentService.getBatchUserCounts(session, [
        resident.userInfoId,
        reporter.userInfoId,
      ]);

      expect(counts[resident.userInfoId.uuid], isNotNull);
      expect(counts[resident.userInfoId.uuid]!['messages'], 2);
      expect(counts[resident.userInfoId.uuid]!['moments'], 1);
      expect(counts[resident.userInfoId.uuid]!['reports'], 1);
      expect(counts[reporter.userInfoId.uuid]!['messages'], 0);
      expect(counts[reporter.userInfoId.uuid]!['moments'], 0);
      expect(counts[reporter.userInfoId.uuid]!['reports'], 0);
    });

    test(
      'applyLegacyMigration restores XP without clobbering profile edits',
      () async {
        final session = sessionBuilder.build();
        final resident = await protocol.Resident.db.insertRow(
          session,
          protocol.Resident(
            userInfoId: UuidValue.fromString(uuid.v4()),
            userName: 'New Persona',
            bio: 'Fresh bio',
            avatar: '🤖',
            gender: 'prefer-not-to-say',
            languages: const ['en'],
            xp: 0,
            level: 1,
            trustScore: 100,
            role: protocol.ResidentRole.user,
          ),
        );

        final updated = await ResidentService.applyLegacyMigration(
          session,
          resident: resident,
          migration: protocol.LegacyMigrationData(
            name: 'Legacy Persona',
            bio: 'Legacy bio',
            avatar: '😎',
            gender: 'female',
            languages: const ['en', 'tl'],
            xp: 1440,
            level: 6,
            role: protocol.ResidentRole.admin,
          ),
        );

        expect(updated.userName, 'New Persona');
        expect(updated.bio, 'Fresh bio');
        expect(updated.avatar, '🤖');
        expect(updated.gender, 'female');
        expect(updated.languages, ['en', 'tl']);
        expect(updated.xp, 1440);
        expect(updated.level, 6);
        expect(updated.role, protocol.ResidentRole.admin);
      },
    );

    test(
      'applyLegacyMigration keeps newer progress and premium avatar',
      () async {
        final session = sessionBuilder.build();
        final resident = await protocol.Resident.db.insertRow(
          session,
          protocol.Resident(
            userInfoId: UuidValue.fromString(uuid.v4()),
            userName: 'Resident',
            avatar: '🥷',
            customAvatarUrl: 'https://cdn.example.com/current.png',
            gender: 'male',
            languages: const ['en', 'es'],
            xp: 5000,
            level: 9,
            trustScore: 100,
            role: protocol.ResidentRole.moderator,
          ),
        );

        final updated = await ResidentService.applyLegacyMigration(
          session,
          resident: resident,
          migration: protocol.LegacyMigrationData(
            avatar: 'https://lh3.googleusercontent.com/a/photo.jpg',
            gender: 'female',
            languages: const ['en', 'tl'],
            xp: 1440,
            level: 6,
            role: protocol.ResidentRole.user,
          ),
        );

        expect(updated.customAvatarUrl, 'https://cdn.example.com/current.png');
        expect(updated.gender, 'male');
        expect(updated.languages, ['en', 'es']);
        expect(updated.xp, 5000);
        expect(updated.level, 9);
        expect(updated.role, protocol.ResidentRole.moderator);
      },
    );
  });
}
