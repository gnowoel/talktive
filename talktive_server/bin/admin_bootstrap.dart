
import 'package:serverpod/serverpod.dart';
import 'package:talktive_server/src/generated/protocol.dart' as protocol;
import 'package:talktive_server/src/generated/endpoints.dart';
import 'dart:io';

void main(List<String> args) async {
  if (args.isEmpty) {
    print('Usage:');
    print('  dart bin/admin_bootstrap.dart promote <username>');
    print('  dart bin/admin_bootstrap.dart demote <username>');
    print('  dart bin/admin_bootstrap.dart promote-mod <username>');
    print('  dart bin/admin_bootstrap.dart demote-mod <username>');
    print('  dart bin/admin_bootstrap.dart privatize <groupId>');
    print('  dart bin/admin_bootstrap.dart list-users');
    print('  dart bin/admin_bootstrap.dart list-groups');
    print('  dart bin/admin_bootstrap.dart fix-roles');
    exit(1);
  }

  final command = args[0];
  final pod = Serverpod(['--mode', 'development'], protocol.Protocol(), Endpoints());
  final session = await pod.createSession();

  try {
    switch (command) {
      case 'promote':
        if (args.length < 2) {
          print('Missing username');
          break;
        }
        await _promote(session, args[1]);
        break;
      case 'demote':
        if (args.length < 2) {
          print('Missing username');
          break;
        }
        await _demote(session, args[1]);
        break;
      case 'promote-mod':
        if (args.length < 2) {
          print('Missing username');
          break;
        }
        await _promoteMod(session, args[1]);
        break;
      case 'demote-mod':
        if (args.length < 2) {
          print('Missing username');
          break;
        }
        await _demoteMod(session, args[1]);
        break;
      case 'privatize':
        if (args.length < 2) {
          print('Missing groupId');
          break;
        }
        await _privatize(session, int.parse(args[1]));
        break;
      case 'list-users':
        await _listUsers(session);
        break;
      case 'list-groups':
        await _listGroups(session);
        break;
      case 'fix-roles':
        await _fixRoles(session);
        break;
      default:
        print('Unknown command: $command');
    }
  } catch (e) {
    print('An error occurred: $e');
  } finally {
    await session.close();
    pod.shutdown();
    exit(0);
  }
}

Future<void> _promote(Session session, String username) async {
  final resident = await protocol.Resident.db.findFirstRow(
    session,
    where: (t) => t.userName.equals(username),
  );
  if (resident == null) {
    print('User "$username" not found.');
    return;
  }
  resident.role = protocol.ResidentRole.admin;
  await protocol.Resident.db.updateRow(session, resident);
  print('SUCCESS: ${resident.userName} is now an admin!');
}

Future<void> _demote(Session session, String username) async {
  final resident = await protocol.Resident.db.findFirstRow(
    session,
    where: (t) => t.userName.equals(username),
  );
  if (resident == null) {
    print('User "$username" not found.');
    return;
  }
  resident.role = protocol.ResidentRole.user;
  await protocol.Resident.db.updateRow(session, resident);
  print('SUCCESS: ${resident.userName} is no longer an admin.');
}

Future<void> _promoteMod(Session session, String username) async {
  final resident = await protocol.Resident.db.findFirstRow(
    session,
    where: (t) => t.userName.equals(username),
  );
  if (resident == null) {
    print('User "$username" not found.');
    return;
  }
  resident.role = protocol.ResidentRole.moderator;
  await protocol.Resident.db.updateRow(session, resident);
  print('SUCCESS: ${resident.userName} is now a moderator!');
}

Future<void> _demoteMod(Session session, String username) async {
  final resident = await protocol.Resident.db.findFirstRow(
    session,
    where: (t) => t.userName.equals(username),
  );
  if (resident == null) {
    print('User "$username" not found.');
    return;
  }
  resident.role = protocol.ResidentRole.user;
  await protocol.Resident.db.updateRow(session, resident);
  print('SUCCESS: ${resident.userName} is no longer a moderator.');
}

Future<void> _privatize(Session session, int groupId) async {
  final group = await protocol.Group.db.findById(session, groupId);
  if (group == null) {
    print('Group with ID $groupId not found.');
    return;
  }
  group.isPublic = false;
  group.isStaffLocked = true;
  await protocol.Group.db.updateRow(session, group);
  print('SUCCESS: Group "${group.name}" (ID: $groupId) is now PRIVATE and LOCKED.');
}

Future<void> _listUsers(Session session) async {
  final users = await protocol.Resident.db.find(session);
  for (var u in users) {
    String roleStr = '[${u.role.name.toUpperCase()}]';
    print('- ${u.userName} (${u.userInfoId}) $roleStr [XP: ${u.xp}] [Floor: ${u.level}] [TS: ${u.trustScore}]');
  }
}

Future<void> _listGroups(Session session) async {
  final groups = await protocol.Group.db.find(session);
  for (var g in groups) {
    String lockStr = g.isStaffLocked ? '[LOCKED]' : '[OPEN]';
    print('- ${g.name} (ID: ${g.id}) $lockStr - Public: ${g.isPublic}');
  }
}

Future<void> _fixRoles(Session session) async {
  print('Checking for residents with null roles...');
  final residents = await protocol.Resident.db.find(
    session,
    where: (t) => t.role.equals(null),
  );

  print('Found ${residents.length} residents needing fix.');

  for (var r in residents) {
    r.role = protocol.ResidentRole.user;
    await protocol.Resident.db.updateRow(session, r);
    print('- Fixed ${r.userName} (${r.userInfoId})');
  }

  print('SUCCESS: All residents have roles.');
}
