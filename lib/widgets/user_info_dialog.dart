import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:talktive/helpers/helpers.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../models/user.dart';
import '../services/firedata.dart';
import '../services/server_clock.dart';
import '../services/user_cache.dart';
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
  late Firedata firedata;
  late UserCache userCache;

  @override
  void initState() {
    super.initState();
    firedata = context.read<Firedata>();
    userCache = context.read<UserCache>();
  }

  Future<void> _addFriend() async {
    final user = widget.user;

    if (user == null) return;

    try {
      final self = userCache.user!;
      await firedata.createFriend(self, user);
      if (!mounted) return;
      Navigator.of(context).pop();
    } on AppException catch (e) {
      if (!mounted) return;
      ErrorHandler.showSnackBarMessage(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                  child: SizedBox(
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
            Text(
              widget.displayName,
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              widget.user!.description!,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
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
                if (userStatus == 'warning') ...[
                  Tag(status: 'warning'),
                ] else if (userStatus == 'alert') ...[
                  Tag(status: 'alert'),
                ] else if (userStatus == 'newcomer') ...[
                  Tag(status: 'newcomer'),
                ],
              ],
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _addFriend,
              child: const Text('Add Friend'),
            ),
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
