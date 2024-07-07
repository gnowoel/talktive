import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../helpers/helpers.dart';

class Fireauth {
  final FirebaseAuth instance = FirebaseAuth.instance;

  Future<User> signInAnonymously() async {
    final currentUser = instance.currentUser;

    if (currentUser != null) {
      return currentUser;
    }

    try {
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
    } on FirebaseAuthException catch (e) {
      // TODO: logout unless there's a network error
      // await instance.signOut();
      throw Exception(e.code);
    }
  }
}
