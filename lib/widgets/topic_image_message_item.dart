import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../helpers/helpers.dart';
import '../models/topic_message.dart';
import '../services/fireauth.dart';
import '../services/firestore.dart';
import 'bubble.dart';
import 'image_viewer.dart';
import 'user_info_loader.dart';

class TopicImageMessageItem extends StatefulWidget {
  final String topicId;
  final TopicImageMessage message;

  const TopicImageMessageItem({
    super.key,
    required this.topicId,
    required this.message,
  });

  @override
  State<TopicImageMessageItem> createState() => _TopicImageMessageItemState();
}

class _TopicImageMessageItemState extends State<TopicImageMessageItem> {
  late Fireauth fireauth;
  late Firestore firestore;
  late CachedNetworkImageProvider _imageProvider;
  late String _imageUrl;

  @override
  void initState() {
    super.initState();
    fireauth = context.read<Fireauth>();
    firestore = context.read<Firestore>();
    _imageUrl = convertUri(widget.message.uri);
    _imageProvider = getCachedImageProvider(widget.message.uri);
  }

  void _showUserInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => UserInfoLoader(
        userId: widget.message.userId,
        photoURL: widget.message.userPhotoURL,
        displayName: widget.message.userDisplayName,
      ),
    );
  }

  void _showContextMenu(BuildContext context, Offset position) {
    final currentUser = fireauth.instance.currentUser!;
    final byMe = widget.message.userId == currentUser.uid;

    if (byMe && !widget.message.recalled!) {
      showMenu(
        context: context,
        position: RelativeRect.fromLTRB(
          position.dx,
          position.dy,
          position.dx + 1,
          position.dy + 1,
        ),
        items: [
          PopupMenuItem(
            child: Row(
              children: const [
                Icon(Icons.replay, size: 20),
                SizedBox(width: 8),
                Text('Recall'),
              ],
            ),
            onTap: () => _showRecallDialog(context),
          ),
        ],
      );
    }
  }

  void _showRecallDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recall Image?'),
        content: const Text(
          'This image will be removed from the topic. The action cannot be undone.',
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: const Text('Recall'),
            onPressed: () {
              Navigator.of(context).pop();
              _recallMessage(context);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _recallMessage(BuildContext context) async {
    if (widget.message.id == null) return;

    try {
      await firestore.recallTopicMessage(
        topicId: widget.topicId,
        messageId: widget.message.id!,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Widget _buildMessageBox(
    BuildContext context,
    BoxConstraints constraints, {
    bool byMe = false,
  }) {
    if (widget.message.recalled!) {
      return Bubble(content: '- Image recalled -', byMe: byMe);
    }

    if (byMe) {
      return GestureDetector(
        onLongPressStart: (details) =>
            _showContextMenu(context, details.globalPosition),
        child: _buildCachedImage(context, constraints),
      );
    }

    return _buildCachedImage(context, constraints);
  }

  void _showImageViewer(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => ImageViewer(imageProvider: _imageProvider),
    );
  }

  Widget _buildCachedImage(BuildContext context, BoxConstraints constraints) {
    final halfWidth = constraints.maxWidth / 2;
    final theme = Theme.of(context);

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: halfWidth, maxHeight: halfWidth),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: GestureDetector(
          onTap: () => _showImageViewer(context),
          child: CachedNetworkImage(
            imageUrl: _imageUrl,
            imageBuilder: (context, imageProvider) =>
                Image(image: imageProvider, fit: BoxFit.contain),
            placeholder: (context, url) =>
                getImagePlaceholder(color: theme.colorScheme.primary),
            errorWidget: (context, url, error) => getImageErrorWidget(),
            cacheKey: widget.message.uri,
            memCacheWidth:
                (halfWidth * MediaQuery.of(context).devicePixelRatio).round(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = fireauth.instance.currentUser!;
    final byMe = widget.message.userId == currentUser.uid;

    return byMe
        ? _buildMessageItemRight(context)
        : _buildMessageItemLeft(context);
  }

  Widget _buildMessageItemLeft(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => _showUserInfo(context),
            child: Tooltip(
              message: widget.message.userDisplayName,
              child: Text(
                widget.message.userPhotoURL,
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Flexible(child: LayoutBuilder(builder: _buildMessageBox)),
              ],
            ),
          ),
          const SizedBox(width: 32),
        ],
      ),
    );
  }

  Widget _buildMessageItemRight(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const SizedBox(width: 32),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: LayoutBuilder(
                    builder: (context, constraints) =>
                        _buildMessageBox(context, constraints, byMe: true),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _showUserInfo(context),
            child: Tooltip(
              message: widget.message.userDisplayName,
              child: Text(
                widget.message.userPhotoURL,
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
