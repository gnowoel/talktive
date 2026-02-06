import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/topic_message.dart';
import '../services/paginated_message_service.dart';
import 'topic_image_message_item.dart';
import 'topic_text_message_item.dart';
import 'message_separator.dart';

class PaginatedMessageList extends StatefulWidget {
  final String id; // topicId
  final String topicCreatorId;
  final FocusNode focusNode;
  final ScrollController scrollController;
  final void Function(int) updateMessageCount;
  final int readMessageCount;
  final void Function(String)? onInsertMention;
  final bool isTwoPersonTopic;

  const PaginatedMessageList({
    super.key,
    required this.id,
    required this.topicCreatorId,
    required this.focusNode,
    required this.scrollController,
    required this.updateMessageCount,
    required this.readMessageCount,
    this.onInsertMention,
    this.isTwoPersonTopic = false,
  });

  @override
  State<PaginatedMessageList> createState() => _PaginatedMessageListState();
}

class _PaginatedMessageListState extends State<PaginatedMessageList> {
  PaginatedMessageService? _messageService;

  List<TopicMessage> _messages = [];
  bool _isLoading = false;
  bool _hasMore = true;
  bool _isSticky = true;
  bool _initialLoadComplete = false;
  String? _errorMessage;
  ScrollNotification? _lastNotification;

  // Scroll management
  static const double _scrollThreshold = 200.0;
  static const double _loadingIndicatorHeight = 64.0;
  Timer? _scrollDebouncer;

  // Scroll position preservation
  double? _savedScrollOffset;
  double? _savedMaxScrollExtent;

