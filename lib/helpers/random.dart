import 'dart:math';

final Random _random = Random();

const String _lowerChars = 'abcdefghijklmnopqrstuvwxyz';
const String _upperChars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
const String _numberChars = '0123456789';
const String _symbolChars = '!@#\$%^&*()_+';

const String _emailChars = _lowerChars;
const String _passwordChars =
    _lowerChars + _upperChars + _numberChars + _symbolChars;

/// Generates a random email address.
///
/// [length] specifies the length of the local part of the email (default: 8).
String generateEmail({int length = 8}) {
  return '${_generateString(length, _emailChars)}@example.com';
}

/// Generates a random password.
///
/// [length] specifies the total length of the password (default: 16).
/// Ensures the password contains at least one lowercase letter, one uppercase letter,
/// one number, and one symbol.
String generatePassword({int length = 16}) {
  if (length < 4) {
    throw ArgumentError('Password length must be at least 4 characters');
  }

  String password = '';
  password += _generateString(1, _lowerChars);
  password += _generateString(1, _upperChars);
  password += _generateString(1, _numberChars);
  password += _generateString(1, _symbolChars);
  password += _generateString(length - 4, _passwordChars);

  return _shuffleString(password);
}

String _generateString(int length, String chars) {
  return String.fromCharCodes(
    Iterable.generate(length, (_) {
      return chars.codeUnitAt(_random.nextInt(chars.length));
    }),
  );
}

String _shuffleString(String input) {
  List<String> characters = input.split('');
  characters.shuffle(_random);
  return characters.join();
}
