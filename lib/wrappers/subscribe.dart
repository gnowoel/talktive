import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/chat_cache.dart';
import '../services/fireauth.dart';
import '../services/firedata.dart';
import '../services/firestore.dart';
import '../services/follow_cache.dart';
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
  late Firestore firestore;
  late Messaging messaging;
  late ServerClock serverClock;
  late UserCache userCache;
  late FollowCache followCache;
  late ChatCache chatCache;
  late ChatMessageCache chatMessageCache;

  late StreamSubscription clockSkewSubscription;
  late StreamSubscription userSubscription;
  late StreamSubscription followeesSubscription;
  late StreamSubscription chatsSubscription;
  late StreamSubscription fcmTokenSubscription;

  @override
  void initState() {
    super.initState();

    fireauth = context.read<Fireauth>();
    firedata = context.read<Firedata>();
    firestore = context.read<Firestore>();
    messaging = context.read<Messaging>();
    serverClock = context.read<ServerClock>();
    userCache = context.read<UserCache>();
    followCache = context.read<FollowCache>();
    chatCache = context.read<ChatCache>();
    chatMessageCache = context.read<ChatMessageCache>();

    final userId = fireauth.instance.currentUser!.uid;

    clockSkewSubscription = firedata.subscribeToClockSkew().listen((clockSkew) {
      serverClock.updateClockSkew(clockSkew);
    });
    userSubscription = firedata.subscribeToUser(userId).listen((user) {
      userCache.updateUser(user);
    });
    followeesSubscription = firestore.subscribeToFollowees(userId).listen((
      followees,
    ) {
      followCache.updateFollowees(followees);
    });
    chatsSubscription = firedata.subscribeToChats(userId).listen((chats) {
      chatCache.updateChats(chats);
      // Clean up message cache for inactive chats
      chatMessageCache.cleanup(chatCache.activeChatIds);
    });
    fcmTokenSubscription = messaging.subscribeToFcmToken().listen((
      token,
    ) async {
      await firedata.storeFcmToken(userId, token);
    });
  }

  @override
  void dispose() {
    fcmTokenSubscription.cancel();
    chatsSubscription.cancel();
    followeesSubscription.cancel();
    userSubscription.cancel();
    clockSkewSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
