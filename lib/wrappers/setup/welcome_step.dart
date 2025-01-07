import 'package:flutter/material.dart';

class WelcomeStep extends StatelessWidget {
  final VoidCallback onNext;

  const WelcomeStep({
    super.key,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            '👋',
            style: TextStyle(fontSize: 64),
          ),
          const SizedBox(height: 32),
          Text(
            'Welcome to Talktive',
            style: theme.textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Connect with people around the world and start meaningful conversations.',
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          FilledButton(
            onPressed: onNext,
            child: const Text('Get Started'),
          ),
        ],
      ),
    );
  }
}
