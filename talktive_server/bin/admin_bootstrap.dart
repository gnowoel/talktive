import 'package:serverpod/serverpod.dart';
import 'package:talktive_server/src/generated/protocol.dart' as protocol;
import 'package:talktive_server/src/generated/endpoints.dart';
import 'dart:io';

void main(List<String> args) async {
  if (args.isEmpty) {
    stdout.writeln('Usage:');
    stdout.writeln('  dart bin/admin_bootstrap.dart promote <username>');
    stdout.writeln('  dart bin/admin_bootstrap.dart demote <username>');
    stdout.writeln('  dart bin/admin_bootstrap.dart promote-mod <username>');
    stdout.writeln('  dart bin/admin_bootstrap.dart demote-mod <username>');
    stdout.writeln('  dart bin/admin_bootstrap.dart privatize <loungeId>');
    stdout.writeln('  dart bin/admin_bootstrap.dart list-users');
    stdout.writeln('  dart bin/admin_bootstrap.dart list-lounges');
    stdout.writeln('  dart bin/admin_bootstrap.dart fix-roles');
    exit(1);
  }

  final command = args[0];
  final pod = Serverpod(
    ['--mode', 'development'],
    protocol.Protocol(),
    Endpoints(),
  );
  final session = await pod.createSession();

  try {
    switch (command) {
      case 'promote':
        if (args.length < 2) {
          stdout.writeln('Missing username');
          break;
        }
        await _promote(session, args[1]);
        break;
      case 'demote':
        if (args.length < 2) {
          stdout.writeln('Missing username');
          break;
        }
        await _demote(session, args[1]);
        break;
      case 'promote-mod':
        if (args.length < 2) {
          stdout.writeln('Missing username');
          break;
        }
        await _promoteMod(session, args[1]);
        break;
      case 'demote-mod':
        if (args.length < 2) {
          stdout.writeln('Missing username');
          break;
        }
        await _demoteMod(session, args[1]);
        break;
      case 'privatize':
        if (args.length < 2) {
          stdout.writeln('Missing loungeId');
          break;
        }
        await _privatize(session, int.parse(args[1]));
        break;
      case 'list-users':
        await _listUsers(session);
        break;
      case 'list-lounges':
        await _listLounges(session);
        break;
      case 'fix-roles':
        await _fixRoles(session);
        break;
      default:
        stdout.writeln('Unknown command: $command');
    }
  } catch (e) {
    stdout.writeln('An error occurred: $e');
  } finally {
    await session.close();
    await pod.shutdown();
    exit(0);
  }
}

Future<void> _promote(Session session, String username) async {
  final resident = await protocol.Resident.db.findFirstRow(
    session,
    where: (t) => t.userName.equals(username),
  );
  if (resident == null) {
    stdout.writeln('User "$username" not found.');
    return;
  }
  resident.role = protocol.ResidentRole.admin;
  await protocol.Resident.db.updateRow(session, resident);
  stdout.writeln('SUCCESS: ${resident.userName} is now an admin!');
}

Future<void> _demote(Session session, String username) async {
  final resident = await protocol.Resident.db.findFirstRow(
    session,
    where: (t) => t.userName.equals(username),
  );
  if (resident == null) {
    stdout.writeln('User "$username" not found.');
    return;
  }
  resident.role = protocol.ResidentRole.user;
  await protocol.Resident.db.updateRow(session, resident);
  stdout.writeln('SUCCESS: ${resident.userName} is no longer an admin.');
}

Future<void> _promoteMod(Session session, String username) async {
  final resident = await protocol.Resident.db.findFirstRow(
    session,
    where: (t) => t.userName.equals(username),
  );
  if (resident == null) {
    stdout.writeln('User "$username" not found.');
    return;
  }
  resident.role = protocol.ResidentRole.moderator;
  await protocol.Resident.db.updateRow(session, resident);
  stdout.writeln('SUCCESS: ${resident.userName} is now a moderator!');
}

Future<void> _demoteMod(Session session, String username) async {
  final resident = await protocol.Resident.db.findFirstRow(
    session,
    where: (t) => t.userName.equals(username),
  );
  if (resident == null) {
    stdout.writeln('User "$username" not found.');
    return;
  }
  resident.role = protocol.ResidentRole.user;
  await protocol.Resident.db.updateRow(session, resident);
  stdout.writeln('SUCCESS: ${resident.userName} is no longer a moderator.');
}

Future<void> _privatize(Session session, int loungeId) async {
  final lounge = await protocol.Lounge.db.findById(session, loungeId);
  if (lounge == null) {
    stdout.writeln('Lounge with ID $loungeId not found.');
    return;
  }
  lounge.isPublic = false;
  lounge.isStaffLocked = true;
  await protocol.Lounge.db.updateRow(session, lounge);
  stdout.writeln(
    'SUCCESS: Lounge "${lounge.name}" (ID: $loungeId) is now PRIVATE and LOCKED.',
  );
}

Future<void> _listUsers(Session session) async {
  final users = await protocol.Resident.db.find(session);
  for (var u in users) {
    String roleStr = '[${u.role.name.toUpperCase()}]';
    stdout.writeln(
      '- ${u.userName} (${u.userInfoId}) $roleStr [XP: ${u.xp}] [Floor: ${u.level}] [TS: ${u.trustScore}]',
    );
  }
}

Future<void> _listLounges(Session session) async {
  final lounges = await protocol.Lounge.db.find(session);
  for (var l in lounges) {
    String lockStr = l.isStaffLocked ? '[LOCKED]' : '[OPEN]';
    stdout.writeln(
      '- ${l.name} (ID: ${l.id}) $lockStr - Public: ${l.isPublic}',
    );
  }
}

Future<void> _fixRoles(Session session) async {
  stdout.writeln('Checking for residents with null roles...');
  final residents = await protocol.Resident.db.find(
    session,
    where: (t) => t.role.equals(null),
  );

  stdout.writeln('Found ${residents.length} residents needing fix.');

  for (var r in residents) {
    r.role = protocol.ResidentRole.user;
    await protocol.Resident.db.updateRow(session, r);
    stdout.writeln('- Fixed ${r.userName} (${r.userInfoId})');
  }

  stdout.writeln('SUCCESS: All residents have roles.');
}
