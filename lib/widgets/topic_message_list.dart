import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/topic_message.dart';
import '../services/firestore.dart';
import 'info.dart';
import 'topic_text_message_item.dart';
import 'topic_image_message_item.dart';

class TopicMessageList extends StatefulWidget {
  final String topicId;
  final FocusNode focusNode;
  final ScrollController scrollController;
  final void Function(int) updateMessageCount;

  const TopicMessageList({
    super.key,
    required this.topicId,
    required this.focusNode,
    required this.scrollController,
    required this.updateMessageCount,
  });

  @override
  State<TopicMessageList> createState() => _TopicMessageListState();
}

class _TopicMessageListState extends State<TopicMessageList> {
  late Firestore firestore;
  List<TopicMessage> _messages = [];
  bool _isSticky = true;
  ScrollNotification? _lastNotification;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_handleInputFocus);
    firestore = context.read<Firestore>();
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_handleInputFocus);
    super.dispose();
  }

  void _handleInputFocus() {
    if (widget.scrollController.hasClients && widget.focusNode.hasFocus) {
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    final controller = widget.scrollController;
    final bottom = controller.position.maxScrollExtent;
    controller.jumpTo(bottom);
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    final metrics = notification.metrics;

    if (_lastNotification.runtimeType != notification.runtimeType) {
      _lastNotification = notification;

      if (notification is ScrollEndNotification) {
        if (metrics.extentAfter == 0) {
          if (!_isSticky) {
            setState(() => _isSticky = true);
          }
        }
      }

      if (notification is ScrollUpdateNotification) {
        if (metrics.extentAfter != 0) {
          if (_isSticky) {
            setState(() => _isSticky = false);
          }
        }
      }
    }

    return false;
  }

  bool _handleScrollMetricsNotification(
    ScrollMetricsNotification notification,
  ) {
    if (_isSticky) {
      _scrollToBottom();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<TopicMessage>>(
      stream: firestore.subscribeToTopicMessages(widget.topicId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          throw snapshot.error!;
          // return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        _messages = snapshot.data!;

        if (_messages.isEmpty) {
          return const Center(
            child: Info(lines: ['Be the first to', 'start the discussion!']),
          );
        }

        return NotificationListener<ScrollMetricsNotification>(
          onNotification: _handleScrollMetricsNotification,
          child: NotificationListener<ScrollNotification>(
            onNotification: _handleScrollNotification,
            child: ListView.builder(
              controller: widget.scrollController,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];

                if (message is TopicImageMessage) {
                  return TopicImageMessageItem(
                    key: ValueKey(message.id),
                    message: message,
                  );
                }

                return TopicTextMessageItem(
                  key: ValueKey(message.id),
                  message: message as TopicTextMessage,
                );
              },
            ),
          ),
        );
      },
    );
  }
}
