import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/fireauth.dart';
import '../services/firestore.dart';
import '../services/user_cache.dart';
import '../widgets/topic_message_list.dart';
import '../widgets/message_input.dart';

class TopicPage extends StatefulWidget {
  final String topicId;

  const TopicPage({super.key, required this.topicId});

  @override
  State<TopicPage> createState() => _TopicPageState();
}

class _TopicPageState extends State<TopicPage> {
  late Fireauth fireauth;
  late Firestore firestore;
  late UserCache userCache;
  final _focusNode = FocusNode();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    fireauth = context.read<Fireauth>();
    firestore = context.read<Firestore>();
    userCache = context.read<UserCache>();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _scrollController.dispose();
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
    // TODO: Implement read message count tracking
  }

  @override
  Widget build(BuildContext context) {
    final userId = fireauth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: StreamBuilder(
          stream: firestore.subscribeToTopic(userId, widget.topicId),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Text('Loading...');
            }
            return Text(snapshot.data!.title);
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: TopicMessageList(
              topicId: widget.topicId,
              focusNode: _focusNode,
              scrollController: _scrollController,
              updateMessageCount: _updateMessageCount,
            ),
          ),
          MessageInput(
            focusNode: _focusNode,
            onSendMessage: _sendMessage,
            // TODO: Implement image sending
            // onSendImage: _sendImage,
          ),
        ],
      ),
    );
  }
}
