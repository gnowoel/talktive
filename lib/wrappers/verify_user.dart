import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../pages/error.dart';
import '../../services/fireauth.dart';
import '../theme.dart';

class VerifyUser extends StatefulWidget {
  final Widget child;

  const VerifyUser({super.key, required this.child});

  @override
  State<VerifyUser> createState() => _VerifyUserState();
}

class _VerifyUserState extends State<VerifyUser> {
  late Fireauth fireauth;

  @override
  void initState() {
    super.initState();
    fireauth = context.read<Fireauth>();
  }

  void refresh() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (fireauth.instance.currentUser == null) {
      return widget.child;
    }

    return FutureBuilder(
      future: fireauth.signInAnonymously(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return MaterialApp(
            theme: getTheme(context),
            home: const Scaffold(
              body: SafeArea(
                child: Center(child: CircularProgressIndicator(strokeWidth: 3)),
              ),
            ),
          );
        }
        if (snapshot.hasError) {
          return MaterialApp(
            theme: getTheme(context),
            home: ErrorPage(message: '${snapshot.error}', refresh: refresh),
          );
        }

        return widget.child;
      },
    );
  }
}
