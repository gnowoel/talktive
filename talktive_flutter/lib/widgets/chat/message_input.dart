import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/theme.dart';

/// Modern message input field with glassmorphism design.
class MessageInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final bool enabled;
  final String hintText;
  final VoidCallback? onImagePick;

  const MessageInput({
    super.key,
    required this.controller,
    required this.onSend,
    this.enabled = true,
    this.hintText = 'Type a message...',
    this.onImagePick,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Image picker button (optional)
            if (onImagePick != null)
              IconButton(
                icon: Icon(
                  Icons.image,
                  color: enabled
                      ? AppTheme.primaryColor
                      : AppTheme.textSecondary.withValues(alpha: 0.5),
                ),
                onPressed: enabled ? onImagePick : null,
              ),

            // Text input field
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppTheme.primaryColor.withValues(alpha: 0.2),
                  ),
                ),
                child: TextField(
                  controller: controller,
                  enabled: enabled,
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: hintText,
                    hintStyle: TextStyle(
                      color: AppTheme.textSecondary.withValues(alpha: 0.6),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 15,
                  ),
                  onSubmitted: enabled ? (_) => _handleSend() : null,
                ),
              ),
            ),

            const SizedBox(width: 8),

            // Send button
            Container(
              decoration: BoxDecoration(
                gradient: enabled
                    ? LinearGradient(
                        colors: [
                          AppTheme.primaryColor,
                          AppTheme.secondaryColor,
                        ],
                      )
                    : null,
                color: enabled
                    ? null
                    : AppTheme.textSecondary.withValues(alpha: 0.3),
                shape: BoxShape.circle,
                boxShadow: enabled
                    ? [
                        BoxShadow(
                          color: AppTheme.primaryColor.withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white),
                onPressed: enabled ? _handleSend : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleSend() {
    if (controller.text.trim().isEmpty) return;
    HapticFeedback.lightImpact();
    onSend();
  }
}
