import 'package:flutter/material.dart';
import 'package:talktive_client/talktive_client.dart';
import '../../config/languages.dart';
import '../../config/theme.dart';
import 'package:talktive/helpers/duo_floor_helper.dart';
import 'duo_card.dart';
import 'duo_avatar.dart';
import 'duo_floor_badge.dart';

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
    // Determine gender symbol
    String? genderSymbol;
    if (resident.gender != null && resident.gender != 'prefer-not-to-say') {
      genderSymbol = switch (resident.gender) {
        'male' => '♂️',
        'female' => '♀️',
        'non-binary' => '⚧️',
        _ => null,
      };
    }

    // Determine age display
    final ageDisplay =
        resident.ageRange != null && resident.ageRange != 'Not Specified'
            ? resident.ageRange
            : null;

    // Determine languages display
    final languages = resident.languages ?? [];
    final languagesDisplay = languages.isNotEmpty
        ? (languages.length > 2
            ? '${languages.take(2).map((c) => AppLanguages.getName(c)).join(', ')} +${languages.length - 2}'
            : languages.map((c) => AppLanguages.getName(c)).join(', '))
        : null;

    return DuoCard(
      onTap: onTap,
      margin: const EdgeInsets.only(bottom: AppTheme.duoSpacingMedium),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                DuoAvatar(
                  imageUrl: resident.customAvatarUrl ?? resident.avatar,
                  placeholderEmoji: resident.avatar,
                  size: 56,
                  showRing: true,
                  showMood: false,
                  showFloor: false,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title Row: Name + Mood + Floor
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              resident.userName ?? 'Resident',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Poppins',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          if (resident.mood != null) ...[
                            const SizedBox(width: 6),
                            Text(resident.mood!,
                                style: const TextStyle(fontSize: 16)),
                          ],
                          const SizedBox(width: 8),
                          DuoFloorBadge(
                              floor: DuoFloorHelper.computeFloor(resident)),
                          const Spacer(),
                          Text(
                            '⭐ ${resident.trustScore}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.duoOrange,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),

                      // Bio on the second line
                      if (resident.bio != null && resident.bio!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            resident.bio!,
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                              fontFamily: 'Rubik',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                      const SizedBox(height: 6),

                      // Metadata Row: Gender/Age · Languages
                      DefaultTextStyle(
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                          fontFamily: 'Rubik',
                        ),
                        child: Row(
                          children: [
                            if (genderSymbol != null || ageDisplay != null) ...[
                              Text([?genderSymbol, ?ageDisplay].join(' ')),
                              if (languagesDisplay != null)
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 6),
                                  child: Text('·'),
                                ),
                            ],
                            if (languagesDisplay != null) ...[
                              const Icon(
                                Icons.language_rounded,
                                size: 13,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  languagesDisplay,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (onTap != null && (actions == null || actions!.isEmpty))
                  const SizedBox(width: 8),
                if (onTap != null && (actions == null || actions!.isEmpty))
                  const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
              ],
            ),
            if (actions != null && actions!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: actions!),
            ],
          ],
        ),
      ),
    );
  }
}
