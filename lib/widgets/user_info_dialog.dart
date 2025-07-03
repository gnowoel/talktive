import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:talktive/helpers/helpers.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../models/user.dart';
import '../services/firestore.dart';
import '../services/follow_cache.dart';
import '../services/server_clock.dart';
import '../services/user_cache.dart';
import '../theme.dart';
import 'tag.dart';

class UserInfoDialog extends StatefulWidget {
  final String photoURL;
  final String displayName;
  final User? user;
  final String? error;
  final bool isFriend;

  const UserInfoDialog({
    super.key,
    required this.photoURL,
    required this.displayName,
    this.user,
    this.error,
    this.isFriend = false,
  });

  @override
  State<UserInfoDialog> createState() => _UserInfoDialogState();
}

class _UserInfoDialogState extends State<UserInfoDialog> {
  late Firestore firestore;
  late UserCache userCache;
  late FollowCache followCache;

  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    firestore = context.read<Firestore>();
    userCache = context.read<UserCache>();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    followCache = Provider.of<FollowCache>(context);
  }

  bool get isNull {
    final other = widget.user;
    return other == null;
  }

  bool get isSelf {
    final self = userCache.user!;
    final other = widget.user;
    return other != null && other.id == self.id;
  }

  bool get isFollowing {
    final other = widget.user;
    return other != null && followCache.isFollowing(other.id);
  }

  Future<void> _followUser() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    final self = userCache.user!;
    final other = widget.user;

    try {
      if (!isNull && !isSelf && !isFollowing) {
        await firestore.followUser(self.id, other!.id);
      }

      if (!mounted) return;
      Navigator.of(context).pop();
    } on AppException catch (e) {
      if (!mounted) return;
      ErrorHandler.showSnackBarMessage(context, e);
    } catch (e) {
      if (!mounted) return;
      ErrorHandler.showSnackBarMessage(
          context, AppException('Failed to follow user: ${e.toString()}'));
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _unfollowUser() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    final self = userCache.user!;
    final other = widget.user;

    try {
      if (!isNull && !isSelf && isFollowing) {
        await firestore.unfollowUser(self.id, other!.id);
      }

      if (!mounted) return;
      Navigator.of(context).pop();
    } on AppException catch (e) {
      if (!mounted) return;
      ErrorHandler.showSnackBarMessage(context, e);
    } catch (e) {
      if (!mounted) return;
      ErrorHandler.showSnackBarMessage(
          context, AppException('Failed to unfollow user: ${e.toString()}'));
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customColors = theme.extension<CustomColors>()!;

    if (widget.user == null) {
      return Dialog(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.photoURL, style: const TextStyle(fontSize: 64)),
              const SizedBox(height: 16),
              Text(
                widget.displayName,
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              if (widget.error == null)
                Padding(
                  padding: const EdgeInsets.only(top: 24, bottom: 8),
                  child: const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  ),
                ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      );
    }

    final now = DateTime.fromMillisecondsSinceEpoch(ServerClock().now);
    final updatedAt = DateTime.fromMillisecondsSinceEpoch(
      widget.user!.updatedAt,
    );
    final userStatus = widget.user!.status;

    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.photoURL, style: const TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isFollowing) ...[
                  Icon(
                    Icons.grade,
                    size: 20,
                    color: customColors.friendIndicator,
                  ),
                  const SizedBox(width: 5),
                ],
                Flexible(
                  child: Text(
                    widget.displayName,
                    style: theme.textTheme.titleLarge,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              widget.user!.description!,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            // Main user info tags
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                Tag(
                  tooltip: '${getLongGenderName(widget.user!.gender!)}',
                  child: Text(
                    widget.user!.gender!,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                Tag(
                  tooltip: '${getLanguageName(widget.user!.languageCode!)}',
                  child: Text(
                    widget.user!.languageCode!,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                Tag(
                  tooltip: 'Level ${widget.user!.level}',
                  child: Text(
                    'L${widget.user!.level}',
                    style: TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Tag(
                  tooltip: 'Last seen',
                  child: Text(
                    timeago.format(updatedAt, locale: 'en_short', clock: now),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                // Show single most relevant status tag (priority-based)
                // Priority order: warning > alert > moderator > very_poor > poor > newcomer > excellent > good
                if (userStatus == 'warning') ...[
                  Tag(status: 'warning'),
                ] else if (userStatus == 'alert') ...[
                  Tag(status: 'alert'),
                ] else if (widget.user!.isModerator &&
                    !widget.user!.isAdmin) ...[
                  Tag(status: 'mod'),
                ] else if (widget.user!.reputationLevel == 'very_poor') ...[
                  Tag(status: 'very_poor'),
                ] else if (widget.user!.reputationLevel == 'poor') ...[
                  Tag(status: 'poor'),
                ] else if (userStatus == 'newcomer') ...[
                  Tag(status: 'newcomer'),
                  // ] else if (widget.user!.reputationLevel == 'excellent') ...[
                  //   Tag(status: 'excellent'),
                  // ] else if (widget.user!.reputationLevel == 'good') ...[
                  //   Tag(status: 'good'),
                ],
              ],
            ),
            const SizedBox(height: 8),
            // Follow counts section
            if (widget.user!.followeeCount != null ||
                widget.user!.followerCount != null) ...[
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (widget.user!.followeeCount != null)
                    Tag(
                      tooltip: 'Following ${widget.user!.followeeCount} users',
                      child: Text(
                        'Following: ${widget.user!.followeeCount}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  if (widget.user!.followerCount != null)
                    Tag(
                      tooltip: '${widget.user!.followerCount} followers',
                      child: Text(
                        'Followers: ${widget.user!.followerCount}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            if (!isSelf && !isFollowing) ...[
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: _isProcessing ? null : _followUser,
                icon: const Icon(Icons.grade),
                label: const Text('Follow'),
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.secondaryContainer,
                  foregroundColor: theme.colorScheme.onSecondaryContainer,
                  elevation: 0,
                ),
              ),
            ] else if (!isSelf && isFollowing) ...[
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: _isProcessing ? null : _unfollowUser,
                icon: const Icon(Icons.grade),
                label: const Text('Unfollow'),
                style: FilledButton.styleFrom(
                  backgroundColor:
                      theme.colorScheme.errorContainer.withValues(alpha: 0.7),
                  foregroundColor: theme.colorScheme.onErrorContainer,
                  elevation: 0,
                ),
              ),
            ],
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
}
