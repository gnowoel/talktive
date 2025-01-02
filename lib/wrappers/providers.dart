import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/avatar.dart';
import '../services/cache.dart';
import '../services/fireauth.dart';
import '../services/firedata.dart';
import '../services/messaging.dart';
import '../services/storage.dart';

class Providers extends StatelessWidget {
  final Widget child;

  const Providers({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final auth = FirebaseAuth.instance;
    final database = FirebaseDatabase.instance;
    final storage = FirebaseStorage.instance;
    final messaging = FirebaseMessaging.instance;

    return MultiProvider(
      providers: [
        Provider(create: (context) => Fireauth(auth)),
        Provider(create: (context) => Firedata(database)),
        Provider(create: (context) => Storage(storage)),
        Provider(create: (context) => Messaging(messaging)),
        ChangeNotifierProvider(create: (context) => Avatar()),
        ChangeNotifierProvider(create: (context) => Cache()),
      ],
      child: child,
    );
  }
}
