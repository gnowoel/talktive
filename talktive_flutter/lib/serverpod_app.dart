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
import 'widgets/duo/duo_notification_toast.dart';
import 'providers/router_provider.dart';

class ServerpodApp extends StatelessWidget {
  final VoidCallback onExit;

  const ServerpodApp({super.key, required this.onExit});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: _ServerpodAppContent(onExit: onExit),
    );
  }
}

class _ServerpodAppContent extends ConsumerWidget {
  final VoidCallback onExit;
  const _ServerpodAppContent({required this.onExit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return Initialize(
      useEmulators: true,
      child: MaterialApp.router(
        title: 'Talktive (Serverpod)',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        routerConfig: router,
        builder: (context, child) {
          return Stack(
            children: [
              if (child != null) child,
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: DuoNotificationToast(),
              ),
            ],
          );
        },
      ),
    );
  }
}
