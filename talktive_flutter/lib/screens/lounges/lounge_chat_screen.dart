import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:talktive_client/talktive_client.dart';
import '../../providers/realtime_chat_provider.dart';
import '../../providers/current_resident_provider.dart';
import '../../providers/blocked_users_provider.dart';
import '../../config/theme.dart';
import 'package:talktive/helpers/duo_floor_helper.dart';
import '../../widgets/chat/message_bubble.dart';

import '../../helpers/resident_ext.dart';
import 'create_lounge_dialog.dart';
import 'package:talktive/helpers/duo_snackbar_helper.dart';
import '../../providers/lounge_provider.dart';
import '../../providers/client_provider.dart';
import '../../widgets/duo/duo_chat_layout.dart';
import '../../widgets/duo/duo_refresh_button.dart';
import '../../services/media_service.dart';
import 'package:image_picker/image_picker.dart';
import 'lounge_profile_screen.dart';
import '../../providers/private_chat_provider.dart';

/// Loader for deep linking into LoungeChatScreen without the Lounge model
class LoungeChatLoader extends ConsumerStatefulWidget {
  final int loungeId;
  const LoungeChatLoader({super.key, required this.loungeId});

  @override
  ConsumerState<LoungeChatLoader> createState() => _LoungeChatLoaderState();
}

class _LoungeChatLoaderState extends ConsumerState<LoungeChatLoader> {
  LoungeWithMembership? _membership;
  bool _isLoading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _loadLounge();
  }

  Future<void> _loadLounge() async {
    try {
      final membership =
          await ref.read(loungeWithMembershipProvider(widget.loungeId).future);
      if (mounted) {
        setState(() {
          _membership = membership;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppTheme.duoBlue),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              'Error: $_error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.duoRed),
            ),
          ),
        ),
      );
    }

    if (_membership?.lounge != null) {
      if (_membership!.membershipStatus == ChannelMemberStatus.joined) {
        return LoungeChatScreen(lounge: _membership!.lounge);
      } else {
        return LoungeProfileScreen(
          loungeId: widget.loungeId,
          initialLounge: _membership!.lounge,
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Chat',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
      ),
      body: const Center(
        child: Text(
          'Lounge not found',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      ),
    );
  }
}

/// Lounge chat screen for multi-user conversations
class LoungeChatScreen extends ConsumerStatefulWidget {
  final Lounge lounge;

  const LoungeChatScreen({super.key, required this.lounge});

  @override
  ConsumerState<LoungeChatScreen> createState() => _LoungeChatScreenState();
}

