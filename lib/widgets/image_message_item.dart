import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../helpers/helpers.dart';
import '../models/image_message.dart';
import '../services/fireauth.dart';
import 'image_viewer.dart';
import 'user_info_loader.dart';

class ImageMessageItem extends StatefulWidget {
  final ImageMessage message;
  final String? reporterUserId;

  const ImageMessageItem({
    super.key,
    required this.message,
    this.reporterUserId,
  });

  @override
  State<ImageMessageItem> createState() => _ImageMessageItemState();
}

class _ImageMessageItemState extends State<ImageMessageItem> {
  late CachedNetworkImageProvider _imageProvider;
  late String _imageUrl;

  @override
  void initState() {
    super.initState();
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

  void _showImageViewer(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => ImageViewer(imageProvider: _imageProvider),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fireauth = Provider.of<Fireauth>(context, listen: false);
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
                Flexible(
                  child: LayoutBuilder(
                    builder:
                        (context, constraints) =>
                            _buildCachedImage(context, constraints),
                  ),
                ),
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
                        (context, constraints) =>
                            _buildCachedImage(context, constraints),
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
