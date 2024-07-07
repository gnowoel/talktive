import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../helpers/helpers.dart';

class Fireauth {
  final FirebaseAuth instance = FirebaseAuth.instance;

  Future<UserCredential> signInAnonymously() async {
    try {
      if (kDebugMode) {
        final userCredential = await instance.createUserWithEmailAndPassword(
          email: generateEmail(),
          password: generatePassword(),
        );
        return userCredential;
      } else {
        final userCredential = await instance.signInAnonymously();
        return userCredential;
      }
    } on FirebaseAuthException catch (e) {
      throw Exception(e.code);
    }
  }
}
