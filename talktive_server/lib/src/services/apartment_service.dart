import 'package:serverpod/serverpod.dart';
import 'dart:math';
import '../generated/protocol.dart';

/// Apartment Service
/// Handles reputation (safety/moderation) system
class ApartmentService {
  // Reputation Constants
  static const int REPUTATION_MAX = 100;
  static const int REPUTATION_START = 100;
  static const int REPUTATION_RESTORE_RATE = 2; // points per hour

  /// Restore reputation passively (2pts/hour, max 100)
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
        'Restored $points reputation to ${resident.userInfoId}. New reputation: ${resident.reputation}',
      );
    } else if (resident.lastReputationIncrease == null) {
      // Initialize timestamp for new users
      resident.lastReputationIncrease = now;
      await Resident.db.updateRow(session, resident);
    }
  }

  /// Apply report penalty to target
  /// Penalty = max(1, reporter's level)
  static void applyReportPenalty({
    required Resident reporter,
    required Resident target,
  }) {
    final penalty = max(1, reporter.level);
    target.reputation = max(0, target.reputation - penalty);
  }

  /// Check if user is muted
  /// Muted if: reputation <= 0 OR mutedUntil is in the future OR suspended
  static bool isMuted(Resident resident) {
    // Suspended users are always muted
    if (resident.suspended) return true;

    // Reputation-based mute
    if (resident.reputation <= 0) return true;

    // Temporary mute
    if (resident.mutedUntil != null &&
        resident.mutedUntil!.isAfter(DateTime.now())) {
      return true;
    }

    return false;
  }

  /// Get mute reason for user-facing message
  static String getMuteReason(Resident resident) {
    if (resident.suspended) {
      return 'Your account has been suspended.';
    }

    if (resident.reputation <= 0) {
      return 'You are muted due to low reputation. Your reputation will restore at 2 points per hour.';
    }

    if (resident.mutedUntil != null &&
        resident.mutedUntil!.isAfter(DateTime.now())) {
      final hoursLeft = resident.mutedUntil!.difference(DateTime.now()).inHours;
      return 'You are temporarily muted for $hoursLeft more hours due to multiple reports.';
    }

    return 'You are muted.';
  }

  /// Check if user can invite another user to private chat
  /// Rule: Can only invite users on same floor or below
  static bool canInvite({
    required Resident sender,
    required Resident receiver,
  }) {
    return receiver.floor <= sender.floor;
  }

  /// Clamp reputation to valid range
  static int clampReputation(int reputation) {
    return reputation.clamp(0, REPUTATION_MAX);
  }
}
