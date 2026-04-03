import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod/src/framework.dart' show Override;
import 'package:talktive/providers/auth_provider.dart';
import 'package:talktive/providers/fcm_provider.dart';
import 'package:talktive/screens/onboarding/welcome_screen.dart';
import 'package:talktive/screens/splash_screen.dart';

class TestAuthNotifier extends Auth {
  TestAuthNotifier({
    required this.initialState,
    this.loginResult = AuthStatus.cancelled,
    this.postLoginState,
  });

  final TalktiveAuthState initialState;
  final AuthStatus loginResult;
  final TalktiveAuthState? postLoginState;

  @override
  FutureOr<TalktiveAuthState> build() => initialState;

  @override
  Future<AuthStatus> loginWithGoogle() async {
    if (postLoginState != null) {
      state = AsyncValue.data(postLoginState!);
    }
    return loginResult;
  }

  void setAuthState(TalktiveAuthState nextState) {
    state = AsyncValue.data(nextState);
  }
}

class TestFCMNotifier extends FCMManager {
  @override
  FutureOr<String?> build() => null;

  @override
  Future<String?> initialize() async => null;
}

Widget buildTestApp({
  required List<Override> overrides,
  required String initialLocation,
}) {
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const Scaffold(body: Text('home')),
      ),
      GoRoute(
        path: '/profile-setup',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final migrationData =
              extra?['migrationData'] as Map<String, dynamic>?;
          final name = migrationData?['name'] as String?;
          return Scaffold(body: Text('profile-setup:${name ?? 'none'}'));
        },
      ),
    ],
  );

  return ProviderScope(
    overrides: overrides,
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  group('auth routing', () {
    testWidgets('Splash routes authenticated users to home', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          initialLocation: '/splash',
          overrides: [
            authProvider.overrideWith(
              () => TestAuthNotifier(
                initialState: const Authenticated(
                  userId: 'user-1',
                  userName: 'Test User',
                ),
              ),
            ),
            fCMManagerProvider.overrideWith(() => TestFCMNotifier()),
          ],
        ),
      );

      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      expect(find.text('home'), findsOneWidget);
    });

    testWidgets('Splash routes needs-profile users to profile setup', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(
          initialLocation: '/splash',
          overrides: [
            authProvider.overrideWith(
              () => TestAuthNotifier(
                initialState: const NeedsProfile(
                  migrationData: {'name': 'Legacy User'},
                ),
              ),
            ),
            fCMManagerProvider.overrideWith(() => TestFCMNotifier()),
          ],
        ),
      );

      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      expect(find.text('profile-setup:Legacy User'), findsOneWidget);
    });

    testWidgets('Welcome routes needs-profile state to profile setup', (
      tester,
    ) async {
      final auth = TestAuthNotifier(initialState: const Unauthenticated());

      await tester.pumpWidget(
        buildTestApp(
          initialLocation: '/welcome',
          overrides: [authProvider.overrideWith(() => auth)],
        ),
      );

      auth.setAuthState(
        const NeedsProfile(migrationData: {'name': 'Migrated User'}),
      );
      await tester.pumpAndSettle();

      expect(find.text('profile-setup:Migrated User'), findsOneWidget);
    });
  });
}
