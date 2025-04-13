import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/messaging.dart';

class NotificationStep extends StatefulWidget {
  final VoidCallback onNext;

  const NotificationStep({super.key, required this.onNext});

  @override
  State<NotificationStep> createState() => _NotificationStepState();
}

class _NotificationStepState extends State<NotificationStep> {
  Future<void> _requestPermission() async {
    try {
      final messaging = context.read<Messaging>();

      final status = await messaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (status.authorizationStatus == AuthorizationStatus.authorized) {
        await messaging.instance.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
      }
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      widget.onNext();
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
          const Text('🔔', style: TextStyle(fontSize: 64)),
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
          TextButton(onPressed: widget.onNext, child: const Text('Skip')),
        ],
      ),
    );
  }
}
