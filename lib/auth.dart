import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'pages/empty.dart';
import 'pages/error.dart';
import 'streams.dart';
import 'services/fireauth.dart';

class Auth extends StatefulWidget {
  const Auth({super.key});

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
          return const EmptyPage(
            hasAppBar: false,
            child: SizedBox(), // CircularProgressIndicator()
          );
        }

        if (snapshot.hasError) {
          return ErrorPage(
            message: '${snapshot.error}',
            refresh: refresh,
          );
        }

        return const Streams();
      },
    );
  }
}
