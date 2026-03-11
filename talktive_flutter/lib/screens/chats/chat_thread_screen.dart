import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:talktive_client/talktive_client.dart';
import '../../widgets/duo/duo_chat_layout.dart';
import '../../providers/realtime_chat_provider.dart';
import '../../providers/current_resident_provider.dart';
import '../../config/theme.dart';
import '../../helpers/snackbar_helper.dart';
import '../../utils/floor_utils.dart';
import '../../widgets/duo/duo_avatar.dart';
import '../../widgets/chat/message_bubble.dart';
import '../../widgets/duo/duo_refresh_button.dart';
import '../../services/media_service.dart';
import '../../providers/private_chat_provider.dart';

/// Chat thread screen for private 1-on-1 conversations
class ChatThreadScreen extends ConsumerStatefulWidget {
  final int channelId;

  const ChatThreadScreen({
    super.key,
    required this.channelId,
  });

  @override
  ConsumerState<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends ConsumerState<ChatThreadScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();
  Resident? _currentResident;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentResident();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentResident() async {
    final residentAsync = ref.read(currentResidentProvider);
    if (residentAsync.hasValue) {
      setState(() {
        _currentResident = residentAsync.value;
      });
    }
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) {
      return;
    }

    await _sendMessageInternal(content: content);
  }

  Future<void> _sendMessageInternal({String? content, String? imageUrl}) async {
    try {
      if (imageUrl != null) {
        await ref
            .read(realtimeChatProvider(widget.channelId).notifier)
            .sendMessage(content ?? '', imageUrl: imageUrl);
      } else if (content != null) {
        await ref
            .read(realtimeChatProvider(widget.channelId).notifier)
            .sendMessage(content);
      }
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
            content: Text('Failed to send message: $e'),
            backgroundColor: AppTheme.duoRed,
          ),
        );
      }
    }
  }

  Future<void> _pickAndSendImage() async {
    final mediaService = ref.read(mediaServiceProvider);
    final image = await mediaService.pickImage();
    if (image == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      final imageUrl = await mediaService.uploadFile(image, 'chats');
      if (imageUrl != null) {
        await _sendMessageInternal(imageUrl: imageUrl);
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(context, 'Failed to upload image: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatDetailsAsync = ref.watch(privateChatDetailsProvider(widget.channelId));

    return chatDetailsAsync.when(
      data: (details) {
        final privateChat = details.chat;
        final otherResident = details.otherResident;
        final otherName = details.otherUserName ?? 'Resident';
        final otherAvatar = details.otherUserAvatar;
        final otherFloor = FloorUtils.computeFloor(otherResident);
        final otherMood = details.otherUserMood;
    
        final chatState = ref.watch(
          realtimeChatProvider(widget.channelId),
        );

        final canSend = _currentResident != null && !FloorUtils.isMuted(_currentResident!);
        final hintText = (_currentResident != null && FloorUtils.isMuted(_currentResident!))
            ? FloorUtils.getMuteInputHint(_currentResident!)
            : 'Type a message...';

    return DuoChatInputLayout(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
        ),
        title: Row(
          children: [
            DuoAvatar(
              imageUrl: otherAvatar,
              size: 36,
              mood: otherMood,
              showRing: true,
              floorLevel: otherFloor,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    otherName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    'Online', // TODO: Implement real presence status
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppTheme.duoGreen),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          DuoRefreshButton(
            color: Colors.black,
            onRefresh: () {
              ref.read(realtimeChatProvider(widget.channelId).notifier).refresh();
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onSelected: (value) async {
              if (value == 'leave') {
                 final confirm = await showDialog<bool>(
                   context: context,
                   builder: (ctx) => AlertDialog(
                     title: const Text('Leave Chat?'),
                     content: const Text('Are you sure you want to leave this chat? You won\'t be able to receive messages until you\'re invited back.'),
                     actions: [
                       TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
                       TextButton(
                         onPressed: () => Navigator.pop(ctx, true), 
                         child: const Text('Leave', style: TextStyle(color: AppTheme.duoRed)),
                       ),
                     ],
                   )
                 );
                 if (confirm == true && mounted) {
                    try {
                      await ref.read(privateChatListProvider.notifier).leaveChat(widget.channelId);
                      if (mounted) {
                        Navigator.pop(context); // Go back to chats list
                      }
                    } catch (e) {
                      if (mounted) SnackBarHelper.showError(context, 'Failed to leave chat');
                    }
                 }
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem<String>(
                  value: 'leave',
                  child: Row(
                    children: [
                      Icon(Icons.exit_to_app, color: AppTheme.duoRed, size: 20),
                      SizedBox(width: 8),
                      Text('Leave Chat', style: TextStyle(color: AppTheme.duoRed)),
                    ],
                  ),
                ),
              ];
            },
          ),
        ],
      ),
      controller: _messageController,
      onSend: _sendMessage,
      onImagePick: _pickAndSendImage,
      enabled: canSend && !_isUploading,
      activeColor: AppTheme.duoOrange,
      hintText: _isUploading ? 'Sending image...' : hintText,
      content: chatState.when(
        data: (messages) => messages.isEmpty
            ? _buildEmptyState()
            : _buildMessagesList(messages),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryColor),
        ),
        error: (error, stack) => _buildErrorState(error),
      ),
    );
        },
      loading: () => Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(title: const Text('Loading Chat...'), elevation: 0, backgroundColor: Colors.white),
        body: const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
      ),
      error: (e, stack) => Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(title: const Text('Error'), elevation: 0, backgroundColor: Colors.white),
        body: Center(child: Column(
           mainAxisAlignment: MainAxisAlignment.center,
           children: [
             const Icon(Icons.error_outline, color: AppTheme.duoRed, size: 48),
             const SizedBox(height: 16),
             Text('Failed to load chat: $e', style: const TextStyle(color: Colors.grey), textAlign: TextAlign.center),
             TextButton(
               onPressed: () => ref.invalidate(privateChatDetailsProvider(widget.channelId)), 
               child: const Text('Retry')
             ),
           ],
        )),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.accentColor.withValues(alpha: 0.2),
                      AppTheme.primaryColor.withValues(alpha: 0.2),
                    ],
                  ),
                ),
                child: const Center(
                  child: Text('👋', style: TextStyle(fontSize: 40)),
                ),
              )
              .animate(onPlay: (controller) => controller.repeat())
              .scale(
                duration: 2000.ms,
                begin: const Offset(1.0, 1.0),
                end: const Offset(1.1, 1.1),
                curve: Curves.easeInOut,
              )
              .then()
              .scale(
                duration: 2000.ms,
                begin: const Offset(1.1, 1.1),
                end: const Offset(1.0, 1.0),
                curve: Curves.easeInOut,
              ),
          const SizedBox(height: AppTheme.duoSpacingLarge),
          Text(
            'Start the conversation',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppTheme.duoSpacingSmall),
          Text(
            'Say hello and break the ice!',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: AppTheme.duoRed),
          const SizedBox(height: AppTheme.duoSpacingMedium),
          Text(
            'Failed to load messages',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppTheme.duoSpacingSmall),
          Text(
            error.toString(),
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList(List<Message> messages) {
    return RefreshIndicator(
      onRefresh: () async {
        ref
            .read(realtimeChatProvider(widget.channelId).notifier)
            .refresh();
      },
      color: AppTheme.primaryColor,
      child: ListView.builder(
        controller: _scrollController,
        reverse: true,
        padding: const EdgeInsets.all(AppTheme.duoSpacingMedium),
        itemCount: messages.length,
        itemBuilder: (context, index) {
          final message = messages[index];
          final isCurrentUser =
              _currentResident != null &&
              message.senderId == _currentResident!.userInfoId;

          return MessageBubble(
                message: message,
                isCurrentUser: isCurrentUser,
                currentResident: _currentResident,
              )
              .animate(delay: Duration(milliseconds: index * 30))
              .fadeIn(duration: 200.ms)
              .slideY(begin: 0.1, end: 0);
        },
      ),
    );
  }


}
