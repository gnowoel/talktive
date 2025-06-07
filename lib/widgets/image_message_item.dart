import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:talktive/widgets/bubble.dart';

import '../helpers/helpers.dart';
import '../helpers/message_status_helper.dart';
import '../models/image_message.dart';
import '../services/fireauth.dart';
import '../services/firedata.dart';
import '../services/firestore.dart';
import '../services/user_cache.dart';
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
  late ThemeData theme;
  late Fireauth fireauth;
  late Firedata firedata;
  late Firestore firestore;
  late UserCache userCache;
  late CachedNetworkImageProvider _imageProvider;
  late String _imageUrl;
  bool _isRevealed = false;

  @override
  void initState() {
    super.initState();
    fireauth = context.read<Fireauth>();
    firedata = context.read<Firedata>();
    firestore = context.read<Firestore>();
    _imageUrl = convertUri(widget.message.uri);
    _imageProvider = getCachedImageProvider(widget.message.uri);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    theme = Theme.of(context);
    userCache = Provider.of<UserCache>(context);
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
    final byMe = widget.reporterUserId == null
        ? widget.message.userId == currentUser.uid
        : widget.message.userId == widget.reporterUserId;
    final isUserWithoutAlert =
        userCache.user != null && !userCache.user!.withAlert;

    final menuItems = <PopupMenuEntry>[];

    // Always show Copy option
    menuItems.add(
      PopupMenuItem(
        child: Row(
          children: const [
            Icon(Icons.copy, size: 20),
            SizedBox(width: 8),
            Text('Copy'),
          ],
        ),
        onTap: () => _copyToClipboard(context),
      ),
    );

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

    if (!byMe && isUserWithoutAlert && MessageStatusHelper.shouldShowReportOption(widget.message, byMe)) {
      menuItems.add(
        PopupMenuItem(
          child: Row(
            children: const [
              Icon(Icons.report, size: 20),
              SizedBox(width: 8),
              Text('Report'),
            ],
          ),
          onTap: () => _showReportDialog(context),
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
      builder: (context) => AlertDialog(
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

  void _showReportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.report_outlined,
          color: theme.colorScheme.error,
          size: 32,
        ),
        title: const Text('Report this message?'),
        content: const Text(
          'If you believe this is an inappropriate message, you can report it for review. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: Text(
              'Report',
              style: TextStyle(color: theme.colorScheme.error),
            ),
            onPressed: () {
              Navigator.of(context).pop();
              _reportMessage(context);
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

  Future<void> _reportMessage(BuildContext context) async {
    try {
      final currentUser = fireauth.instance.currentUser!;

      // No need to wait, show snack bar message immediately
      firestore.reportMessage(
        chatId: widget.chatId,
        messageId: widget.message.id!,
        reporterUserId: currentUser.uid,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: theme.colorScheme.errorContainer,
            content: Text(
              'Thank you for your report. We will review it shortly.',
              style: TextStyle(color: theme.colorScheme.onErrorContainer),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Future<void> _copyToClipboard(BuildContext context) async {
    // Capture the BuildContext before the async gap
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    String contentToCopy;
    if (widget.message.recalled) {
      contentToCopy = '- Image recalled -';
    } else {
      contentToCopy = MessageStatusHelper.getCopyContent(widget.message, widget.message.content);
    }

    await Clipboard.setData(ClipboardData(text: contentToCopy));
    if (!mounted) return;

    scaffoldMessenger.showSnackBar(
      const SnackBar(
        content: Text('Image description copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Widget _buildMessageBox(
    BuildContext context,
    BoxConstraints constraints, {
    bool byMe = false,
  }) {
    if (widget.message.recalled) {
      return Bubble(content: '- Image recalled -', byMe: byMe, recalled: true);
    }

    // Check if message should be shown based on report status
    final shouldShow = MessageStatusHelper.shouldShowMessage(
      widget.message,
      isAdmin: false, // TODO: Add admin check if needed
    );

    // Determine what content to display
    Widget contentWidget;
    bool isHidden = false;

    if (shouldShow) {
      contentWidget = _buildCachedImage(context, constraints);
    } else if (MessageStatusHelper.isHiddenButRevealable(widget.message)) {
      isHidden = true;
      if (_isRevealed) {
        contentWidget = _buildCachedImage(context, constraints);
      } else {
        final hiddenContent = MessageStatusHelper.getHiddenMessageContent(widget.message);
        contentWidget = Bubble(content: hiddenContent, byMe: byMe, recalled: true);
      }
    } else {
      final hiddenContent = MessageStatusHelper.getHiddenMessageContent(widget.message);
      contentWidget = Bubble(content: hiddenContent, byMe: byMe, recalled: true);
    }

    // Handle tap to reveal for hidden messages
    if (isHidden && widget.reporterUserId == null) {
      return GestureDetector(
        onTap: () {
          setState(() {
            _isRevealed = !_isRevealed;
          });
        },
        onLongPressStart: (details) =>
            _showContextMenu(context, details.globalPosition),
        child: contentWidget,
      );
    } else if (widget.reporterUserId == null && byMe) {
      return GestureDetector(
        onLongPressStart: (details) =>
            _showContextMenu(context, details.globalPosition),
        child: contentWidget,
      );
    }

    return contentWidget;
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
    final byMe = widget.message.userId == currentUser.uid ||
        widget.message.userId == widget.reporterUserId;

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
            imageBuilder: (context, imageProvider) =>
                Image(image: imageProvider, fit: BoxFit.contain),
            placeholder: (context, url) =>
                getImagePlaceholder(color: theme.colorScheme.primary),
            errorWidget: (context, url, error) => getImageErrorWidget(),
            cacheKey: widget.message.uri,
            memCacheWidth:
                (halfWidth * MediaQuery.of(context).devicePixelRatio).round(),
            cacheManager: null,
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
                    builder: (context, constrains) =>
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
