import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:talktive_client/talktive_client.dart';
import 'config/theme.dart';

import 'screens/splash_screen.dart';
import 'screens/onboarding/welcome_screen.dart';
import 'screens/onboarding/profile_setup_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/chats/chat_loader_screen.dart';
import 'screens/achievements/achievements_screen.dart';
import 'screens/profile/user_profile_view_screen.dart';
import 'wrappers/initialize.dart';

class ServerpodApp extends StatelessWidget {
  final VoidCallback onExit;

  const ServerpodApp({super.key, required this.onExit});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: Initialize(
        useEmulators: true,
        child: MaterialApp.router(
          title: 'Talktive (Serverpod)',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          routerConfig: _buildRouter(onExit),
        ),
      ),
    );
  }

  GoRouter _buildRouter(VoidCallback onExit) {
    return GoRouter(
      initialLocation: '/splash',
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
          path: '/profile-setup',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            final resident = extra?['resident'] as Resident?;
            final userName = extra?['userName'] as String?;
            return ProfileSetupScreen(
              initialResident: resident,
              initialName: userName,
            );
          },
        ),
        GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
        GoRoute(
          path: '/plaza',
          builder: (context, state) => const HomeScreen(initialIndex: 0),
        ),
        GoRoute(
          path: '/moments',
          builder: (context, state) => const HomeScreen(initialIndex: 1),
        ),
        GoRoute(
          path: '/chats',
          builder: (context, state) => const HomeScreen(initialIndex: 2),
          routes: [
            GoRoute(
              path: 'thread/:channelId',
              builder: (context, state) {
                final channelId =
                    int.tryParse(state.pathParameters['channelId'] ?? '') ?? 0;
                return ChatLoaderScreen(channelId: channelId);
              },
            ),
          ],
        ),
        GoRoute(
          path: '/groups',
          builder: (context, state) => const HomeScreen(initialIndex: 3),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const HomeScreen(initialIndex: 4),
        ),
        GoRoute(
          path: '/achievements',
          builder: (context, state) => const AchievementsScreen(),
        ),
        GoRoute(
          path: '/user/:userId',
          builder: (context, state) {
            final userId = state.pathParameters['userId']!;
            return UserProfileViewScreen(userId: userId);
          },
        ),

      ],
    );
  }
}
