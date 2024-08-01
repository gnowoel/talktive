import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../helpers/helpers.dart';

class Fireauth {
  final FirebaseAuth instance;

  Fireauth(this.instance);

  Future<User> signInAnonymously() async {
    final currentUser = instance.currentUser;

    try {
      if (currentUser != null) {
        await currentUser.reload(); // Touch the server to check connection
        return currentUser;
      } else {
        if (kDebugMode) {
          final userCredential = await instance.createUserWithEmailAndPassword(
            email: generateEmail(),
            password: generatePassword(),
          );
          return userCredential.user!;
        } else {
          final userCredential = await instance.signInAnonymously();
          return userCredential.user!;
        }
      }
    } on FirebaseAuthException catch (e) {
      if (e.code != 'network-request-failed') {
        await instance.signOut();
      }
      throw Exception(e.code);
    }
  }
}
