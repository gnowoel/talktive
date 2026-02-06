import 'package:flutter/material.dart';
import 'package:talktive_client/talktive_client.dart';

class ServerpodApp extends StatelessWidget {
  final VoidCallback onExit;

  const ServerpodApp({super.key, required this.onExit});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Talktive (Serverpod)',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('The Plaza'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: onExit,
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                // client.auth.signOutDevice();
                // Disabled until auth is fixed
              },
            ),
          ],
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Auth UI Placeholder'),
              SizedBox(height: 20),
              Text('Use the legacy app for now.'),
            ],
          ),
        ),
      ),
    );
  }
}
