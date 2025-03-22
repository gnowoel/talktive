import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/user_cache.dart';
import '../theme.dart';

class CurrentUser extends StatefulWidget {
  final Widget child;

  const CurrentUser({super.key, required this.child});

  @override
  State<CurrentUser> createState() => _CurrentUserState();
}

class _CurrentUserState extends State<CurrentUser> {
  late UserCache userCache;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    userCache = Provider.of<UserCache>(context);
  }

  @override
  Widget build(BuildContext context) {
    if (userCache.user == null) {
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
