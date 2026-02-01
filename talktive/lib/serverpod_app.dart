import 'package:flutter/material.dart';

class ServerpodApp extends StatelessWidget {
  final VoidCallback onExit;

  const ServerpodApp({super.key, required this.onExit});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Talktive (Serverpod)',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Talktive (Serverpod)'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: onExit,
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Welcome to the Serverpod version!'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: onExit,
                child: const Text('Back to Version Selection'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
