import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:serverpod/serverpod.dart';
import 'package:talktive_server/src/generated/protocol.dart' as protocol;
import 'package:talktive_server/src/services/resident_service.dart';
import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Given Resident Avatar Lifecycle', (sessionBuilder, endpoints) {
    late protocol.Resident testResident;

    setUp(() async {
      final session = sessionBuilder.build();

      // Create a resident with an initial custom avatar
      final resident = protocol.Resident(
        userInfoId: UuidValue.fromString(
          'e1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d',
        ),
        userName: 'Avatar User',
        customAvatarUrl:
            'http://localhost:8080/serverpod_cloud_storage?method=file&path=avatars/old_avatar.jpg',
        level: 1,
        trustScore: 100,
      );
      testResident = await protocol.Resident.db.insertRow(session, resident);

      // Manually create the "file" in mock storage
      await session.storage.storeFile(
        storageId: 'public',
        path: 'avatars/old_avatar.jpg',
        byteData: ByteData(8),
      );
    });

    test('deletes old avatar when updating to a new one', () async {
      final session = sessionBuilder.build();

      // Update to new avatar
      testResident.customAvatarUrl =
          'http://localhost:8080/serverpod_cloud_storage?method=file&path=avatars/new_avatar.jpg';
      await ResidentService.updateResident(session, testResident);

      // Verify old file is gone
      final oldExists = await session.storage.fileExists(
        storageId: 'public',
        path: 'avatars/old_avatar.jpg',
      );
      expect(oldExists, isFalse);
    });

    test('deletes old avatar when removing it (switching to emoji)', () async {
      final session = sessionBuilder.build();

      // Remove custom avatar
      testResident.customAvatarUrl = null;
      await ResidentService.updateResident(session, testResident);

      // Verify old file is gone
      final oldExists = await session.storage.fileExists(
        storageId: 'public',
        path: 'avatars/old_avatar.jpg',
      );
      expect(oldExists, isFalse);
    });

    test('skips stale background updates after the resident row is deleted', () async {
      final session = sessionBuilder.build();

      await protocol.Resident.db.deleteRow(session, testResident);

      testResident.customAvatarUrl =
          'http://localhost:8080/serverpod_cloud_storage?method=file&path=avatars/new_avatar.jpg';
      final updatedResident = await ResidentService.updateResident(
        session,
        testResident,
      );

      final oldExists = await session.storage.fileExists(
        storageId: 'public',
        path: 'avatars/old_avatar.jpg',
      );

      expect(updatedResident.customAvatarUrl, contains('avatars/new_avatar.jpg'));
      expect(oldExists, isTrue);
    });
  });
}
