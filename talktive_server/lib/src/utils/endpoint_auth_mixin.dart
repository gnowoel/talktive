import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart' as protocol;
import '../services/resident_service.dart';

/// A mixin to provide shared authentication and resident lookup utility for Serverpod endpoints.
mixin EndpointAuthMixin {
  /// Retrieves the UUID of the authenticated user.
  /// Throws a TalktiveException if the user is not authenticated.
  Future<UuidValue> getUserId(Session session) async {
    final auth = session.authenticated;
    if (auth == null) {
      throw protocol.TalktiveException(
        message: 'You must be signed in to perform this action.',
        code: 'NOT_AUTHENTICATED',
      );
    }
    return UuidValue.fromString(auth.userIdentifier);
  }

  /// Retrieves the Resident record for a specific user ID.
  /// Throws a TalktiveException if the resident is not found.
  Future<protocol.Resident> getResidentProfile(
    Session session,
    UuidValue userId,
  ) async {
    final resident = await ResidentService.getResident(session, userId);
    if (resident == null) {
      throw protocol.TalktiveException(
        message: 'Resident profile not found.',
        code: 'RESIDENT_NOT_FOUND',
      );
    }
    return resident;
  }

  /// Retrieves the Resident record for the currently authenticated user session.
  /// This also performs passive maintenance like trust score restoration.
  /// Throws a TalktiveException if not found or not authenticated.
  Future<protocol.Resident> getAuthenticatedResident(Session session) async {
    final userId = await getUserId(session);
    final resident = await ResidentService.getActiveResident(session, userId);
    if (resident == null) {
      throw protocol.TalktiveException(
        message: 'Resident profile not found.',
        code: 'RESIDENT_NOT_FOUND',
      );
    }
    return resident;
  }

  /// Retrieves the Resident record for the currently authenticated user session,
  /// and verifies that they have the 'admin' role.
  /// Throws a TalktiveException if not found, not authenticated, or not an admin.
  Future<protocol.Resident> getAdminProfile(Session session) async {
    final resident = await getAuthenticatedResident(session);
    if (resident.role != 'admin') {
      throw protocol.TalktiveException(
        message: 'Admin access required.',
        code: 'ADMIN_ACCESS_REQUIRED',
      );
    }
    return resident;
  }
}
