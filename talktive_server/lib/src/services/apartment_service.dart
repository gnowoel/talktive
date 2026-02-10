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
  /// Downstairs (Floor 0) -> Upstairs (Floor >= 1) : FORBIDDEN
  static bool canInvite({
    required Resident sender,
    required Resident receiver,
  }) {
    // If sender is on Floor 0 (Plaza level)
    if (sender.floor == 0) {
      // And receiver is Upstairs (Floor >= 1)
      if (receiver.floor >= 1) {
        return false; // Forbidden
      }
    }

    // All other cases are Allowed (Upstairs -> Downstairs, Same Floor)
    return true;
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

  /// Awards credit score points if more than 1 hour has passed since last increase.
  /// Awards 2 points per hour (changed from 1 for faster recovery).
  /// Maximum credit score is capped at 100.
  static Future<void> awardMessageCredit(
    Session session,
    Resident resident,
  ) async {
    final now = DateTime.now();
    final lastIncrease = resident.lastCreditIncrease;

    // Check time constraint (1 hour)
    if (lastIncrease == null || now.difference(lastIncrease).inHours >= 1) {
      // Award 2 points per hour (faster recovery)
      resident.creditScore = (resident.creditScore + 2).clamp(-1000, 100);
      resident.lastCreditIncrease = now;

      // Upgrade floor if applicable
      resident.floor = calculateFloor(
        messageCount: resident.experienceMessageCount,
        creditScore: resident.creditScore,
      );

      await Resident.db.updateRow(session, resident);
    }
  }
}
