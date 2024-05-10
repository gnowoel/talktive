import 'package:firebase_database/firebase_database.dart';

import '../models/message.dart';
import '../models/room.dart';

class Firedata {
  final FirebaseDatabase instance = FirebaseDatabase.instance;

  Future<Room> createRoom(
    String userId,
    String userName,
    String userCode,
    String languageCode,
  ) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    final seedRoom = SeedRoom(
      userId: userId,
      userName: userName,
      userCode: userCode,
      languageCode: languageCode,
      createdAt: timestamp,
      updatedAt: 0,
    );

    final ref = instance.ref('rooms').push();

    await ref.set(seedRoom.toJson());

    return Room.fromSeed(seedRoom: seedRoom, id: ref.key!);
  }

  Future<void> sendMessage(String roomId, Message message) async {
    final ref = instance.ref('messages/$roomId').push();
    await ref.set(message.toJson());
  }

  Stream<List<Message>> receiveMessages(String roomId) {
    return instance.ref('messages/$roomId').onValue.map<List<Message>>((event) {
      final value = event.snapshot.value;

      if (value == null) {
        return <Message>[];
      }

      final jsonMap = Map<String, dynamic>.from(value as Map);

      return jsonMap.entries.map((entry) {
        final json = Map<String, dynamic>.from(entry.value as Map);
        return Message.fromJson(json);
      }).toList();
    });
  }

  Future<Room?> selectRoom() async {
    final ref = instance.ref('rooms');
    final snapshot = await ref.limitToLast(1).get();
    if (snapshot.exists) {
      final value = snapshot.value;
      final valueMap = Map<String, dynamic>.from(value as Map);
      final roomList = valueMap.entries.map((entry) {
        final valueMap = Map<String, dynamic>.from(entry.value as Map);
        final seedRoom = SeedRoom.fromJson(valueMap);
        final room = Room.fromSeed(seedRoom: seedRoom, id: entry.key);
        return room;
      }).toList();
      return roomList.last;
    } else {
      return null;
    }
  }
}
