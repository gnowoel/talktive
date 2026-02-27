// ignore_for_file: avoid_print, unawaited_futures
import 'package:talktive_server/src/generated/protocol.dart';
import 'package:talktive_server/src/generated/endpoints.dart';
import 'package:serverpod/serverpod.dart';

void main(List<String> args) async {
  final pod = Serverpod(
    args,
    Protocol(),
    Endpoints(),
  );
  final session = await pod.createSession(enableLogging: true);
  try {
    print('Checking channels...');
    final channels = await Channel.db.find(session);
    print('Found ${channels.length} channels.');
    for (var c in channels) {
      print('Channel: ${c.id} - ${c.name} (${c.type})');
    }

    if (channels.isEmpty) {
      print('No channels found. Creating Plaza...');
      final plaza = Channel(
        type: ChannelType.plaza,
        name: 'Plaza',
        createdAt: DateTime.now(),
      );
      await Channel.db.insertRow(session, plaza);
      print('Plaza channel created.');
    }
  } catch (e) {
    print('Error: $e');
  } finally {
    session.close();
  }
}
