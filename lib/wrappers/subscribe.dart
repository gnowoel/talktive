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
import '../services/topic_cache.dart';
import '../services/topic_message_cache.dart';
import '../services/tribe_cache.dart';
import '../services/user_cache.dart';

class Subscribe extends StatefulWidget {
  final Widget child;

  const Subscribe({super.key, required this.child});

  @override
  State<Subscribe> createState() => _SubscribeState();
}

class _SubscribeState extends State<Subscribe> with WidgetsBindingObserver {
  List<StreamSubscription> _subscriptions = [];

  late Fireauth fireauth;
  late Firedata firedata;
  late Firestore firestore;
  late Messaging messaging;
  late ServerClock serverClock;
  late UserCache userCache;
  late FollowCache followCache;
  late ChatCache chatCache;
  late ChatMessageCache chatMessageCache;
  late TopicCache topicCache;
  late TopicMessageCache topicMessageCache;
  late TribeCache tribeCache;

  late StreamSubscription clockSkewSubscription;
  late StreamSubscription userSubscription;
  late StreamSubscription followeesSubscription;
  late StreamSubscription followersSubscription;
  late StreamSubscription chatsSubscription;
  late StreamSubscription fcmTokenSubscription;
  late StreamSubscription topicsSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeSubscriptions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cancelSubscriptions();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // Pause subscriptions when app goes to background
      for (final subscription in _subscriptions) {
        subscription.pause();
      }
    } else if (state == AppLifecycleState.resumed) {
      // Resume subscriptions when app comes to foreground
      for (final subscription in _subscriptions) {
        subscription.resume();
      }
    }
  }

  void _initializeSubscriptions() {
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
    topicCache = context.read<TopicCache>();
    topicMessageCache = context.read<TopicMessageCache>();
    tribeCache = context.read<TribeCache>();

    final userId = fireauth.instance.currentUser!.uid;
    
    // Initialize tribes cache at startup
    tribeCache.initialize();

    _subscriptions = [
      firedata.subscribeToClockSkew().listen((clockSkew) {
        serverClock.updateClockSkew(clockSkew);
      }),

      firedata.subscribeToUser(userId).listen((user) {
        userCache.updateUser(user);
      }),

      firestore.subscribeToFollowees(userId).listen((followees) {
        followCache.updateFollowees(followees);
      }),

      firestore.subscribeToFollowers(userId).listen((followers) {
        followCache.updateFollowers(followers);
      }),

      firedata.subscribeToChats(userId).listen((chats) {
        chatCache.updateChats(chats);
        // Clean up message cache for inactive chats
        chatMessageCache.cleanup(chatCache.activeChatIds);
      }),

      firestore.subscribeToTopics(userId).listen((topics) {
        topicCache.updateTopics(topics);
        // Clean up message cache for inactive topics
        topicMessageCache.cleanup(topicCache.activeTopicIds);
      }),

      messaging.subscribeToFcmToken().listen((token) async {
        await firedata.storeFcmToken(userId, token);
      }),
    ];
  }

  void _cancelSubscriptions() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
