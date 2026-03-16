import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../helpers/url_helper.dart';
import 'package:talktive/helpers/duo_trust_score_helper.dart';

/// Duolingo-style avatar with gradient ring and optional mood or floor overlays.
class DuoAvatar extends StatelessWidget {
  final String? imageUrl;
  final double size;
  final int? floorLevel;
  final int? trustScore;
  final String? mood;
  final Color? ringColor;
  final bool showRing;

  /// Whether to show the floor level badge on the avatar itself.
  /// Defaults to false to avoid clutter in chat threads.
  final bool showFloor;

  /// Whether to show the mood emoji overlay on the avatar.
  final bool showMood;

  final bool? isOnline;
  final VoidCallback? onTap;

  const DuoAvatar({
    super.key,
    this.imageUrl,
    this.size = 48,
    this.floorLevel,
    this.trustScore,
    this.mood,
    this.ringColor,
    this.showRing = true,
    this.showFloor = false,
    this.showMood = true,
    this.isOnline,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final widget = _buildAvatar(context);

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(size / 2),
        child: widget,
      );
    }

    return widget;
  }

  Widget _buildAvatar(BuildContext context) {
    final ringWidth = size > 60 ? 3.0 : 2.0;
    final badgeSize = size > 60 ? 24.0 : 18.0;
    final hasImageUrl = imageUrl != null && _isNetworkUrl(imageUrl!);
    final isEmoji = !hasImageUrl && imageUrl != null && imageUrl!.isNotEmpty;
    final avatarText = hasImageUrl
        ? '👤'
        : (imageUrl?.isNotEmpty == true ? imageUrl : '👤');

    // Determine ring color from trustScore or explicit ringColor
    final effectiveRingColor =
        ringColor ??
        (trustScore != null
            ? DuoTrustScoreHelper.getTrustColor(trustScore!)
            : AppTheme.primaryColor);

    Widget avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: hasImageUrl || isEmoji
            ? null
            : LinearGradient(
                colors: [
                  effectiveRingColor,
                  _lightenColor(effectiveRingColor, 0.2),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        color: isEmoji ? Colors.white : null,
        image: hasImageUrl
            ? DecorationImage(
                image: NetworkImage(UrlHelper.resolve(imageUrl!)),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: hasImageUrl
          ? null
          : Center(
              child: Text(
                avatarText ?? '👤',
                style: TextStyle(
                  color: isEmoji ? null : Colors.white,
                  fontSize: isEmoji ? size * 0.55 : size * 0.4,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
    );

    if (showRing) {
      avatar = Container(
        padding: EdgeInsets.all(ringWidth),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [
              effectiveRingColor,
              _lightenColor(effectiveRingColor, 0.2),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Container(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
          padding: EdgeInsets.all(ringWidth),
          child: avatar,
        ),
      );
    }

    final hasFloor = showFloor && floorLevel != null;
    final hasMood = showMood && mood != null && mood!.isNotEmpty;

    if (hasFloor || hasMood) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          avatar,
          if (hasFloor)
            Positioned(
              left: -4,
              bottom: -4,
              child: Container(
                width: badgeSize,
                height: badgeSize,
                decoration: BoxDecoration(
                  color: _getFloorColor(floorLevel!),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
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
                    '$floorLevel',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: badgeSize * 0.5,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ),
            ),
          if (hasMood)
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                width: badgeSize * 1.2,
                height: badgeSize * 1.2,
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
                    mood!,
                    style: TextStyle(fontSize: badgeSize * 0.7),
                  ),
                ),
              ),
            ),
        ],
      );
    }

    if (isOnline != null && isOnline!) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          avatar,
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: size * 0.3,
              height: size * 0.3,
              decoration: BoxDecoration(
                color: AppTheme.duoGreen,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
        ],
      );
    }

    return avatar;
  }

  Color _getFloorColor(int floor) {
    if (floor >= 10) return AppTheme.diamondBadge;
    if (floor >= 7) return AppTheme.goldBadge;
    if (floor >= 4) return AppTheme.silverBadge;
    if (floor >= 2) return AppTheme.bronzeBadge;
    return AppTheme.primaryColor;
  }

  Color _lightenColor(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness + amount).clamp(0.0, 1.0))
        .toColor();
  }

  bool _isNetworkUrl(String value) {
    final uri = Uri.tryParse(value);
    return uri != null &&
        uri.hasScheme &&
        (uri.scheme == 'http' || uri.scheme == 'https');
  }
}
