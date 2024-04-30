import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'pages/empty.dart';
import 'pages/error.dart';
import 'pages/user.dart';

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: FirebaseAuth.instance.signInAnonymously(),
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
  }
}
