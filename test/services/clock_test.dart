import 'package:flutter_test/flutter_test.dart';
import 'package:talktive/services/clock.dart';

void main() {
  group('Clock', () {
    final clock = Clock();

    test('instantiates a singleton object', () async {
      final anotherClock = Clock();

      expect(identical(clock, anotherClock), isTrue);
    });

    test('.serverNow()', () async {
      final now = clock.serverNow();

      expect(now, isA<num>());
      expect(now > 0, isTrue);
    });

    test('.updateClockSkew()', () async {
      final now1 = clock.serverNow();

      clock.updateClockSkew(10);

      final now2 = clock.serverNow();

      expect(now2 - now1 >= 10, isTrue);
    });
  });
}
