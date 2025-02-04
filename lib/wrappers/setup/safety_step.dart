import 'package:flutter/material.dart';

class SafetyStep extends StatelessWidget {
  final VoidCallback onNext;

  const SafetyStep({
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
            '🛡️',
            style: TextStyle(fontSize: 64),
          ),
          const SizedBox(height: 32),
          Text(
            'Your Safety Matters',
            style: theme.textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'We want you to have a safe and enjoyable experience.',
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          _buildSafetyPoint(
            theme,
            'Report any inappropriate messages or behavior immediately.',
          ),
          const SizedBox(height: 12),
          _buildSafetyPoint(
            theme,
            'You can swipe left or right to delete any chat that makes you uncomfortable.',
          ),
          const SizedBox(height: 12),
          _buildSafetyPoint(
            theme,
            'Never share personal information with strangers.',
          ),
          const SizedBox(height: 48),
          FilledButton(
            onPressed: onNext,
            child: const Text('I Understand'),
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyPoint(ThemeData theme, String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: theme.textTheme.bodyMedium?.copyWith(
          height: 1.5,
        ),
      ),
    );
  }
}
