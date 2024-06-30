import 'dart:math';

// https://stackoverflow.com/a/61929967

const _chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
Random _rnd = Random();

String getRandomString(int length) {
  return String.fromCharCodes(
    Iterable.generate(length, (_) {
      return _chars.codeUnitAt(_rnd.nextInt(_chars.length));
    }),
  );
}
