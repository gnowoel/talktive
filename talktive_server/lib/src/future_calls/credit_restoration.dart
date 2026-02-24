import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';
import '../services/apartment_service.dart';

class CreditRestorationCall extends FutureCall {
  @override
  Future<void> invoke(Session session, dynamic object) async {
    // Reputation restoration is now handled passively in ApartmentService.restoreTrustScore()
    // This future call is kept for backward compatibility but does nothing.

    // Optional: Clear expired temporary mutes
    final now = DateTime.now();
    final mutedUsers = await Resident.db.find(
      session,
      where: (t) => t.mutedUntil.notEquals(null),
    );

    for (final user in mutedUsers) {
      if (user.mutedUntil != null && now.isAfter(user.mutedUntil!)) {
        // Clear expired mute
        user.mutedUntil = null;
        await Resident.db.updateRow(session, user);
      }
    }
  }
}
