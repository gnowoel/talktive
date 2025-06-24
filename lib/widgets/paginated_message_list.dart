import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/message.dart';
import '../models/image_message.dart';
import '../models/text_message.dart';
import '../models/topic_message.dart';
import '../models/chat.dart';
import '../services/paginated_message_service.dart';
import '../services/cache/sqlite_message_cache.dart';
import 'image_message_item.dart';
import 'text_message_item.dart';
import 'topic_image_message_item.dart';
import 'topic_text_message_item.dart';
import 'message_separator.dart';
import 'skipped_messages_placeholder.dart';
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
        readMessageCount = null;

  const PaginatedMessageList.topic({
    super.key,
    required this.id,
    required this.topicCreatorId,
    required this.focusNode,
    required this.scrollController,
    required this.updateMessageCount,
    required this.readMessageCount,
    this.onInsertMention,
  })  : type = MessageListType.topic,
        chat = null,
        reporterUserId = null;

  @override
  State<PaginatedMessageList> createState() => _PaginatedMessageListState();
}

class _PaginatedMessageListState extends State<PaginatedMessageList> {
  late PaginatedMessageService _messageService;
  late SqliteMessageCache _cache;

  List<dynamic> _messages = []; // Can be Message or TopicMessage
  bool _isLoading = false;
  bool _hasMore = true;
  bool _isSticky = true;
  bool _initialLoadComplete = false;
  String? _errorMessage;

  // Scroll management
  ScrollNotification? _lastNotification;
  static const double _scrollThreshold =
      200.0; // Pixels from top to trigger load

  // Message collapsing state
  int _additionalMessagesRevealedUp = 0;
  int _additionalMessagesRevealedDown = 0;
  static const int _baseMessagesToShow = 25;

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
    _messageService = Provider.of<PaginatedMessageService>(context);
    _cache = Provider.of<SqliteMessageCache>(context);

