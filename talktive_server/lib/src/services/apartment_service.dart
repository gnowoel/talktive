import 'package:serverpod/serverpod.dart';
import 'dart:math';
import '../generated/protocol.dart';

/// Apartment Service
/// Handles reputation (safety/moderation) system and the
/// Hybrid Floor formula.
class ApartmentService {
  // Reputation Constants
  static const int REPUTATION_MAX = 100;
  static const int REPUTATION_START = 100;
  static const int REPUTATION_RESTORE_RATE = 2; // points per hour

  // ---------------------------------------------------------------------------
  // HYBRID FLOOR FORMULA
  // ---------------------------------------------------------------------------

  /// Compute the user's effective floor.
  ///
  /// Effective Floor = min(XP Level, Reputation Tier)
  ///
  /// This means a user must be BOTH active (XP) and trusted (reputation) to
  /// achieve a high floor. Spammers can earn XP but lose reputation, which
  /// caps their floor and limits who they can invite.
  static int effectiveFloor(Resident resident) {
    final xpLevel = resident.level; // already = floor(xp / 100)
    final repTier = _reputationTier(resident.reputation);
    return min(xpLevel, repTier);
  }

  /// Maps a reputation score (0–100) to a floor ceiling (tier).
  ///
  /// Reputation ranges  →  Max floor allowed
  ///   90–100  →  10  (fully trusted, no practical cap)
  ///   75–89   →  7
  ///   50–74   →  5
  ///   25–49   →  3
  ///   10–24   →  1
  ///    0–9    →  0   (cannot send invites)
  static int _reputationTier(int reputation) {
    if (reputation >= 90) return 10;
    if (reputation >= 75) return 7;
    if (reputation >= 50) return 5;
    if (reputation >= 25) return 3;
    if (reputation >= 10) return 1;
    return 0;
  }

  /// Returns a human-readable label for the reputation tier.
  static String reputationTierLabel(int reputation) {
    if (reputation >= 90) return 'Trusted';
    if (reputation >= 75) return 'Good Standing';
    if (reputation >= 50) return 'Neutral';
    if (reputation >= 25) return 'Low Trust';
    if (reputation >= 10) return 'At Risk';
    return 'Restricted';
  }

  // ---------------------------------------------------------------------------
  // REPUTATION RESTORATION
  // ---------------------------------------------------------------------------

  /// Restore reputation passively (2 pts/hour, max 100).
  static Future<void> restoreReputation(
    Session session,
    Resident resident,
  ) async {
    final now = DateTime.now();
    final lastIncrease = resident.lastReputationIncrease ?? now;
    final hoursPassed = now.difference(lastIncrease).inHours;

    if (hoursPassed >= 1 && resident.reputation < REPUTATION_MAX) {
      final points = hoursPassed * REPUTATION_RESTORE_RATE;
      resident.reputation = (resident.reputation + points).clamp(
        0,
        REPUTATION_MAX,
      );
      resident.lastReputationIncrease = lastIncrease.add(
        Duration(hours: hoursPassed),
      );
      await Resident.db.updateRow(session, resident);
      session.log(
        'Restored $points reputation to ${resident.userInfoId}. '
        'New reputation: ${resident.reputation}',
      );
    } else if (resident.lastReputationIncrease == null) {
      resident.lastReputationIncrease = now;
      await Resident.db.updateRow(session, resident);
    }
  }

  // ---------------------------------------------------------------------------
  // MUTE / SUSPENSION
  // ---------------------------------------------------------------------------

  /// Returns true if the user is currently muted for any reason.
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
      return 'You are temporarily muted for $hoursLeft more hour${hoursLeft == 1 ? '' : 's'} due to multiple reports.';
    }
    if (resident.reputation <= 0) {
      return 'Your reputation is too low to send messages. It restores automatically at 2 points per hour.';
    }
    return 'You are muted.';
  }

  // ---------------------------------------------------------------------------
  // INVITE / SOCIAL RULES
  // ---------------------------------------------------------------------------

  /// Returns true if [sender] is allowed to invite [receiver] to a chat.
  ///
  /// Rules:
  ///   1. Sender must not be muted or suspended.
  ///   2. Receiver's effective floor must be ≤ sender's effective floor.
  ///      (You can only invite those on your floor or below — apartment rule.)
  static bool canInvite({
    required Resident sender,
    required Resident receiver,
  }) {
    if (isMuted(sender)) return false;
    return effectiveFloor(receiver) <= effectiveFloor(sender);
  }

  /// Returns the reason canInvite returned false, for user-facing messages.
  static String cannotInviteReason({
    required Resident sender,
    required Resident receiver,
  }) {
    if (isMuted(sender)) return getMuteReason(sender);
    final senderFloor = effectiveFloor(sender);
    final receiverFloor = effectiveFloor(receiver);
    return 'You are on Floor $senderFloor and cannot invite someone on Floor $receiverFloor. '
        'Increase your reputation or XP to reach a higher floor.';
  }

  // ---------------------------------------------------------------------------
  // REPORTING
  // ---------------------------------------------------------------------------

  /// Apply a reputation penalty to [target] when reported by [reporter].
  /// Penalty scales with the reporter's effective floor (credibility).
  static void applyReportPenalty({
    required Resident reporter,
    required Resident target,
  }) {
    // Use effective floor so that low-reputation reporters do less damage
    final penalty = max(1, effectiveFloor(reporter));
    target.reputation = max(0, target.reputation - penalty);
  }

  // ---------------------------------------------------------------------------
  // HELPERS
  // ---------------------------------------------------------------------------

  /// Clamp reputation to valid range [0, REPUTATION_MAX].
  static int clampReputation(int reputation) {
    return reputation.clamp(0, REPUTATION_MAX);
  }
}
