import 'package:flutter/material.dart';

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: const Center(
        child: Text(
          'Legacy RTDB reports are deprecated.\nPlease use the Firebase Console to view Firestore reports.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
