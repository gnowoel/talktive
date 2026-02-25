import 'package:flutter/material.dart';
import '../../config/theme.dart';

/// Duolingo-style avatar with gradient ring and optional floor badge
class DuoAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? initials;
  final double size;
  final int? floorLevel;
  final Color? ringColor;
  final bool showRing;
  final VoidCallback? onTap;

  const DuoAvatar({
    super.key,
    this.imageUrl,
    this.initials,
    this.size = 48,
    this.floorLevel,
    this.ringColor,
    this.showRing = true,
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
        ? initials
        : (imageUrl?.isNotEmpty == true ? imageUrl : initials);

    Widget avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: hasImageUrl || isEmoji
            ? null
            : LinearGradient(
                colors: [
                  ringColor ?? AppTheme.primaryColor,
                  _lightenColor(ringColor ?? AppTheme.primaryColor, 0.2),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        color: isEmoji ? Colors.white : null,
        image: hasImageUrl
            ? DecorationImage(image: NetworkImage(imageUrl!), fit: BoxFit.cover)
            : null,
      ),
      child: hasImageUrl
          ? null
          : Center(
              child: Text(
                avatarText ?? '?',
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
              ringColor ?? AppTheme.primaryColor,
              _lightenColor(ringColor ?? AppTheme.primaryColor, 0.2),
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

    if (floorLevel != null) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          avatar,
          Positioned(
            right: -4,
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
                    color: Colors.black.withOpacity(0.1),
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
