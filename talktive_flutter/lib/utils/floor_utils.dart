import 'dart:math';
import 'package:talktive_client/talktive_client.dart';

/// Utility functions for computing and displaying the Luxury High-Rise Floor.
///
/// Floor = min(BaseFloor, TrustCap)
class FloorUtils {
  FloorUtils._(); // Prevent instantiation

  // ---------------------------------------------------------------------------
  // Core Formula
  // ---------------------------------------------------------------------------

  /// Compute the effective floor for a [resident].
  static int computeFloor(Resident resident) {
    final baseFloor = resident.level;
    final trustCap = _trustCap(resident.trustScore);
    return min(baseFloor, trustCap);
  }

  /// Helper used in some places where we only have the profile view
  static int computeFloorFromProfile(UserProfileView profile) {
    final baseFloor = profile.level ?? 0;
    final trustScore = profile.trustScore;
    return min(baseFloor, _trustCap(trustScore));
  }

  /// Safety/Social pillar: Maps a trustScore to a maximum allowable floor.
  static int _trustCap(int trustScore) {
    if (trustScore >= 1000) return 50;
    if (trustScore >= 500) return 48;
    if (trustScore >= 200) return 45;
    if (trustScore >= 100) return 40;
    if (trustScore >= 75) return 30;
    if (trustScore >= 50) return 15;
    if (trustScore >= 25) return 5;
    if (trustScore >= 10) return 2;
    return 0; // Muted
  }

  // ---------------------------------------------------------------------------
  // XP Helpers (matches GamificationService logic)
  // ---------------------------------------------------------------------------

  /// Calculate the XP needed for the current base floor
  static int xpForBaseFloor(int floor) {
    if (floor <= 1) return 0;
    return (50 * pow(floor - 1, 2)).toInt();
  }

  /// Get the current progress within the actual base level
  static int getXPProgress(Resident resident) {
    final floor = resident.level;
    final xpForCurrent = xpForBaseFloor(floor);
    return max(0, resident.xp - xpForCurrent);
  }

  static int getXPProgressFromProfile(UserProfileView profile) {
    final floor = profile.level ?? 0;
    final xpForCurrent = xpForBaseFloor(floor);
    return max(0, (profile.xp ?? 0) - xpForCurrent);
  }

  /// Get the total XP required to level up to the next base floor from the current base floor
  static int getXPNeeded(Resident resident) {
    final floor = resident.level;
    final xpForCurrent = xpForBaseFloor(floor);
    final xpForNext = xpForBaseFloor(floor + 1);
    return xpForNext - xpForCurrent;
  }

  static int getXPNeededFromProfile(UserProfileView profile) {
    final floor = profile.level ?? 0;
    final xpForCurrent = xpForBaseFloor(floor);
    final xpForNext = xpForBaseFloor(floor + 1);
    return xpForNext - xpForCurrent;
  }

  // ---------------------------------------------------------------------------
  // Display Helpers
  // ---------------------------------------------------------------------------

  /// Human-readable label for a trustScore.
  static String trustStandingLabel(int trustScore) {
    if (trustScore >= 90) return 'Trusted';
    if (trustScore >= 75) return 'Good Standing';
    if (trustScore >= 50) return 'Neutral';
    if (trustScore >= 25) return 'Low Trust';
    if (trustScore >= 10) return 'At Risk';
    return 'Restricted';
  }

  // ---------------------------------------------------------------------------
  // Mute Checks
  // ---------------------------------------------------------------------------

  /// Returns true if the resident is considered muted on the client side.
  static bool isMuted(Resident resident) {
    if (resident.suspended) return true;
    if (resident.trustScore <= 0) return true;
    if (resident.mutedUntil != null &&
        resident.mutedUntil!.isAfter(DateTime.now())) {
      return true;
    }
    return false;
  }

  /// Returns a user-facing mute reason string.
  static String getMuteReason(Resident resident) {
    if (resident.suspended) {
      return 'Your account has been suspended.';
    }
    if (resident.mutedUntil != null &&
        resident.mutedUntil!.isAfter(DateTime.now())) {
      final minutesLeft = resident.mutedUntil!
          .difference(DateTime.now())
          .inMinutes;
      final hoursLeft = (minutesLeft / 60).ceil();
      return '🔇 Muted for $hoursLeft more hour${hoursLeft == 1 ? '' : 's'} '
          'due to community reports.';
    }
    if (resident.trustScore <= 0) {
      return '⭐ Your trust score is too low to send messages. '
          'It restores at 5 points/hour.';
    }
    return '🔇 You are muted.';
  }

  /// Returns a short input hint when muted.
  static String getMuteInputHint(Resident resident) {
    if (resident.suspended) return 'Account suspended';
    if (resident.mutedUntil != null &&
        resident.mutedUntil!.isAfter(DateTime.now())) {
      final minutesLeft = resident.mutedUntil!
          .difference(DateTime.now())
          .inMinutes;
      if (minutesLeft < 60) {
        return '🔇 Muted for $minutesLeft more min';
      }
      final hoursLeft = (minutesLeft / 60).ceil();
      return '🔇 Muted for $hoursLeft more hr${hoursLeft == 1 ? '' : 's'}';
    }
    if (resident.trustScore <= 0) {
      return '⭐ Low trust score — restoring...';
    }
    return '🔇 Muted';
  }
}
