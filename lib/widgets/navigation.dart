import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../services/cache.dart';
import '../services/fireauth.dart';
import '../services/firedata.dart';

class Navigation extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const Navigation({
    super.key,
    required this.navigationShell,
  });

  @override
  State<Navigation> createState() => _NavigationState();
}

class _NavigationState extends State<Navigation> {
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

  void _goBranch(int index) {
    widget.navigationShell.goBranch(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: widget.navigationShell.currentIndex,
        destinations: const [
          NavigationDestination(
            label: 'Users',
            icon: Icon(Icons.person_add),
          ),
          NavigationDestination(
            label: 'Chats',
            icon: Icon(Icons.chat),
          ),
          NavigationDestination(
            label: 'Profile',
            icon: Icon(Icons.face),
          ),
        ],
        onDestinationSelected: _goBranch,
      ),
    );
  }
}
