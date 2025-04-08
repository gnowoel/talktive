import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'router.dart';
import 'theme.dart';
import 'wrappers/verify_user.dart';
import 'wrappers/current_user.dart';
import 'wrappers/initialize.dart';
import 'wrappers/providers.dart';
import 'wrappers/setup.dart';
import 'wrappers/subscribe.dart';
import 'wrappers/whats_new.dart';

const useEmulators = true;

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return Initialize(
      useEmulators: useEmulators,
      child: Providers(
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
