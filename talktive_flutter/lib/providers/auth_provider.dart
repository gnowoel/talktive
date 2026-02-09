import 'dart:async';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:serverpod_auth_firebase_flutter/serverpod_auth_firebase_flutter.dart';
import '../serverpod_client.dart';

part 'auth_provider.g.dart';

enum AuthStatus { authenticated, needsProfile, cancelled, error }

@Riverpod(keepAlive: true)
class Auth extends _$Auth {
  @override
  FutureOr<bool> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('onboarding_completed') ?? false;
  }

  /// Initiates Google Sign-In flow via Firebase
  Future<AuthStatus> loginWithGoogle() async {
    state = const AsyncValue.loading();

    try {
      // 1. Sign in with Google (Client Side)
      final googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) {
        // User cancelled
        state = const AsyncValue.data(false);
        return AuthStatus.cancelled;
      }

      // 2. Get Google Credentials
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 3. Sign in to Firebase
      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );
      final user = userCredential.user;

      if (user == null) {
        throw Exception("Firebase Sign-In failed: User is null");
      }

      // 4. Get Firebase ID Token
      final idToken = await user.getIdToken();

      // 5. Authenticate with Serverpod
      // This verifies the Firebase token on the server and creates a Serverpod session
      final serverpodAuth = await client.modules.auth.firebase.authenticate(
        idToken!,
      );

      if (!serverpodAuth.success) {
        throw Exception(
          "Serverpod Authentication failed: ${serverpodAuth.failReason}",
        );
      }

      // 6. Check if Resident Profile exists
      final resident = await client.resident.getResident();

      if (resident != null) {
        // Profile exists, we are good to go!
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('onboarding_completed', true);
        await prefs.setString('user_name', resident.avatar ?? 'Anonymous');
        await prefs.setString('user_id', resident.userInfoId.toString());

        state = const AsyncValue.data(true);
        return AuthStatus.authenticated;
      } else {
        // Authenticated but no profile -> Go to Setup
        return AuthStatus.needsProfile;
      }
    } catch (e, st) {
      debugPrint('Google Sign-In error: $e');
      state = AsyncValue.error(e, st);
      return AuthStatus.error;
    }
  }

  /// Completes the profile setup for the authenticated user
  Future<bool> completeSetup({
    required String name,
    required String avatar,
    required String gender,
    required String country,
    required String bio,
    List<String> interests = const [],
    String mood = '😊',
  }) async {
    state = const AsyncValue.loading();

    try {
      final bioWithExtras =
          '$bio\nMood: $mood\nInterests: ${interests.join(", ")}';

      final resident = await client.resident.initializeResident(
        name: name,
        avatar: avatar,
        gender: gender,
        country: country,
        bio: bioWithExtras,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_completed', true);
      await prefs.setString('user_name', name);
      await prefs.setString('user_id', resident.userInfoId.toString());

      state = const AsyncValue.data(true);
      return true;
    } catch (e, st) {
      debugPrint('Setup error: $e');
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    try {
      // await sessionManager.signOut();
      await FirebaseAuth.instance.signOut();
      await GoogleSignIn().signOut();
    } catch (e) {
      debugPrint("SignOut error: $e");
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    state = const AsyncValue.data(false);
  }
}
