import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../pages/empty.dart';
import '../../pages/error.dart';
import '../../services/fireauth.dart';
import '../../theme.dart';

class Auth extends StatefulWidget {
  final Widget child;

  const Auth({super.key, required this.child});

  @override
  State<Auth> createState() => _AuthState();
}

class _AuthState extends State<Auth> {
  void refresh() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final fireauth = Provider.of<Fireauth>(context);

    return FutureBuilder(
      future: fireauth.signInAnonymously(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Talktive',
            theme: getTheme(context),
            home: const EmptyPage(
              hasAppBar: false,
              child: SizedBox(), // CircularProgressIndicator()
            ),
          );
        }

        if (snapshot.hasError) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Talktive',
            home: ErrorPage(
              message: '${snapshot.error}',
              refresh: refresh,
            ),
          );
        }

        return widget.child;
      },
    );
  }
}
