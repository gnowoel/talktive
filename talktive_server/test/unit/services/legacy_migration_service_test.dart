import 'package:test/test.dart';
import 'package:talktive_server/src/generated/protocol.dart';
import 'package:talktive_server/src/services/legacy_migration_service.dart';

void main() {
  group('LegacyMigrationService.convertLegacyUserData', () {
    test('maps legacy fields and normalizes values', () {
      final migration = LegacyMigrationService.convertLegacyUserData({
        'displayName': '  Legacy User  ',
        'description': '  Old bio  ',
        'photoURL': '😎',
        'gender': 'F',
        'languageCode': 'FIL',
        'messageCount': 144,
        'role': 'ADMIN',
      });

      expect(migration, isNotNull);
      expect(migration!.name, 'Legacy User');
      expect(migration.bio, 'Old bio');
      expect(migration.avatar, '😎');
      expect(migration.gender, 'female');
      expect(migration.languages, ['en', 'tl']);
      expect(migration.xp, 1440);
      expect(migration.level, 6);
      expect(migration.role, ResidentRole.admin);
    });

    test('falls back to English for unsupported languages', () {
      final migration = LegacyMigrationService.convertLegacyUserData({
        'languageCode': 'sw',
      });

      expect(migration, isNotNull);
      expect(migration!.languages, ['en']);
    });

    test('clamps negative message counts and ignores unknown roles', () {
      final migration = LegacyMigrationService.convertLegacyUserData({
        'messageCount': -99,
        'role': 'vip',
      });

      expect(migration, isNotNull);
      expect(migration!.xp, 0);
      expect(migration.level, 1);
      expect(migration.role, isNull);
    });
  });
}
