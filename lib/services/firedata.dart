import 'dart:async';

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
    final roomValue = RoomStub(
      userId: userId,
      userName: userName,
      userCode: userCode,
      languageCode: languageCode,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      updatedAt: 0,
    );

    final ref = instance.ref('rooms').push();

    await ref.set(roomValue.toJson());

    return Room.fromStub(key: ref.key!, value: roomValue);
  }

  Future<bool> sendMessage(
    Room room,
    String userId,
    String userName,
    String userCode,
    String content,
  ) async {
    final messageRef = instance.ref('messages/${room.id}').push();
    final now = DateTime.now();

    final message = Message(
      userId: userId,
      userName: userName,
      userCode: userCode,
      content: content,
      createdAt: now.millisecondsSinceEpoch,
    );

    await messageRef.set(message.toJson());

    final roomRef = instance.ref('rooms/${room.id}');

    if (room.isOpen) {
      await roomRef.update({'updatedAt': now.millisecondsSinceEpoch});
    }

    return room.isOpen;
  }

  Stream<Room> subscribeToRoom(String roomId) {
    final ref = instance.ref('rooms/$roomId');

    final stream = ref.onValue.map((event) {
      final snapshot = event.snapshot;
      final value = snapshot.value;
      final json = Map<String, dynamic>.from(value as Map);
      final stub = RoomStub.fromJson(json);
      final room = Room.fromStub(key: roomId, value: stub);

      return room;
    });

    return stream;
  }

  Stream<List<Message>> subscribeToMessages(String roomId) {
    final messages = <Message>[];

    final ref = instance.ref('messages/$roomId');
    final query = ref.orderByKey();

    final stream = query.onChildAdded.map<List<Message>>((event) {
      final snapshot = event.snapshot;
      final value = snapshot.value;
      final json = Map<String, dynamic>.from(value as Map);
      final message = Message.fromJson(json);

      return messages..add(message);
    });

    return stream;
  }

  Future<Room?> selectRoom(List<String> recentRoomIds) async {
    var limit = 16;
    var next = true;
    var rooms = <Room>[];

    while (next) {
      rooms = await _getRooms(limit);
      if (rooms.length < limit) next = false;
      rooms = rooms.where((room) => !recentRoomIds.contains(room.id)).toList();
      if (rooms.isNotEmpty) next = false;
      limit *= 2;
    }

    return rooms.isNotEmpty ? rooms.first : null;
  }

  Future<List<Room>> _getRooms(int limit) async {
    final oneHourAgo = DateTime.now()
        .subtract(const Duration(seconds: 360)) // TODO: 3600
        .millisecondsSinceEpoch;
    final ref = instance.ref('rooms');
    final query = ref
        .orderByChild('updatedAt')
        .startAt(oneHourAgo + 1)
        .limitToLast(limit);
    final snapshot = await query.get();

    if (!snapshot.exists) {
      return [];
    }

    final map1 = Map<String, dynamic>.from(snapshot.value as Map);
    final list = map1.entries.map((entry) {
      final map2 = Map<String, dynamic>.from(entry.value as Map);
      final roomStub = RoomStub.fromJson(map2);
      return Room.fromStub(key: entry.key, value: roomStub);
    }).toList();

    return list;
  }
}
