import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:talktive/models/user.dart';

import '../../services/cache.dart';
import '../../services/firedata.dart';
import '../../services/messaging.dart';
import '../../services/settings.dart';

class Notifier extends StatefulWidget {
  final Widget child;

  const Notifier({super.key, required this.child});

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
      await _localSetup();
      await _addListeners();
    } catch (e) {
      // Ignore on unsupported platforms
      debugPrint(e.toString());
    }
  }

  Future<void> _requestPermission() async {
    try {
      // Only proceed on Android 13+ where runtime permission is needed
      if (!Platform.isAndroid) return;

      // final hasRequested = await Settings.hasRequestedNotificationPermission();
      // if (hasRequested) return;

      // Wait a bit before showing the permission request
      await Future.delayed(const Duration(seconds: 2));

      // Show custom dialog first
      // if (!mounted) return;
      // final shouldRequest = await showDialog<bool>(
      //       context: context,
      //       builder: (context) => AlertDialog(
      //         title: const Text('Stay connected'),
      //         content: const Text(
      //           'Enable notifications to never miss messages from your chat partners.',
      //         ),
      //         actions: [
      //           TextButton(
      //             child: const Text('Not Now'),
      //             onPressed: () => Navigator.pop(context, false),
      //           ),
      //           TextButton(
      //             child: const Text('Enable'),
      //             onPressed: () => Navigator.pop(context, true),
      //           ),
      //         ],
      //       ),
      //     ) ??
      //     false;

      // if (!shouldRequest) return;

      // Request system permission
      final status = await messaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      await messaging.instance.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      await Settings.markNotificationPermissionRequested();

      if (status.authorizationStatus == AuthorizationStatus.authorized) {
        // Permission granted
      }
    } catch (e) {
      // Ignore on unsupported platforms
      debugPrint(e.toString());
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
      debugPrint(e.toString());
    }
  }

  Future<void> _localSetup() async {
    try {
      await messaging.localSetup();
    } catch (e) {
      // Ignore on unsupported platforms
      debugPrint(e.toString());
    }
  }

  Future<void> _addListeners() async {
    try {
      await messaging.addListeners();
    } catch (e) {
      // Ignore on unsupported platforms
      debugPrint(e.toString());
    }
  }

  @override
  void dispose() {
    fcmTokenSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
