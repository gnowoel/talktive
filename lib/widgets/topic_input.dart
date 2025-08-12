import 'package:flutter/material.dart';
import '../models/topic.dart';
import 'two_person_topic_input.dart';
import 'normal_topic_input.dart';

class TopicInput extends StatelessWidget {
  final Topic? topic;
  final FocusNode focusNode;
  final Future<void> Function(String) onSendTextMessage;
  final Future<void> Function(String) onSendImageMessage;
  final void Function(String)? onInsertMention;
  final bool isTwoPersonTopic;

  const TopicInput({
    super.key,
    required this.topic,
    required this.focusNode,
    required this.onSendTextMessage,
    required this.onSendImageMessage,
    this.onInsertMention,
    this.isTwoPersonTopic = false,
  });

  @override
  Widget build(BuildContext context) {
    // Route to appropriate input based on topic type
    // Use the explicit parameter first, then fall back to topic property
    final isActuallyTwoPersonTopic =
        isTwoPersonTopic || (topic?.isTwoPersonTopic ?? false);

    if (isActuallyTwoPersonTopic) {
      return TwoPersonTopicInput(
        topic: topic,
        focusNode: focusNode,
        onSendTextMessage: onSendTextMessage,
        onSendImageMessage: onSendImageMessage,
        onInsertMention: onInsertMention,
      );
    } else {
      return NormalTopicInput(
        topic: topic,
        focusNode: focusNode,
        onSendTextMessage: onSendTextMessage,
        onSendImageMessage: onSendImageMessage,
        onInsertMention: onInsertMention,
      );
    }
  }
}

// Re-export the state class for backward compatibility
typedef TopicInputState = TwoPersonTopicInputState;
