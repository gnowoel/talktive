import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/message.dart';
import '../models/image_message.dart';
import '../models/text_message.dart';
import '../models/topic_message.dart';
import '../models/chat.dart';
import '../services/simple_paginated_message_service.dart';
import 'image_message_item.dart';
import 'text_message_item.dart';
import 'topic_image_message_item.dart';
import 'topic_text_message_item.dart';
import 'message_separator.dart';
import 'info.dart';

enum MessageListType { chat, topic }

class SimplePaginatedMessageList extends StatefulWidget {
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

  const SimplePaginatedMessageList.chat({
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

  const SimplePaginatedMessageList.topic({
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
  State<SimplePaginatedMessageList> createState() =>
      _SimplePaginatedMessageListState();
}

class _SimplePaginatedMessageListState
    extends State<SimplePaginatedMessageList> {
  SimplePaginatedMessageService? _messageService;

  List<dynamic> _messages = []; // Can be Message or TopicMessage
  bool _isLoading = false;
  bool _hasMore = true;
  bool _isSticky = true;
  bool _initialLoadComplete = false;
  String? _errorMessage;

  // Scroll management
  static const double _scrollThreshold =
      200.0; // Pixels from top to trigger load

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

    final newMessageService =
        Provider.of<SimplePaginatedMessageService>(context);

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
    controller.jumpTo(bottom);
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
    final isAtBottom = position.extentAfter == 0;
    if (isAtBottom != _isSticky && mounted) {
      setState(() {
        _isSticky = isAtBottom;
      });
    }
  }

  void _onServiceUpdated() {
    // Update messages from service state when it changes (for real-time updates)
    if (_initialLoadComplete && mounted) {
      _updateMessagesFromService();
    }
  }

  void _updateMessagesFromService() {
    try {
      List<dynamic> serviceMessages;
      bool serviceHasMore;

      if (widget.type == MessageListType.chat) {
        final state = _messageService?.getChatState(widget.id);
        if (state == null) return;

        serviceMessages = state.messages;
        serviceHasMore = state.hasMore;
      } else {
        final state = _messageService?.getTopicState(widget.id);
        if (state == null) return;

        serviceMessages = state.messages;
        serviceHasMore = state.hasMore;
      }

      // Check if we need to update the UI
      final shouldUpdate = _messages.length != serviceMessages.length ||
          (serviceMessages.isNotEmpty &&
              _messages.isNotEmpty &&
              _getMessageId(serviceMessages.last) !=
                  _getMessageId(_messages.last));

      if (shouldUpdate) {
        final wasAtBottom = _isSticky;
        final hadNewMessages = serviceMessages.length > _messages.length;

        if (mounted) {
          setState(() {
            _messages = List.from(serviceMessages);
            _hasMore = serviceHasMore;
          });
        }

        debugPrint(
            'SimplePaginatedMessageList: Updated from service - ${_messages.length} messages');
        widget.updateMessageCount(_messages.length);

        // Auto-scroll to bottom for new messages if user was at bottom
        if (wasAtBottom && hadNewMessages && mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _scrollToBottom();
          });
        }
      }
    } catch (e) {
      debugPrint('Error updating from service: $e');
    }
  }

  Future<void> _loadInitialMessages() async {
    if (_isLoading) return;

    debugPrint(
        'SimplePaginatedMessageList: Loading initial messages for ${widget.type.name} ${widget.id}');

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
      });

      debugPrint(
          'SimplePaginatedMessageList: Initial load complete - ${_messages.length} messages, hasMore: $_hasMore');
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

    debugPrint(
        'SimplePaginatedMessageList: Loading more messages for ${widget.type.name} ${widget.id}');

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
      });

      debugPrint(
          'SimplePaginatedMessageList: Loaded more messages, total: ${_messages.length}, hasMore: $_hasMore');
      widget.updateMessageCount(_messages.length);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
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
    if (message is Message) {
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
