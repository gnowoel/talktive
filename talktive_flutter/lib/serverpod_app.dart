import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'config/theme.dart';
import 'wrappers/serverpod_initialize.dart';
import 'widgets/duo/duo_notification_toast.dart';
import 'providers/router_provider.dart';
import 'providers/fcm_provider.dart';
import 'widgets/prewarmer.dart';
import 'services/ad/ad_service.dart';

class ServerpodApp extends StatelessWidget {
  const ServerpodApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProviderScope(child: _ServerpodAppContent());
  }
}

class _ServerpodAppContent extends ConsumerStatefulWidget {
  const _ServerpodAppContent();

  @override
  ConsumerState<_ServerpodAppContent> createState() => _ServerpodAppContentState();
}

class _ServerpodAppContentState extends ConsumerState<_ServerpodAppContent> {
  @override
  void initState() {
    super.initState();
    // Initialize AdService for the Serverpod version
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adServiceProvider).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
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
              if (child != null) TalktivePrewarmer(child: child),
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
