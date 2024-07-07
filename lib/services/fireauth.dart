import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../helpers/helpers.dart';

class Fireauth {
  final FirebaseAuth instance = FirebaseAuth.instance;

  Future<User> signInAnonymously() async {
    final currentUser = instance.currentUser;

    try {
      if (currentUser != null) {
        await currentUser.reload(); // Touch the server to check connection
        return currentUser;
      } else {
        debugPrint('currentUser == null');
        if (kDebugMode) {
          final userCredential = await instance.createUserWithEmailAndPassword(
            email: generateEmail(),
            password: generatePassword(),
          );
          debugPrint(userCredential.user!.toString());
          return userCredential.user!;
        } else {
          final userCredential = await instance.signInAnonymously();
          return userCredential.user!;
        }
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-token-expired') {
        await instance.signOut();
      }
      throw Exception(e.code);
    }
  }
}
