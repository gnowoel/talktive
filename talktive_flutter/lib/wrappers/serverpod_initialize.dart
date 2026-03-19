import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

import '../services/edge_to_edge_manager.dart';
import '../config/theme.dart';

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

      // 2. Firebase Emulator Initialization (if in debug mode)
      if (kDebugMode && widget.useEmulators) {
        final isAndroid = defaultTargetPlatform == TargetPlatform.android;
        final host = isAndroid ? '10.0.2.2' : 'localhost';
        
        try {
          debugPrint('ServerpodInitialize: Using Firebase Emulators at $host');
          FirebaseDatabase.instance.useDatabaseEmulator(host, 9000);
          FirebaseFirestore.instance.useFirestoreEmulator(host, 8088);
          await FirebaseAuth.instance.useAuthEmulator(host, 9099);
          await FirebaseStorage.instance.useStorageEmulator(host, 9199);
          FirebaseFunctions.instance.useFunctionsEmulator(host, 5001);
          debugPrint('ServerpodInitialize: Firebase Emulators initialized successfully');
        } catch (e) {
          debugPrint('ServerpodInitialize: Error setting up emulators: $e');
          // We don't throw here to allow app to start even if emulators fail
        }
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
