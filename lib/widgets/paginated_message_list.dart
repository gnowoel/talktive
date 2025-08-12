import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/chat_message.dart';
import '../models/topic_message.dart';
import '../models/chat.dart';
import '../services/paginated_message_service.dart';
import 'chat_image_message_item.dart';
import 'chat_text_message_item.dart';
import 'topic_image_message_item.dart';
import 'topic_text_message_item.dart';
import 'message_separator.dart';
import 'info.dart';

enum MessageListType { chat, topic }

class PaginatedMessageList extends StatefulWidget {
  // Common properties
  final MessageListType type;
  final String id; // chatId or topicId
  final FocusNode focusNode;
  final ScrollController scrollController;
  final void Function(int) updateMessageCount;
  final void Function(String)? onInsertMention;

  // Chat-specific properties
  final Chat? chat;
  final String? reporterUserId;

  // Topic-specific properties
  final String? topicCreatorId;
  final int? readMessageCount;
  final bool isTwoPersonTopic;

  const PaginatedMessageList.chat({
    super.key,
    required this.id,
    required this.chat,
    required this.focusNode,
    required this.scrollController,
    required this.updateMessageCount,
    this.onInsertMention,
    this.reporterUserId,
  })  : type = MessageListType.chat,
        topicCreatorId = null,
        readMessageCount = null,
        isTwoPersonTopic = false;

  const PaginatedMessageList.topic({
    super.key,
    required this.id,
    required this.topicCreatorId,
    required this.focusNode,
    required this.scrollController,
    required this.updateMessageCount,
    required this.readMessageCount,
    this.onInsertMention,
    this.isTwoPersonTopic = false,
  })  : type = MessageListType.topic,
        chat = null,
        reporterUserId = null;

  @override
  State<PaginatedMessageList> createState() => _PaginatedMessageListState();
}

class _PaginatedMessageListState extends State<PaginatedMessageList> {
  PaginatedMessageService? _messageService;

  List<dynamic> _messages = []; // Can be ChatMessage or TopicMessage
  bool _isLoading = false;
  bool _hasMore = true;
  bool _isSticky = true;
  bool _initialLoadComplete = false;
  String? _errorMessage;
  ScrollNotification? _lastNotification;

  // Scroll management
  static const double _scrollThreshold = 200.0;
  static const double _loadingIndicatorHeight =
      64.0; // Height of loading indicator + padding
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

