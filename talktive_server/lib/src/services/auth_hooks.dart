import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_server/serverpod_auth_server.dart';
// import '../generated/protocol.dart';

class AuthHooks {
  static Future<void> onUserCreated(Session session, UserInfo userInfo) async {
    // When a user is created in Legacy Serverpod Auth (Int ID), we cannot create a Resident (UUID).
    // This hook is effectively obsolete as we move to AuthServices (UUID).
    session.log(
      'AuthHooks: Legacy User created ${userInfo.id}. usage is deprecated.',
    );

    /*
    // Legacy Code:
    // Default Resident values
    final resident = Resident(
      userInfoId: userInfo.id!, // ERROR: int != UuidValue
      floor: 0,
      creditScore: 100,
      experienceMessageCount: 0,
      lastCreditIncrease: null,
    );

    await Resident.db.insertRow(session, resident);
    session.log(
      'AuthHooks: Resident created successfully for User ${userInfo.id}',
    );
    */
  }
}
