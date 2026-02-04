import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/avatar.dart';
import '../services/fireauth.dart';
import '../services/firedata.dart';
import '../services/firestore.dart';
import '../services/messaging.dart';
import '../services/service_locator.dart';
import '../services/storage.dart';
import '../services/version_service.dart';

class Providers extends StatelessWidget {
  final Widget child;
  final VoidCallback? onExit;

  const Providers({super.key, required this.child, this.onExit});

  @override
  Widget build(BuildContext context) {
    // Create Firebase service instances
    final fireauth = Fireauth(Fireauth.firebaseAuth);
    final firedata = Firedata(Firedata.firebaseDatabase);

    return MultiProvider(
      providers: [
        // Use ServiceLocator to create optimized providers
        ...ServiceLocator.createProviders(
          fireauth: fireauth,
          firedata: firedata,
        ),

        // Additional services not managed by ServiceLocator
        Provider(create: (context) => Storage()),
        Provider(create: (context) => Messaging()),
        Provider(create: (context) => VersionService(onExit: onExit)),
        ChangeNotifierProvider(create: (context) => Avatar()),
      ],
      child: child,
    );
  }
}
