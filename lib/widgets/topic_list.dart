import 'package:flutter/material.dart';

import '../models/public_topic.dart';
import 'topic_item.dart';

class TopicList extends StatelessWidget {
  final List<PublicTopic> topics;

  const TopicList({
    super.key,
    required this.topics,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      itemCount: topics.length,
      itemBuilder: (context, index) {
        final topic = topics[index];
        return TopicItem(
          key: ValueKey(topic.id),
          topic: topic,
        );
      },
    );
  }
}
