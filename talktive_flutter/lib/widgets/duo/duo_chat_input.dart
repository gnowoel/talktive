import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/theme.dart';

/// Duolingo-style chat input with a pill-shaped design and vibrant send button.
class DuoChatInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final bool enabled;
  final String hintText;
  final VoidCallback? onImagePick;
  final Widget? prefix;
  final Color? activeColor;
  final FocusNode? focusNode;
  final bool isSending;
  final bool isLoading;

  const DuoChatInput({
    super.key,
    required this.controller,
    required this.onSend,
    this.enabled = true,
    this.isSending = false,
    this.isLoading = false,
    this.hintText = 'Type a message...',
    this.onImagePick,
    this.prefix,
    this.activeColor,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    final themeColor = activeColor ?? AppTheme.primaryColor;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.duoSpacingMedium,
        vertical: AppTheme.duoSpacingSmall,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (prefix != null) ...[
              prefix!,
              const SizedBox(width: AppTheme.duoSpacingSmall),
            ],

            // Image picker button (optional)
            if (onImagePick != null)
              GestureDetector(
                onTap: (enabled && !isSending && !isLoading) ? onImagePick : null,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.lightBackground,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Icon(
                    Icons.add_a_photo,
                    size: 20,
                    color: (enabled && !isSending && !isLoading) ? themeColor : AppTheme.textLight,
                  ),
                ),
              ),

            if (onImagePick != null)
              const SizedBox(width: AppTheme.duoSpacingSmall),

            // Text input field
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.lightBackground,
                  borderRadius: BorderRadius.circular(AppTheme.duoRadiusPill),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  enabled: enabled,
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  style: const TextStyle(
                    fontSize: 15,
                    fontFamily: 'Rubik',
                    color: AppTheme.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: _effectiveHintText,
                    hintStyle: const TextStyle(
                      color: AppTheme.textLight,
                      fontFamily: 'Rubik',
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.duoSpacingMedium,
                      vertical: AppTheme.duoSpacingSmall,
                    ),
                  ),
                  onSubmitted: (enabled && !isSending && !isLoading) ? (_) => _handleSend() : null,
                ),
              ),
            ),

            const SizedBox(width: AppTheme.duoSpacingSmall),

            // Send button
            GestureDetector(
              onTap: (enabled && !isSending && !isLoading) ? _handleSend : null,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: (enabled && !isSending && !isLoading)
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            themeColor,
                            themeColor.withValues(alpha: 0.8),
                          ],
                        )
                      : null,
                  color: (enabled && !isSending && !isLoading) ? null : Colors.grey.shade300,
                  shape: BoxShape.circle,
                  boxShadow: (enabled && !isSending && !isLoading)
                      ? [
                          BoxShadow(
                            color: themeColor.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: const Icon(Icons.send, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _effectiveHintText {
    if (isLoading) return 'Loading profile...';
    if (isSending) return 'Sending...';
    return hintText;
  }

  void _handleSend() {
    if (isSending || isLoading || controller.text.trim().isEmpty) return;
    HapticFeedback.lightImpact();
    onSend();
  }
}
