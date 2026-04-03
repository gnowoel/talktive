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

    test(
      'returns null when only an unsupported language code is present',
      () {
        // 'sw' (Swahili) is unsupported — normalises to just ['en'], which is
        // the default and not counted as a meaningful language preference.
        // Because no other useful fields are present, hasUsefulData → false.
        final migration = LegacyMigrationService.convertLegacyUserData({
          'languageCode': 'sw',
        });

        expect(migration, isNull);
      },
    );

    test('counts known non-English language as useful data', () {
      // 'fil' → 'tl' is supported, so languages becomes ['en', 'tl'],
      // which satisfies the non-English language check in hasUsefulData.
      final migration = LegacyMigrationService.convertLegacyUserData({
        'languageCode': 'fil',
      });

      expect(migration, isNotNull);
      expect(migration!.languages, ['en', 'tl']);
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

    test('returns null for completely empty data', () {
      final migration = LegacyMigrationService.convertLegacyUserData({});
      expect(migration, isNull);
    });

    test('returns null when all fields are blank, null, or unrecognised', () {
      final migration = LegacyMigrationService.convertLegacyUserData({
        'displayName': '   ',
        'description': '',
        'photoURL': null,
        'gender': 'unknown_value',
      });
      // blank name → null, blank bio → null, null avatar → null,
      // unrecognised gender → null → hasUsefulData = false
      expect(migration, isNull);
    });

    test('stores Google photo URL verbatim in avatar field', () {
      // The backend stores the raw URL in LegacyMigrationData.avatar.
      // The Flutter profile_setup_screen detects '://' and routes it to
      // _customAvatarUrl instead of the emoji slot.
      const googlePhotoUrl = 'https://lh3.googleusercontent.com/a/photo.jpg';
      final migration = LegacyMigrationService.convertLegacyUserData({
        'displayName': 'Test User',
        'photoURL': googlePhotoUrl,
      });

      expect(migration, isNotNull);
      expect(migration!.avatar, googlePhotoUrl);
    });

    test('handles zh-CN alias and normalises to zh', () {
      final migration = LegacyMigrationService.convertLegacyUserData({
        'displayName': 'User',
        'languageCode': 'zh-CN',
      });

      expect(migration, isNotNull);
      expect(migration!.languages, containsAll(['en', 'zh']));
    });

    test('handles nb (Norwegian Bokmål) alias', () {
      final migration = LegacyMigrationService.convertLegacyUserData({
        'displayName': 'User',
        'languageCode': 'nb',
      });

      expect(migration, isNotNull);
      expect(migration!.languages, containsAll(['en', 'no']));
    });
  });
}
