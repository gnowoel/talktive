import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

class NotificationStep extends StatelessWidget {
  final VoidCallback onNext;

  const NotificationStep({
    super.key,
    required this.onNext,
  });

  Future<void> _requestPermission() async {
    try {
      final messaging = FirebaseMessaging.instance;

      final status = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (status.authorizationStatus == AuthorizationStatus.authorized) {
        await messaging.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
      }
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      onNext();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            '🔔',
            style: TextStyle(fontSize: 64),
          ),
          const SizedBox(height: 32),
          Text(
            'Stay Connected',
            style: theme.textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Enable notifications to never miss messages from your chat partners.',
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          FilledButton(
            onPressed: _requestPermission,
            child: const Text('Enable Notifications'),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: onNext,
            child: const Text('Skip'),
          ),
        ],
      ),
    );
  }
}
