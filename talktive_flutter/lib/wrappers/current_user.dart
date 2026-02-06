import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user.dart';
import '../services/ad_service/admob_compliance.dart';
import '../services/firedata.dart';
import '../services/user_cache.dart';
import '../theme.dart';

class CurrentUser extends StatefulWidget {
  final Widget child;

  const CurrentUser({super.key, required this.child});

  @override
  State<CurrentUser> createState() => _CurrentUserState();
}

class _CurrentUserState extends State<CurrentUser> {
  late Firedata firedata;
  late UserCache userCache;

  User? _user;
  User? _previousUser;

  @override
  void initState() {
    super.initState();
    firedata = context.read<Firedata>();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    userCache = Provider.of<UserCache>(context);
    _user = userCache.user;

    // Check if user changed (including role changes)
    if (_user != _previousUser) {
      // Reinitialize AdMob compliance when user changes
      // This is important when a user logs in as admin
      AdMobCompliance.initialize();
      _previousUser = _user;
    }

    if (_user != null) {
      if (_user!.fcmToken == null) {
        firedata.storeFcmToken(_user!.id); // No wait
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return MaterialApp(
        theme: getTheme(context),
        home: const Scaffold(
          body: Center(child: CircularProgressIndicator(strokeWidth: 3)),
        ),
      );
    }
    return widget.child;
  }
}
