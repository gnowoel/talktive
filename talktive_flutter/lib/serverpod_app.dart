import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:talktive_client/talktive_client.dart';
import 'config/theme.dart';

import 'screens/splash_screen.dart';
import 'screens/onboarding/welcome_screen.dart';
import 'screens/onboarding/profile_setup_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/chat/chat_screen.dart';

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
          path: '/chat/:channelId',
          builder: (context, state) {
            final channelId =
                int.tryParse(state.pathParameters['channelId'] ?? '') ?? 0;
            // Get title from extra or query param, or default
            final title = state.extra as String? ?? 'Chat $channelId';
            return ChatScreen(channelId: channelId, title: title);
          },
        ),
      ],
    );
  }
}
