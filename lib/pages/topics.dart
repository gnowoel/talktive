import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../helpers/exception.dart';
import '../models/public_topic.dart';
import '../models/tribe.dart';
import '../services/firestore.dart';
import '../services/server_clock.dart';
import '../services/topic_cache.dart';
import '../services/tribe_cache.dart';
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

    _fetchTopics();
    _fetchTribes();
  }

  Future<void> _fetchTopics() async {
    try {
      final topics = await firestore.fetchPublicTopics(serverClock.now);

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
    context.go('/topics/tribe/${tribe.id}');
  }
  
  void _navigateToCreateTopic([String? tribeId]) {
    final uri = tribeId != null 
        ? Uri(path: '/topics/create', queryParameters: {'tribeId': tribeId})
        : Uri(path: '/topics/create');
    context.push(uri.toString());
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
              'To create your own topic, head over to the Friends tab.',
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
      'No topics here yet. Create',
      'one from the Friends tab.',
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
            icon: const Icon(Icons.add),
            onPressed: () => _navigateToCreateTopic(),
            tooltip: 'Create Topic',
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfoDialog(context),
            tooltip: 'Help',
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            tooltip: 'Refresh topics',
            onPressed: _canRefresh ? _refreshTopics : null,
          ),
        ],
      ),
      body: SafeArea(
        child:
            _topics.isEmpty
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
                              Text(
                                'Tribes',
                                style: theme.textTheme.titleMedium,
                              ),
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
                                      color: theme.colorScheme.primaryContainer,
                                      child: InkWell(
                                        onTap: () => _navigateToTribe(tribe),
                                        child: SizedBox(
                                          width: 100,
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  tribe.iconEmoji ?? '🏷️',
                                                  style: const TextStyle(fontSize: 24),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  tribe.name,
                                                  style: theme.textTheme.labelMedium,
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
                        ),
                      ),
                    ],
                  ),
                ),
      ),
    );
  }
}
