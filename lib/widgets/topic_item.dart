import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../models/public_topic.dart';
import '../services/server_clock.dart';
import 'tag.dart';

class TopicItem extends StatelessWidget {
  final PublicTopic topic;

  const TopicItem({super.key, required this.topic});

  void _handleTap(BuildContext context) {
    // Navigate to topic detail page
    context.push('/topics/${topic.id}');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final now = DateTime.fromMillisecondsSinceEpoch(ServerClock().now);
    final updatedAt = DateTime.fromMillisecondsSinceEpoch(topic.updatedAt);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      color: colorScheme.surfaceContainerHigh,
      child: InkWell(
        onTap: () => _handleTap(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(topic.title, style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    child: Text(
                      topic.creator.photoURL ?? '',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    topic.creator.displayName ?? '',
                    style: theme.textTheme.bodySmall,
                  ),
                  const Spacer(),
                  Tag(
                    tooltip: 'Messages',
                    child: Text(
                      '${topic.messageCount}',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Tag(
                    tooltip: 'Last updated',
                    child: Text(
                      timeago.format(updatedAt, locale: 'en_short', clock: now),
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
