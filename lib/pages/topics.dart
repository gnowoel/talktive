import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../helpers/exception.dart';
import '../models/public_topic.dart';
import '../models/tribe.dart';
import '../services/firestore.dart';
import '../services/follow_cache.dart';
import '../services/server_clock.dart';
import '../services/topic_cache.dart';
import '../services/tribe_cache.dart';
import '../services/user_cache.dart';
import '../widgets/info.dart';
import '../widgets/layout.dart';
import '../widgets/topic_list.dart';

class TopicsPage extends StatefulWidget {
  const TopicsPage({super.key});

  @override
  State<TopicsPage> createState() => _TopicsPageState();
}

class _TopicsPageState extends State<TopicsPage> {
  late ServerClock serverClock;
  late Firestore firestore;
  late TopicCache topicCache;
  late TribeCache tribeCache;
  late FollowCache followCache;
  late UserCache userCache;

  List<PublicTopic> _seenTopics = [];
  List<PublicTopic> _topics = [];
  List<Tribe> _tribes = [];
  bool _isPopulated = false;
  bool _isTribesLoaded = false;
  bool _canRefresh = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    serverClock = context.read<ServerClock>();
    firestore = context.read<Firestore>();
    topicCache = context.read<TopicCache>();
    tribeCache = context.read<TribeCache>();
    followCache = context.read<FollowCache>();
    userCache = context.read<UserCache>();
    _fetchTopics();
    _fetchTribes();
  }

  Future<void> _refreshTopics() async {
    if (!_canRefresh) return;

    setState(() => _canRefresh = false);

    _refreshTimer?.cancel();
    _refreshTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() => _canRefresh = true);
      }
    });

    _fetchTopics(forceRefresh: true);
    _fetchTribes();
  }

  Future<void> _fetchTopics({bool forceRefresh = false}) async {
    try {
      final topics = await firestore.fetchPublicTopics(
        serverClock.now,
        noCache: forceRefresh,
      );

      if (mounted) {
        setState(() {
          _seenTopics = _topics;
          _topics = topics;
          _isPopulated = true;
        });
      }
    } on AppException catch (e) {
      if (mounted) {
        ErrorHandler.showSnackBarMessage(context, e);
      }
    }
  }

  Future<void> _fetchTribes() async {
    try {
      await tribeCache.fetchTribes();

      if (mounted) {
        setState(() {
          _tribes = tribeCache.tribes;
          _isTribesLoaded = true;
        });
      }
    } on AppException catch (e) {
      if (mounted) {
        ErrorHandler.showSnackBarMessage(context, e);
      }
    }
  }

  void _navigateToTribe(Tribe tribe) {
    context.push('/topics/tribe/${tribe.id}');
  }

  bool _canCreateTopic() {
    final user = userCache.user;
    if (user == null) return false;

    return !user.isTrainee &&
        !user.withAlert &&
        followCache.followers.isNotEmpty;
  }

  Future<void> _showRestrictionDialog() async {
    final user = userCache.user!;
    final colorScheme = Theme.of(context).colorScheme;

    String title;
    List<Widget> content;

    if (user.withAlert) {
      title = 'Temporarily Restricted';
      content = [
        Text(
          'Your account has been restricted due to reported inappropriate behavior.',
          style: TextStyle(height: 1.5, color: colorScheme.error),
        ),
        const SizedBox(height: 16),
        const Text(
          'You cannot create topics until this restriction expires.',
          style: TextStyle(height: 1.5),
        ),
      ];
    } else if (user.isTrainee) {
      title = 'Account Too New';
      content = [
        Text(
          'Your account needs to be at least 24 hours old and reach level 4 to create topics.',
          style: TextStyle(height: 1.5, color: colorScheme.error),
        ),
        const SizedBox(height: 16),
        const Text(
          'This restriction helps maintain quality discussions in our community.',
          style: TextStyle(height: 1.5),
        ),
      ];
    } else {
      title = 'No Followers Yet';
      content = [
        Text(
          'You need at least one follower to create topics.',
          style: TextStyle(height: 1.5, color: colorScheme.error),
        ),
        const SizedBox(height: 16),
        const Text(
          'Make some friends first! Topics are meant for sharing with your followers.',
          style: TextStyle(height: 1.5),
        ),
      ];
    }

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: content,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _handleCreateTopic() {
    if (!_canCreateTopic()) {
      _showRestrictionDialog();
      return;
    }

    context.push('/topics/create');
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quick Tips'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Topics are public spaces where anyone can join the conversation.',
              style: TextStyle(height: 1.5),
            ),
            SizedBox(height: 16),
            Text(
              'Use the + button below to create your own topic and start discussions.',
              style: TextStyle(height: 1.5),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const lines = [
      'No topics here yet. Use',
      'the + button to create one!',
      '',
    ];

    final joinedTopicIds = topicCache.topicIds;
    final seenTopicIds = _seenTopics.map((topic) => topic.id).toList();

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLow,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surfaceContainerLow,
        title: const Text('Active Topics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfoDialog(context),
            tooltip: 'Help',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh topics',
            onPressed: _canRefresh ? _refreshTopics : null,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _handleCreateTopic,
        tooltip: _canCreateTopic()
            ? 'Create Topic'
            : (userCache.user?.withAlert == true
                ? 'Account restricted'
                : (userCache.user?.isTrainee == true
                    ? 'Account too new'
                    : 'Need followers')),
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: _topics.isEmpty
            ? (_isPopulated
                ? const Center(child: Info(lines: lines))
                : const Center(
                    child: CircularProgressIndicator(strokeWidth: 3),
                  ))
            : Layout(
                child: Column(
                  children: [
                    if (_isTribesLoaded && _tribes.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Categories',
                                style: theme.textTheme.titleMedium),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 100,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _tribes.length,
                                itemBuilder: (context, index) {
                                  final tribe = _tribes[index];
                                  return Card(
                                    margin: const EdgeInsets.only(right: 8),
                                    color: theme.colorScheme.secondaryContainer,
                                    child: InkWell(
                                      onTap: () => _navigateToTribe(tribe),
                                      child: SizedBox(
                                        width: 100,
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                tribe.iconEmoji ?? '🏷️',
                                                style: const TextStyle(
                                                  fontSize: 24,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                tribe.name,
                                                style: theme
                                                    .textTheme.labelMedium!
                                                    .copyWith(
                                                  color: theme.colorScheme
                                                      .onSecondaryContainer,
                                                ),
                                                textAlign: TextAlign.center,
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 2,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Expanded(
                      child: TopicList(
                        topics: _topics,
                        joinedTopicIds: joinedTopicIds,
                        seenTopicIds: seenTopicIds,
                        showTribeTags: true,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
