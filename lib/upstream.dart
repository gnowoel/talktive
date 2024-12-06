import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/cache.dart';
import '../services/fireauth.dart';
import '../services/firedata.dart';
import 'pages/home.dart';

class Upstream extends StatefulWidget {
  const Upstream({super.key});

  @override
  State<Upstream> createState() => _UpstreamState();
}

class _UpstreamState extends State<Upstream> {
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
    return const HomePage();
  }
}
