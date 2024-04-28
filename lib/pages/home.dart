import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    FirebaseAuth.instance.authStateChanges().listen((user) {
      setState(() {
        currentUser = user;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: currentUser == null ? buildSignInButton() : buildUserProfile(),
        ),
      ),
    );
  }

  Widget buildSignInButton() {
    return FilledButton(
      onPressed: () {
        FirebaseAuth.instance.signInAnonymously();
      },
      child: const Text('Sign In'),
    );
  }

  Widget buildUserProfile() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.network('https://i.pravatar.cc/150?u=${currentUser!.uid}'),
        const SizedBox(height: 25),
        FilledButton(
          onPressed: () {
            FirebaseAuth.instance.signOut();
          },
          child: const Text('Sign Out'),
        ),
      ],
    );
  }
}
