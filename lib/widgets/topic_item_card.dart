import 'package:flutter/material.dart';
import '../models/topic.dart';
import 'two_person_topic_item_card.dart';
import 'normal_topic_item_card.dart';

class TopicItemCard extends StatelessWidget {
  final Topic topic;
  final Function(Topic) onRemove;
  final Function(Topic) onRestore;

  const TopicItemCard({
    super.key,
    required this.topic,
    required this.onRemove,
    required this.onRestore,
  });

  @override
  Widget build(BuildContext context) {
    // Route to appropriate card based on topic type
    if (topic.isTwoPersonTopic) {
      return TwoPersonTopicItemCard(
        topic: topic,
        onRemove: onRemove,
        onRestore: onRestore,
      );
    } else {
      return NormalTopicItemCard(
        topic: topic,
        onRemove: onRemove,
        onRestore: onRestore,
      );
    }
  }
}
