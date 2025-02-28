import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/chat_cache.dart';
import '../services/fireauth.dart';
import '../services/firedata.dart';
import '../services/message_cache.dart';
import '../services/messaging.dart';
import '../services/server_clock.dart';
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
  late ServerClock serverClock;
  late UserCache userCache;
  late ChatCache chatCache;
  late ChatMessageCache chatMessageCache;

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
    serverClock = context.read<ServerClock>();
    userCache = context.read<UserCache>();
    chatCache = context.read<ChatCache>();
    chatMessageCache = context.read<ChatMessageCache>();

    final userId = fireauth.instance.currentUser!.uid;

    clockSkewSubscription = firedata.subscribeToClockSkew().listen((clockSkew) {
      serverClock.updateClockSkew(clockSkew);
    });
    userSubscription = firedata.subscribeToUser(userId).listen((user) {
      userCache.updateUser(user);
    });
    chatsSubscription = firedata.subscribeToChats(userId).listen((chats) {
      chatCache.updateChats(chats);
      // Invalidate the message cache to avoid messing up
      chatMessageCache.clear(chatCache.inactiveChatIds);
    });
    fcmTokenSubscription = messaging.subscribeToFcmToken().listen((
      token,
    ) async {
      await firedata.storeFcmToken(userId, token);
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
