import 'dart:math';

const _pushChars =
    '-0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ_abcdefghijklmnopqrstuvwxyz';

/// Requirements:
/// - generated id should contain 20 characters
/// - should prevent collisions if called more than once in a millisecond
/// - should sort lexicographically (ids created earlier will appear before
///   keys created later if sorted)
final nextPushId = (() {
  // prevents collisions if you push more than once in one millisecond
  var lastPushTime = 0;
  // if called more than once in one millisecond previous random chars
  // will be used except incremented by 1
  final lastRandChars = List<int>.generate(12, (index) => 0);
  final random = Random.secure();

  // now is time in milliseconds since epoch
  return (int now) {
    final duplicateTime = now == lastPushTime;
    lastPushTime = now;

    // List<String> but it's actually chars
    final timestampChars = List<String>.generate(8, (index) => '');
    for (var i = 7; i >= 0; i--) {
      timestampChars[i] = _pushChars[now % 64];
      // probably could use bit shift for this, JS version deliberately
      // does not use it, so neither does this
      now ~/= 64;
    }
    assert(now == 0);

    // add 8 timestamp chars
    var id = timestampChars.join();

    if (!duplicateTime) {
      for (var i = 0; i < 12; i++) {
        // FIXME(gnowoel): Consider `lastRandChars[0] = 0`
        lastRandChars[i] = random.nextInt(64);
      }
    } else {
      // timestamp hasn't changed since last push, thus will use
      // previous random number incremented by 1
      late int i;
      for (i = 11; i >= 0 && lastRandChars[i] == 63; i--) {
        lastRandChars[i] = 0;
      }
      // FIXME(gnowoel): What if all numbers were `63`?
      lastRandChars[i]++;
    }

    // add 12 random chars
    for (var i = 0; i < 12; i++) {
      id += _pushChars[lastRandChars[i]];
    }

    assert(id.length == 20);

    return id;
  };
})();
