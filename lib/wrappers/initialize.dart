import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/ad_service/admob_compliance.dart';
import '../services/ad_service/new/robust_consent_service.dart';
import '../services/ad_service/new/robust_ad_request_helper.dart';
import '../services/ad_service/ad_service_adapter.dart';
import '../services/avatar.dart';
import '../services/messaging.dart';
import '../services/report_cache.dart';
import '../services/service_locator.dart';
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

    // Ensure ServiceLocator is initialized before proceeding
    try {
      if (!ServiceLocator.instance.isInitialized) {
        if (ServiceLocator.instance.isInitializing) {
          debugPrint(
              'Initialize: Waiting for ongoing ServiceLocator initialization...');
          // Wait for ongoing initialization to complete
          while (ServiceLocator.instance.isInitializing) {
            await Future.delayed(const Duration(milliseconds: 100));
          }

          // Check if initialization failed
          if (!ServiceLocator.instance.isInitialized &&
              ServiceLocator.instance.initializationError != null) {
            throw Exception(
                'ServiceLocator initialization failed: ${ServiceLocator.instance.initializationError}');
          }
          debugPrint(
              'Initialize: ServiceLocator initialization completed (was waiting)');
        } else {
          debugPrint('Initialize: Starting ServiceLocator initialization...');
          // Initialize ServiceLocator if not already done
          await ServiceLocator.instance.initialize();
          debugPrint('Initialize: ServiceLocator initialization completed');
        }
      } else {
        debugPrint('Initialize: ServiceLocator already initialized');
      }
    } catch (e) {
      debugPrint('Failed to initialize ServiceLocator: $e');
      throw Exception(
          'Critical service initialization failed. Please restart the app.');
    }

    debugPrint('Initialize: Starting other services initialization...');

    final settings = my.Settings();
    await settings.load();
    debugPrint('Initialize: Settings loaded');

    final reportCache = ReportCacheService();
    await reportCache.initialize();
    debugPrint('Initialize: ReportCache initialized');

    final avatar = Avatar();
    avatar.init();
    debugPrint('Initialize: Avatar initialized');

    final messaging = Messaging();
    await messaging.localSetup();
    await messaging.clearAllNotifications(); // Clear existing notifications
    await messaging.addListeners();
    debugPrint('Initialize: Messaging services initialized');

    // Initialize ads with robust consent handling
    try {
      debugPrint('Initialize: Starting ads and consent initialization...');

      // Initialize robust consent service first
      final consentInitialized =
          await RobustConsentService.instance.initialize();
      debugPrint(
          'Initialize: Robust consent service initialized: $consentInitialized');

      // Initialize Mobile Ads SDK with consent validation
      final adsInitialized =
          await RobustAdRequestHelper.instance.initializeMobileAds();
      debugPrint('Initialize: Mobile Ads SDK initialized: $adsInitialized');

      // Initialize ad service adapter
      AdServiceAdapter.instance.initialize();
      debugPrint('Initialize: Ad service adapter initialized');

      // Check if consent is blocking ads
      final consentBlock =
          await RobustAdRequestHelper.instance.checkConsentBlocking();
      if (consentBlock.isBlocked) {
        debugPrint(
            'Initialize: WARNING - Ads blocked by consent: ${consentBlock.reason}');
        debugPrint('Initialize: Action needed: ${consentBlock.action}');
      }

      // Log compliance status for debugging
      if (kDebugMode) {
        await AdMobCompliance.logComplianceStatus();
        final stats = RobustAdRequestHelper.instance.getRequestStats();
        debugPrint('Initialize: Ad request stats: $stats');
      }

      debugPrint('Initialize: Ads and consent initialization completed');
    } catch (e) {
      debugPrint('Initialize: Failed to initialize ads and consent: $e');
      // Continue without ads rather than crashing
    }

    debugPrint('Initialize: All services initialization completed');
  }

  @override
  void dispose() {
    // Dispose ServiceLocator and all its managed services
    if (ServiceLocator.instance.isInitialized) {
      ServiceLocator.instance.dispose();
    }
    super.dispose();
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
