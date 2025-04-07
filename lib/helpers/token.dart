import 'dart:math';

class RecoveryToken {
  static const _chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
  static const _domain = '@talktive.app';
  static const _emailLength = 8; // First half
  static const _passwordLength = 8; // Second half

  final String email;
  final String password;

  RecoveryToken._(this.email, this.password);

  factory RecoveryToken.generate() {
    final random = Random.secure();

    // Generate email part (starting with a number)
    final firstChar = random.nextInt(10).toString(); // 0-9
    final restEmail = List.generate(
      _emailLength - 1,
      (index) => _chars[random.nextInt(_chars.length)],
    ).join();
    final emailPart = '$firstChar$restEmail';

    // Generate password part
    final passwordPart = List.generate(
      _passwordLength,
      (index) => _chars[random.nextInt(_chars.length)],
    ).join();

    return RecoveryToken._('$emailPart$_domain', passwordPart);
  }

  factory RecoveryToken.fromString(String token) {
    if (token.length != _emailLength + _passwordLength) {
      throw FormatException('Invalid token length');
    }

    final emailPart = token.substring(0, _emailLength);
    final passwordPart = token.substring(_emailLength);

    return RecoveryToken._('$emailPart$_domain', passwordPart);
  }

  String get token => email.replaceAll(_domain, '') + password;

  @override
  String toString() => token;
}
