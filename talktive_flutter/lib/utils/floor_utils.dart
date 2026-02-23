import 'dart:math';
import 'package:talktive_client/talktive_client.dart';

/// Utility functions for computing and displaying the hybrid effective floor.
///
/// Effective Floor = min(XPLevel, ReputationTier)
///
/// A user must be BOTH active (XP) and trusted (reputation) to achieve a
/// high floor. Spammers can farm XP but lose reputation, which caps their
/// floor and limits who they can interact with.
class FloorUtils {
  FloorUtils._(); // Prevent instantiation

  // ---------------------------------------------------------------------------
  // Core Formula
  // ---------------------------------------------------------------------------

  /// Compute the effective floor for a [resident].
  ///
  /// This is the floor shown everywhere in the UI — on avatar badges,
  /// profile headers, and chat input areas.
  static int effectiveFloor(Resident resident) {
    final xpLevel = resident.level;
    final repTier = reputationTier(resident.reputation);
    return min(xpLevel, repTier);
  }

  /// Maps a reputation score (0–100) to a floor ceiling (tier).
  ///
  /// | Reputation | Max floor |
  /// |---|---|
  /// | 90–100 | 10 (fully trusted) |
  /// | 75–89  | 7  |
  /// | 50–74  | 5  |
  /// | 25–49  | 3  |
  /// | 10–24  | 1  |
  /// | 0–9    | 0  (restricted) |
  static int reputationTier(int reputation) {
    if (reputation >= 90) return 10;
    if (reputation >= 75) return 7;
    if (reputation >= 50) return 5;
    if (reputation >= 25) return 3;
    if (reputation >= 10) return 1;
    return 0;
  }

  // ---------------------------------------------------------------------------
  // Display Helpers
  // ---------------------------------------------------------------------------

  /// Human-readable label for a reputation score.
  static String reputationTierLabel(int reputation) {
    if (reputation >= 90) return 'Trusted';
    if (reputation >= 75) return 'Good Standing';
    if (reputation >= 50) return 'Neutral';
    if (reputation >= 25) return 'Low Trust';
    if (reputation >= 10) return 'At Risk';
    return 'Restricted';
  }

  /// Returns true if the effective floor is being limited by reputation
  /// (i.e., the user has more XP level than reputation tier allows).
  static bool isFloorCapByReputation(Resident resident) {
    final xpLevel = resident.level;
    final repTier = reputationTier(resident.reputation);
    return xpLevel > repTier;
  }

  /// Returns the reputation score needed to unlock the next reputation tier.
  /// Returns null if already at the maximum tier (90+).
  static int? nextReputationThreshold(int reputation) {
    if (reputation < 10) return 10;
    if (reputation < 25) return 25;
    if (reputation < 50) return 50;
    if (reputation < 75) return 75;
    if (reputation < 90) return 90;
    return null; // Already at max tier
  }

  /// Returns the next floor ceiling if the user improves reputation.
  /// Returns null if already at max tier.
  static int? nextReputationFloorUnlock(int reputation) {
    final next = nextReputationThreshold(reputation);
    if (next == null) return null;
    return reputationTier(next);
  }

  /// Returns a user-friendly "floor cap" explanation string.
  static String? floorCapMessage(Resident resident) {
    if (!isFloorCapByReputation(resident)) return null;
    final currentRepTier = reputationTier(resident.reputation);
    final nextThreshold = nextReputationThreshold(resident.reputation);
    if (nextThreshold == null) return null;
    final nextTier = reputationTier(nextThreshold);
    final needed = nextThreshold - resident.reputation;
    return 'Floor limited to $currentRepTier by reputation. '
        'Earn $needed more reputation to unlock Floor $nextTier.';
  }

  // ---------------------------------------------------------------------------
  // Mute Checks (mirrors server-side ApartmentService)
  // ---------------------------------------------------------------------------

  /// Returns true if the resident is considered muted on the client side.
  static bool isMuted(Resident resident) {
    if (resident.suspended) return true;
    if (resident.reputation <= 0) return true;
    if (resident.mutedUntil != null &&
        resident.mutedUntil!.isAfter(DateTime.now()))
      return true;
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
    if (resident.reputation <= 0) {
      return '⭐ Your reputation is too low to send messages. '
          'It restores at 2 points/hour.';
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
    if (resident.reputation <= 0) {
      return '⭐ Low reputation — restoring...';
    }
    return '🔇 Muted';
  }
}
