import 'package:flutter/material.dart';

import 'tag.dart';

class UserInfoDialog extends StatelessWidget {
  final String photoURL;
  final String displayName;

  const UserInfoDialog({
    super.key,
    required this.photoURL,
    required this.displayName,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
              [
                "This is a line of description.",
                "In fact, it's a very, very, very long line.",
                "Can we say, it's a multiline text?",
              ].join(' '),
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
                    'F',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                Tag(
                  child: Text(
                    'en',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                Tag(
                  child: Text(
                    '2h',
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
