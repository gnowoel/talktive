import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'config/theme.dart';
import 'wrappers/serverpod_initialize.dart';
import 'widgets/duo/duo_notification_toast.dart';
import 'providers/router_provider.dart';
import 'providers/fcm_provider.dart';

class ServerpodApp extends StatelessWidget {
  const ServerpodApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProviderScope(child: _ServerpodAppContent());
  }
}

class _ServerpodAppContent extends ConsumerWidget {
  const _ServerpodAppContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    // Keep FCMManager alive to handle background/foreground messages
    ref.watch(fCMManagerProvider);

    return ServerpodInitialize(
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
