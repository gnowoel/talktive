import 'package:serverpod/serverpod.dart';
import 'package:talktive_server/src/generated/protocol.dart' as protocol;
import '../services/resident_service.dart';
import 'task_utils.dart';

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

  /// Retrieves the UUID of the authenticated user if they are signed in.
  Future<UuidValue?> getUserIdOptional(Session session) async {
    final auth = session.authenticated;
    if (auth == null) return null;
    return UuidValue.fromString(auth.userIdentifier);
  }

  /// Retrieves the Resident record for the authenticated user session if they exist.
  Future<protocol.Resident?> getResidentOptional(Session session) async {
    final userId = await getUserIdOptional(session);
    if (userId == null) return null;
    return await ResidentService.getResident(session, userId);
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

    if (resident.suspended) {
      throw protocol.TalktiveException(
        message: 'Your account has been suspended for violating our community guidelines.',
        code: 'ACCOUNT_SUSPENDED',
      );
    }

    return resident;
  }

  /// Retrieves the Resident record for the currently authenticated user session,
  /// and verifies that they have either 'admin' or 'moderator' privileges.
  Future<protocol.Resident> getStaffProfile(Session session) async {
    final resident = await getAuthenticatedResident(session);
    if (resident.role != protocol.ResidentRole.admin &&
        resident.role != protocol.ResidentRole.moderator) {
      throw protocol.TalktiveException(
        message: 'Moderator or Admin access required.',
        code: 'ACCESS_DENIED',
      );
    }
    return resident;
  }

  /// Retrieves the Resident record for the currently authenticated user session,
  /// and verifies that they have 'admin' privileges.
  Future<protocol.Resident> getAdminProfile(Session session) async {
    final resident = await getAuthenticatedResident(session);
    if (resident.role != protocol.ResidentRole.admin) {
      throw protocol.TalktiveException(
        message: 'Administrator access required.',
        code: 'ADMIN_ACCESS_REQUIRED',
      );
    }
    return resident;
  }

  /// Safely runs a background task with a temporary background session.
  /// This prevents 'Session is closed' errors for tasks that outlive the request.
  void runBackground(Session session, Future<void> Function(Session backgroundSession) task) {
    TaskUtils.runBackground(session, task);
  }
}
