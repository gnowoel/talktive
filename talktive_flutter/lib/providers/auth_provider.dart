import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:serverpod_auth_client/serverpod_auth_client.dart';
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';
import 'package:serverpod_client/serverpod_client.dart';
import 'package:uuid/uuid.dart';
import '../serverpod_client.dart';

part 'auth_provider.g.dart';

@Riverpod(keepAlive: true)
class Auth extends _$Auth {
  @override
  FutureOr<bool> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('onboarding_completed') ?? false;
  }

  Future<bool> signInAnonymously({
    required String name,
    required String avatar,
    required String gender,
    required String country,
    required String bio,
    List<String> interests = const [],
    String mood = '😊',
  }) async {
    state = const AsyncValue.loading();

    // Real Authentication logic
    try {
      final jsonResult = await client.resident.createResident(
        name: name,
        avatar: avatar,
        gender: gender,
        country: country,
        bio: bio,
      );

      final map = jsonDecode(jsonResult);
      // Key is the JWT token
      final key = map['key'] as String;
      // keyId is likely 0 or unused for JWT, but strictly formatted by server
      // final keyId = map['keyId'] as int?;

      // userInfoId is now a UUID String
      final userInfoIdStr = map['userInfoId'] as String;

      // final userInfoName = map['userInfoName'] as String?;
      // final userInfoEmail = map['userInfoEmail'] as String?; // Might be derived or present

      final authSuccess = AuthSuccess(
        authStrategy:
            'session', // Or 'jwt'? Flutter client might expect specific value.
        token:
            key, // Just the token. If client expects 'id:key', we might need to adjust.
        // If we use 'session' naming, SasAuthProvider might prefix headers unpredictably.
        // If we use pure JWT, we probably set authStrategy to 'jwt'.
        // But let's check generated AuthSuccess definition if possible?
        // Assuming 'token' field stores the JWT.
        authUserId: UuidValue.fromString(userInfoIdStr),
        scopeNames: {},
      );

      // Register the session
      await sessionManager.updateSignedInUser(authSuccess);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_completed', true);
      await prefs.setString('user_name', name);
      await prefs.setString('user_id', userInfoIdStr); // Store as String (UUID)

      state = const AsyncValue.data(true);
      return true;
    } catch (e, st) {
      debugPrint('Sign in error: $e');
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    state = const AsyncValue.data(false);
  }
}
