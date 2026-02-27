import 'package:talktive_server/src/generated/protocol.dart' as p;
import 'package:talktive_server/src/generated/endpoints.dart' as e;
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_server/serverpod_auth_server.dart';

void main(List<String> args) async {
  final pod = Serverpod(
    args,
    p.Protocol(),
    e.Endpoints(),
  );
  final session = await pod.createSession(enableLogging: true);
  try {
    final res = await Resident.db.find(session, limit: 1);
    if (res.isNotEmpty) {
      print('Resident userInfoId: ${res.first.userInfoId}');
      
      final userInfoById = await UserInfo.db.findById(
        session,
        1,
      );
      print('First UserInfo by id 1: ${userInfoById?.userIdentifier}, ${userInfoById?.userName}');
      
      final userInfos = await UserInfo.db.find(session, limit: 5);
      for (var u in userInfos) {
        print('UserInfo ID: ${u.id}, userIdentifier: ${u.userIdentifier}, userName: ${u.userName}');
      }
    }
  } catch (e) {
    print('Error: $e');
  } finally {
    session.close();
  }
}
