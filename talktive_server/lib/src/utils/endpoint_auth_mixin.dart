import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart' as protocol;

/// A mixin to provide shared authentication and resident lookup utility for Serverpod endpoints.
mixin EndpointAuthMixin {
  /// Retrieves the UUID of the authenticated user.
  /// Throws an exception if the user is not authenticated.
  Future<UuidValue> getUserId(Session session) async {
    final auth = session.authenticated;
    if (auth == null || auth.userIdentifier == null) {
      throw Exception('Not authenticated');
    }
    return UuidValue.fromString(auth.userIdentifier!);
  }

  /// Retrieves the Resident record for a specific user ID.
  /// Throws an exception if the resident is not found.
  Future<protocol.Resident> getResidentProfile(Session session, UuidValue userId) async {
    final resident = await protocol.Resident.db.findFirstRow(
      session,
      where: (t) => t.userInfoId.equals(userId),
    );
    if (resident == null) {
      throw Exception('Resident profile not found for user $userId');
    }
    return resident;
  }

  /// Retrieves the Resident record for the currently authenticated user session.
  /// Throws an exception if not found or not authenticated.
  Future<protocol.Resident> getAuthenticatedResident(Session session) async {
    final userId = await getUserId(session);
    return getResidentProfile(session, userId);
  }

  /// Retrieves the Resident record for the currently authenticated user session,
  /// and verifies that they have the 'admin' role.
  /// Throws an exception if not found, not authenticated, or not an admin.
  Future<protocol.Resident> getAdminProfile(Session session) async {
    final resident = await getAuthenticatedResident(session);
    if (resident.role != 'admin') {
      throw Exception('Admin access required');
    }
    return resident;
  }
}
