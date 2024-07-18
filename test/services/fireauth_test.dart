import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talktive/services/fireauth.dart';

import '../mock.dart';

void main() {
  setupMocks();

  final user = MockUser(isAnonymous: true);
  final auth = MockFirebaseAuth(mockUser: user);
  final fireauth = Fireauth(instance: auth);

  group('Fireauth', () {
    test('can sign in anonymously', () async {
      expect(fireauth.instance.currentUser, isNull);
      await fireauth.signInAnonymously();
      expect(fireauth.instance.currentUser, isNotNull);
    });
  });
}
