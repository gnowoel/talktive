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
import '../../utils/floor_utils.dart';
import '../../widgets/chat/message_bubble.dart';

import 'create_group_dialog.dart';
import '../../helpers/snackbar_helper.dart';
import '../../providers/group_provider.dart';
import '../../providers/client_provider.dart';
import '../../widgets/duo/duo_chat_layout.dart';
import '../../widgets/duo/duo_refresh_button.dart';
import '../../services/media_service.dart';

/// Loader for deep linking into GroupChatScreen without the Group model
class GroupChatLoader extends ConsumerWidget {
  final int groupId;
  const GroupChatLoader({super.key, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupAsync = ref.watch(groupWithMembershipProvider(groupId));
    return groupAsync.when(
      data: (membership) {
        if (membership?.group != null) {
          return GroupChatScreen(group: membership!.group);
        }
        return const Scaffold(body: Center(child: Text('Group not found')));
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, s) => Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }
}

/// Group chat screen for multi-user conversations
class GroupChatScreen extends ConsumerStatefulWidget {
  final Group group;

  const GroupChatScreen({super.key, required this.group});

  @override
  ConsumerState<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends ConsumerState<GroupChatScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _messageController.dispose();
    super.dispose();
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
        await _sendMessage(imageUrl: imageUrl);
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

  Future<void> _sendMessage({String? imageUrl}) async {
    final content = _messageController.text.trim();
    if (content.isEmpty && imageUrl == null) {
      return;
    }

    try {
      await ref
          .read(realtimeChatProvider(widget.group.channelId).notifier)
          .sendMessage(content, imageUrl: imageUrl);
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

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(realtimeChatProvider(widget.group.channelId));
    final currentResident = ref.watch(currentResidentProvider).value;
    final canSend =
        currentResident != null && !FloorUtils.isMuted(currentResident);

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
        title: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            context.push(
              '/groups/profile/${widget.group.id!}',
              extra: widget.group,
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
                    widget.group.emoji ?? '👥',
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
                      widget.group.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      '${widget.group.memberCount} members',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          DuoRefreshButton(
            color: Colors.black,
            onRefresh: () {
              ref
                  .read(realtimeChatProvider(widget.group.channelId).notifier)
                  .refresh();
            },
          ),
          IconButton(
            icon: const Icon(Icons.people, color: Colors.black),
            onPressed: () {
              HapticFeedback.lightImpact();
              context.push(
                '/groups/members/${widget.group.id!}',
                extra: widget.group,
              );
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_horiz, color: Colors.black),
            onSelected: (value) async {
              if (value == 'profile') {
                context.push(
                  '/groups/profile/${widget.group.id!}',
                  extra: widget.group,
                );
              } else if (value == 'edit') {
                showDialog(
                  context: context,
                  builder: (context) =>
                      CreateGroupDialog(existingGroup: widget.group),
                );
              } else if (value == 'leave') {
                _confirmLeaveClub(context, ref);
              } else if (value == 'delete') {
                _confirmDeleteClub(context, ref);
              }
            },
            itemBuilder: (_) {
              final isCreator =
                  currentResident?.userInfoId == widget.group.creatorId;
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
                        'Club Info',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                if (isCreator)
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, color: AppTheme.duoBlue, size: 20),
                        SizedBox(width: 12),
                        Text(
                          'Edit Club Info',
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
                          'Leave Club',
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
                          'Disband Club',
                          style: TextStyle(
                            color: AppTheme.duoRed,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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
      activeColor: AppTheme.duoBlue,
      hintText: _isUploading
          ? 'Uploading image...'
          : (canSend
                ? 'Message the club...'
                : FloorUtils.getMuteInputHint(currentResident)),
      content: chatState.when(
        data: (messages) => messages.isEmpty
            ? _buildEmptyState()
            : _buildMessagesList(messages, currentResident),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryColor),
        ),
        error: (error, stack) => _buildErrorState(error),
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
                      AppTheme.duoBlueGradient[0].withValues(alpha: 0.2),
                      AppTheme.duoBlueGradient[1].withValues(alpha: 0.2),
                    ],
                  ),
                ),
                child: Center(
                  child: Text(
                    widget.group.emoji ?? '👥',
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
            'Welcome to ${widget.group.name}!',
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

    final filteredMessages = messages.where((msg) {
      return !blockedUsers.contains(msg.senderId.toString());
    }).toList();

    return RefreshIndicator(
      onRefresh: () async {
        ref
            .read(realtimeChatProvider(widget.group.channelId).notifier)
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
              )
              .animate(delay: Duration(milliseconds: index * 30))
              .fadeIn(duration: 200.ms)
              .slideY(begin: 0.1, end: 0);
        },
      ),
    );
  }

  void _confirmLeaveClub(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave Club?'),
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
        await ref.read(groupListProvider.notifier).leaveGroup(widget.group.id!);
        if (context.mounted) {
          Navigator.pop(context); // Go back to Groups screen
          SnackBarHelper.showSuccess(context, 'You left the club.');
        }
      } catch (e) {
        if (context.mounted) {
          SnackBarHelper.showError(context, e.toString());
        }
      }
    }
  }

  void _confirmDeleteClub(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Disband Club?',
          style: TextStyle(color: AppTheme.duoRed),
        ),
        content: const Text(
          'This will delete the club for everyone and all messages will be lost. This cannot be undone!',
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
        await client.group.deleteGroup(widget.group.id!);
        if (context.mounted) {
          ref.invalidate(groupListProvider);
          Navigator.pop(context);
          SnackBarHelper.showSuccess(context, 'The club has been disbanded.');
        }
      } catch (e) {
        if (context.mounted) {
          SnackBarHelper.showError(context, e.toString());
        }
      }
    }
  }
}
