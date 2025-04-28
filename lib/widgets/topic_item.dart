import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../helpers/text.dart';
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
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: () => _handleTap(context),
        child: ListTile(
          contentPadding: const EdgeInsets.fromLTRB(16, 4, 16, 2),
          leading: GestureDetector(
            onTap: () {}, // _showUserInfo(context)
            child: Text(
              topic.creator.photoURL ?? '',
              style: TextStyle(fontSize: 36),
            ),
          ),
          title: Text(topic.title, overflow: TextOverflow.ellipsis),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                formatText(topic.lastMessageContent), // firstMessageContent
                overflow: TextOverflow.ellipsis,
                style: TextStyle(height: 1.2),
                maxLines: 3,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Tag(
                    tooltip: 'Messages',
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.message_outlined, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          '${topic.messageCount}',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  Tag(
                    tooltip: 'Last updated',
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.schedule, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          timeago.format(
                            updatedAt,
                            locale: 'en_short',
                            clock: now,
                          ),
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          trailing: IconButton(
            icon: const Icon(Icons.keyboard_arrow_right),
            // icon: const Icon(Icons.keyboard_double_arrow_right),
            onPressed: () {},
            tooltip: 'Join topic',
          ),
        ),
      ),
    );
  }
}
