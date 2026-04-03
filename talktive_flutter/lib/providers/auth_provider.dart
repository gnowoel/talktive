import 'dart:async' show StreamSubscription, unawaited;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import '../serverpod_client.dart';

part 'auth_provider.g.dart';

enum AuthStatus { authenticated, needsProfile, migrating, cancelled, error }

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
  final Map<String, dynamic>? migrationData;
  const NeedsProfile({this.migrationData});
}

class Migrating extends TalktiveAuthState {
  const Migrating();
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
  Future<AuthStatus>? _ongoingLogin;
  StreamSubscription<GoogleSignInAuthenticationEvent>? _webAuthSubscription;

  @override
  FutureOr<TalktiveAuthState> build() async {
    if (kIsWeb && _webAuthSubscription == null) {
      _webAuthSubscription = GoogleSignIn.instance.authenticationEvents.listen((
        event,
      ) {
        if (event is GoogleSignInAuthenticationEventSignIn) {
          unawaited(_completeWebGoogleSignIn(event.user));
        }
      });
      ref.onDispose(() {
        _webAuthSubscription?.cancel();
        _webAuthSubscription = null;
      });
    }

    // Existing session check
    if (!sessionManager.isAuthenticated) {
      // Check if user is already logged in with Firebase but not Serverpod.
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        try {
          final idToken = await firebaseUser.getIdToken();
          if (idToken != null) {
            debugPrint(
              'Auth: Found active Firebase user, attempting Serverpod login...',
            );
            final authResponse = await client.firebaseIdp.login(
              idToken: idToken,
            );
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
        // If we need profile, check for legacy data to migrate
        final migrationData = await _loadLegacyMigrationData();
        if (migrationData != null) {
          return NeedsProfile(migrationData: migrationData);
        }
        return const NeedsProfile();
      }
    } catch (e) {
      return AuthFailure(e.toString());
    }
  }

  /// Initiates Google Sign-In flow via Firebase
  Future<AuthStatus> loginWithGoogle() async {
    if (_ongoingLogin != null) {
      return _ongoingLogin!;
    }

    _ongoingLogin = _loginWithGoogleInternal();
    try {
      return await _ongoingLogin!;
    } finally {
      _ongoingLogin = null;
    }
  }

  Future<AuthStatus> _loginWithGoogleInternal() async {
    state = const AsyncValue.loading();

    try {
      // 1. Sign in with Google / Firebase (client side)
      debugPrint('Auth: Triggering Google Sign-In...');

      if (kIsWeb) {
        // Web interactive auth is driven by the GIS-rendered button.
        // We finish the Firebase + Serverpod exchange from authenticationEvents.
        return AuthStatus.cancelled;
      }

      final googleUser = await GoogleSignIn.instance.authenticate();
      return await _exchangeGoogleUserForSession(googleUser);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        state = const AsyncValue.data(Unauthenticated());
        return AuthStatus.cancelled;
      }
      state = AsyncValue.error(e, StackTrace.current);
      return AuthStatus.error;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'popup-closed-by-user' ||
          e.code == 'cancelled-popup-request') {
        state = const AsyncValue.data(Unauthenticated());
        return AuthStatus.cancelled;
      }
      debugPrint('Auth: Firebase auth failed: $e');
      state = AsyncValue.error(e, StackTrace.current);
      return AuthStatus.error;
    } catch (e) {
      debugPrint('Sign in failed: $e');
      state = AsyncValue.error(e, StackTrace.current);
      return AuthStatus.error;
    }
  }

  Future<void> _completeWebGoogleSignIn(GoogleSignInAccount googleUser) async {
    if (_ongoingLogin != null) {
      return;
    }

    _ongoingLogin = _exchangeGoogleUserForSession(googleUser);
    try {
      await _ongoingLogin;
    } finally {
      _ongoingLogin = null;
    }
  }

  Future<AuthStatus> _exchangeGoogleUserForSession(
    GoogleSignInAccount googleUser,
  ) async {
    debugPrint('Auth: Getting Google auth tokens for ${googleUser.email}...');
    final googleAuth = googleUser.authentication;
    final idTokenFromGoogle = googleAuth.idToken;

    if (idTokenFromGoogle == null) {
      debugPrint('Auth: Error - Google idToken is null!');
      state = const AsyncValue.data(Unauthenticated());
      return AuthStatus.error;
    }

    final credential = GoogleAuthProvider.credential(
      idToken: idTokenFromGoogle,
    );

    // Link or sign in to Firebase.
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
          debugPrint(
            'Auth: Google account already in use, signing in to existing account...',
          );
          userCredential = await FirebaseAuth.instance.signInWithCredential(
            credential,
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
      throw Exception('Firebase sign-in failed: User is null');
    }

    debugPrint('Auth: Firebase sign-in success. Getting idToken...');
    final idToken = await user.getIdToken();
    debugPrint('Auth: idToken length: ${idToken?.length}');

    if (idToken == null) {
      throw Exception('Firebase ID token is null');
    }

    debugPrint('Auth: Calling firebaseIdp.login with Serverpod...');
    final authSuccess = await client.firebaseIdp.login(idToken: idToken);
    debugPrint('Auth: Serverpod login SUCCEEDED.');
    debugPrint(
      'Auth: Serverpod token (first 10 chars): ${authSuccess.token.substring(0, authSuccess.token.length > 10 ? 10 : authSuccess.token.length)}',
    );

    await sessionManager.updateSignedInUser(authSuccess);

    final newState = await _refreshAuthState();
    state = AsyncValue.data(newState);

    if (newState is Authenticated) {
      return AuthStatus.authenticated;
    } else if (newState is NeedsProfile) {
      return newState.migrationData != null
          ? AuthStatus.migrating
          : AuthStatus.needsProfile;
    } else {
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

  Future<Map<String, dynamic>?> _loadLegacyMigrationData() async {
    try {
      final migration = await client.resident.getLegacyMigrationData();
      if (migration == null) {
        debugPrint('Auth: No legacy user data found.');
        return null;
      }

      return {
        if (migration.name != null) 'name': migration.name,
        if (migration.bio != null) 'bio': migration.bio,
        if (migration.avatar != null) 'avatar': migration.avatar,
        if (migration.gender != null) 'gender': migration.gender,
        if (migration.languages != null) 'languages': migration.languages,
      };
    } catch (e) {
      debugPrint('Auth: Migration failed: $e');
      return null;
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
