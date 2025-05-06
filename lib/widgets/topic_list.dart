import 'package:flutter/material.dart';

import '../models/public_topic.dart';
import 'topic_item.dart';

class TopicList extends StatelessWidget {
  final List<PublicTopic> topics;
  final List<String> joinedTopicIds;

  const TopicList({
    super.key,
    required this.topics,
    required this.joinedTopicIds,
  });

  bool _hasJoined(PublicTopic topic) {
    return joinedTopicIds.contains(topic.id);
  }

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
          hasJoined: _hasJoined(topic),
        );
      },
    );
  }
}
