import 'package:firebase_auth/firebase_auth.dart';

class Fireauth {
  final FirebaseAuth instance = FirebaseAuth.instance;

  Future<UserCredential> signInAnonymously() async {
    try {
      final userCredential = await instance.signInAnonymously();
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.code);
    } catch (e) {
      throw Exception('$e');
    }
  }
}
