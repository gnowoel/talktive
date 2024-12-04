import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../models/user.dart';
import '../services/cache.dart';
import 'tag.dart';

class UserInfoDialog extends StatelessWidget {
  final String photoURL;
  final String displayName;
  final User? user;
  final String? error;

  const UserInfoDialog({
    super.key,
    required this.photoURL,
    required this.displayName,
    this.user,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (user == null) {
      return Dialog(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                photoURL,
                style: const TextStyle(fontSize: 64),
              ),
              const SizedBox(height: 16),
              Text(
                displayName,
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              if (error == null)
                Padding(
                  padding: const EdgeInsets.only(top: 24, bottom: 8),
                  child: SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      );
    }

    final now = DateTime.fromMillisecondsSinceEpoch(Cache().now);
    final updatedAt = DateTime.fromMillisecondsSinceEpoch(user!.updatedAt);

    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              photoURL,
              style: const TextStyle(fontSize: 64),
            ),
            const SizedBox(height: 16),
            Text(
              displayName,
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              user!.description!,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                Tag(
                  child: Text(
                    user!.gender!,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                Tag(
                  child: Text(
                    user!.languageCode!,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                Tag(
                  child: Text(
                    timeago.format(updatedAt, locale: 'en_short', clock: now),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
}
