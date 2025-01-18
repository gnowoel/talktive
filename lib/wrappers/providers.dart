import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/avatar.dart';
import '../services/cache.dart';
import '../services/fireauth.dart';
import '../services/firedata.dart';
import '../services/message_cache.dart';
import '../services/messaging.dart';
import '../services/settings.dart';
import '../services/storage.dart';

class Providers extends StatelessWidget {
  final Widget child;

  const Providers({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(create: (context) => Fireauth(Fireauth.firebaseAuth)),
        Provider(create: (context) => Firedata(Firedata.firebaseDatabase)),
        Provider(create: (context) => Storage()),
        Provider(create: (context) => Messaging()),
        Provider(create: (context) => Settings()),
        ChangeNotifierProvider(create: (context) => Avatar()),
        ChangeNotifierProvider(create: (context) => Cache()),
        ChangeNotifierProvider(create: (context) => MessageCache()),
      ],
      child: child,
    );
  }
}
