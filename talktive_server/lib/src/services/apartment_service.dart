import 'package:serverpod/serverpod.dart';
import 'dart:math';
import '../generated/protocol.dart';

/// Apartment Service
/// Handles trustScore (safety/moderation) system and the
/// Hybrid Floor formula.
class ApartmentService {
  // Reputation Constants
  static const int TRUST_SCORE_MAX = 100;
  static const int TRUST_SCORE_START = 100;
  static const int REPUTATION_RESTORE_RATE = 2; // points per hour

  // ---------------------------------------------------------------------------
  // 3-PILLAR REPUTATION FORMULA
  // ---------------------------------------------------------------------------

  /// Compute the user's overall Reputation.
  ///
  /// Reputation = min(Level, min(TrustCap, SocialCap))
  ///
  /// This means a user must be BOTH active (Level), trusted (Trust Score), and
  /// appreciated by the community (Likes) to achieve a high reputation.
  static int computeReputation(Resident resident) {
    final xpLevel = resident.level; // already = floor(xp / 100)
    final trustCap = _trustCap(resident.trustScore);
    final socialCap = _socialCap(resident.likeCount);
    return min(xpLevel, min(trustCap, socialCap));
  }

  /// Safety pillar: Maps a trustScore (0-100) to a maximum allowable reputation.
  static int _trustCap(int trustScore) {
    if (trustScore >= 90) return 1000; // No practical cap
    if (trustScore >= 75) return 10;
    if (trustScore >= 50) return 5;
    if (trustScore >= 25) return 2;
    if (trustScore >= 10) return 1;
    return 0; // Muted
  }

  /// Social pillar: Maps a like count to a maximum allowable reputation.
  static int _socialCap(int likeCount) {
    if (likeCount >= 10) return 1000; // No practical cap
    if (likeCount >= 5) return 25;
    if (likeCount >= 3) return 15;
    if (likeCount >= 2) return 10;
    if (likeCount >= 1) return 5;
    return 3;
  }

  /// Returns a human-readable label for the trustScore standing.
  static String trustStandingLabel(int trustScore) {
    if (trustScore >= 90) return 'Trusted';
    if (trustScore >= 75) return 'Good Standing';
    if (trustScore >= 50) return 'Neutral';
    if (trustScore >= 25) return 'Low Trust';
    if (trustScore >= 10) return 'At Risk';
    return 'Restricted';
  }

  // ---------------------------------------------------------------------------
  // REPUTATION RESTORATION
  // ---------------------------------------------------------------------------

  /// Restore trustScore passively (2 pts/hour, max 100).
  static Future<void> restoreReputation(
    Session session,
    Resident resident,
  ) async {
    final now = DateTime.now();
    final lastIncrease = resident.lastReputationIncrease ?? now;
    final hoursPassed = now.difference(lastIncrease).inHours;

    if (hoursPassed >= 1 && resident.trustScore < TRUST_SCORE_MAX) {
      final points = hoursPassed * REPUTATION_RESTORE_RATE;
      resident.trustScore = (resident.trustScore + points).clamp(
        0,
        TRUST_SCORE_MAX,
      );
      resident.lastReputationIncrease = lastIncrease.add(
        Duration(hours: hoursPassed),
      );
      await Resident.db.updateRow(session, resident);
      session.log(
        'Restored $points trustScore to ${resident.userInfoId}. '
        'New trustScore: ${resident.trustScore}',
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
    if (resident.trustScore <= 0) return true;
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
    if (resident.trustScore <= 0) {
      return 'Your trustScore is too low to send messages. It restores automatically at 2 points per hour.';
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
    return computeReputation(receiver) <= computeReputation(sender);
  }

  /// Returns the reason canInvite returned false, for user-facing messages.
  static String cannotInviteReason({
    required Resident sender,
    required Resident receiver,
  }) {
    if (isMuted(sender)) return getMuteReason(sender);
    final senderReputation = computeReputation(sender);
    final receiverReputation = computeReputation(receiver);
    return 'You have a Reputation of $senderReputation and cannot invite someone with Reputation $receiverReputation. '
        'Increase your Level, Trust Score, or Likes to reach a higher Reputation.';
  }

  // ---------------------------------------------------------------------------
  // REPORTING
  // ---------------------------------------------------------------------------

  /// Apply a trustScore penalty to [target] when reported by [reporter].
  /// Penalty scales with the reporter's effective floor (credibility).
  static void applyReportPenalty({
    required Resident reporter,
    required Resident target,
  }) {
    // Use effective floor so that low-trustScore reporters do less damage
    final penalty = max(1, computeReputation(reporter));
    target.trustScore = max(0, target.trustScore - penalty);
  }

  // ---------------------------------------------------------------------------
  // HELPERS
  // ---------------------------------------------------------------------------

  /// Clamp trustScore to valid range [0, TRUST_SCORE_MAX].
  static int clampReputation(int trustScore) {
    return trustScore.clamp(0, TRUST_SCORE_MAX);
  }
}
