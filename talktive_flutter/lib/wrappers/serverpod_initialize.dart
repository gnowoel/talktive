import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../serverpod_client.dart';
import '../services/edge_to_edge_manager.dart';
import '../services/background_messaging_handler.dart';
import '../config/theme.dart';
import '../firebase_options.dart';

class ServerpodInitialize extends StatefulWidget {
  final Widget child;
  final bool useEmulators;

  const ServerpodInitialize({
    super.key,
    required this.child,
    this.useEmulators = true,
  });

  @override
  State<ServerpodInitialize> createState() => _ServerpodInitializeState();
}

class _ServerpodInitializeState extends State<ServerpodInitialize> {
  bool _initialized = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      // 1. Core Platform Services
      await EdgeToEdgeManager.initialize();
      await SharedPreferences.getInstance();

      // 2. Firebase Initialization (needed for Auth and FCM)
      // Already handled in main.dart, but we ensure emulators if needed
      if (kDebugMode && widget.useEmulators) {
        final host = defaultTargetPlatform == TargetPlatform.android ? '10.0.2.2' : 'localhost';
        await FirebaseAuth.instance.useAuthEmulator(host, 9099);
      }

      if (mounted) {
        setState(() => _initialized = true);
      }
    } catch (e, stack) {
      debugPrint('Initialization error: $e\n$stack');
      if (mounted) {
        setState(() => _error = e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: AppTheme.duoRed),
                  const SizedBox(height: 16),
                  const Text(
                    'Failed to initialize app',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(_error!, textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => setState(() {
                      _error = null;
                      _initialized = false;
                      _init();
                    }),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (!_initialized) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          body: Center(
            child: CircularProgressIndicator(color: AppTheme.duoBlue),
          ),
        ),
      );
    }

    return widget.child;
  }
}
