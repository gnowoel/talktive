import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'pages/empty.dart';
import 'pages/error.dart';
import 'pages/user.dart';
import 'services/fireauth.dart';

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    final fireauth = Provider.of<Fireauth>(context);

    try {
      return FutureBuilder(
        future: fireauth.signInAnonymously(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return ErrorPage(message: '${snapshot.error}');
          } else if (!snapshot.hasData) {
            return const EmptyPage();
          } else {
            return const UserPage();
          }
        },
      );
    } catch (e) {
      return ErrorPage(message: '$e');
    }
  }
}
