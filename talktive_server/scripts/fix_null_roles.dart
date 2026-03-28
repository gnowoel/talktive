import 'package:serverpod/serverpod.dart';
import 'package:talktive_server/src/generated/protocol.dart' as protocol;
import 'package:talktive_server/src/generated/endpoints.dart';
import 'dart:io';

void main(List<String> args) async {
  final pod = Serverpod(
    ['--mode', 'development'],
    protocol.Protocol(),
    Endpoints(),
  );
  final session = await pod.createSession();

  stdout.writeln('Fixing null roles in Resident table...');

  final residents = await protocol.Resident.db.find(
    session,
    where: (t) => t.role.equals(null),
  );

  stdout.writeln('Found ${residents.length} residents with null roles.');

  for (var resident in residents) {
    resident.role = protocol.ResidentRole.user;
    await protocol.Resident.db.updateRow(session, resident);
    stdout.writeln('- Fixed ${resident.userName}');
  }

  stdout.writeln('SUCCESS: All residents now have roles.');
  await session.close();
  await pod.shutdown();
}
