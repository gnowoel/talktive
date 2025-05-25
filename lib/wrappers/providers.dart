import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/avatar.dart';
import '../services/chat_cache.dart';
import '../services/fireauth.dart';
import '../services/firedata.dart';
import '../services/firestore.dart';
import '../services/follow_cache.dart';
import '../services/message_cache.dart';
import '../services/messaging.dart';
import '../services/server_clock.dart';
import '../services/settings.dart';
import '../services/storage.dart';
import '../services/topic_cache.dart';
import '../services/topic_message_cache.dart';
import '../services/tribe_cache.dart';
import '../services/user_cache.dart';

class Providers extends StatelessWidget {
  final Widget child;

  const Providers({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(create: (context) => Fireauth(Fireauth.firebaseAuth)),
        Provider(create: (context) => Firedata(Firedata.firebaseDatabase)),
        Provider(
          create: (context) => Firestore(Firestore.firebaseFirestore),
          dispose: (context, firestore) => firestore.dispose(),
        ),
        Provider(create: (context) => Storage()),
        Provider(create: (context) => Messaging()),
        Provider(create: (context) => Settings()),
        Provider(create: (context) => ServerClock()),
        ChangeNotifierProvider(create: (context) => Avatar()),
        ChangeNotifierProvider(create: (context) => UserCache()),
        ChangeNotifierProvider(create: (context) => FollowCache()),
        ChangeNotifierProvider(create: (context) => ChatCache()),
        ChangeNotifierProvider(create: (context) => ChatMessageCache()),
        ChangeNotifierProvider(create: (context) => ReportMessageCache()),
        ChangeNotifierProvider(create: (context) => TopicCache()),
        ChangeNotifierProvider(create: (context) => TopicMessageCache()),
        ChangeNotifierProvider(
          create: (context) => TribeCache(context.read<Firestore>()),
        ),
      ],
      child: child,
    );
  }
}
