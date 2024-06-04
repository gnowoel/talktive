import 'dart:async';

import 'package:firebase_database/firebase_database.dart';

import '../models/message.dart';
import '../models/room.dart';

class Firedata {
  Firedata._();

  static final Firedata _instance = Firedata._();

  factory Firedata() => _instance;

  final FirebaseDatabase instance = FirebaseDatabase.instance;

  int _clockSkew = 0;

  int now() {
    return DateTime.now().millisecondsSinceEpoch + _clockSkew;
  }

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
      createdAt: now(),
      updatedAt: 0,
      accessedAt: 0,
      filter: '$languageCode-zzzz',
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
    final now = this.now();

    final message = Message(
      userId: userId,
      userName: userName,
      userCode: userCode,
      content: content,
      createdAt: now,
    );

    await messageRef.set(message.toJson());

    return await _updateRoomUpdatedAt(room, now);
  }

  Future<bool> _updateRoomUpdatedAt(Room room, int now) async {
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

    final languageCode = room.languageCode;
    final timeElapsed = DateTime.fromMillisecondsSinceEpoch(
      now - roomCreatedAt,
      isUtc: true,
    ).toIso8601String();

    params['filter'] = '$languageCode-$timeElapsed';

    await roomRef.update(params);

    return roomIsOpen;
  }

  Future<void> _updateRoomAccessedAt(Room room, int now) async {
    if (!room.isActive) return;

    final roomRef = instance.ref('rooms/${room.id}');
    final params = <String, dynamic>{};
    final roomCreatedAt = room.createdAt;

    params['accessedAt'] = now;

    final languageCode = room.languageCode;
    final timeElapsed = DateTime.fromMillisecondsSinceEpoch(
      now - roomCreatedAt,
      isUtc: true,
    ).toIso8601String();

    params['filter'] = '$languageCode-$timeElapsed';

    await roomRef.update(params);
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
  Future<Room?> selectRoom(
    String languageCode,
    List<String> recentRoomIds,
  ) async {
    final rooms = <Room>[];
    final expired = <Room>[];
    var startAt = '$languageCode-0000';
    var limit = 16; // For test: 2
    var next = true;

    // TODO: Limit the number of retries
    while (next) {
      final result = await _getRooms(
        languageCode: languageCode,
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

    _markClosed(expired); // To save time, don't wait.

    return rooms.isNotEmpty ? rooms.first : null;
  }

  Future<List<Room>> _getRooms({
    required String languageCode,
    required String startAt,
    required int limit,
  }) async {
    final ref = instance.ref('rooms');
    final query = ref
        .orderByChild('filter')
        .startAt(startAt)
        .endAt('$languageCode-9999')
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

  Future<void> _markClosed(List<Room> rooms) async {
    final ref = instance.ref('rooms');
    final params = <String, dynamic>{};

    for (final room in rooms) {
      params['${room.id}/filter'] = '${room.languageCode}-zzzz';
    }

    await ref.update(params);
  }

  Future<void> syncTime() async {
    final ref = FirebaseDatabase.instance.ref(".info/serverTimeOffset");

    ref.onValue.listen((event) {
      final offset = event.snapshot.value as num? ?? 0.0;
      _clockSkew = offset.toInt();
    });
  }
}
