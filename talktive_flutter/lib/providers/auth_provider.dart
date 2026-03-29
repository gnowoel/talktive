import 'dart:async';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import '../serverpod_client.dart';
import '../config/auth_config.dart';

part 'auth_provider.g.dart';

enum AuthStatus { authenticated, needsProfile, cancelled, error }

sealed class TalktiveAuthState {
  const TalktiveAuthState();
}

class AuthInitial extends TalktiveAuthState {
  const AuthInitial();
}

class Authenticated extends TalktiveAuthState {
  final String userId;
  final String userName;
  const Authenticated({required this.userId, required this.userName});
}

class NeedsProfile extends TalktiveAuthState {
  const NeedsProfile();
}

class Unauthenticated extends TalktiveAuthState {
  const Unauthenticated();
}

class AuthFailure extends TalktiveAuthState {
  final String message;
  const AuthFailure(this.message);
}

@Riverpod(keepAlive: true)
class Auth extends _$Auth {
  @override
    FutureOr<TalktiveAuthState> build() async {
    // 1. Initialize Google Sign-In with configuration
    await GoogleSignIn.instance.initialize(
      clientId: kIsWeb ? AuthConfig.webClientId : null,
    );

    // 2. Listen for Google Sign-In changes
    GoogleSignIn.instance.authenticationEvents.listen((event) {
      if (event is GoogleSignInAuthenticationEventSignIn && (state.value is Unauthenticated || state.value is AuthInitial)) {
        debugPrint('Auth: Google user signed in - initiating auto-exchange for Serverpod...');
        loginWithGoogle();
      }
    });

    // 3. Existing session check
    if (!sessionManager.isAuthenticated) {
      // Check if user is already logged in with Firebase but not Serverpod.
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        try {
          final idToken = await firebaseUser.getIdToken();
          if (idToken != null) {
            debugPrint('Auth: Found active Firebase user, attempting Serverpod login...');
            final authResponse = await client.firebaseIdp.login(idToken: idToken);
            // If we're here, it succeeded (otherwise it would throw)
            await sessionManager.updateSignedInUser(authResponse);
            return await _refreshAuthState();
          }
        } catch (e) {
          debugPrint('Auth: Auto-login failed: $e');
        }
      }
      return const Unauthenticated();
    }

