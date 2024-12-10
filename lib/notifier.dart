import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:talktive/models/user.dart';

import 'pages/home.dart';
import 'services/cache.dart';
import 'services/firedata.dart';
import 'services/messaging.dart';

class Notifier extends StatefulWidget {
  const Notifier({super.key});

  @override
  State<Notifier> createState() => _NotifierState();
}

class _NotifierState extends State<Notifier> {
  late Firedata firedata;
  late Messaging messaging;
  late Cache cache;

  StreamSubscription? fcmTokenSubscription;
  User? _user;
  String? _fcmToken;

  @override
  void initState() {
    super.initState();
    firedata = context.read<Firedata>();
    messaging = context.read<Messaging>();
    cache = context.read<Cache>();
    _user = cache.user;
    _firstTimeSetup();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    cache = Provider.of<Cache>(context);
    _user = cache.user;
    _storeFcmToken();
  }

  Future<void> _firstTimeSetup() async {
    try {
      await _requestPermission();
      await _storeFcmToken();
      await _addListeners();
    } catch (e) {
      // Ignore on unsupported platforms
    }
  }

  Future<void> _requestPermission() async {
    try {
      await messaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (e) {
      // Ignore on unsupported platforms
    }
  }

  Future<void> _storeFcmToken() async {
    try {
      if (_user?.fcmToken == null) {
        _fcmToken = _fcmToken ?? await messaging.instance.getToken();
        await firedata.setUserFcmToken(_user?.id, _fcmToken);
      }
      fcmTokenSubscription?.cancel();
      fcmTokenSubscription =
          messaging.subscribeToFcmToken().listen((token) async {
        _fcmToken = token;
        await firedata.setUserFcmToken(_user?.id, _fcmToken);
      });
    } catch (e) {
      // Ignore on unsupported platforms
    }
  }

  Future<void> _addListeners() async {
    try {
      await messaging.addListeners();
    } catch (e) {
      // Ignore on unsupported platforms
    }
  }

  @override
  void dispose() {
    fcmTokenSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const HomePage();
  }
}