    // Dispose pagination state to prevent memory leaks and excessive subscriptions
    if (_messageService != null) {
      try {
        if (widget.type == MessageListType.chat) {
          _messageService!.disposeChatState(widget.id);
        } else {
          _messageService!.disposeTopicState(widget.id);
        }
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
    ScrollMetricsNotification notification,
  ) {
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
      List<dynamic> serviceMessages;
      bool serviceHasMore;

      if (widget.type == MessageListType.chat) {
        final state = _messageService!.getChatState(widget.id);
        if (state == null || state.isLoading) return;

        serviceMessages = state.messages;
        serviceHasMore = state.hasMore;
      } else {
        final state = _messageService!.getTopicState(widget.id);
        if (state == null || state.isLoading) return;

        serviceMessages = state.messages;
        serviceHasMore = state.hasMore;
      }

      // Early return if no change needed
      if (_messages.length == serviceMessages.length &&
          _hasMore == serviceHasMore &&
          serviceMessages.isNotEmpty &&
          _messages.isNotEmpty &&
          _getMessageId(serviceMessages.last) ==
              _getMessageId(_messages.last)) {
        return;
      }

      final wasAtBottom = _isSticky;
      final hadNewMessages = serviceMessages.length > _messages.length;

      setState(() {
        _messages = List.from(serviceMessages);
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
        'PaginatedMessageList: Loading initial messages for ${widget.type.name} ${widget.id}');

    _currentInitialLoadId = widget.id;

    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      late SimplePaginatedResult result;

      if (widget.type == MessageListType.chat) {
        result = await _messageService!.loadChatMessages(
          widget.id,
          isInitialLoad: true,
          chatCreatedAt: widget.chat?.createdAt,
        );
      } else {
        result = await _messageService!.loadTopicMessages(
          widget.id,
          isInitialLoad: true,
        );
      }

      if (!mounted) return;
      setState(() {
        _messages = List.from(result.items);
        _hasMore = result.hasMore;
        _initialLoadComplete = true;
        _isLoading = false;
        _currentInitialLoadId = null;
      });

      debugPrint(
          'PaginatedMessageList: Initial load complete - ${_messages.length} messages, hasMore: $_hasMore');
      widget.updateMessageCount(_messages.length);

      // Ensure we scroll to bottom after initial load
      // Use multiple post-frame callbacks to ensure layout is complete
      if (mounted && _messages.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && widget.scrollController.hasClients) {
            _scrollToBottom();
            // Double-check after another frame
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && widget.scrollController.hasClients) {
                final position = widget.scrollController.position;
                // If we're not at the bottom, try again
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
        'PaginatedMessageList: Loading more messages for ${widget.type.name} ${widget.id}');

    // Save precise scroll metrics before loading
    if (widget.scrollController.hasClients) {
      final position = widget.scrollController.position;
      _savedScrollOffset = position.pixels;
      _savedMaxScrollExtent = position.maxScrollExtent;
    } else {
      // Fallback when controller doesn't have clients yet
      _savedScrollOffset = 0.0;
      _savedMaxScrollExtent = 0.0;
    }

    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      late SimplePaginatedResult result;

      if (widget.type == MessageListType.chat) {
        result = await _messageService!.loadMoreChatMessages(widget.id);
      } else {
        result = await _messageService!.loadMoreTopicMessages(widget.id);
      }

      if (!mounted) return;

      setState(() {
        _messages = List.from(result.items);
        _hasMore = result.hasMore;
        _errorMessage = null; // Clear previous errors on success
      });

      debugPrint(
          'PaginatedMessageList: Loaded more messages, total: ${_messages.length}, hasMore: $_hasMore');
      widget.updateMessageCount(_messages.length);

      // Precisely maintain scroll position after adding messages
      _adjustScrollPosition();
    } catch (e) {
      debugPrint('Error loading more messages: $e');
      // Try to preserve scroll position even on error if we have saved values
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

  String _getMessageId(dynamic message) {
    if (message is ChatMessage) {
      return message.id ?? '';
    } else if (message is TopicMessage) {
      return message.id ?? '';
    }
    return '';
  }

  bool _isNewChat() {
    return widget.type == MessageListType.chat &&
        (widget.chat?.isDummy == true || _messages.isEmpty);
  }

  int _getReadMessageCount() {
    if (widget.type == MessageListType.chat) {
      return widget.chat?.readMessageCount ?? 0;
    } else {
      return widget.readMessageCount ?? 0;
    }
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

          // Calculate the height of newly added content
          final addedContentHeight =
              currentMaxScrollExtent - _savedMaxScrollExtent!;

          // Account for the loading indicator that will be removed
          final adjustedContentHeight =
              addedContentHeight - _loadingIndicatorHeight;

          // Calculate new scroll position to maintain visual position
          final newScrollOffset = _savedScrollOffset! + adjustedContentHeight;

          // Ensure we don't scroll beyond bounds
          final clampedOffset = newScrollOffset.clamp(
            0.0,
            currentMaxScrollExtent,
          );

          widget.scrollController.jumpTo(clampedOffset);
        }

        // Clear saved values after adjustment
        _savedScrollOffset = null;
        _savedMaxScrollExtent = null;
      });
    } else {
      // Clear saved values if we can't adjust
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
      child: _isNewChat() ? _buildInfo() : _buildMessageList(),
    );
  }

  Widget _buildInfo() {
    const lines = ['Say hi or send a photo', 'to your new friend.'];
    return const SizedBox.expand(
      child: AbsorbPointer(child: Info(lines: lines)),
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
            // Loading indicator at top
            if (_isLoading && _messages.isNotEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),

            // Messages list
            SliverList(
              delegate: SliverChildBuilderDelegate(
                _buildMessageItem,
                childCount: _getItemCount(),
              ),
            ),

            // Bottom padding for better UX
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

    // Handle separator
    if (_shouldShowSeparator() && index == readCount) {
      return const MessageSeparator(label: 'New messages');
    }

    // Adjust index for separator
    final messageIndex =
        _shouldShowSeparator() && index > readCount ? index - 1 : index;

    if (messageIndex < 0 || messageIndex >= _messages.length) {
      return const SizedBox.shrink();
    }

    return _buildSingleMessageItem(_messages[messageIndex]);
  }

  Widget _buildSingleMessageItem(dynamic message) {
    if (widget.type == MessageListType.chat) {
      final chatMessage = message as ChatMessage;
      if (chatMessage is ChatImageMessage) {
        return ChatImageMessageItem(
          key: ValueKey(chatMessage.id),
          chatId: widget.id,
          message: chatMessage,
          reporterUserId: widget.reporterUserId,
          onInsertMention: widget.onInsertMention,
        );
      } else {
        return ChatTextMessageItem(
          key: ValueKey(chatMessage.id),
          chatId: widget.id,
          message: chatMessage as ChatTextMessage,
          reporterUserId: widget.reporterUserId,
          onInsertMention: widget.onInsertMention,
        );
      }
    } else {
      final topicMessage = message as TopicMessage;
      if (topicMessage is TopicImageMessage) {
        return TopicImageMessageItem(
          key: ValueKey(topicMessage.id),
          topicId: widget.id,
          topicCreatorId: widget.topicCreatorId!,
          message: topicMessage,
          onInsertMention: widget.onInsertMention,
          hideDisplayName: widget.isTwoPersonTopic,
        );
      } else {
        return TopicTextMessageItem(
          key: ValueKey(topicMessage.id),
          topicId: widget.id,
          topicCreatorId: widget.topicCreatorId!,
          message: topicMessage as TopicTextMessage,
          onInsertMention: widget.onInsertMention,
          hideDisplayName: widget.isTwoPersonTopic,
        );
      }
    }
  }
}
