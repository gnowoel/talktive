import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_server/serverpod_auth_server.dart';
import '../generated/protocol.dart';

class AuthHooks {
  static Future<void> onUserCreated(Session session, UserInfo userInfo) async {
    // When a user is created in Serverpod Auth, we must create a Resident row.
    session.log('AuthHooks: Creating Resident for User ${userInfo.id}');

    // Default Resident values
    final resident = Resident(
      userInfoId: userInfo.id!,
      floor: 0, // Everyone starts at Plaza
      creditScore: 100, // Default start
      experienceMessageCount: 0,
      lastCreditIncrease: null,
    );

    await Resident.db.insertRow(session, resident);
    session.log(
      'AuthHooks: Resident created successfully for User ${userInfo.id}',
    );
  }
}
