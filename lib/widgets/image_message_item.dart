import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../helpers/helpers.dart';
import '../models/image_message.dart';
import '../services/fireauth.dart';
import 'user_info_loader.dart';

class ImageMessageItem extends StatefulWidget {
  final ImageMessage message;

  const ImageMessageItem({
    super.key,
    required this.message,
  });

  @override
  State<ImageMessageItem> createState() => _ImageMessageItemState();
}

class _ImageMessageItemState extends State<ImageMessageItem> {
  late ImageProvider _imageProvider;

  @override
  void initState() {
    super.initState();
    _imageProvider = getImageProvder(convertUri(widget.message.uri));
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

  @override
  Widget build(BuildContext context) {
    final fireauth = Provider.of<Fireauth>(context, listen: false);
    final currentUser = fireauth.instance.currentUser!;
    final byMe = widget.message.userId == currentUser.uid;

    // Bot messages are always shown on the left
    return byMe
        ? _buildMessageItemRight(context)
        : _buildMessageItemLeft(context);
  }

  Widget _buildMessageItemLeft(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
                child: LayoutBuilder(builder: (context, constraints) {
                  final halfWidth = constraints.maxWidth / 2;
                  return ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: halfWidth,
                      maxHeight: halfWidth,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Image(
                        fit: BoxFit.contain,
                        image: _imageProvider,
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
        const SizedBox(width: 32),
      ]),
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
                  child: LayoutBuilder(builder: (context, constraints) {
                    final halfWidth = constraints.maxWidth / 2;
                    return ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: halfWidth,
                        maxHeight: halfWidth,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image(
                          fit: BoxFit.contain,
                          image: _imageProvider,
                        ),
                      ),
                    );
                  }),
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
