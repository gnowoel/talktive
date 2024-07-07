import 'dart:math';

Random _random = Random();

const _lowerChars = 'abcdefghijklmnopqrstuvwxyz';
const _upperChars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
const _numberChars = '0123456789';
const _symbolChars = '!@#\$%^&*()_+';

const _emailChars = _lowerChars;
const _passwordChars = _lowerChars + _upperChars + _numberChars + _symbolChars;

String generateEmail() {
  return '${_generateString(8, _emailChars)}@example.com';
}

String generatePassword() {
  return _generateString(16, _passwordChars);
}

String _generateString(length, chars) {
  return String.fromCharCodes(
    Iterable.generate(length, (_) {
      return chars.codeUnitAt(_random.nextInt(chars.length));
    }),
  );
}
