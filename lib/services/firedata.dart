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
      filter: '\ufff0',
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
    final now = DateTime.now().millisecondsSinceEpoch;

    final message = Message(
      userId: userId,
      userName: userName,
      userCode: userCode,
      content: content,
      createdAt: now,
    );

    await messageRef.set(message.toJson());

    return await _updateRoom(room, now);
  }

  Future<bool> _updateRoom(Room room, int now) async {
    final roomRef = instance.ref('rooms/${room.id}');
    final params = <String, dynamic>{};
    var roomCreatedAt = room.createdAt;
    var roomIsOpen = false;

    if (room.updatedAt == 0) {
      roomCreatedAt = now;
      params['createdAt'] = roomCreatedAt;
    }

    if (room.isOpen) {
      roomIsOpen = true;
      params['updatedAt'] = now;
    }

    // TODO: If use this, we can keep updating `updatedAt` even if the room is closed.
    // if (!room.isOpen) { // TODO: `&& room.closedAt == 0`
    //   params['closedAt'] = DateTime.fromMillisecondsSinceEpoch(room.updatedAt)
    //       .add(const Duration(seconds: 360)); // TODO: 3600
    // }

    // Just a hack to convert int to sortable strings.
    params['filter'] =
        DateTime.fromMillisecondsSinceEpoch(now - roomCreatedAt, isUtc: true)
            .toIso8601String();

    await roomRef.update(params);

    return roomIsOpen;
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

  // Inactive rooms should be removed after some time
  Future<Room?> selectRoom(List<String> recentRoomIds) async {
    final rooms = <Room>[];
    final expired = <Room>[];
    var startAt = '';
    var limit = 2; // TODO: 16
    var next = true;

    // TODO: Limit the number of retries
    while (next) {
      final result = await _getRooms(
        startAt: startAt,
        limit: limit,
      );

      if (result.length < limit) next = false;

      rooms.clear();

      for (final room in result) {
        if (!room.isActive) {
          expired.add(room);
        } else if (!recentRoomIds.contains(room.id)) {
          rooms.add(room);
        }
      }

      if (rooms.isNotEmpty) next = false;

      if (next) {
        startAt = result.last.filter;
        limit *= 2;
      }
    }

    rooms.sort((a, b) {
      int filterComp = a.filter.compareTo(b.filter);
      if (filterComp == 0) {
        return a.createdAt.compareTo(b.createdAt);
      }
      return filterComp;
    });

    _markClosed(expired);

    return rooms.isNotEmpty ? rooms.first : null;
  }

  Future<void> _markClosed(List<Room> rooms) async {
    for (final room in rooms) {
      instance.ref('rooms/${room.id}').update({
        'filter': '\ufff0',
      });
    }
  }

  Future<List<Room>> _getRooms({
    required String startAt,
    required int limit,
  }) async {
    final ref = instance.ref('rooms');
    final query = ref
        .orderByChild('filter')
        .startAt(startAt)
        .endAt('9999-99-99T99:99:99.999Z')
        .limitToFirst(limit);
    final snapshot = await query.get();

    if (!snapshot.exists) {
      return [];
    }

    final map1 = Map<String, dynamic>.from(snapshot.value as Map);
    final rooms = map1.entries.map((entry) {
      final map2 = Map<String, dynamic>.from(entry.value as Map);
      final roomStub = RoomStub.fromJson(map2);
      return Room.fromStub(key: entry.key, value: roomStub);
    }).toList();

    rooms.sort((a, b) => a.filter.compareTo(b.filter));

    return rooms;
  }
}
