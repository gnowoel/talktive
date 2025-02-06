import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/cache.dart';
import '../services/chat_cache.dart';
import '../services/fireauth.dart';
import '../services/firedata.dart';
import '../services/messaging.dart';
import '../services/user_cache.dart';

class Subscribe extends StatefulWidget {
  final Widget child;

  const Subscribe({super.key, required this.child});

  @override
  State<Subscribe> createState() => _SubscribeState();
}

class _SubscribeState extends State<Subscribe> {
  late Fireauth fireauth;
  late Firedata firedata;
  late Messaging messaging;
  late Cache cache;
  late UserCache userCache;
  late ChatCache chatCache;

  late StreamSubscription clockSkewSubscription;
  late StreamSubscription userSubscription;
  late StreamSubscription chatsSubscription;
  late StreamSubscription fcmTokenSubscription;

  @override
  void initState() {
    super.initState();

    fireauth = context.read<Fireauth>();
    firedata = context.read<Firedata>();
    messaging = context.read<Messaging>();
    cache = context.read<Cache>();
    userCache = context.read<UserCache>();
    chatCache = context.read<ChatCache>();

    final userId = fireauth.instance.currentUser!.uid;

    clockSkewSubscription = firedata.subscribeToClockSkew().listen((clockSkew) {
      cache.updateClockSkew(clockSkew);
    });
    userSubscription = firedata.subscribeToUser(userId).listen((user) {
      userCache.updateUser(user);
    });
    chatsSubscription = firedata.subscribeToChats(userId).listen((chats) {
      chatCache.updateChats(chats);
    });
    fcmTokenSubscription =
        messaging.subscribeToFcmToken().listen((token) async {
      await firedata.setUserFcmToken(userId, token);
    });
  }

  @override
  void dispose() {
    chatsSubscription.cancel();
    userSubscription.cancel();
    clockSkewSubscription.cancel();
    fcmTokenSubscription.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
