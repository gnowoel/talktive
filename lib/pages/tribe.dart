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

class TribePage extends StatefulWidget {
  final String tribeId;

  const TribePage({super.key, required this.tribeId});

  @override
  State<TribePage> createState() => _TribePageState();
}

class _TribePageState extends State<TribePage> {
  late ServerClock serverClock;
  late Firestore firestore;
  late TopicCache topicCache;
  late TribeCache tribeCache;

  List<PublicTopic> _seenTopics = [];
  List<PublicTopic> _topics = [];
  Tribe? _tribe;
  bool _isPopulated = false;
  bool _canRefresh = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    serverClock = context.read<ServerClock>();
    firestore = context.read<Firestore>();
    topicCache = context.read<TopicCache>();
    tribeCache = context.read<TribeCache>();
    _loadTribe();
    _fetchTopics();
  }

  Future<void> _loadTribe() async {
    try {
      await tribeCache.fetchTribes();
      if (mounted) {
        setState(() {
          _tribe = tribeCache.getTribeById(widget.tribeId);
        });
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showSnackBarMessage(
          context,
          e is AppException ? e : AppException(e.toString()),
        );
      }
    }
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
  }

  Future<void> _fetchTopics() async {
    try {
      final topics = await firestore.fetchTopicsByTribe(widget.tribeId);

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

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tribeName = _tribe?.name ?? 'Loading...';
    final lines = [
      'No topics in $tribeName yet.',
      'Be the first to create one!',
      '',
    ];

    final joinedTopicIds = topicCache.topicIds;
    final seenTopicIds = _seenTopics.map((topic) => topic.id).toList();

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLow,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surfaceContainerLow,
        title: Text('${_tribe?.iconEmoji ?? ''} $tribeName'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            tooltip: 'Refresh topics',
            onPressed: _canRefresh ? _refreshTopics : null,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/topics/create?tribeId=${widget.tribeId}'),
        tooltip: 'Create Topic in this Tribe',
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child:
            _topics.isEmpty
                ? (_isPopulated
                    ? Center(child: Info(lines: lines))
                    : const Center(
                      child: CircularProgressIndicator(strokeWidth: 3),
                    ))
                : Layout(
                  child: Column(
                    children: [
                      if (_tribe?.description != null) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                          child: Text(
                            _tribe!.description!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
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