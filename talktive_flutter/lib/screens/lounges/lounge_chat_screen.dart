import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:talktive_client/talktive_client.dart';
import '../../providers/realtime_chat_provider.dart';
import '../../providers/current_resident_provider.dart';
import '../../providers/social_relationships_provider.dart';
import '../../config/theme.dart';
import 'package:talktive/helpers/duo_floor_helper.dart';
import '../../widgets/chat/message_bubble.dart';
import '../../widgets/chat/pinned_message_bar.dart';

import '../../helpers/duo_upgrade_helper.dart';
import '../../helpers/resident_ext.dart';
import 'create_lounge_dialog.dart';
import 'package:talktive/helpers/duo_snackbar_helper.dart';
import '../../providers/lounge_provider.dart';
import '../../providers/client_provider.dart';
import '../../widgets/duo/duo_chat_layout.dart';
import '../../widgets/duo/duo_refresh_button.dart';
import '../../widgets/duo/duo_typing_indicator.dart';
import 'lounge_profile_screen.dart';
import '../../providers/private_chat_provider.dart';
import '../../utils/ad_navigation_utils.dart';
import '../../widgets/chat/chat_screen_mixin.dart';

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
      final membership = await ref.read(
        loungeWithMembershipProvider(widget.loungeId).future,
      );
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

