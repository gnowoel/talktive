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
      final keyId = map['keyId'] as int;
      final key = map['key'] as String;
      final userInfoId = map['userInfoId'] as int;
      final userInfoName = map['userInfoName'] as String?;
      final userInfoEmail = map['userInfoEmail'] as String?;
      final createdStr = map['created'] as String?;
      final created = createdStr != null
          ? DateTime.parse(createdStr)
          : DateTime.now();

      final userInfo = UserInfo(
        id: userInfoId,
        userIdentifier: userInfoEmail ?? '',
        userName: userInfoName ?? '',
        created: created,
        scopeNames: [],
        blocked: false,
      );

      final authSuccess = AuthSuccess(
        authStrategy: 'session',
        token: '$keyId:$key',
        authUserId: UuidValue(const Uuid().v4()),
        scopeNames: {},
      );

      // Register the session
      await sessionManager.updateSignedInUser(
        authSuccess,
      ); // Save local preferences (custom app logic)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_completed', true);
      await prefs.setString('user_name', name);
      await prefs.setInt('user_id', userInfoId);

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
