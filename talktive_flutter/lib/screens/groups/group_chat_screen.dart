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

import 'create_group_dialog.dart';
import 'package:talktive/helpers/duo_snackbar_helper.dart';
import '../../providers/group_provider.dart';
import '../../providers/client_provider.dart';
import '../../widgets/duo/duo_chat_layout.dart';
import '../../widgets/duo/duo_refresh_button.dart';
import '../../services/media_service.dart';
import 'group_profile_screen.dart';
import '../../providers/private_chat_provider.dart';

/// Loader for deep linking into GroupChatScreen without the Group model
class GroupChatLoader extends ConsumerStatefulWidget {
  final int groupId;
  const GroupChatLoader({super.key, required this.groupId});

  @override
  ConsumerState<GroupChatLoader> createState() => _GroupChatLoaderState();
}

class _GroupChatLoaderState extends ConsumerState<GroupChatLoader> {
  GroupWithMembership? _membership;
  bool _isLoading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _loadGroup();
  }

  Future<void> _loadGroup() async {
    try {
      final membership =
          await ref.read(groupWithMembershipProvider(widget.groupId).future);
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

    if (_membership?.group != null) {
      if (_membership!.membershipStatus == ChannelMemberStatus.joined) {
        return GroupChatScreen(group: _membership!.group);
      } else {
        return GroupProfileScreen(
          groupId: widget.groupId,
          initialGroup: _membership!.group,
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
          'Group not found',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      ),
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
  final Set<UuidValue> _mentionedUserIds = {};
  bool _isUploading = false;
  bool _hasMarkedAsRead = false;

  @override
  void initState() {
    super.initState();
    _markAsRead();
  }

  Future<void> _markAsRead() async {
    if (!mounted || _hasMarkedAsRead) return;
    
    try {
      final client = ref.read(clientProvider);
      final channelId = widget.group.channelId;
      
      await client.message.markChannelAsRead(channelId);
      
      if (mounted) {
        _hasMarkedAsRead = true;
        // Invalidate lists to update unread counts
        ref.invalidate(privateChatListProvider);
        ref.invalidate(groupListProvider);
      }
    } catch (e) {
      debugPrint('Error marking group as read: $e');
    }
  }

  @override
  void dispose() {
    // Final mark as read when leaving - capture client and ID synchronously
    try {
      final client = ref.read(clientProvider);
      final channelId = widget.group.channelId;
      // Fire and forget, no longer using 'ref' inside the async part
      client.message.markChannelAsRead(channelId).catchError((e) => debugPrint(e));
    } catch (e) {
      debugPrint('Error in dispose mark read: $e');
    }

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
        DuoSnackBarHelper.showError(context, 'Failed to upload image: $e');
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
      // Filter out only the mentions that are actually still in the text
      final stillMentioned = _mentionedUserIds.where((id) {
        return content.contains('@');
      }).toList();

      await ref
          .read(realtimeChatProvider(widget.group.channelId).notifier)
          .sendMessage(
            content, 
            imageUrl: imageUrl,
            mentionedUserIds: stillMentioned.isNotEmpty ? stillMentioned : null,
          );

      _messageController.clear();
      _mentionedUserIds.clear();
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
    }
  }

  void _addMention(String userName, UuidValue id) {
    _mentionedUserIds.add(id);
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
    ref.listen(realtimeChatProvider(widget.group.channelId), (previous, next) {
      if (previous != null && next.hasValue && next.value != null) {
        final prevLength = previous.value?.length ?? 0;
        final nextLength = next.value?.length ?? 0;
        if (nextLength > prevLength) {
          _hasMarkedAsRead = false; // Reset to allow marking new messages as read
          _markAsRead();
        }
      }
    });

    final chatState = ref.watch(realtimeChatProvider(widget.group.channelId));
    final currentResident = ref.watch(currentResidentProvider).value;
    final canSend =
        currentResident != null && !DuoFloorHelper.isMuted(currentResident);

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
                        fontFamily: 'Poppins',
                      ),
                    ),
                    Text(
                      '${widget.group.memberCount} members',
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
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
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
                : DuoFloorHelper.getMuteInputHint(currentResident)),
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
    
    // Get member names for mention highlighting
    final membersAsync = ref.watch(groupMembersProvider(widget.group.id!));
    final memberNames = membersAsync.when(
      data: (members) => members.map((m) => m.userName ?? '').where((n) => n.isNotEmpty).toList(),
      loading: () => <String>[],
      error: (_, __) => <String>[],
    );

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
          DuoSnackBarHelper.showSuccess(context, 'You left the club.');
        }
      } catch (e) {
        if (context.mounted) {
          DuoSnackBarHelper.showError(context, e.toString());
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
          DuoSnackBarHelper.showSuccess(context, 'The club has been disbanded.');
        }
      } catch (e) {
        if (context.mounted) {
          DuoSnackBarHelper.showError(context, e.toString());
        }
      }
    }
  }
}