    // Listen to cache changes for real-time updates
    _cache.addListener(_onCacheUpdated);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_handleInputFocus);
    widget.scrollController.removeListener(_onScroll);
    _cache.removeListener(_onCacheUpdated);
    super.dispose();
  }

  void _handleInputFocus() {
    if (widget.scrollController.hasClients && widget.focusNode.hasFocus) {
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    if (!widget.scrollController.hasClients) return;

    final controller = widget.scrollController;
    final bottom = controller.position.maxScrollExtent;
    controller.animateTo(
      bottom,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _onScroll() {
    if (!widget.scrollController.hasClients) return;

    final controller = widget.scrollController;
    final position = controller.position;

    // Check if user scrolled near the top and load more messages
    if (position.pixels <= _scrollThreshold && _hasMore && !_isLoading) {
      _loadMoreMessages();
    }

    // Update sticky state based on scroll position
    final isAtBottom = position.extentAfter < 50;
    if (isAtBottom != _isSticky) {
      setState(() {
        _isSticky = isAtBottom;
      });
    }
  }

  void _onCacheUpdated() {
    // Reload messages from cache when it's updated (for real-time updates)
    _loadMessagesFromCache();
  }

  Future<void> _loadInitialMessages() async {
    if (_isLoading) return;

    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      late PaginatedResult result;

      if (widget.type == MessageListType.chat) {
        result = await _messageService.loadChatMessages(
          widget.id,
          isInitialLoad: true,
          chatCreatedAt: widget.chat?.createdAt,
        );
      } else {
        result = await _messageService.loadTopicMessages(
          widget.id,
          isInitialLoad: true,
        );
      }

      if (!mounted) return;
      setState(() {
        _messages = result.items;
        _hasMore = result.hasMore;
        _initialLoadComplete = true;
        _isLoading = false;
      });

      widget.updateMessageCount(_messages.length);

      // Scroll to bottom after initial load
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && widget.scrollController.hasClients) {
            _scrollToBottom();
          }
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreMessages() async {
    if (_isLoading || !_hasMore) return;

    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      late PaginatedResult result;

      if (widget.type == MessageListType.chat) {
        result = await _messageService.loadMoreChatMessages(widget.id);
      } else {
        result = await _messageService.loadMoreTopicMessages(widget.id);
      }

      if (result.items.isNotEmpty) {
        if (!mounted) return;
        setState(() {
          // Insert older messages at the beginning
          _messages.insertAll(0, result.items);
          _hasMore = result.hasMore;
        });

        widget.updateMessageCount(_messages.length);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMessagesFromCache() async {
    try {
      late List<dynamic> cachedMessages;

      if (widget.type == MessageListType.chat) {
        cachedMessages = await _cache.getChatMessages(
          widget.id,
          minCreatedAt: widget.chat?.createdAt,
        );
      } else {
        cachedMessages = await _cache.getTopicMessages(widget.id);
      }

      // Only update if we have more messages than before (for real-time updates)
      if (cachedMessages.length > _messages.length) {
        if (!mounted) return;
        setState(() {
          _messages = cachedMessages;
        });

        widget.updateMessageCount(_messages.length);

        // Auto-scroll to bottom for new messages if user is at bottom
        if (_isSticky && mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _scrollToBottom();
          });
        }
      }
    } catch (e) {
      // Silently handle cache errors to avoid disrupting user experience
      debugPrint('Error loading from cache: $e');
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
    if (_isSticky && widget.scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    }
    return false;
  }

  void _showMoreMessagesUp() {
    if (!widget.scrollController.hasClients) return;

    final currentOffset = widget.scrollController.offset;

    setState(() {
      _additionalMessagesRevealedUp += 25;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.scrollController.hasClients) {
        widget.scrollController.jumpTo(currentOffset);
      }
    });
  }

  void _showMoreMessagesDown() {
    if (!widget.scrollController.hasClients) return;

    final currentOffset = widget.scrollController.offset;

    setState(() {
      _additionalMessagesRevealedDown += 25;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.scrollController.hasClients) {
        widget.scrollController.jumpTo(currentOffset);
      }
    });
  }

  bool _isNewChat() {
    return widget.type == MessageListType.chat &&
        (widget.chat?.isDummy == true || _messages.isEmpty);
  }

  bool _shouldShowPlaceholder() {
    if (widget.type == MessageListType.topic) {
      final readCount = widget.readMessageCount ?? 0;
      final totalMessagesToShow = _baseMessagesToShow +
          _additionalMessagesRevealedUp +
          _additionalMessagesRevealedDown;
      return readCount > totalMessagesToShow;
    } else if (widget.type == MessageListType.chat &&
        widget.reporterUserId == null) {
      final readCount = widget.chat?.readMessageCount ?? 0;
      final totalMessagesToShow = _baseMessagesToShow +
          _additionalMessagesRevealedUp +
          _additionalMessagesRevealedDown;
      return readCount > totalMessagesToShow;
    }
    return false;
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
      child: NotificationListener<ScrollMetricsNotification>(
        onNotification: _handleScrollMetricsNotification,
        child: NotificationListener<ScrollNotification>(
          onNotification: _handleScrollNotification,
          child: _isNewChat() ? _buildInfo() : _buildMessageList(),
        ),
      ),
    );
  }

  Widget _buildInfo() {
    const lines = ['Say hi or send a photo', 'to your new friend.'];
    return const SizedBox.expand(
      child: AbsorbPointer(child: Info(lines: lines)),
    );
  }

  Widget _buildMessageList() {
    return CustomScrollView(
      controller: widget.scrollController,
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
      ],
    );
  }

  int _getItemCount() {
    if (_messages.isEmpty) return 0;

    final showPlaceholder = _shouldShowPlaceholder();
    final readCount = _getReadMessageCount();

    if (showPlaceholder) {
      // First messages + placeholder + last context + separator + unread
      final baseFirstCount = readCount >= 10 ? 10 : readCount;
      final firstMessagesCount =
          (baseFirstCount + _additionalMessagesRevealedDown)
              .clamp(0, readCount);

      final baseLastCount = 15;
      final maxContextCount =
          (readCount - firstMessagesCount).clamp(0, readCount);
      final lastReadContextCount =
          (baseLastCount + _additionalMessagesRevealedUp)
              .clamp(0, maxContextCount);

      var itemCount =
          firstMessagesCount + 1 + lastReadContextCount; // +1 for placeholder

      // Add separator if there are unread messages
      if (_shouldShowSeparator()) itemCount += 1;

      // Add unread messages
      final unreadCount =
          (_messages.length - readCount).clamp(0, _messages.length);
      itemCount += unreadCount;

      return itemCount;
    } else {
      var itemCount = _messages.length;
      if (_shouldShowSeparator()) itemCount += 1;
      return itemCount;
    }
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

  Widget _buildMessageItem(BuildContext context, int index) {
    final showPlaceholder = _shouldShowPlaceholder();
    final readCount = _getReadMessageCount();

    if (showPlaceholder) {
      return _buildMessageItemWithPlaceholder(context, index, readCount);
    } else {
      return _buildMessageItemWithoutPlaceholder(context, index, readCount);
    }
  }

  Widget _buildMessageItemWithPlaceholder(
      BuildContext context, int index, int readCount) {
    final baseFirstCount = readCount >= 10 ? 10 : readCount;
    final firstMessagesCount =
        (baseFirstCount + _additionalMessagesRevealedDown).clamp(0, readCount);

    final baseLastCount = 15;
    final maxContextCount =
        (readCount - firstMessagesCount).clamp(0, readCount);
    final lastReadContextCount = (baseLastCount + _additionalMessagesRevealedUp)
        .clamp(0, maxContextCount);

    // Calculate total context shown and messages to skip
    final totalContextShown = firstMessagesCount + lastReadContextCount;
    final messagesToSkip =
        readCount > totalContextShown ? readCount - totalContextShown : 0;

    // Handle first messages
    if (index < firstMessagesCount) {
      if (index >= _messages.length) return const SizedBox.shrink();
      return _buildSingleMessageItem(_messages[index]);
    }

    // Show placeholder
    if (index == firstMessagesCount) {
      return SkippedMessagesPlaceholder(
        messageCount: messagesToSkip,
        onTapUp: _showMoreMessagesUp,
        onTapDown: _showMoreMessagesDown,
      );
    }

    // Handle last read context messages
    if (index < firstMessagesCount + 1 + lastReadContextCount) {
      final contextIndex = index - firstMessagesCount - 1;
      final messageIndex = readCount - lastReadContextCount + contextIndex;

      if (messageIndex < 0 || messageIndex >= _messages.length) {
        return const SizedBox.shrink();
      }

      return _buildSingleMessageItem(_messages[messageIndex]);
    }

    // Handle separator
    final separatorIndex = firstMessagesCount + 1 + lastReadContextCount;
    if (_shouldShowSeparator() && index == separatorIndex) {
      return const MessageSeparator(label: 'New messages');
    }

    // Handle unread messages
    final separatorOffset = _shouldShowSeparator() ? 1 : 0;
    final messageIndex = readCount + (index - separatorIndex - separatorOffset);

    if (messageIndex < 0 || messageIndex >= _messages.length) {
      return const SizedBox.shrink();
    }

    return _buildSingleMessageItem(_messages[messageIndex]);
  }

  Widget _buildMessageItemWithoutPlaceholder(
      BuildContext context, int index, int readCount) {
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
      final chatMessage = message as Message;
      if (chatMessage is ImageMessage) {
        return ImageMessageItem(
          key: ValueKey(chatMessage.id),
          chatId: widget.id,
          message: chatMessage,
          reporterUserId: widget.reporterUserId,
          onInsertMention: widget.onInsertMention,
        );
      } else {
        return TextMessageItem(
          key: ValueKey(chatMessage.id),
          chatId: widget.id,
          message: chatMessage as TextMessage,
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
          message: topicMessage,
          onInsertMention: widget.onInsertMention,
        );
      } else {
        return TopicTextMessageItem(
          key: ValueKey(topicMessage.id),
          topicId: widget.id,
          topicCreatorId: widget.topicCreatorId!,
          message: topicMessage as TopicTextMessage,
          onInsertMention: widget.onInsertMention,
        );
      }
    }
  }
}