class _LoungeChatScreenState extends ConsumerState<LoungeChatScreen>
    with ChatScreenMixin {
  bool _hasMarkedAsRead = false;
  bool _isExiting = false;

  @override
  int get channelId => widget.lounge.channelId;

  void _showUpgradePrompt(String feature) {
    DuoUpgradeHelper.showUpgradePrompt(context, feature);
  }

  @override
  void initState() {
    super.initState();
    _loungeMarkAsRead();
  }

  Future<void> _loungeMarkAsRead() async {
    if (!mounted || _hasMarkedAsRead) return;

    try {
      final client = ref.read(clientProvider);
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
  Widget build(BuildContext context) {
    // Listen for real-time updates to mark as read if user is viewing
    ref.listen(realtimeChatProvider(channelId), (previous, next) {
      if (previous != null && next.hasValue && next.value != null) {
        final prevLength = previous.value?.messages.length ?? 0;
        final nextLength = next.value?.messages.length ?? 0;
        if (nextLength > prevLength) {
          _hasMarkedAsRead =
              false; // Reset to allow marking new messages as read
          _loungeMarkAsRead();
        }
      }
    });

    final chatState = ref.watch(realtimeChatProvider(channelId));
    final currentResidentAsync = ref.watch(currentResidentProvider);
    final currentResident = currentResidentAsync.value;
    final canSend =
        currentResident != null && !DuoFloorHelper.isMuted(currentResident);

    final typingUsers = chatState.value?.typingUsers ?? {};
    final otherTypingUsers = typingUsers
        .where((u) => u != currentResident?.userName)
        .toList();

    // Get member names for mention highlighting and autocompletion
    final membersAsync = ref.watch(loungeMembersProvider(widget.lounge.id!));
    final memberNames = membersAsync.when(
      data: (members) => members
          .map((m) => m.userName ?? '')
          .where((n) => n.isNotEmpty)
          .toList(),
      loading: () => <String>[],
      error: (_, _) => <String>[],
    );

    return PopScope(
      canPop: _isExiting,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (context.mounted) {
          setState(() => _isExiting = true);
          await context.popWithAd(ref);
        }
      },
      child: DuoChatInputLayout(
        typingIndicator:
            (currentResident?.isPlus == true && otherTypingUsers.isNotEmpty)
            ? DuoTypingIndicator(typingUsers: otherTypingUsers)
            : null,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () {
              HapticFeedback.lightImpact();
              context.popWithAd(ref);
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
                    borderRadius: BorderRadius.circular(
                      AppTheme.duoRadiusSmall,
                    ),
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
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
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
              icon: const Icon(Icons.people, size: 24, color: Colors.black),
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
                ref.read(realtimeChatProvider(channelId).notifier).refresh();
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
                  PopupMenuItem(
                    value: 'profile',
                    child: Row(
                      children: [
                        Icon(Icons.info, size: 20, color: AppTheme.textPrimary),
                        const SizedBox(width: 12),
                        Text('Lounge Profile'),
                      ],
                    ),
                  ),
                  if (isCreator)
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          const Icon(
                            Icons.edit,
                            size: 20,
                            color: AppTheme.textPrimary,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Edit Lounge',
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
                      enabled:
                          widget.lounge.isPublic &&
                          !widget.lounge.isStaffLocked,
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
                          Icon(Icons.gavel, color: AppTheme.duoRed, size: 20),
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
        header: (chatState.value?.pinnedMessage != null)
            ? PinnedMessageBar(
                message: chatState.value!.pinnedMessage!,
                onUnpin:
                    (currentResident?.isStaff ?? false) ||
                        (currentResident?.userInfoId == widget.lounge.creatorId)
                    ? () => ref
                          .read(realtimeChatProvider(channelId).notifier)
                          .unpinMessage(chatState.value!.pinnedMessage!.id!)
                    : null,
              )
            : null,
        controller: messageController,
        onSend: sendMessage,
        onVoiceSend: sendVoiceMessage,
        onVoiceStart: () async {
          final currentResident = ref.read(currentResidentProvider).value;
          if (currentResident == null) return false;

          if (!currentResident.isPlus) {
            _showUpgradePrompt('Voice Messages');
            return false;
          }

          if (!currentResident.showVoiceMessages) {
            DuoSnackBarHelper.showWarning(
              context,
              'Enable voice messages in Settings! 🎙️',
            );
            return false;
          }
          return true;
        },
        onTypingStatusChanged: handleTypingStatus,
        onImagePick: () async {
          pickAndSendImage(floorRestriction: 2);
        },
        mentionsWhitelist: memberNames,
        enabled: canSend,
        isSending: isSending,
        isLoading: currentResidentAsync.isLoading,
        focusNode: focusNode,
        activeColor: AppTheme.duoBlue,
        hintText: canSend
            ? 'Message the lounge...'
            : DuoFloorHelper.getMuteInputHint(currentResident),
        content: chatState.when(
          data: (state) => state.messages.isEmpty
              ? _buildEmptyState()
              : _buildMessagesList(state, currentResident, memberNames),
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryColor),
          ),
          error: (error, stack) => _buildErrorState(error),
        ),
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

  Widget _buildMessagesList(
    RealtimeChatState state,
    Resident? currentResident,
    List<String> memberNames,
  ) {
    final messages = state.messages;
    final socialState = ref.watch(socialRelationshipsStateProvider).value;
    final blockedUsers = socialState?.blockedUserIds ?? [];

    final filteredMessages = messages.where((msg) {
      return !blockedUsers.contains(msg.senderId.toString());
    }).toList();

    return RefreshIndicator(
      onRefresh: () async {
        ref.read(realtimeChatProvider(channelId).notifier).refresh();
      },
      color: AppTheme.primaryColor,
      child: ListView.builder(
        controller: scrollController,
        reverse: true,
        padding: const EdgeInsets.all(AppTheme.duoSpacingMedium),
        itemCount: filteredMessages.length + (state.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == filteredMessages.length) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: state.isLoadingMore
                    ? const CircularProgressIndicator(strokeWidth: 2)
                    : state.hasMore
                    ? const Text(
                        'Scroll for more messages',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      )
                    : const SizedBox.shrink(),
              ),
            );
          }

          final message = filteredMessages[index];
          final isCurrentUser =
              currentResident != null &&
              message.senderId == currentResident.userInfoId;

          return MessageBubble(
                key: ValueKey(message.id),
                message: message,
                isCurrentUser: isCurrentUser,
                currentResident: currentResident,
                onMention: (name) {
                  final current = messageController.text;
                  if (current.isEmpty || current.endsWith(' ')) {
                    messageController.text = '$current@$name ';
                  } else {
                    messageController.text = '$current @$name ';
                  }
                  messageController.selection = TextSelection.fromPosition(
                    TextPosition(offset: messageController.text.length),
                  );
                  focusNode.requestFocus();
                },
                otherMemberNames: memberNames,
                canPin:
                    (currentResident?.isStaff ?? false) ||
                    (currentResident?.userInfoId == widget.lounge.creatorId),
                canRecall:
                    isCurrentUser ||
                    (currentResident?.isStaff ?? false) ||
                    (currentResident?.userInfoId == widget.lounge.creatorId),
              )
              .animate(delay: Duration(milliseconds: index * 10))
              .fadeIn(duration: 200.ms)
              .slideX(begin: isCurrentUser ? 0.1 : -0.1, end: 0);
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
        await ref
            .read(loungeListProvider.notifier)
            .leaveLounge(widget.lounge.id!);
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
          DuoSnackBarHelper.showSuccess(
            context,
            'The lounge has been disbanded.',
          );
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
