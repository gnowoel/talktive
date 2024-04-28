import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: FilledButton(
            onPressed: () async {
              await FirebaseAuth.instance.signInAnonymously();
              print(FirebaseAuth.instance.currentUser!.uid);
            },
            child: const Text('Sign In'),
          ),
        ),
      ),
    );
  }
}
