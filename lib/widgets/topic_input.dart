import 'package:flutter/material.dart';
import '../models/topic.dart';
import 'two_person_topic_input.dart';
import 'normal_topic_input.dart';

class TopicInput extends StatefulWidget {
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
  State<TopicInput> createState() => TopicInputState();
}

class TopicInputState extends State<TopicInput> {
  final GlobalKey<TwoPersonTopicInputState> _twoPersonInputKey =
      GlobalKey<TwoPersonTopicInputState>();
  final GlobalKey<NormalTopicInputState> _normalInputKey =
      GlobalKey<NormalTopicInputState>();

  void insertMention(String displayName) {
    final isActuallyTwoPersonTopic =
        widget.isTwoPersonTopic || (widget.topic?.isTwoPersonTopic ?? false);

    if (isActuallyTwoPersonTopic) {
      _twoPersonInputKey.currentState?.insertMention(displayName);
    } else {
      _normalInputKey.currentState?.insertMention(displayName);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Route to appropriate input based on topic type
    // Use the explicit parameter first, then fall back to topic property
    final isActuallyTwoPersonTopic =
        widget.isTwoPersonTopic || (widget.topic?.isTwoPersonTopic ?? false);

    if (isActuallyTwoPersonTopic) {
      return TwoPersonTopicInput(
        key: _twoPersonInputKey,
        topic: widget.topic,
        focusNode: widget.focusNode,
        onSendTextMessage: widget.onSendTextMessage,
        onSendImageMessage: widget.onSendImageMessage,
        onInsertMention: widget.onInsertMention,
      );
    } else {
      return NormalTopicInput(
        key: _normalInputKey,
        topic: widget.topic,
        focusNode: widget.focusNode,
        onSendTextMessage: widget.onSendTextMessage,
        onSendImageMessage: widget.onSendImageMessage,
        onInsertMention: widget.onInsertMention,
      );
    }
  }
}
