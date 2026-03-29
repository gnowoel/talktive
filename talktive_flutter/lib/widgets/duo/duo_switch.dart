import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/theme.dart';

class DuoSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Color? activeColor;
  final String? activeEmoji;
  final String? inactiveEmoji;

  const DuoSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.activeColor,
    this.activeEmoji,
    this.inactiveEmoji,
  });

  @override
  Widget build(BuildContext context) {
    final themeColor = activeColor ?? AppTheme.primaryColor;
    final isDisabled = onChanged == null;

    return GestureDetector(
      onTap: isDisabled
          ? null
          : () {
              HapticFeedback.lightImpact();
              onChanged!(!value);
            },
      child: AnimatedContainer(
        duration: AppTheme.duoAnimationQuick,
        width: 54,
        height: 32,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: isDisabled
              ? Colors.grey.shade200
              : value
              ? themeColor
              : Colors.grey.shade300,
          boxShadow: [
            if (!isDisabled && value)
              BoxShadow(
                color: themeColor.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Stack(
          children: [
            AnimatedAlign(
              duration: AppTheme.duoAnimationQuick,
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    value ? (activeEmoji ?? '') : (inactiveEmoji ?? ''),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
