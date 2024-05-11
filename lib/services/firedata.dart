import 'package:firebase_database/firebase_database.dart';

import '../models/message.dart';
import '../models/room.dart';

class Firedata {
  final FirebaseDatabase instance = FirebaseDatabase.instance;

  int get _now => DateTime.now().millisecondsSinceEpoch;

  Future<Room> createRoom(
    String userId,
    String userName,
    String userCode,
    String languageCode,
  ) async {
    final roomValue = RoomValue(
      userId: userId,
      userName: userName,
      userCode: userCode,
      languageCode: languageCode,
      createdAt: _now,
      updatedAt: 0,
    );

    final ref = instance.ref('rooms').push();

    await ref.set(roomValue.toJson());

    return Room.fromValue(key: ref.key!, value: roomValue);
  }

  Future<void> sendMessage(
    String roomId,
    String userId,
    String userName,
    String userCode,
    String content,
  ) async {
    final ref = instance.ref('messages/$roomId').push();

    final message = Message(
      userId: userId,
      userName: userName,
      userCode: userCode,
      content: content,
      createdAt: _now,
    );

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
    final ref = instance.ref('rooms').orderByKey().limitToLast(1);
    final snapshot = await ref.get();

    if (!snapshot.exists) {
      return null;
    }

    final map1 = Map<String, dynamic>.from(snapshot.value as Map);
    final list = map1.entries.map((entry) {
      final map2 = Map<String, dynamic>.from(entry.value as Map);
      final roomValue = RoomValue.fromJson(map2);
      return Room.fromValue(key: entry.key, value: roomValue);
    }).toList();

    return list.last;
  }
}
