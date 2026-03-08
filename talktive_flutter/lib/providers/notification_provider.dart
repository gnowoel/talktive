import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'notification_provider.g.dart';

class DuoNotification {
  final String title;
  final String message;
  final String emoji;
  final VoidCallback? onTap;
  final Duration duration;

  DuoNotification({
    required this.title,
    required this.message,
    this.emoji = '🔔',
    this.onTap,
    this.duration = const Duration(seconds: 4),
  });
}

@riverpod
class NotificationNotifier extends _$NotificationNotifier {
  @override
  DuoNotification? build() => null;

  void show(DuoNotification notification) {
    state = notification;
    // Auto-dismiss
    Future.delayed(notification.duration, () {
      if (state == notification) {
        state = null;
      }
    });
  }

  void dismiss() {
    state = null;
  }
}