    return _refreshAuthState();
  }

  Future<TalktiveAuthState> _refreshAuthState() async {
    try {
      if (!sessionManager.isAuthenticated) {
        return const Unauthenticated();
      }
      final resident = await client.resident.getResident();

      if (resident != null) {
        final prefs = await SharedPreferences.getInstance();
        final cachedName = prefs.getString('user_name');
        final userName = (cachedName != null && cachedName.isNotEmpty)
            ? cachedName
            : (FirebaseAuth.instance.currentUser?.displayName ?? 'Anonymous');
        await prefs.setBool('onboarding_completed', true);
        await prefs.setString('user_name', userName);
        await prefs.setString('user_id', resident.userInfoId.toString());

        return Authenticated(
          userId: resident.userInfoId.toString(),
          userName: userName,
        );
      } else {
        return const NeedsProfile();
      }
    } catch (e) {
      return AuthFailure(e.toString());
    }
  }

  /// Initiates Google Sign-In flow via Firebase
  Future<AuthStatus> loginWithGoogle() async {
    state = const AsyncValue.loading();

    try {
      // 1. Sign in with Google (Client Side)
      debugPrint('Auth: Triggering Google Sign-In...');
      
      GoogleSignInAccount? googleUser;
      
      if (kIsWeb) {
        // On Web, the user signs in via our button which triggers GIS.
        // We try to pick up the already signed in user here.
        googleUser = await GoogleSignIn.instance.attemptLightweightAuthentication();
        if (googleUser == null) {
          debugPrint('Auth: Web lightweight auth failed or returned null.');
          return AuthStatus.cancelled;
        }
      } else {
        googleUser = await GoogleSignIn.instance.authenticate();
      }

      if (googleUser == null) {
        debugPrint('Auth: Google user is null (cancelled or blocked)');
        return AuthStatus.cancelled;
      }

      // 2. Get Google Credentials
      debugPrint('Auth: Getting Google auth tokens for ${googleUser.email}...');
      // In 7.2.0, authentication is a getter, not a future.
      final googleAuth = googleUser.authentication;
      final idTokenFromGoogle = googleAuth.idToken;

      if (idTokenFromGoogle == null) {
        debugPrint('Auth: Error - Google idToken is null!');
        return AuthStatus.error;
      }

      final credential = GoogleAuthProvider.credential(
        idToken: idTokenFromGoogle,
      );

      // 3. Link or Sign in to Firebase
      final currentUser = FirebaseAuth.instance.currentUser;
      UserCredential userCredential;

      if (currentUser != null &&
          (currentUser.isAnonymous ||
              currentUser.providerData.every(
                (info) => info.providerId != 'google.com',
              ))) {
        try {
          userCredential = await currentUser.linkWithCredential(credential);
        } on FirebaseAuthException catch (e) {
          if (e.code == 'provider-already-linked') {
            userCredential = await FirebaseAuth.instance.signInWithCredential(
              credential,
            );
          } else if (e.code == 'credential-already-in-use') {
            throw Exception(
              "This Google account is already linked to another Talktive account.",
            );
          } else {
            rethrow;
          }
        }
      } else {
        userCredential = await FirebaseAuth.instance.signInWithCredential(
          credential,
        );
      }
      final user = userCredential.user;

      if (user == null) {
        throw Exception("Firebase Sign-In failed: User is null");
      }

      // 4. Get Firebase ID Token
      debugPrint('Auth: Firebase Sign-In success. Getting idToken...');
      final idToken = await userCredential.user!.getIdToken();
      debugPrint('Auth: idToken length: ${idToken?.length}');

      if (idToken == null) {
        throw Exception("Firebase ID Token is null");
      }

      // 5. Authenticate with Serverpod
      debugPrint('Auth: Calling firebaseIdp.login with Serverpod...');
      final authSuccess = await client.firebaseIdp.login(idToken: idToken);
      debugPrint('Auth: Serverpod login SUCCEEDED.');
      debugPrint('Auth: Serverpod token (first 10 chars): ${authSuccess.token.substring(0, authSuccess.token.length > 10 ? 10 : authSuccess.token.length)}');

      await sessionManager.updateSignedInUser(authSuccess);

      // 6. Refresh Auth State
      final newState = await _refreshAuthState();
      state = AsyncValue.data(newState);

      if (newState is Authenticated) {
        return AuthStatus.authenticated;
      } else if (newState is NeedsProfile) {
        return AuthStatus.needsProfile;
      } else {
        return AuthStatus.error;
      }
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        state = const AsyncValue.data(Unauthenticated());
        return AuthStatus.cancelled;
      }
      state = AsyncValue.error(e, StackTrace.current);
      return AuthStatus.error;
    } catch (e) {
      debugPrint("Sign in failed: $e");
      state = AsyncValue.error(e, StackTrace.current);
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
    List<String> languages = const ['en'],
    String mood = '😊',
    String? ageRange,
    String? customAvatarUrl,
  }) async {
    state = const AsyncValue.loading();

    try {
      final resident = await client.resident.initializeResident(
        name: name,
        avatar: avatar,
        gender: gender,
        country: country,
        bio: bio,
        mood: mood,
        ageRange: ageRange,
        interests: interests,
        languages: languages,
        customAvatarUrl: customAvatarUrl,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_completed', true);
      await prefs.setString('user_name', name);
      await prefs.setString('user_id', resident.userInfoId.toString());

      state = AsyncValue.data(
        Authenticated(userId: resident.userInfoId.toString(), userName: name),
      );
      return true;
    } catch (e) {
      debugPrint('Setup error: $e');
      state = AsyncValue.data(AuthFailure(e.toString()));
      return false;
    }
  }

  /// Updates the user's existing profile
  Future<bool> updateProfile({
    required String name,
    required String avatar,
    required String gender,
    required String country,
    required String bio,
    List<String> interests = const [],
    List<String> languages = const ['en'],
    String mood = '😊',
    String? ageRange,
    String? customAvatarUrl,
  }) async {
    try {
      final resident = await client.resident.updateResident(
        name: name,
        avatar: avatar,
        gender: gender,
        country: country,
        bio: bio,
        mood: mood,
        ageRange: ageRange,
        interests: interests,
        languages: languages,
        customAvatarUrl: customAvatarUrl,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_name', name);
      await prefs.setString('user_id', resident.userInfoId.toString());

      state = AsyncValue.data(
        Authenticated(userId: resident.userInfoId.toString(), userName: name),
      );
      return true;
    } catch (e) {
      debugPrint('Update profile error: $e');
      return false;
    }
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    try {
      await sessionManager.signOutDevice();
      await FirebaseAuth.instance.signOut();
      await GoogleSignIn.instance.signOut();
    } catch (e) {
      debugPrint("SignOut error: $e");
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_name');
    await prefs.remove('user_id');
    await prefs.remove('onboarding_completed');
    state = const AsyncValue.data(Unauthenticated());
  }
}
