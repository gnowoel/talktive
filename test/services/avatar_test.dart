import 'package:flutter_test/flutter_test.dart';
import 'package:talktive/services/avatar.dart';

void main() {
  group('Avatar', () {
    final avatar = Avatar();

    test('has an initial value', () {
      expect(avatar.name.isNotEmpty, true);
      expect(avatar.code.isNotEmpty, true);
    });

    test('can generate new values', () {
      avatar.refresh();
      expect(avatar.name.isNotEmpty, true);
      expect(avatar.code.isNotEmpty, true);
    });

    test('can change old values', () {
      final name = avatar.name;
      final code = avatar.code;
      avatar.refresh();
      expect(avatar.name == name, false);
      expect(avatar.code == code, false);
    });
  });
}
