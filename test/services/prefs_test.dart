import 'package:flutter_test/flutter_test.dart';
import 'package:talktive/services/prefs.dart';

import '../mock.dart';

void main() {
  setupMocks();

  group('Prefs', () {
    final prefs = Prefs();

    test('can save a string value', () async {
      final result = await prefs.setString('key1', 'value1');
      expect(result, true);
    });

    test('can get a previouly-saved string value', () async {
      await prefs.setString('key2', 'value2');
      final result = await prefs.getString('key2');
      expect(result, 'value2');
    });
  });
}
