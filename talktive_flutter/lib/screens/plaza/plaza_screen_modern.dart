import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:talktive_client/talktive_client.dart';
import '../../providers/chat_provider.dart';
import '../../providers/client_provider.dart';
import '../../config/theme.dart';
import '../../widgets/chat/message_bubble.dart';
import '../../widgets/chat/message_input.dart';

/// Modern Plaza screen with glassmorphism and animations
class PlazaScreenModern extends ConsumerStatefulWidget {
  const PlazaScreenModern({super.key});

  @override
  ConsumerState<PlazaScreenModern> createState() => _PlazaScreenModernState();
}

class _PlazaScreenModernState extends ConsumerState<PlazaScreenModern>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();
  Resident? _currentResident;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _loadCurrentResident();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _messageController.dispose();
    _animationController.dispose();
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

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    try {
      await ref.read(chatProvider(1).notifier).sendMessage(content);
      _messageController.clear();
      HapticFeedback.lightImpact();

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
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider(1));

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryColor.withOpacity(0.9),
                AppTheme.secondaryColor.withOpacity(0.9),
              ],
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('🏛️', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 8),
                const Text(
                  'The Plaza',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
            Text(
              'Public chat for all residents',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 12,
              ),
            ),
          ],
        ),
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
          _buildInfoBanner()
              .animate()
              .fadeIn(delay: 100.ms)
              .slideY(begin: -0.1, end: 0),
          Expanded(
            child: chatState.when(
              data: (messages) => _buildMessagesList(messages),
              loading: () => _buildLoadingState(),
              error: (error, stack) => _buildErrorState(error),
            ),
          ),
          MessageInput(
            controller: _messageController,
            onSend: _sendMessage,
            enabled:
                _currentResident != null && _currentResident!.creditScore > 0,
            hintText:
                _currentResident != null && _currentResident!.creditScore <= 0
                ? 'You are muted. Wait for credit restoration...'
                : 'Type a message...',
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
        ],
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      margin: const EdgeInsets.only(top: 100),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.accentColor.withOpacity(0.3),
            AppTheme.accentColor.withOpacity(0.1),
          ],
        ),
        border: Border(
          bottom: BorderSide(color: AppTheme.accentColor.withOpacity(0.3)),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 18,
            color: Colors.white.withOpacity(0.9),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Text only. No images allowed in Plaza.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
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
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.apartment, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            'Floor ${_currentResident!.floor}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.star, size: 14, color: Colors.amber),
          const SizedBox(width: 4),
          Text(
            '${_currentResident!.creditScore}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const CircularProgressIndicator(color: Colors.white),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading messages...',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.white),
            const SizedBox(height: 16),
            const Text(
              'Error loading messages',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.invalidate(chatProvider(1));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppTheme.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessagesList(List<Message> messages) {
    if (messages.isEmpty) {
      return Center(
        child:
            Container(
                  margin: const EdgeInsets.all(24),
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'No messages yet',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Be the first to say hello!',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                )
                .animate()
                .fadeIn(delay: 300.ms)
                .scale(begin: const Offset(0.8, 0.8), duration: 400.ms),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(chatProvider(1));
      },
      color: AppTheme.primaryColor,
      child: ListView.builder(
        controller: _scrollController,
        reverse: true,
        padding: const EdgeInsets.all(16),
        itemCount: messages.length,
        itemBuilder: (context, index) {
          final message = messages[index];
          final isCurrentUser =
              _currentResident != null &&
              message.senderId == _currentResident!.userInfoId;

          return MessageBubble(message: message, isCurrentUser: isCurrentUser)
              .animate()
              .fadeIn(delay: (50 * (index % 5)).ms)
              .slideX(
                begin: isCurrentUser ? 0.2 : -0.2,
                end: 0,
                duration: 200.ms,
              );
        },
      ),
    );
  }
}
