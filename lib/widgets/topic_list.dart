import 'package:flutter/material.dart';

import '../models/public_topic.dart';
import '../models/tribe.dart';
import 'topic_item.dart';

class TopicList extends StatelessWidget {
  final List<PublicTopic> topics;
  final List<String> joinedTopicIds;
  final List<String> seenTopicIds;
  final bool showTribeTags;
  final void Function(Tribe)? onTribeSelected;

  const TopicList({
    super.key,
    required this.topics,
    required this.joinedTopicIds,
    required this.seenTopicIds,
    this.showTribeTags = false,
    this.onTribeSelected,
  });

  bool _hasJoined(PublicTopic topic) {
    return joinedTopicIds.contains(topic.id);
  }

  bool _hasSeen(PublicTopic topic) {
    return seenTopicIds.contains(topic.id);
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
      itemCount: topics.length,
      itemBuilder: (context, index) {
        final topic = topics[index];
        return TopicItem(
          key: ValueKey(topic.id),
          topic: topic,
          hasJoined: _hasJoined(topic),
          hasSeen: _hasSeen(topic),
          showTribeTag: showTribeTags,
          onTribeSelected: onTribeSelected,
        );
      },
    );
  }
}
