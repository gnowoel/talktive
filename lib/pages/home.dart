import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'empty.dart';
import 'user.dart';

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
        final currentUser = snapshot.data;
        return currentUser == null ? const EmptyPage() : const UserPage();
      },
    );
  }
}
