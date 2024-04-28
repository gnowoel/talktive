import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'pages/empty.dart';
import 'pages/user.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  void initState() {
    super.initState();
    FirebaseAuth.instance.signInAnonymously();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        return snapshot.hasData ? const UserPage() : const EmptyPage();
      },
    );
  }
}
