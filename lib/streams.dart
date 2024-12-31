import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/cache.dart';
import '../services/fireauth.dart';
import '../services/firedata.dart';

class Streams extends StatefulWidget {
  final Widget child;

  const Streams({super.key, required this.child});

  @override
  State<Streams> createState() => _StreamsState();
}

class _StreamsState extends State<Streams> {
  late Fireauth fireauth;
  late Firedata firedata;
  late Cache cache;

  late StreamSubscription clockSkewSubscription;
  late StreamSubscription userSubscription;
  late StreamSubscription chatsSubscription;

  @override
  void initState() {
    super.initState();

    fireauth = context.read<Fireauth>();
    firedata = context.read<Firedata>();
    cache = context.read<Cache>();

    final userId = fireauth.instance.currentUser!.uid;

    clockSkewSubscription = firedata.subscribeToClockSkew().listen((clockSkew) {
      cache.updateClockSkew(clockSkew);
    });
    userSubscription = firedata.subscribeToUser(userId).listen((user) {
      cache.updateUser(user);
    });
    chatsSubscription = firedata.subscribeToChats(userId).listen((chats) {
      cache.updateChats(chats);
    });
  }

  @override
  void dispose() {
    chatsSubscription.cancel();
    userSubscription.cancel();
    clockSkewSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
