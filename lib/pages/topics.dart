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
  Tribe? _selectedTribe;
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

  void _selectTribe(Tribe tribe) {
    setState(() {
      _selectedTribe = tribe;
    });
  }

  void _clearFilter() {
    setState(() {
      _selectedTribe = null;
    });
  }

  List<PublicTopic> get _filteredTopics {
    if (_selectedTribe == null) {
      return _topics;
    }
    return _topics
        .where((topic) => topic.tribeId == _selectedTribe!.id)
        .toList();
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

    // Pass the selected tribe ID if a category is filtered
    final route = _selectedTribe != null
        ? '/topics/create?tribeId=${_selectedTribe!.id}'
        : '/topics/create';

    context.push(route);
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
              'Tap on a category to filter topics, or use the + button to create your own.',
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

  String get _appBarTitle {
    if (_selectedTribe != null) {
      return '${_selectedTribe!.iconEmoji ?? ''} ${_selectedTribe!.name}';
    }
    return 'Active Topics';
  }

  String get _fabTooltip {
    if (!_canCreateTopic()) {
      return userCache.user?.withAlert == true
          ? 'Account restricted'
          : (userCache.user?.isTrainee == true
              ? 'Account too new'
              : 'Need followers');
    }

    return _selectedTribe != null
        ? 'Create Topic in ${_selectedTribe!.name}'
        : 'Create Topic';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filteredTopics = _filteredTopics;

    final lines = _selectedTribe != null
        ? [
            'No topics in this category yet.',
            'Be the first to create one!',
            '',
          ]
        : [
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
        title: Text(_appBarTitle),
        leading: _selectedTribe != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _clearFilter,
                tooltip: 'Show all topics',
              )
            : null,
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
        tooltip: _fabTooltip,
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: filteredTopics.isEmpty && _isPopulated
            ? Center(child: Info(lines: lines))
            : !_isPopulated
                ? const Center(
                    child: CircularProgressIndicator(strokeWidth: 3),
                  )
                : Layout(
                    child: Column(
                      children: [
                        if (_isTribesLoaded && _tribes.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text('Categories',
                                        style: theme.textTheme.titleMedium),
                                    if (_selectedTribe != null) ...[
                                      const SizedBox(width: 8),
                                      TextButton.icon(
                                        onPressed: _clearFilter,
                                        icon: const Icon(Icons.clear, size: 16),
                                        label: const Text('Clear filter'),
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          minimumSize: const Size(0, 0),
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  height: 100,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: _tribes.length,
                                    itemBuilder: (context, index) {
                                      final tribe = _tribes[index];
                                      final isSelected =
                                          _selectedTribe?.id == tribe.id;

                                      return Card(
                                        margin: const EdgeInsets.only(right: 8),
                                        color: isSelected
                                            ? theme.colorScheme.primaryContainer
                                            : theme
                                                .colorScheme.secondaryContainer,
                                        child: InkWell(
                                          onTap: () => _selectTribe(tribe),
                                          child: Container(
                                            width: 100,
                                            decoration: isSelected
                                                ? BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                    border: Border.all(
                                                      color: theme
                                                          .colorScheme.primary,
                                                      width: 2,
                                                    ),
                                                  )
                                                : null,
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
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
                                                      color: isSelected
                                                          ? theme.colorScheme
                                                              .onPrimaryContainer
                                                          : theme.colorScheme
                                                              .onSecondaryContainer,
                                                      fontWeight: isSelected
                                                          ? FontWeight.w600
                                                          : FontWeight.normal,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                    overflow:
                                                        TextOverflow.ellipsis,
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
                        // Show tribe description when filtered
                        if (_selectedTribe?.description != null &&
                            filteredTopics.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                            child: Text(
                              _selectedTribe!.description!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 10),
                        Expanded(
                          child: filteredTopics.isEmpty
                              ? Center(
                                  child: _selectedTribe?.description != null
                                      ? Padding(
                                          padding: const EdgeInsets.all(32.0),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                _selectedTribe!.description!,
                                                style: theme.textTheme.bodyLarge
                                                    ?.copyWith(
                                                  color: theme.colorScheme
                                                      .onSurfaceVariant,
                                                  height: 1.5,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                              const SizedBox(height: 24),
                                              const Info(lines: [
                                                'No topics in this category yet.',
                                                'Be the first to create one!',
                                                '',
                                              ]),
                                            ],
                                          ),
                                        )
                                      : Info(lines: lines),
                                )
                              : TopicList(
                                  topics: filteredTopics,
                                  joinedTopicIds: joinedTopicIds,
                                  seenTopicIds: seenTopicIds,
                                  showTribeTags: _selectedTribe == null,
                                ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }
}
