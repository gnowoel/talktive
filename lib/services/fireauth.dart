import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/foundation.dart';

import '../helpers/helpers.dart';

class Fireauth {
  final FirebaseAuth instance;

  Fireauth(this.instance);

  static final firebaseAuth = FirebaseAuth.instance;

  bool get hasSignedIn => instance.currentUser != null;

  Future<User> signInAnonymously() async {
    final currentUser = instance.currentUser;

    try {
      if (currentUser != null) {
        // Touch the server to check connection, would raise "internal-error" if failed
        await currentUser.reload();
        return currentUser;
      } else {
        // if (kDebugMode) {
        //   final userCredential = await instance.createUserWithEmailAndPassword(
        //     email: generateEmail(),
        //     password: generatePassword(),
        //   );
        //   return userCredential.user!;
        // } else {
        final userCredential = await instance.signInAnonymously();
        return userCredential.user!;
        // }
      }
    } on FirebaseAuthException catch (e) {
      // if (e.code == 'internal-error' || e.code == 'user-not-found') {
      if (e.code != 'network-request-failed') {
        await instance.signOut();
      }
      throw AppException(e.code);
    } catch (e) {
      throw AppException(e.toString());
    }
  }

  Future<void> convertAnonymousAccount(String email, String password) async {
    try {
      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );

      await instance.currentUser?.linkWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw AppException(e.code);
    } catch (e) {
      throw AppException(e.toString());
    }
  }

  Future<User> signInWithEmail(String email, String password) async {
    try {
      final userCredential = await instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user!;
    } on FirebaseAuthException catch (e) {
      throw AppException(e.code);
    } catch (e) {
      throw AppException(e.toString());
    }
  }

  Future<RecoveryToken> createRecoveryToken() async {
    try {
      final token = RecoveryToken.generate();

      final credential = EmailAuthProvider.credential(
        email: token.email,
        password: token.password,
      );

      await instance.currentUser?.linkWithCredential(credential);
      return token;
    } on FirebaseAuthException catch (e) {
      throw AppException(e.code);
    } catch (e) {
      throw AppException(e.toString());
    }
  }

  Future<User> signInWithToken(String token) async {
    try {
      final recoveryToken = RecoveryToken.fromString(token);

      final userCredential = await instance.signInWithEmailAndPassword(
        email: recoveryToken.email,
        password: recoveryToken.password,
      );
      return userCredential.user!;
    } on FirebaseAuthException catch (e) {
      throw AppException(e.code);
    } catch (e) {
      throw AppException(e.toString());
    }
  }
}
