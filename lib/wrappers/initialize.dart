import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/avatar.dart';
import '../services/messaging.dart';
import '../services/settings.dart' as my;
import '../theme.dart';

class Initialize extends StatefulWidget {
  final bool useEmulators;
  final Widget child;

  const Initialize({super.key, this.useEmulators = true, required this.child});

  @override
  State<Initialize> createState() => _InitializeState();
}

class _InitializeState extends State<Initialize> {
  bool _initialized = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      if (kDebugMode && widget.useEmulators) {
        final isAndroid = defaultTargetPlatform == TargetPlatform.android;
        final host = isAndroid ? '10.0.2.2' : 'localhost';

        await _initializeEmulators(host);
      }

      await _initializeServices();

      if (mounted) {
        setState(() => _initialized = true);
      }
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  Future<void> _initializeEmulators(String host) async {
    try {
      FirebaseDatabase.instance.useDatabaseEmulator(host, 9000);
      FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
      await FirebaseAuth.instance.useAuthEmulator(host, 9099);
      await FirebaseStorage.instance.useStorageEmulator(host, 9199);
      FirebaseFunctions.instance.useFunctionsEmulator(host, 5001);
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> _initializeServices() async {
    if (!kDebugMode && !kIsWeb) {
      FirebaseDatabase.instance.setPersistenceEnabled(true);
    }

    final settings = my.Settings();
    await settings.load();

    final avatar = Avatar();
    avatar.init();

    final messaging = Messaging();
    await messaging.localSetup();
    await messaging.clearAllNotifications(); // Clear existing notifications
    await messaging.addListeners();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return MaterialApp(
        theme: getTheme(context),
        home: Scaffold(body: Center(child: Text('Error: $_error'))),
      );
    }

    if (!_initialized) {
      return MaterialApp(
        theme: getTheme(context),
        home: const Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    return widget.child;
  }
}
