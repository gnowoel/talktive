import 'dart:math';
import 'package:talktive_client/talktive_client.dart';

/// Utility functions for computing and displaying the 3-pillar reputation.
///
/// Reputation = min(Level, min(TrustCap, SocialCap))
class ReputationUtils {
  ReputationUtils._(); // Prevent instantiation

  // ---------------------------------------------------------------------------
  // Core Formula
  // ---------------------------------------------------------------------------

  /// Compute the effective reputation for a [resident].
  static int computeReputation(Resident resident) {
    final xpLevel = resident.level;
    final trustCap = _trustCap(resident.trustScore);
    final socialCap = _socialCap(resident.likeCount);
    return min(xpLevel, min(trustCap, socialCap));
  }

  /// Helper used in some places where we only have the profile map
  static int computeReputationFromProfile(Map<String, dynamic> profile) {
    final xpLevel = profile['level'] as int? ?? 0;
    final trustScore = profile['trustScore'] as int? ?? 100;
    final likeCount = profile['likes'] as int? ?? 0;
    return min(xpLevel, min(_trustCap(trustScore), _socialCap(likeCount)));
  }

  /// Safety pillar: Maps a trustScore (0-100) to a maximum allowable reputation.
  static int _trustCap(int trustScore) {
    if (trustScore >= 90) return 1000;
    if (trustScore >= 75) return 10;
    if (trustScore >= 50) return 5;
    if (trustScore >= 25) return 2;
    if (trustScore >= 10) return 1;
    return 0; // Muted
  }

  /// Social pillar: Maps a like count to a maximum allowable reputation.
  static int _socialCap(int likeCount) {
    if (likeCount >= 10) return 1000;
    if (likeCount >= 5) return 25;
    if (likeCount >= 3) return 15;
    if (likeCount >= 2) return 10;
    if (likeCount >= 1) return 5;
    return 3;
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
    if (resident.trustScore <= 0) {
      return '⭐ Your trust score is too low to send messages. '
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
    if (resident.trustScore <= 0) {
      return '⭐ Low trust score — restoring...';
    }
    return '🔇 Muted';
  }
}
