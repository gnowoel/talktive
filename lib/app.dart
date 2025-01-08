import 'package:flutter/material.dart';

import 'router.dart';
import 'theme.dart';
import 'wrappers/providers.dart';
import 'wrappers/auth.dart';
import 'wrappers/subscribe.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return Providers(
      child: Auth(
        child: Subscribe(
          child: MaterialApp.router(
            routerConfig: router,
            debugShowCheckedModeBanner: false,
            title: 'Talktive',
            theme: getTheme(context),
          ),
        ),
      ),
    );
  }
}
