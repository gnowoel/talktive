import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talktive/services/prefs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

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
