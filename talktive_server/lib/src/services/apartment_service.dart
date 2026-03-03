// ignore_for_file: constant_identifier_names
import 'package:serverpod/serverpod.dart';
import 'dart:math';
import '../generated/protocol.dart';

/// Apartment Service
/// Handles trustScore (safety/moderation) system and the
/// Hybrid Floor formula.
class ApartmentService {
  // Trust Score Constants
  static const int TRUST_SCORE_START = 100;
  static const int REPUTATION_RESTORE_RATE = 5; // points per hour

  // ---------------------------------------------------------------------------
  // THE LUXURY HIGH-RISE FORMULA
  // ---------------------------------------------------------------------------

  /// Compute the user's Effective Floor.
  ///
  /// Effective Floor = min(BaseFloor, TrustCap)
  ///
  /// This means a user must be BOTH active (BaseFloor) and trusted by the
  /// community (Trust Score) to achieve a high floor in the 50-story building.
  static int computeEffectiveFloor(Resident resident) {
    final baseFloor = resident.level;
    final trustCap = _trustCap(resident.trustScore);
    return min(baseFloor, trustCap);
  }

  /// Safety/Social pillar: Maps a trustScore to a maximum allowable floor.
  /// Base Trust is 100.
  /// Reports are -30. Likes are +10.
  static int _trustCap(int trustScore) {
    if (trustScore >= 1000) return 50; // The Penthouse (~90 net likes)
    if (trustScore >= 500) return 48; // (~40 net likes)
    if (trustScore >= 200) return 45; // (~10 net likes)
    if (trustScore >= 100) return 40; // Default max with no reports
    if (trustScore >= 75) return 30; // 1 report
    if (trustScore >= 50) return 15; // 2 reports
    if (trustScore >= 25) return 5; // 3 reports
    if (trustScore >= 10) return 2; // 4 reports
    return 0; // Muted
  }

  // ---------------------------------------------------------------------------
  // TRUST SCORE RESTORATION
  // ---------------------------------------------------------------------------

  /// Restore trustScore passively (5 pts/hour) ONLY up to 100.
  /// Returns true if changes were made to the resident object.
  static Future<bool> restoreTrustScore(
    Session session,
    Resident resident, {
    bool save = true,
  }) async {
    final now = DateTime.now();
    final lastIncrease = resident.lastReputationIncrease ?? now;
    final hoursPassed = now.difference(lastIncrease).inHours;

    if (hoursPassed >= 1 && resident.trustScore < 100) {
      final points = hoursPassed * REPUTATION_RESTORE_RATE;
      resident.trustScore = min(resident.trustScore + points, 100);

      resident.lastReputationIncrease = lastIncrease.add(
        Duration(hours: hoursPassed),
      );
      if (save) {
        await Resident.db.updateRow(session, resident);
      }
      session.log(
        'Restored $points trustScore to ${resident.userInfoId}. '
        'New trustScore: ${resident.trustScore}',
      );
      return true;
    } else if (resident.lastReputationIncrease == null) {
      resident.lastReputationIncrease = now;
      if (save) {
        await Resident.db.updateRow(session, resident);
      }
      return true;
    }
    return false;
  }

  // ---------------------------------------------------------------------------
  // MUTE / SUSPENSION
  // ---------------------------------------------------------------------------

  /// Returns true if the user is currently muted for any reason.
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
    return computeEffectiveFloor(receiver) <= computeEffectiveFloor(sender);
  }

  /// Returns the reason canInvite returned false, for user-facing messages.
  static String cannotInviteReason({
    required Resident sender,
    required Resident receiver,
  }) {
    if (isMuted(sender)) return getMuteReason(sender);
    final senderReputation = computeEffectiveFloor(sender);
    final receiverReputation = computeEffectiveFloor(receiver);
    return 'You are on Floor $senderReputation and cannot invite someone from Floor $receiverReputation. '
        'Increase your XP or Trust Score to reach a higher Floor.';
  }

  // ---------------------------------------------------------------------------
  // REPORTING
  // ---------------------------------------------------------------------------

  /// Apply a trustScore penalty to [target] when reported by [reporter].
  /// Penalty is a flat -30 to Trust Score.
  static void applyReportPenalty({
    required Resident reporter,
    required Resident target,
  }) {
    target.trustScore = max(0, target.trustScore - 30);
  }
}
