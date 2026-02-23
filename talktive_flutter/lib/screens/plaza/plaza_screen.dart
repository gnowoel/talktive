import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:talktive_client/talktive_client.dart';
import '../../providers/realtime_chat_provider.dart';
import '../../providers/client_provider.dart';
import '../../config/theme.dart';
import '../../utils/floor_utils.dart';
import '../../widgets/chat/message_bubble.dart';
import '../../widgets/chat/message_input.dart';

/// Plaza screen - The public chat room (Floor 0) where everyone can chat.
class PlazaScreen extends ConsumerStatefulWidget {
  const PlazaScreen({super.key});

  @override
  ConsumerState<PlazaScreen> createState() => _PlazaScreenState();
}

class _PlazaScreenState extends ConsumerState<PlazaScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();
  Resident? _currentResident;

  @override
  void initState() {
    super.initState();
    _loadCurrentResident();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentResident() async {
    try {
      final client = ref.read(clientProvider);
      final resident = await client.resident.getResident();
      if (mounted) {
        setState(() {
          _currentResident = resident;
        });
      }
    } catch (e) {
      print('Error loading resident: $e');
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      // Load more messages when near bottom
      ref.read(realtimeChatProvider(1).notifier).loadMore();
    }
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    try {
      await ref.read(realtimeChatProvider(1).notifier).sendMessage(content);
      _messageController.clear();
      HapticFeedback.lightImpact();

      // Scroll to top to show new message
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(realtimeChatProvider(1));

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🏛️ The Plaza',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            Text(
              'Public chat for all residents',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 2,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
        actions: [
          if (_currentResident != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(child: _buildStatusChip()),
            ),
        ],
      ),
      body: Column(
        children: [
          // Info banner
          _buildInfoBanner(),

          // Messages list
          Expanded(
            child: chatState.when(
              data: (messages) => _buildMessagesList(messages),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: AppTheme.errorColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading messages',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        ref.read(realtimeChatProvider(1).notifier).refresh();
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Message input
          MessageInput(
            controller: _messageController,
            onSend: _sendMessage,
            enabled:
                _currentResident != null &&
                !FloorUtils.isMuted(_currentResident!),
            hintText:
                _currentResident != null &&
                    FloorUtils.isMuted(_currentResident!)
                ? FloorUtils.getMuteInputHint(_currentResident!)
                : 'Type a message...',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(color: AppTheme.primaryColor.withOpacity(0.2)),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: AppTheme.primaryColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Text only. No images allowed in Plaza.',
              style: TextStyle(color: AppTheme.primaryColor, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip() {
    if (_currentResident == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withOpacity(0.8),
            AppTheme.secondaryColor.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.apartment, size: 16, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            'Floor ${FloorUtils.effectiveFloor(_currentResident!)}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.star, size: 16, color: Colors.amber),
          const SizedBox(width: 4),
          Text(
            '${_currentResident!.reputation}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList(List<Message> messages) {
    if (messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.6),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chat_bubble_outline,
                size: 64,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No messages yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first to say hello!',
              style: TextStyle(fontSize: 16, color: AppTheme.textSecondary),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(realtimeChatProvider(1).notifier).refresh();
      },
      child: ListView.builder(
        controller: _scrollController,
        reverse: true, // Show newest at bottom
        padding: const EdgeInsets.all(16),
        itemCount: messages.length,
        itemBuilder: (context, index) {
          final message = messages[index];
          final isCurrentUser =
              _currentResident != null &&
              message.senderId == _currentResident!.userInfoId;

          return MessageBubble(message: message, isCurrentUser: isCurrentUser);
        },
      ),
    );
  }
}
