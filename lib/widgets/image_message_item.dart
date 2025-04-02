import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:talktive/widgets/bubble.dart';

import '../helpers/helpers.dart';
import '../models/image_message.dart';
import '../services/fireauth.dart';
import '../services/firedata.dart';
import 'image_viewer.dart';
import 'user_info_loader.dart';

class ImageMessageItem extends StatefulWidget {
  final String chatId;
  final ImageMessage message;
  final String? reporterUserId;

  const ImageMessageItem({
    super.key,
    required this.chatId,
    required this.message,
    this.reporterUserId,
  });

  @override
  State<ImageMessageItem> createState() => _ImageMessageItemState();
}

class _ImageMessageItemState extends State<ImageMessageItem> {
  late Fireauth fireauth;
  late Firedata firedata;
  late CachedNetworkImageProvider _imageProvider;
  late String _imageUrl;

  @override
  void initState() {
    super.initState();
    fireauth = context.read<Fireauth>();
    firedata = context.read<Firedata>();
    _imageUrl = convertUri(widget.message.uri);
    _imageProvider = getCachedImageProvider(widget.message.uri);
  }

  void _showUserInfo(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => UserInfoLoader(
            userId: widget.message.userId,
            photoURL: widget.message.userPhotoURL,
            displayName: widget.message.userDisplayName,
          ),
    );
  }

  void _showContextMenu(BuildContext context, Offset position) {
    final currentUser = fireauth.instance.currentUser!;
    final byMe =
        widget.reporterUserId == null
            ? widget.message.userId == currentUser.uid
            : widget.message.userId == widget.reporterUserId;

    final menuItems = <PopupMenuEntry>[];

    if (byMe && !widget.message.recalled) {
      menuItems.add(
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
      );
    }

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + 1,
        position.dy + 1,
      ),
      items: menuItems,
    );
  }

  void _showRecallDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Recall Image?'),
            content: const Text(
              'This image will be removed from the chat. The action cannot be undone.',
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
    try {
      await firedata.recallMessage(widget.chatId, widget.message.id!);
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
    if (widget.message.recalled) {
      return Bubble(content: '- Image recalled -', byMe: byMe, recalled: true);
    }

    if (byMe) {
      return GestureDetector(
        onLongPressStart:
            (details) => _showContextMenu(context, details.globalPosition),
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

  @override
  Widget build(BuildContext context) {
    final currentUser = fireauth.instance.currentUser!;
    final byMe =
        widget.message.userId == currentUser.uid ||
        widget.message.userId == widget.reporterUserId;

    // Bot messages are always shown on the left
    return byMe
        ? _buildMessageItemRight(context)
        : _buildMessageItemLeft(context);
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
            imageBuilder:
                (context, imageProvider) =>
                    Image(image: imageProvider, fit: BoxFit.contain),
            placeholder:
                (context, url) =>
                    getImagePlaceholder(color: theme.colorScheme.primary),
            // progressIndicatorBuilder:
            //     (context, url, downloadProgress) => getProgressIndicator(
            //       downloadProgress,
            //       color: theme.colorScheme.primary,
            //     ),
            errorWidget: (context, url, error) => getImageErrorWidget(),
            cacheKey: widget.message.uri, // Use original URI as cache key
            // Enable memory caching
            memCacheWidth:
                (halfWidth * MediaQuery.of(context).devicePixelRatio).round(),
            // Set cache refresh strategy
            cacheManager: null, // Use default cache manager
          ),
        ),
      ),
    );
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
                    builder:
                        (context, constrains) =>
                            _buildMessageBox(context, constrains, byMe: true),
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
