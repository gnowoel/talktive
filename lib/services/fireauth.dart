import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/foundation.dart';

import '../helpers/helpers.dart';

class Fireauth {
  final FirebaseAuth instance;

  Fireauth(this.instance);

  static final firebaseAuth = FirebaseAuth.instance;

  bool get hasSignedIn => instance.currentUser != null;

  Future<User> reloadCurrentUser() async {
    final currentUser = instance.currentUser;

    if (currentUser == null) {
      throw AppException('Current user is not available');
    }

    try {
      // Touch the server to check connection
      await currentUser.reload();
      return currentUser;
    } on FirebaseAuthException catch (e) {
      // I got "internal-error" on iOS. Fixed it by selecting "Device > Erase
      // all content and settings" in the Simulator.
      //
      // I also got "invalid-user-token" for linked users. On iOS, it seems that
      // the user will be signed out automatically.
      //
      // Sometimes, I got "unknown" error on Andoid, when the underlying user
      // record has been deleted.
      //
      // See also:
      // https://pub.dev/documentation/firebase_auth/latest/firebase_auth/FirebaseAuth/signInWithEmailAndPassword.html
      if (e.code == 'user-not-found' ||
          e.code == 'invalid-user-token' ||
          e.code == 'internal-error' ||
          e.code == "unknown") {
        await instance.signOut();
      }
      throw AppException(e.code);
    } catch (e) {
      throw AppException(e.toString());
    }
  }

  Future<User> signInAnonymously() async {
    try {
      final userCredential = await instance.signInAnonymously();
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
      await instance.currentUser?.updateDisplayName(token.toString());
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
    } on FirebaseAuthException catch (_) {
      throw AppException('Oops, something went wrong. Please try again later.');
    } catch (e) {
      throw AppException(e.toString());
    }
  }

  String? getStoredToken() {
    return instance.currentUser?.displayName;
  }

  bool get hasBackup => !instance.currentUser!.isAnonymous;
}
