import 'package:serverpod/serverpod.dart';
import 'package:talktive_server/src/generated/protocol.dart' as protocol;

void main(List<String> args) async {
  final session = await createSession();
  
  print('Fixing null roles in Resident table...');
  
  final residents = await protocol.Resident.db.find(
    session,
    where: (t) => t.role.equals(null),
  );
  
  print('Found ${residents.length} residents with null roles.');
  
  for (var resident in residents) {
    resident.role = protocol.ResidentRole.user;
    await protocol.Resident.db.updateRow(session, resident);
    print('- Fixed ${resident.userName}');
  }
  
  print('SUCCESS: All residents now have roles.');
  await session.close();
}

Future<Session> createSession() async {
  final config = ServerpodConfig(
    configuration: {
      'database': {
        'host': 'localhost',
        'port': 5432,
        'name': 'talktive',
        'user': 'postgres',
        'pass': 'postgres',
      }
    },
    passwords: {},
  );
  
  final serverpod = Serverpod(
    [],
    protocol.Protocol(),
    config: config,
  );
  
  return await serverpod.createSession();
}
