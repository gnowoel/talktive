import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';

class CreditRestorationCall extends FutureCall {
  @override
  Future<void> invoke(Session session, dynamic object) async {
    // Un-muting: If Credit < 0, wait Abs(Credit Score) hours.

    // 1. Find users with Credit < 0.
    final mutedUsers = await Resident.db.find(
      session,
      where: (t) => t.creditScore < 0,
    );

    for (final user in mutedUsers) {
      if (user.lastCreditIncrease == null) continue;

      final penaltyHours = user.creditScore.abs();

      final restoreTime = user.lastCreditIncrease!.add(
        Duration(hours: penaltyHours),
      );

      if (DateTime.now().isAfter(restoreTime)) {
        // Reset to 0
        user.creditScore = 0;
        await Resident.db.updateRow(session, user);
      }
    }
  }
}
