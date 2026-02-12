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

class ServerpodApp extends StatelessWidget {
  final VoidCallback onExit;

  const ServerpodApp({super.key, required this.onExit});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp.router(
        title: 'Talktive (Serverpod)',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        routerConfig: _buildRouter(onExit),
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
          builder: (context, state) => const ProfileSetupScreen(),
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
          builder: (context, state) {
            final tab = state.uri.queryParameters['tab'];
            final tabIndex = tab == 'groups' ? 1 : 0;
            return HomeScreen(initialIndex: 2, initialTabIndex: tabIndex);
          },
        ),
        GoRoute(
          path: '/groups',
          builder: (context, state) =>
              const HomeScreen(initialIndex: 2, initialTabIndex: 1),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const HomeScreen(initialIndex: 3),
        ),
        GoRoute(
          path: '/achievements',
          builder: (context, state) => const AchievementsScreen(),
        ),
        GoRoute(
          path: '/chat/:channelId',
          builder: (context, state) {
            final channelId =
                int.tryParse(state.pathParameters['channelId'] ?? '') ?? 0;
            // Get title from extra or query param, or default
            // Get title from extra or query param, or default
            // final title = state.extra as String? ?? 'Chat $channelId'; // Title not needed for loader
            return ChatLoaderScreen(channelId: channelId);
          },
        ),
      ],
    );
  }
}
