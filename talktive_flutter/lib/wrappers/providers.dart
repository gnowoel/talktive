import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/avatar.dart';
import '../services/messaging.dart';
import '../services/service_locator.dart';
import '../services/storage.dart';

class Providers extends StatelessWidget {
  final Widget child;

  const Providers({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Use ServiceLocator to create optimized providers
        ...ServiceLocator.createProviders(),

        // Additional services not managed by ServiceLocator
        Provider(create: (context) => Storage()),
        Provider(create: (context) => Messaging()),
        ChangeNotifierProvider(create: (context) => Avatar()),
      ],
      child: child,
    );
  }
}
