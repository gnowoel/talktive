import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        final currentUser = snapshot.data;
        return Scaffold(
          body: SafeArea(
            child: Center(
              child: currentUser == null
                  ? buildSignInButton()
                  : buildUserProfile(currentUser),
            ),
          ),
        );
      },
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

  Widget buildUserProfile(User? currentUser) {
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
