import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../helpers/exception.dart';
import '../models/topic.dart';
import '../services/firestore.dart';
import '../services/user_cache.dart';
import '../widgets/layout.dart';
import '../widgets/topic_list.dart';

class JoinedTopicsPage extends StatefulWidget {
  const JoinedTopicsPage({super.key});

  @override
  State<JoinedTopicsPage> createState() => _JoinedTopicsPageState();
}

class _JoinedTopicsPageState extends State<JoinedTopicsPage> {
  late Firestore firestore;
  StreamSubscription<List<Topic>>? _topicsSubscription;
  List<Topic> _topics = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    firestore = context.read<Firestore>();
    final userCache = context.read<UserCache>();
    final userId = userCache.user?.id;

    if (userId != null) {
      _subscribeToTopics(userId);
    }
  }

  void _subscribeToTopics(String userId) {
    try {
      _topicsSubscription =
          firestore.subscribeToTopics(userId).listen((topics) {
        if (!mounted) return;
        setState(() {
          _topics = topics;
          _isLoading = false;
        });
      }, onError: (error) {
        if (!mounted) return;
        ErrorHandler.showSnackBarMessage(
            context, AppException(error.toString()));
        setState(() => _isLoading = false);
      });
    } catch (e) {
      if (mounted) {
        ErrorHandler.showSnackBarMessage(context, AppException(e.toString()));
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _topicsSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Filter out hidden topics or apply other view logic if needed
    // For now, we show all joined topics.

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLow,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surfaceContainerLow,
        title: const Text(
            'Chats'), // Keeping the name "Chats" for user familiarity
      ),
      body: SafeArea(
        child: Layout(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _topics.isEmpty
                  ? Center(
                      child: Text(
                        'No conversations yet.',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : TopicList(
                      topics: _topics,
                      joinedTopicIds: _topics.map((e) => e.id).toList(),
                      seenTopicIds: const [], // Mark all as unseen? Or handle read state
                      showTribeTags: true,
                      // We don't implement remove/restore here yet for joined topics
                      // as that logic might differ from generic TopicList
                      onRemove: (topic) {},
                      onRestore: (topic) {},
                    ),
        ),
      ),
    );
  }
}
