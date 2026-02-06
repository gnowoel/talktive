import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

    try {
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 2));

      // Save local profile data
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_completed', true);
      await prefs.setString('user_name', name);
      await prefs.setString('user_avatar', avatar);

      // TODO: Call actual backend endpoint when available
      // await client.user.create( ... );

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
