import 'package:flutter/material.dart';

import 'services/edge_to_edge_manager.dart';
import 'package:go_router/go_router.dart';

import 'router.dart';
import 'services/messaging.dart';
import 'services/service_locator.dart';
import 'theme.dart';
import 'widgets/edge_to_edge_wrapper.dart';
import 'wrappers/verify_user.dart';
import 'wrappers/current_user.dart';
import 'wrappers/initialize.dart';
import 'wrappers/providers.dart';
import 'wrappers/setup.dart';
import 'wrappers/subscribe.dart';
import 'wrappers/whats_new.dart';

const useEmulators = true;

class App extends StatefulWidget {
  final VoidCallback? onExit;

  const App({super.key, this.onExit});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ServiceLocator.instance.reset();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final messaging = Messaging();
      messaging.clearAllNotifications();

      // Update system UI overlay style when app is resumed
      EdgeToEdgeManager.instance.updateForContext(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Initialize(
      useEmulators: useEmulators,
      child: Providers(
        onExit: widget.onExit,
        child: VerifyUser(
          child: WhatsNew(
            child: Setup(
              child: Subscribe(
                child: CurrentUser(
                  child: FutureBuilder<GoRouter>(
                    future: initRouter(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return MaterialApp(
                          theme: getTheme(context),
                          home: Scaffold(body: const SizedBox.shrink()),
                        );
                      }
                      return MaterialApp.router(
                        routerConfig: snapshot.data,
                        debugShowCheckedModeBanner: false,
                        title: 'Talktive',
                        theme: getTheme(context),
                        builder: (context, child) {
                          // Update system UI overlay style when theme changes
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            EdgeToEdgeManager.instance.updateForContext(
                              context,
                            );
                          });

                          return EdgeToEdgeWrapper(
                            includeTop:
                                false, // Let individual screens handle top padding
                            includeBottom:
                                false, // Let individual screens handle bottom padding
                            child: child ?? const SizedBox.shrink(),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