  // Track current initial load to prevent duplicates
  String? _currentInitialLoadId;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_handleInputFocus);
    widget.scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialMessages();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final newMessageService = Provider.of<PaginatedMessageService>(context);

    // Only update listener if service instance changed
    if (_messageService != newMessageService) {
      // Remove old listener if it exists
      _messageService?.removeListener(_onServiceUpdated);

      _messageService = newMessageService;

      // Add listener to new service
      _messageService?.addListener(_onServiceUpdated);
    }
  }

  @override
  void dispose() {
    _scrollDebouncer?.cancel();

    try {
      widget.focusNode.removeListener(_handleInputFocus);
    } catch (e) {
      debugPrint('Error removing focus listener: $e');
    }

    try {
      widget.scrollController.removeListener(_onScroll);
    } catch (e) {
      debugPrint('Error removing scroll listener: $e');
    }

    try {
      _messageService?.removeListener(_onServiceUpdated);
    } catch (e) {
      debugPrint('Error removing service listener: $e');
    }

    // Dispose pagination state
    if (_messageService != null) {
      try {
        _messageService!.disposeTopicState(widget.id);
      } catch (e) {
        debugPrint('Error disposing pagination state: $e');
      }
    }

    super.dispose();
  }

  void _handleInputFocus() {
    if (widget.scrollController.hasClients && widget.focusNode.hasFocus) {
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    if (!widget.scrollController.hasClients) return;

    try {
      final controller = widget.scrollController;
      final position = controller.position;
      final bottom = position.maxScrollExtent;

      // Use animateTo for smoother scrolling if we're close
      if ((bottom - position.pixels).abs() < 500) {
        controller.animateTo(
          bottom,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      } else {
        // Jump directly if we're far away
        controller.jumpTo(bottom);
      }
    } catch (e) {
      debugPrint('Error scrolling to bottom: $e');
    }
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
      ScrollMetricsNotification notification) {
    // Only auto-scroll if we're sticky and the metrics changed due to new content
    if (_isSticky &&
        notification.metrics.maxScrollExtent > notification.metrics.pixels) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.scrollController.hasClients) {
          _scrollToBottom();
        }
      });
    }
    return false;
  }

  void _onScroll() {
    if (!widget.scrollController.hasClients) return;

    final position = widget.scrollController.position;

    // Check if user scrolled near the top and load more messages
    if (position.pixels <= _scrollThreshold && _hasMore && !_isLoading) {
      _scrollDebouncer?.cancel();
      _scrollDebouncer = Timer(const Duration(milliseconds: 150), () {
        if (mounted && _hasMore && !_isLoading) {
          _loadMoreMessages();
        }
      });
    }
  }

  void _onServiceUpdated() {
    // Update messages from service state when it changes (for real-time updates)
    if (_initialLoadComplete && mounted && !_isLoading) {
      _updateMessagesFromService();
    }
  }

  void _updateMessagesFromService() {
    if (!mounted || _messageService == null) return;

    try {
      final state = _messageService!.getTopicState(widget.id);
      if (state == null || state.isLoading) return;

      final serviceMessages = List<TopicMessage>.from(state.messages);
      final serviceHasMore = state.hasMore;

      // Early return if no change needed
      if (_messages.length == serviceMessages.length &&
          _hasMore == serviceHasMore &&
          serviceMessages.isNotEmpty &&
          _messages.isNotEmpty &&
          serviceMessages.last.id == _messages.last.id) {
        return;
      }

      final wasAtBottom = _isSticky;
      final hadNewMessages = serviceMessages.length > _messages.length;

      setState(() {
        _messages = serviceMessages;
        _hasMore = serviceHasMore;
        _errorMessage = null;
      });

      widget.updateMessageCount(_messages.length);

      // Auto-scroll to bottom for new messages if user was at bottom
      if (wasAtBottom && hadNewMessages && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && widget.scrollController.hasClients) {
            _scrollToBottom();
          }
        });
      }
    } catch (e) {
      debugPrint('Error updating from service: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to update messages: ${e.toString()}';
        });
      }
    }
  }

  Future<void> _loadInitialMessages() async {
    if (_isLoading || _messageService == null) return;

    // Prevent duplicate initial loads for the same ID
    if (_currentInitialLoadId == widget.id) {
      return;
    }

    debugPrint(
        'PaginatedMessageList: Loading initial messages for topic ${widget.id}');

    _currentInitialLoadId = widget.id;

    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _messageService!.loadTopicMessages(
        widget.id,
        isInitialLoad: true,
      );

      if (!mounted) return;
      setState(() {
        _messages = List<TopicMessage>.from(result.items);
        _hasMore = result.hasMore;
        _initialLoadComplete = true;
        _isLoading = false;
        _currentInitialLoadId = null;
      });

      debugPrint(
          'PaginatedMessageList: Initial load complete - ${_messages.length} messages, hasMore: $_hasMore');
      widget.updateMessageCount(_messages.length);

      // Ensure we scroll to bottom after initial load
      if (mounted && _messages.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && widget.scrollController.hasClients) {
            _scrollToBottom();
            // Double-check after another frame
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && widget.scrollController.hasClients) {
                final position = widget.scrollController.position;
                if (position.pixels < position.maxScrollExtent - 10) {
                  _scrollToBottom();
                }
              }
            });
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading initial messages: $e');
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
        _initialLoadComplete = true;
        _currentInitialLoadId = null;
      });
    }
  }

  Future<void> _loadMoreMessages() async {
    if (_isLoading || !_hasMore || _messageService == null) return;

    debugPrint(
        'PaginatedMessageList: Loading more messages for topic ${widget.id}');

    // Save precise scroll metrics before loading
    if (widget.scrollController.hasClients) {
      final position = widget.scrollController.position;
      _savedScrollOffset = position.pixels;
      _savedMaxScrollExtent = position.maxScrollExtent;
    } else {
      _savedScrollOffset = 0.0;
      _savedMaxScrollExtent = 0.0;
    }

    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _messageService!.loadMoreTopicMessages(widget.id);

      if (!mounted) return;

      setState(() {
        _messages = List<TopicMessage>.from(result.items);
        _hasMore = result.hasMore;
        _errorMessage = null;
      });

      debugPrint(
          'PaginatedMessageList: Loaded more messages, total: ${_messages.length}, hasMore: $_hasMore');
      widget.updateMessageCount(_messages.length);

      _adjustScrollPosition();
    } catch (e) {
      debugPrint('Error loading more messages: $e');
      _adjustScrollPosition();
      if (!mounted) return;
      setState(() {
        _hasMore = false;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  int _getReadMessageCount() {
    return widget.readMessageCount;
  }

  bool _shouldShowSeparator() {
    final readCount = _getReadMessageCount();
    return readCount > 0 && _messages.length > readCount;
  }

  void _adjustScrollPosition() {
    if (mounted &&
        widget.scrollController.hasClients &&
        _savedScrollOffset != null &&
        _savedMaxScrollExtent != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.scrollController.hasClients) {
          final currentMaxScrollExtent =
              widget.scrollController.position.maxScrollExtent;
          final addedContentHeight =
              currentMaxScrollExtent - _savedMaxScrollExtent!;
          final adjustedContentHeight =
              addedContentHeight - _loadingIndicatorHeight;
          final newScrollOffset = _savedScrollOffset! + adjustedContentHeight;
          final clampedOffset = newScrollOffset.clamp(
            0.0,
            currentMaxScrollExtent,
          );

          widget.scrollController.jumpTo(clampedOffset);
        }

        _savedScrollOffset = null;
        _savedMaxScrollExtent = null;
      });
    } else {
      _savedScrollOffset = null;
      _savedMaxScrollExtent = null;
    }
  }

  int _getItemCount() {
    if (_messages.isEmpty) return 0;

    var itemCount = _messages.length;
    if (_shouldShowSeparator()) itemCount += 1;
    return itemCount;
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialLoadComplete) {
      return const Center(
        child: CircularProgressIndicator(strokeWidth: 3),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load messages',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadInitialMessages,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Listener(
      onPointerDown: (details) => FocusScope.of(context).unfocus(),
      onPointerMove: (details) => FocusScope.of(context).unfocus(),
      child: _buildMessageList(),
    );
  }

  Widget _buildMessageList() {
    return NotificationListener<ScrollMetricsNotification>(
      onNotification: _handleScrollMetricsNotification,
      child: NotificationListener<ScrollNotification>(
        onNotification: _handleScrollNotification,
        child: CustomScrollView(
          controller: widget.scrollController,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            if (_isLoading && _messages.isNotEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                _buildMessageItem,
                childCount: _getItemCount(),
              ),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageItem(BuildContext context, int index) {
    final readCount = _getReadMessageCount();

    if (_shouldShowSeparator() && index == readCount) {
      return const MessageSeparator(label: 'New messages');
    }

    final messageIndex =
        _shouldShowSeparator() && index > readCount ? index - 1 : index;

    if (messageIndex < 0 || messageIndex >= _messages.length) {
      return const SizedBox.shrink();
    }

    return _buildSingleMessageItem(_messages[messageIndex]);
  }

  Widget _buildSingleMessageItem(TopicMessage message) {
    if (message is TopicImageMessage) {
      return TopicImageMessageItem(
        key: ValueKey(message.id),
        topicId: widget.id,
        topicCreatorId: widget.topicCreatorId,
        message: message,
        onInsertMention: widget.onInsertMention,
        hideDisplayName: widget.isTwoPersonTopic,
      );
    } else {
      return TopicTextMessageItem(
        key: ValueKey(message.id),
        topicId: widget.id,
        topicCreatorId: widget.topicCreatorId,
        message: message as TopicTextMessage,
        onInsertMention: widget.onInsertMention,
        hideDisplayName: widget.isTwoPersonTopic,
      );
    }
  }
}
