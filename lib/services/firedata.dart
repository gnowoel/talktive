import 'dart:async';

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
    final roomRef = instance.ref('rooms/$roomId');
    final messageRef = instance.ref('messages/$roomId').push();
    final timestamp = _now;

    final message = Message(
      userId: userId,
      userName: userName,
      userCode: userCode,
      content: content,
      createdAt: timestamp,
    );

    await messageRef.set(message.toJson());
    await roomRef.update({'updatedAt': timestamp});
  }

  Stream<List<Message>> receiveMessages(String roomId) {
    final messages = <Message>[];

    final ref = instance.ref('messages/$roomId').orderByKey();

    final stream = ref.onChildAdded.map<List<Message>>((event) {
      final value = event.snapshot.value;
      final json = Map<String, dynamic>.from(value as Map);
      final message = Message.fromJson(json);

      return messages..add(message);
    });

    return stream;
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
