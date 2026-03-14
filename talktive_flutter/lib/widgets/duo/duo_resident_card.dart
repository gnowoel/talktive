import 'package:flutter/material.dart';
import 'package:talktive_client/talktive_client.dart';
import '../../config/theme.dart';
import 'package:talktive_flutter/helpers/duo_floor_helper.dart';
import 'duo_card.dart';
import 'duo_avatar.dart';

/// Duolingo-style card for displaying a resident's summary information.
class DuoResidentCard extends StatelessWidget {
  final Resident resident;
  final String? subtitle;
  final List<Widget>? actions;
  final VoidCallback? onTap;
  final bool showBadge;
  final String? badgeText;
  final Color? badgeColor;
  final bool isHost;

  const DuoResidentCard({
    super.key,
    required this.resident,
    this.subtitle,
    this.actions,
    this.onTap,
    this.showBadge = false,
    this.badgeText,
    this.badgeColor,
    this.isHost = false,
  });

  @override
  Widget build(BuildContext context) {
    return DuoCard(
      onTap: onTap,
      margin: const EdgeInsets.only(bottom: AppTheme.duoSpacingMedium),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.duoSpacingMedium),
        child: Column(
          children: [
            Row(
              children: [
                DuoAvatar(
                  imageUrl: resident.avatar,
                  size: 48,
                  mood: resident.mood,
                  floorLevel: DuoFloorHelper.computeFloor(resident),
                  showRing: true,
                ),
                const SizedBox(width: AppTheme.duoSpacingMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              resident.userName ?? 'Resident',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Poppins',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          if (isHost) ...[
                            const SizedBox(width: 8),
                            _buildTag(
                              'HOST',
                              Colors.orange,
                              AppTheme.duoYellow,
                            ),
                          ],
                          if (showBadge && badgeText != null) ...[
                            const SizedBox(width: 8),
                            _buildTag(
                              badgeText!,
                              badgeColor ?? AppTheme.primaryColor,
                              (badgeColor ?? AppTheme.primaryColor).withValues(
                                alpha: 0.1,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle ??
                            'Floor ${DuoFloorHelper.computeFloor(resident)} • ⭐ ${resident.trustScore}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                          fontFamily: 'Rubik',
                        ),
                      ),
                    ],
                  ),
                ),
                if (onTap != null && (actions == null || actions!.isEmpty))
                  const Icon(Icons.chevron_right, color: AppTheme.textLight),
              ],
            ),
            if (actions != null && actions!.isNotEmpty) ...[
              const SizedBox(height: AppTheme.duoSpacingMedium),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: actions!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String text, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: textColor,
          fontFamily: 'Poppins',
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