class _LoungeChatScreenState extends ConsumerState<LoungeChatScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isSending = false;
  bool _hasMarkedAsRead = false;

  Future<void> _sendVoiceMessage(String path) async {
    final currentResident = ref.read(currentResidentProvider).value;
    if (currentResident == null) return;

    if (!currentResident.isPremium) {
      DuoSnackBarHelper.showError(
        context,
        'Voice messages are a Premium feature! 🎙️ Upgrade in Settings.',
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      final mediaService = ref.read(mediaServiceProvider);
      final voiceUrl = await mediaService.uploadFile(XFile(path), 'voices');
      
      if (voiceUrl != null) {
        await ref
            .read(realtimeChatProvider(widget.lounge.channelId).notifier)
            .sendMessage(
              mediaUrl: voiceUrl,
              mediaType: 'voice',
            );
        HapticFeedback.lightImpact();
      }
    } catch (e) {
      if (mounted) {
        DuoSnackBarHelper.showError(context, 'Failed to send voice: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _markAsRead();
  }

  Future<void> _markAsRead() async {
    if (!mounted || _hasMarkedAsRead) return;
    
    try {
      final client = ref.read(clientProvider);
      final channelId = widget.lounge.channelId;
      
      await client.message.markChannelAsRead(channelId);
      
      if (mounted) {
        _hasMarkedAsRead = true;
        // Invalidate lists to update unread counts
        ref.invalidate(privateChatListProvider);
        ref.invalidate(loungeListProvider);
      }
    } catch (e) {
      debugPrint('Error marking lounge as read: $e');
    }
  }

  @override
  void dispose() {
    // Final mark as read when leaving - capture client and ID synchronously
    try {
      final client = ref.read(clientProvider);
      final channelId = widget.lounge.channelId;
      // Fire and forget, no longer using 'ref' inside the async part
      client.message.markChannelAsRead(channelId).catchError((e) => debugPrint(e));
    } catch (e) {
      debugPrint('Error in dispose mark read: $e');
    }

    _scrollController.dispose();
    _messageController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _pickAndSendImage() async {
    final mediaService = ref.read(mediaServiceProvider);
    final image = await mediaService.pickImage();
    if (image == null) return;

    setState(() {
      _isSending = true;
    });

    try {
      final imageUrl = await mediaService.uploadFile(image, 'chats');
      if (imageUrl != null) {
        await _sendMessage(imageUrl: imageUrl);
      }
    } catch (e) {
      if (mounted) {
        DuoSnackBarHelper.showError(context, 'Failed to upload image: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  Future<void> _sendMessage({String? imageUrl}) async {
    final content = _messageController.text.trim();
    if (content.isEmpty && imageUrl == null) {
      return;
    }

    setState(() => _isSending = true);
    try {
      await ref
          .read(realtimeChatProvider(widget.lounge.channelId).notifier)
          .sendMessage(
            content: content.isEmpty ? null : content, 
            imageUrl: imageUrl,
          );

      _messageController.clear();
      _hasMarkedAsRead = false; // Allow re-marking as read for new messages
      _markAsRead();
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
        DuoSnackBarHelper.showError(context, e);
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
        // On Web, requesting focus needs to happen after the next frame to work reliably
        Future.delayed(Duration.zero, () {
          if (mounted) _focusNode.requestFocus();
        });
      }
    }
  }

  void _addMention(String userName) {
    final current = _messageController.text;
    if (current.isEmpty || current.endsWith(' ')) {
      _messageController.text = '$current@$userName ';
    } else {
      _messageController.text = '$current @$userName ';
    }
    // Move cursor to end
    _messageController.selection = TextSelection.fromPosition(
      TextPosition(offset: _messageController.text.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Listen for real-time updates to mark as read if user is viewing
    ref.listen(realtimeChatProvider(widget.lounge.channelId), (previous, next) {
      if (previous != null && next.hasValue && next.value != null) {
        final prevLength = previous.value?.messages.length ?? 0;
        final nextLength = next.value?.messages.length ?? 0;
        if (nextLength > prevLength) {
          _hasMarkedAsRead = false; // Reset to allow marking new messages as read
          _markAsRead();
        }
      }
    });

    final chatState = ref.watch(realtimeChatProvider(widget.lounge.channelId));
    final currentResidentAsync = ref.watch(currentResidentProvider);
    final currentResident = currentResidentAsync.value;
    final canSend =
        currentResident != null && !DuoFloorHelper.isMuted(currentResident);

    final typingUsers = chatState.value?.typingUsers ?? {};
    final otherTypingUsers =
        typingUsers.where((u) => u != currentResident?.userName).toList();

    return DuoChatInputLayout(
      typingIndicator: (currentResident?.isPremium == true && otherTypingUsers.isNotEmpty)
          ? _buildTypingIndicator(otherTypingUsers)
          : null,
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
        title: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            context.push(
              '/lounges/profile/${widget.lounge.id!}',
              extra: widget.lounge,
            );
          },
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.duoBlueGradient[0].withValues(alpha: 0.2),
                      AppTheme.duoBlueGradient[1].withValues(alpha: 0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.duoRadiusSmall),
                ),
                child: Center(
                  child: Text(
                    widget.lounge.emoji ?? '👥',
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.lounge.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    Text(
                      '${widget.lounge.memberCount} members',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                        fontFamily: 'Rubik',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.people, color: Colors.black),
            onPressed: () {
              HapticFeedback.lightImpact();
              context.push(
                '/lounges/members/${widget.lounge.id!}',
                extra: widget.lounge,
              );
            },
          ),
          DuoRefreshButton(
            color: Colors.black,
            onRefresh: () {
              ref
                  .read(realtimeChatProvider(widget.lounge.channelId).notifier)
                  .refresh();
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_horiz, color: Colors.black),
            onSelected: (value) async {
              if (value == 'profile') {
                context.push(
                  '/lounges/profile/${widget.lounge.id!}',
                  extra: widget.lounge,
                );
              } else if (value == 'edit') {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) =>
                      CreateLoungeDialog(existingLounge: widget.lounge),
                );
              } else if (value == 'leave') {
                _confirmLeaveLounge(context, ref);
              } else if (value == 'delete') {
                _confirmDeleteLounge(context, ref);
              } else if (value == 'admin_private') {
                _confirmForcePrivate(context, ref);
              } else if (value == 'admin_disband') {
                _confirmAdminDisband(context, ref);
              }
            },
            itemBuilder: (_) {
              final isCreator =
                  currentResident?.userInfoId == widget.lounge.creatorId;
              return [
                const PopupMenuItem(
                  value: 'profile',
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppTheme.duoBlue,
                        size: 20,
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Lounge Info',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                if (isCreator)
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, color: AppTheme.duoBlue, size: 20),
                        SizedBox(width: 12),
                        Text(
                          'Edit Lounge Info',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                if (!isCreator)
                  const PopupMenuItem(
                    value: 'leave',
                    child: Row(
                      children: [
                        Icon(
                          Icons.exit_to_app,
                          color: AppTheme.duoRed,
                          size: 20,
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Leave Lounge',
                          style: TextStyle(
                            color: AppTheme.duoRed,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (isCreator)
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_forever,
                          color: AppTheme.duoRed,
                          size: 20,
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Disband Lounge',
                          style: TextStyle(
                            color: AppTheme.duoRed,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (currentResident?.isStaff ?? false) ...[
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'admin_private',
                    enabled: widget.lounge.isPublic && !widget.lounge.isStaffLocked,
                    child: Row(
                      children: [
                        Icon(
                          Icons.gavel,
                          color: widget.lounge.isStaffLocked
                              ? Colors.grey
                              : AppTheme.duoPurple,
                          size: 20,
                        ),
                        SizedBox(width: 12),
                        Text(
                          widget.lounge.isStaffLocked
                              ? 'Staff Locked'
                              : 'Force Private',
                          style: TextStyle(
                            color: widget.lounge.isStaffLocked
                                ? Colors.grey
                                : AppTheme.duoPurple,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'admin_disband',
                    child: Row(
                      children: [
                        Icon(
                          Icons.gavel_rounded,
                          color: AppTheme.duoRed,
                          size: 20,
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Admin: Disband',
                          style: TextStyle(
                            color: AppTheme.duoRed,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ];
            },
          ),
        ],
      ),
      controller: _messageController,
      onSend: _sendMessage,
      onVoiceSend: _sendVoiceMessage,
      onVoiceStart: () async {
        final currentResident = ref.read(currentResidentProvider).value;
        if (currentResident == null) return false;

        if (!currentResident.isPremium) {
          DuoSnackBarHelper.showError(
            context,
            'Voice messages are a Premium feature! 🎙️ Upgrade in Settings.',
          );
          return false;
        }
        return true;
      },
      onTypingStatusChanged: (isTyping) {
        if (currentResident?.isPremium == true && currentResident?.showTypingIndicator == true) {
          ref
              .read(realtimeChatProvider(widget.lounge.channelId).notifier)
              .setTyping(isTyping);
        }
      },
      onImagePick: _pickAndSendImage,
      enabled: canSend,
      isSending: _isSending,
      isLoading: currentResidentAsync.isLoading,
      focusNode: _focusNode,
      activeColor: AppTheme.duoBlue,
      hintText: canSend
          ? 'Message the lounge...'
          : DuoFloorHelper.getMuteInputHint(currentResident),
      content: chatState.when(
        data: (state) => state.messages.isEmpty
            ? _buildEmptyState()
            : _buildMessagesList(state.messages, currentResident),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryColor),
        ),
        error: (error, stack) => _buildErrorState(error),
      ),
    );
  }

  Widget _buildTypingIndicator(List<String> typingUsers) {
    if (typingUsers.isEmpty) return const SizedBox.shrink();

    final text = typingUsers.length == 1
        ? '${typingUsers[0]} is typing...'
        : '${typingUsers[0]} and ${typingUsers.length - 1} others typing...';

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.duoSpacingLarge,
        vertical: 4,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: const Text('✍️', style: TextStyle(fontSize: 14)),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                duration: 600.ms,
                begin: const Offset(0.8, 0.8),
                end: const Offset(1.1, 1.1),
              ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
              fontStyle: FontStyle.italic,
              fontFamily: 'Rubik',
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.2, end: 0);
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
                      AppTheme.duoBlueGradient[0].withValues(alpha: 0.2),
                      AppTheme.duoBlueGradient[1].withValues(alpha: 0.2),
                    ],
                  ),
                ),
                child: Center(
                  child: Text(
                    widget.lounge.emoji ?? '👥',
                    style: const TextStyle(fontSize: 40),
                  ),
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
            'Welcome to ${widget.lounge.name}!',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppTheme.duoSpacingSmall),
          Text(
            'Be the first to send a message',
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

  Widget _buildMessagesList(List<Message> messages, Resident? currentResident) {
    final blockedUsersAsync = ref.watch(blockedUsersProvider);
    final blockedUsers = blockedUsersAsync.value ?? [];
    
    // Get member names for mention highlighting
    final membersAsync = ref.watch(loungeMembersProvider(widget.lounge.id!));
    final memberNames = membersAsync.when(
      data: (members) => members.map((m) => m.userName ?? '').where((n) => n.isNotEmpty).toList(),
      loading: () => <String>[],
      error: (_, _) => <String>[],
    );

    final filteredMessages = messages.where((msg) {
      return !blockedUsers.contains(msg.senderId.toString());
    }).toList();

    return RefreshIndicator(
      onRefresh: () async {
        ref
            .read(realtimeChatProvider(widget.lounge.channelId).notifier)
            .refresh();
      },
      color: AppTheme.primaryColor,
      child: ListView.builder(
        controller: _scrollController,
        reverse: true,
        padding: const EdgeInsets.all(AppTheme.duoSpacingMedium),
        itemCount: filteredMessages.length,
        itemBuilder: (context, index) {
          final message = filteredMessages[index];
          final isCurrentUser =
              currentResident != null &&
              message.senderId == currentResident.userInfoId;

          return MessageBubble(
                message: message,
                isCurrentUser: isCurrentUser,
                currentResident: currentResident,
                onMention: _addMention,
                otherMemberNames: memberNames,
              )
              .animate(delay: Duration(milliseconds: index * 30))
              .fadeIn(duration: 200.ms)
              .slideY(begin: 0.1, end: 0);
        },
      ),
    );
  }

  void _confirmLeaveLounge(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave Lounge?'),
        content: const Text('Are you sure you want to leave this community?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.duoRed),
            child: const Text('Leave'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      HapticFeedback.mediumImpact();
      try {
        await ref.read(loungeListProvider.notifier).leaveLounge(widget.lounge.id!);
        if (context.mounted) {
          Navigator.pop(context); // Go back to Lounges screen
          DuoSnackBarHelper.showSuccess(context, 'You left the lounge.');
        }
      } catch (e) {
        if (context.mounted) {
          DuoSnackBarHelper.showError(context, e.toString());
        }
      }
    }
  }

  void _confirmDeleteLounge(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Disband Lounge?',
          style: TextStyle(color: AppTheme.duoRed),
        ),
        content: const Text(
          'This will delete the lounge for everyone and all messages will be lost. This cannot be undone!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.duoRed),
            child: const Text('DISBAND'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      HapticFeedback.heavyImpact();
      try {
        final client = ref.read(clientProvider);
        await client.lounge.deleteLounge(widget.lounge.id!);
        if (context.mounted) {
          ref.invalidate(loungeListProvider);
          Navigator.pop(context);
          DuoSnackBarHelper.showSuccess(context, 'The lounge has been disbanded.');
        }
      } catch (e) {
        if (context.mounted) {
          DuoSnackBarHelper.showError(context, e.toString());
        }
      }
    }
  }
  void _confirmForcePrivate(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Admin Action: Force Private?'),
        content: const Text(
          'This will force the lounge to become private and lock it. The creator will NOT be able to make it public again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.duoOrange),
            child: const Text('FORCE PRIVATE'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      HapticFeedback.mediumImpact();
      try {
        final client = ref.read(clientProvider);
        await client.admin.makeLoungePrivate(widget.lounge.id!);
        if (context.mounted) {
          ref.invalidate(loungeListProvider);
          DuoSnackBarHelper.showSuccess(
            context,
            'Lounge has been forced to private.',
          );
          Navigator.pop(context); // Optional: leave screen or refresh
        }
      } catch (e) {
        if (context.mounted) {
          DuoSnackBarHelper.showError(context, e.toString());
        }
      }
    }
  }

  void _confirmAdminDisband(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Admin Action: Disband Lounge?',
          style: TextStyle(color: AppTheme.duoRed),
        ),
        content: const Text(
          'As an administrator, you are deleting this lounge permanently for all members. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.duoRed),
            child: const Text('DISBAND PERMANENTLY'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      HapticFeedback.heavyImpact();
      try {
        final client = ref.read(clientProvider);
        await client.admin.disbandLounge(
          loungeId: widget.lounge.id!,
          reason: 'Administrative action',
        );
        if (context.mounted) {
          ref.invalidate(loungeListProvider);
          Navigator.pop(context); // Go back to Lounges screen
          DuoSnackBarHelper.showSuccess(context, 'Lounge has been disbanded.');
        }
      } catch (e) {
        if (context.mounted) {
          DuoSnackBarHelper.showError(context, e.toString());
        }
      }
    }
  }
}
