import 'package:serverpod/serverpod.dart';
import 'dart:math';
import '../generated/protocol.dart';

class ApartmentService {
  /// Calculates the Experience Level based on message count.
  /// Formula: Level = Log(max(1, count)) / Log(3)
  static double calculateExperienceLevel(int messageCount) {
    if (messageCount <= 0) return 0.0;
    // Log base 3 of messageCount
    return log(max(1, messageCount)) / log(3);
  }

  /// Calculates the Floor based on message count and credit score.
  /// Formula: Floor = (Experience Level * Credit Score) / 100
  static int calculateFloor({
    required int messageCount,
    required int creditScore,
  }) {
    final double level = calculateExperienceLevel(messageCount);
    final double floorVal = (level * creditScore) / 100;
    return floorVal.floor();
  }

  /// Updates the Resident's floor based on their current stats.
  /// Returns the updated Resident object (does not save to DB).
  static Resident updateResidentFloor(Resident resident) {
    final int newFloor = calculateFloor(
      messageCount: resident.experienceMessageCount,
      creditScore: resident.creditScore,
    );
    // You might want to use copyWith if available, or just mutate if it's a mutable object
    resident.floor = newFloor;
    return resident;
  }

  /// Checks if [sender] is allowed to invite [receiver] to a chat.
  /// Rule: Residents can only invite people living on the same floor or below.
  static bool canInvite({
    required Resident sender,
    required Resident receiver,
  }) {
    return receiver.floor <= sender.floor;
  }

  /// Applies penalty to [target] when reported by [reporter].
  /// Penalty: CreditScore -= Reporter.Floor
  /// Returns the modified target Resident.
  static Resident applyReportPenalty({
    required Resident reporter,
    required Resident target,
  }) {
    // Implementing strict logic: CreditScore -= max(1, Reporter.Floor)
    int penalty = max(1, reporter.floor);
    target.creditScore -= penalty;

    return target;
  }

  /// Restores credit score points based on time passed.
  /// Awards 2 points per hour.
  /// Maximum credit score is capped at 100.
  static Future<void> restoreCredits(
    Session session,
    Resident resident,
  ) async {
    final now = DateTime.now();
    final lastIncrease = resident.lastCreditIncrease ?? now;

    final diff = now.difference(lastIncrease);
    final hoursPassed = diff.inHours;

    if (hoursPassed >= 1) {
      // Award 2 points per hour
      final points = hoursPassed * 2;

      // Only increase if below cap
      if (resident.creditScore < 100) {
        resident.creditScore = (resident.creditScore + points).clamp(
          -1000,
          100,
        );
      }

      // Update timestamp, preserving the minute/second offset for next hour
      resident.lastCreditIncrease = lastIncrease.add(
        Duration(hours: hoursPassed),
      );

      // Upgrade floor if applicable
      resident.floor = calculateFloor(
        messageCount: resident.experienceMessageCount,
        creditScore: resident.creditScore,
      );

      await Resident.db.updateRow(session, resident);
    } else if (resident.lastCreditIncrease == null) {
      // Initialize timestamp for new users
      resident.lastCreditIncrease = now;
      await Resident.db.updateRow(session, resident);
    }
  }
}
