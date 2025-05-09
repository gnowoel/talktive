import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/public_topic.dart';
import '../services/fireauth.dart';
import '../services/firestore.dart';
import '../services/topic_message_cache.dart';
import '../services/user_cache.dart';
import '../widgets/topic_input.dart';
import '../widgets/topic_message_list.dart';

class TopicPage extends StatefulWidget {
  final String topicId;
  final String topicCreatorId;

  const TopicPage({
    super.key,
    required this.topicId,
    required this.topicCreatorId,
  });

  @override
  State<TopicPage> createState() => _TopicPageState();
}

class _TopicPageState extends State<TopicPage> {
  late Fireauth fireauth;
  late Firestore firestore;
  late UserCache userCache;
  late TopicMessageCache topicMessageCache;
  late StreamSubscription topicSubscription;
  late StreamSubscription messagesSubscription;

  final _focusNode = FocusNode();
  final _scrollController = ScrollController();

  PublicTopic? _topic;
  int _messageCount = 0;

  @override
  void initState() {
    super.initState();

    fireauth = context.read<Fireauth>();
    firestore = context.read<Firestore>();
    userCache = context.read<UserCache>();
    topicMessageCache = context.read<TopicMessageCache>();

    final userId = fireauth.instance.currentUser!.uid;

    topicSubscription = firestore
        .subscribeToTopic(userId, widget.topicId)
        .listen((topic) {
          setState(() {
            _topic = topic;
          });
        });

    final lastTimestamp = topicMessageCache.getLastTimestamp(widget.topicId);

    messagesSubscription = firestore
        .subscribeToTopicMessages(widget.topicId, lastTimestamp)
        .listen((messages) {
          topicMessageCache.addMessages(widget.topicId, messages);
        });
  }

  @override
  void dispose() {
    messagesSubscription.cancel();
    topicSubscription.cancel();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(String content) async {
    try {
      final user = userCache.user!;

      await firestore.sendTopicMessage(
        topicId: widget.topicId,
        userId: user.id,
        userDisplayName: user.displayName ?? '',
        userPhotoURL: user.photoURL ?? '',
        content: content,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  void _updateMessageCount(int count) {
    _messageCount = count;
  }

  Future<void> _updateReadMessageCount() async {
    final selfId = fireauth.instance.currentUser!.uid;
    final count = _messageCount;

    if (count == 0 || count == _topic?.readMessageCount) {
      return;
    }

    await firestore.updateTopicReadMessageCount(
      selfId,
      widget.topicId,
      readMessageCount: count,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _updateReadMessageCount();
        if (context.mounted) {
          Navigator.pop(context, result);
        }
      },
      child: Scaffold(
        appBar: AppBar(title: Text(_topic?.title ?? '')),
        body: Column(
          children: [
            Expanded(
              child: TopicMessageList(
                topicId: widget.topicId,
                topicCreatorId: widget.topicCreatorId,
                focusNode: _focusNode,
                scrollController: _scrollController,
                updateMessageCount: _updateMessageCount,
              ),
            ),
            TopicInput(
              focusNode: _focusNode,
              onSendMessage: _sendMessage,
              // TODO: Implement image sending
              // onSendImage: _sendImage,
            ),
          ],
        ),
      ),
    );
  }
}
