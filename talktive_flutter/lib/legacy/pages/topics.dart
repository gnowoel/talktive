import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../helpers/exception.dart';
import '../models/topic.dart';
import '../models/tribe.dart';
import '../services/firestore.dart';
import '../services/server_clock.dart';
import '../services/topic_cache.dart';
import '../services/tribe_cache.dart';
import '../../widgets/info.dart';
import '../../widgets/layout.dart';
import '../../widgets/topic_list.dart';
import '../helpers/snackbar_helper.dart';

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

  List<Topic> _seenTopics = [];
  List<Topic> _topics = [];
  List<Tribe> _tribes = [];
  Tribe? _selectedTribe;
  bool _isPopulated = false;
  bool _isTribesLoaded = false;

  final ScrollController _tribeScrollController = ScrollController();

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
    await Future.delayed(const Duration(seconds: 1));

    _fetchTopics(forceRefresh: true);
    _fetchTribes();
  }

  Future<void> _fetchTopics({bool forceRefresh = false}) async {
    try {
      final topics = _selectedTribe != null
          ? await firestore.fetchTopicsByTribe(
              _selectedTribe!.id,
              serverClock.now,
              noCache: forceRefresh,
            )
          : await firestore.fetchTopics(serverClock.now, noCache: forceRefresh);

      // Sort topics by createdAt in descending order (newest first)
      topics.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (mounted) {
        setState(() {
          _seenTopics = _topics;
          _topics = topics;
          _isPopulated = true;
        });
      }
    } on AppException catch (e) {
      if (mounted) {
        SnackBarHelper.showError(context, e);
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
        SnackBarHelper.showError(context, e);
      }
    }
  }

  void _selectTribe(Tribe tribe) {
    if (_selectedTribe?.id == tribe.id) return;

    setState(() {
      _selectedTribe = tribe;
      _isPopulated = false; // Show loading while fetching tribe topics
    });

    _fetchTopics(forceRefresh: true);
    _scrollToSelectedTribe();
  }

  void _clearFilter() {
    if (_selectedTribe == null) return;

    setState(() {
      _selectedTribe = null;
      _isPopulated = false; // Show loading while fetching all topics
    });

    _fetchTopics(forceRefresh: true);
    _scrollToBeginning();
  }

  void _scrollToSelectedTribe() {
    if (_selectedTribe == null || !_tribeScrollController.hasClients) return;

    final selectedIndex = _tribes.indexWhere(
      (tribe) => tribe.id == _selectedTribe!.id,
    );
    if (selectedIndex == -1) return;

    // Calculate the scroll position
    // Card width (100) + margin (8) = 108 pixels per card
    const cardWidth = 108.0;
    final scrollPosition = selectedIndex * cardWidth;

    // Get the viewport width to center the selected card
    final viewportWidth = _tribeScrollController.position.viewportDimension;
    final centeredPosition =
        scrollPosition - (viewportWidth / 2) + (cardWidth / 2);

    // Ensure we don't scroll beyond the bounds
    final maxScrollExtent = _tribeScrollController.position.maxScrollExtent;
    final clampedPosition = centeredPosition.clamp(0.0, maxScrollExtent);

    _tribeScrollController.animateTo(
      clampedPosition,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _scrollToBeginning() {
    if (!_tribeScrollController.hasClients) return;

    _tribeScrollController.animateTo(
      0.0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _removeTopic(Topic topic) {
    setState(() {
      _topics.removeWhere((t) => t.id == topic.id);
    });
  }

  void _restoreTopic(Topic topic) {
    setState(() {
      // Insert the topic back at the correct position based on createdAt
      final insertIndex = _topics.indexWhere(
        (t) => t.createdAt < topic.createdAt,
      );
      if (insertIndex == -1) {
        _topics.add(topic);
      } else {
        _topics.insert(insertIndex, topic);
      }
    });
  }

  @override
  void dispose() {
    _tribeScrollController.dispose();
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
              'What happened to you today? Share your experiences, thoughts, and special moments!',
              style: TextStyle(height: 1.5),
            ),
            SizedBox(height: 16),
            Text(
              'Moments are public for a limited time, then become private for your followers.',
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
    return 'Active Moments';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final lines = ['Share your moments with', 'your followers and more!', ''];

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
                tooltip: 'Show all moments',
              )
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfoDialog(context),
            tooltip: 'Help',
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshTopics,
          child: Layout(
            child: Column(
              children: [
                // Always show categories when tribes are loaded
                if (_isTribesLoaded && _tribes.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Categories',
                              style: theme.textTheme.titleMedium,
                            ),
                            if (_selectedTribe != null) ...[
                              const Spacer(),
                              TextButton.icon(
                                onPressed: _clearFilter,
                                icon: const Icon(Icons.clear, size: 16),
                                label: const Text('Clear'),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 0,
                                  ),
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
                            controller: _tribeScrollController,
                            scrollDirection: Axis.horizontal,
                            itemCount: _tribes.length,
                            itemBuilder: (context, index) {
                              final tribe = _tribes[index];
                              final isSelected = _selectedTribe?.id == tribe.id;

                              return Card(
                                margin: const EdgeInsets.only(right: 8),
                                color: isSelected
                                    ? theme.colorScheme.primaryContainer
                                    : theme.colorScheme.secondaryContainer,
                                child: InkWell(
                                  onTap: () => _selectTribe(tribe),
                                  child: Container(
                                    width: 100,
                                    decoration: isSelected
                                        ? BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color: theme.colorScheme.primary,
                                              width: 2,
                                            ),
                                          )
                                        : null,
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
                                            style: theme.textTheme.labelMedium!
                                                .copyWith(
                                                  color: isSelected
                                                      ? theme
                                                            .colorScheme
                                                            .onPrimaryContainer
                                                      : theme
                                                            .colorScheme
                                                            .onSecondaryContainer,
                                                  fontWeight: isSelected
                                                      ? FontWeight.w600
                                                      : FontWeight.normal,
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
                // Show tribe description when filtered and topics exist
                if (_selectedTribe?.description != null &&
                    _topics.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Text(
                      _selectedTribe!.description!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Expanded(
                  child: !_isPopulated
                      ? const SingleChildScrollView(
                          physics: AlwaysScrollableScrollPhysics(),
                          child: SizedBox(
                            height: 400,
                            child: Center(
                              child: CircularProgressIndicator(strokeWidth: 3),
                            ),
                          ),
                        )
                      : _topics.isEmpty
                      ? SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: SizedBox(
                            height: MediaQuery.of(context).size.height * 0.6,
                            child: Center(
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
                                                  color: theme
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                                  height: 1.5,
                                                ),
                                            textAlign: TextAlign.center,
                                          ),
                                          const SizedBox(height: 16),
                                        ],
                                      ),
                                    )
                                  : Info(lines: lines),
                            ),
                          ),
                        )
                      : TopicList(
                          topics: _topics,
                          joinedTopicIds: joinedTopicIds,
                          seenTopicIds: seenTopicIds,
                          showTribeTags: _selectedTribe == null,
                          onTribeSelected: _selectTribe,
                          onRemove: _removeTopic,
                          onRestore: _restoreTopic,
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
