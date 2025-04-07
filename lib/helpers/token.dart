import 'dart:math';

class RecoveryToken {
  static const _chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
  static const _domain = '@talktive.app';
  static const _emailLength = 12;
  static const _passwordLength = 8;
  static const _totalLength = _emailLength + _passwordLength; // 20 chars total

  final String email;
  final String password;

  RecoveryToken._(this.email, this.password);

  factory RecoveryToken.generate() {
    final random = Random.secure();

    final emailPart =
        List.generate(
          _emailLength,
          (index) => _chars[random.nextInt(_chars.length)],
        ).join();

    final passwordPart =
        List.generate(
          _passwordLength,
          (index) => _chars[random.nextInt(_chars.length)],
        ).join();

    return RecoveryToken._('$emailPart$_domain', passwordPart);
  }

  factory RecoveryToken.fromString(String token) {
    if (token.length != _totalLength) {
      throw FormatException('Invalid token length');
    }

    final emailPart = token.substring(0, _emailLength);
    final passwordPart = token.substring(_emailLength);

    if (!RegExp('^[a-z0-9]+\$').hasMatch(token)) {
      throw FormatException('Invalid token format');
    }

    return RecoveryToken._('$emailPart$_domain', passwordPart);
  }

  String get token => email.replaceAll(_domain, '') + password;

  @override
  String toString() => token;
}
