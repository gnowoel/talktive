import 'dart:convert';
import 'package:test/test.dart';
import 'package:serverpod/serverpod.dart';
import 'package:talktive_server/src/generated/protocol.dart' as protocol;
import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Given MediaEndpoint', (sessionBuilder, endpoints) {
    late protocol.Resident regularUser;
    late protocol.Resident plusUser;
    late protocol.Resident floor1User;

    setUp(() async {
      final session = sessionBuilder.build();

      // Create a Regular user (Floor 2+)
      regularUser = await protocol.Resident.db.insertRow(
        session,
        protocol.Resident(
          userInfoId: UuidValue.fromString(
            'b1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d',
          ),
          userName: 'Regular User',
          xp: 500, // High enough for Floor 2+
          level: 5,
          isPremium: false,
        ),
      );

      // Create a Plus user
      plusUser = await protocol.Resident.db.insertRow(
        session,
        protocol.Resident(
          userInfoId: UuidValue.fromString(
            'c1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d',
          ),
          userName: 'Plus User',
          isPremium: true,
        ),
      );

      // Create a Floor 1 user
      floor1User = await protocol.Resident.db.insertRow(
        session,
        protocol.Resident(
          userInfoId: UuidValue.fromString(
            'd1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d',
          ),
          userName: 'Floor 1 User',
          xp: 0,
          level: 1,
        ),
      );
    });

    group('getUploadDescription', () {
      test('allows regular users to upload images to chats', () async {
        final session = sessionBuilder.copyWith(
          authentication: AuthenticationOverride.authenticationInfo(
            regularUser.userInfoId.uuid,
            {},
          ),
        );
        final result = await endpoints.media.getUploadDescription(
          session,
          'chats',
          1024,
          null,
        );
        expect(result, isNotNull);

        final description = jsonDecode(result!) as Map<String, dynamic>;
        final path = description['path'] as String?;
        final publicUrl = description['publicUrl'] as String?;
        expect(path, isNotNull);
        expect(path, startsWith('chats/'));
        expect(publicUrl, isNotNull);
        expect(publicUrl, contains('method=file'));
      });

      test('denies floor 1 users to upload to moments', () async {
        final session = sessionBuilder.copyWith(
          authentication: AuthenticationOverride.authenticationInfo(
            floor1User.userInfoId.uuid,
            {},
          ),
        );
        expect(
          () => endpoints.media.getUploadDescription(
            session,
            'moments',
            1024,
            null,
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

      test('denies regular users to upload voice messages', () async {
        final session = sessionBuilder.copyWith(
          authentication: AuthenticationOverride.authenticationInfo(
            regularUser.userInfoId.uuid,
            {},
          ),
        );
        expect(
          () => endpoints.media.getUploadDescription(
            session,
            'voices',
            1024,
            null,
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

      test('allows plus users to upload voice messages', () async {
        final session = sessionBuilder.copyWith(
          authentication: AuthenticationOverride.authenticationInfo(
            plusUser.userInfoId.uuid,
            {},
          ),
        );
        final result = await endpoints.media.getUploadDescription(
          session,
          'voices',
          1024,
          null,
        );
        expect(result, isNotNull);

        final description = jsonDecode(result!) as Map<String, dynamic>;
        final path = description['path'] as String?;
        final publicUrl = description['publicUrl'] as String?;
        expect(path, isNotNull);
        expect(path, startsWith('voices/'));
        expect(path, endsWith('.m4a'));
        expect(publicUrl, isNotNull);
      });

      test('allows plus users to upload wav voice messages for web', () async {
        final session = sessionBuilder.copyWith(
          authentication: AuthenticationOverride.authenticationInfo(
            plusUser.userInfoId.uuid,
            {},
          ),
        );
        final result = await endpoints.media.getUploadDescription(
          session,
          'voices',
          1024,
          'wav',
        );
        expect(result, isNotNull);

        final description = jsonDecode(result!) as Map<String, dynamic>;
        final path = description['path'] as String?;
        expect(path, isNotNull);
        expect(path, startsWith('voices/'));
        expect(path, endsWith('.wav'));
      });

      test('rejects unsupported voice upload extensions', () async {
        final session = sessionBuilder.copyWith(
          authentication: AuthenticationOverride.authenticationInfo(
            plusUser.userInfoId.uuid,
            {},
          ),
        );

        expect(
          () => endpoints.media.getUploadDescription(
            session,
            'voices',
            1024,
            'webm',
          ),
          throwsA(
            isA<protocol.TalktiveException>().having(
              (e) => e.message,
              'message',
              contains('m4a or wav'),
            ),
          ),
        );
      });

      test('allows plus users to upload custom avatars', () async {
        final session = sessionBuilder.copyWith(
          authentication: AuthenticationOverride.authenticationInfo(
            plusUser.userInfoId.uuid,
            {},
          ),
        );
        final result = await endpoints.media.getUploadDescription(
          session,
          'avatars',
          1024,
          null,
        );
        expect(result, isNotNull);
      });

      test('denies regular users to upload custom avatars', () async {
        final session = sessionBuilder.copyWith(
          authentication: AuthenticationOverride.authenticationInfo(
            regularUser.userInfoId.uuid,
            {},
          ),
        );
        expect(
          () => endpoints.media.getUploadDescription(
            session,
            'avatars',
            1024,
            null,
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

      test('verifies uploaded files through Serverpod storage', () async {
        final session = sessionBuilder.copyWith(
          authentication: AuthenticationOverride.authenticationInfo(
            regularUser.userInfoId.uuid,
            {},
          ),
        );
        final storageSession = session.build();

        await storageSession.db.unsafeQuery(
          '''
          INSERT INTO serverpod_cloud_storage
            ("storageId", "path", "addedTime", "expiration", "verified", "byteData")
          VALUES
            ('public', 'chats/test-upload.jpg', NOW(), NULL, FALSE, decode('', 'base64'))
          ''',
        );

        final verified = await endpoints.media.verifyUpload(
          session,
          'chats/test-upload.jpg',
        );

        expect(verified, isTrue);
        expect(
          await storageSession.storage.getPublicUrl(
            storageId: 'public',
            path: 'chats/test-upload.jpg',
          ),
          isNotNull,
        );
        await storageSession.close();
      });
    });
  });
}
