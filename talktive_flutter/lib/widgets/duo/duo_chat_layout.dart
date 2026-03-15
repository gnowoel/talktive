import 'package:flutter/material.dart';
import '../../config/theme.dart';
import 'duo_chat_input.dart';
import 'duo_keyboard_dismissible.dart';

/// A consolidated layout for all chat-like screens in Talktive.
/// Provides consistent background, keyboard dismissal, and input field placement.
class DuoChatLayout extends StatelessWidget {
  /// The main content of the screen (typically a ListView of messages)
  final Widget content;

  /// The input field widget at the bottom
  final Widget? input;

  /// Optional AppBar. If not provided, you might want to use SliverAppBar in content.
  final PreferredSizeWidget? appBar;

  /// Optional background color
  final Color? backgroundColor;

  /// Optional widget to show between AppBar and content (like an InfoBanner)
  final Widget? header;

  const DuoChatLayout({
    super.key,
    required this.content,
    this.input,
    this.appBar,
    this.backgroundColor,
    this.header,
  });

  @override
  Widget build(BuildContext context) {
    return DuoKeyboardDismissible(
      child: Scaffold(
        backgroundColor: backgroundColor ?? AppTheme.lightBackground,
        appBar: appBar,
        body: Column(
          children: [
            if (header != null) header!,
            Expanded(child: content),
            if (input != null) input!,
          ],
        ),
      ),
    );
  }
}

/// A specialized version of DuoChatLayout that simplifies using DuoChatInput.
class DuoChatInputLayout extends StatelessWidget {
  final Widget content;
  final PreferredSizeWidget? appBar;
  final Widget? header;
  final Color? backgroundColor;

  // DuoChatInput parameters
  final TextEditingController controller;
  final VoidCallback onSend;
  final bool enabled;
  final String hintText;
  final VoidCallback? onImagePick;
  final Widget? prefix;
  final Color? activeColor;
  final FocusNode? focusNode;

  const DuoChatInputLayout({
    super.key,
    required this.content,
    required this.controller,
    required this.onSend,
    this.appBar,
    this.header,
    this.backgroundColor,
    this.enabled = true,
    this.hintText = 'Type a message...',
    this.onImagePick,
    this.prefix,
    this.activeColor,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return DuoChatLayout(
      appBar: appBar,
      header: header,
      backgroundColor: backgroundColor,
      content: content,
      input: DuoChatInput(
        controller: controller,
        onSend: onSend,
        enabled: enabled,
        hintText: hintText,
        onImagePick: onImagePick,
        prefix: prefix,
        activeColor: activeColor,
        focusNode: focusNode,
      ),
    );
  }
}
