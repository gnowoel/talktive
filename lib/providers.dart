import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'initializers/auth.dart';
import 'initializers/notifier.dart';
import 'initializers/streams.dart';
import 'services/avatar.dart';
import 'services/cache.dart';
import 'services/fireauth.dart';
import 'services/firedata.dart';
import 'services/messaging.dart';
import 'services/storage.dart';

class Providers extends StatelessWidget {
  const Providers({super.key});

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
      child: const Auth(
        child: Streams(
          child: Notifier(
            child: App(),
          ),
        ),
      ),
    );
  }
}
