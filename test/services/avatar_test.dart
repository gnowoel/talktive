import 'package:flutter_test/flutter_test.dart';
import 'package:talktive/services/avatar.dart';

import '../mock.dart';

void main() {
  setupMocks();

  group('Avatar', () {
    final avatar = Avatar();

    test('initEmoji()', () async {
      await avatar.init();
      expect(avatar.name, isNotEmpty);
      expect(avatar.code, isNotEmpty);
    });

    test('refresh()', () {
      final name = avatar.name;
      final code = avatar.code;

      avatar.refresh();

      expect(avatar.name == name, isFalse);
      expect(avatar.code == code, isFalse);
    });
  });
}
