import 'dart:async';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:serverpod_auth_google_flutter/serverpod_auth_google_flutter.dart'
    as google_auth;
import 'package:serverpod_auth_shared_flutter/serverpod_auth_shared_flutter.dart';
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

  /// Initiates Google Sign-In flow
  Future<AuthStatus> loginWithGoogle() async {
    state = const AsyncValue.loading();

    try {
      // 1. Sign in with Google (Serverpod Auth)
      // This triggers the native Google Sign-In sheet
      final userInfo = await google_auth.signInWithGoogle(
        client.modules.auth,
        redirectUri: Uri.parse('http://localhost:8082/googlesignin'),
      );

      if (userInfo == null) {
        // User cancelled or failed
        state = const AsyncValue.data(false);
        return AuthStatus.cancelled;
      }

      // 2. Check if Resident Profile exists
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
      // If we are already signed in, we might get an error or immediate success?
      // For now, treat as error.
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
    // await sessionManager.signOut(); // TODO: Verify signOut method name/availability in this version
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    state = const AsyncValue.data(false);
  }
}
