import 'package:firebase_auth/firebase_auth.dart';

import '../helpers/helpers.dart';

class Fireauth {
  final FirebaseAuth instance = FirebaseAuth.instance;

  Future<User> signInAnonymously() async {
    final currentUser = instance.currentUser;

    if (currentUser != null) {
      return currentUser;
    }

    try {
      // We can also use Firebase Anonymous Authentication
      // if (!kDebugMode) {
      //   final userCredential = await instance.signInAnonymously();
      //   return userCredential.user!;
      // }
      final userCredential = await instance.createUserWithEmailAndPassword(
        email: generateEmail(),
        password: generatePassword(),
      );
      return userCredential.user!;
    } on FirebaseAuthException catch (e) {
      // TODO: logout unless there's a network error
      // await instance.signOut();
      throw Exception(e.code);
    }
  }
}
