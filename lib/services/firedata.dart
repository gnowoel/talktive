import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

import '../helpers/exception.dart';
import '../models/message.dart';
import '../models/room.dart';
import 'clock.dart';

class Firedata {
  final FirebaseDatabase instance;
  final Clock clock = Clock();

  Firedata(this.instance);

  void syncTime() {
    final ref = instance.ref(".info/serverTimeOffset");

    ref.onValue.listen((event) {
      final offset = event.snapshot.value as num? ?? 0.0;
      clock.updateClockSkew(offset.toInt());
    });
  }

  Future<Room> createRoom(
    String userId,
    String userName,
    String userCode,
    String languageCode,
  ) async {
    try {
      final now = clock.serverNow();
      final roomValue = RoomStub(
        topic: userName, // Use `userName` as the default topic
        userId: userId,
        userName: userName,
        userCode: userCode,
        languageCode: languageCode,
        createdAt: now,
        updatedAt: now,
        closedAt: now + (kDebugMode ? 360 : 3600) * 1000,
        filter: '$languageCode-nnnn',
      );

      final ref = instance.ref('rooms').push();

      await ref.set(roomValue.toJson());

      return Room.fromStub(key: ref.key!, value: roomValue);
    } catch (e) {
      throw AppException(e.toString());
    }
  }

  Future<Message> sendMessage(
    Room room,
    String userId,
    String userName,
    String userCode,
    String content,
  ) async {
    try {
      final messageRef = instance.ref('messages/${room.id}').push();
      final now = clock.serverNow();

      final message = Message(
        userId: userId,
        userName: userName,
        userCode: userCode,
        content: content,
        createdAt: now,
      );

      await messageRef.set(message.toJson());

      return message;
    } catch (e) {
      throw AppException(e.toString());
    }
  }

  Future<void> createAccess(String roomId) async {
    try {
      final accessRef = instance.ref('accesses').push();
      final entry = {roomId: true};

      await accessRef.set(entry);
    } catch (e) {
      throw AppException(e.toString());
    }
  }

  Future<void> updateRoomTopic(Room room, String topic) async {
    try {
      if (topic.isEmpty || room.topic == topic) return;

      final ref = instance.ref('rooms/${room.id}');

      await ref.update({'topic': topic});
    } catch (e) {
      throw AppException(e.toString());
    }
  }

  Stream<Room> subscribeToRoom(String roomId) {
    final ref = instance.ref('rooms/$roomId');

    final stream = ref.onValue.map((event) {
      final snapshot = event.snapshot;
      final value = snapshot.value;

      late Room room;

      if (value != null) {
        final json = Map<String, dynamic>.from(value as Map);
        final stub = RoomStub.fromJson(json);
        room = Room.fromStub(key: roomId, value: stub);
      } else {
        room = Room.dummyDeletedRoom();
      }

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

      if (messages.isNotEmpty) {
        final last = messages.last;
        final current = message;

        if (last.userId == current.userId) {
          final lastTime = DateTime.fromMillisecondsSinceEpoch(last.createdAt);
          final currentTime =
              DateTime.fromMillisecondsSinceEpoch(current.createdAt);
          const oneMinute = Duration(minutes: 1);

          if (lastTime.isAfter(currentTime.subtract(oneMinute))) {
            final index = messages.length - 1;
            final content = '${last.content}\n${current.content}';

            messages[index] = last.copyWith(content: content);

            return messages;
          }
        }
      }

      return messages..add(message);
    });

    return stream;
  }

  // Inactive rooms should be removed after some time
  Future<Room?> selectRoom(
    String languageCode,
    List<String> recentRoomIds,
  ) async {
    try {
      final rooms = <Room>[];
      final expired = <Room>[];
      var startAt = '$languageCode-0000';
      var limit = kDebugMode ? 2 : 16;
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
          if (room.isClosed) {
            if (!room.isMarkedClosed) {
              expired.add(room);
            }
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

      _markClosed(expired); // No need to wait

      return rooms.isNotEmpty ? rooms.first : null;
    } catch (e) {
      throw AppException(e.toString());
    }
  }

  Future<List<Room>> _getRooms({
    required String languageCode,
    required String startAt,
    required int limit,
  }) async {
    try {
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
    } catch (e) {
      throw AppException(e.toString());
    }
  }

  Future<void> _markClosed(List<Room> rooms) async {
    try {
      final expiresRef = instance.ref('expires').push();
      final collection = <String, dynamic>{};

      for (final room in rooms) {
        collection[room.id] = true;
      }

      await expiresRef.set(collection);
    } catch (e) {
      throw AppException(e.toString());
    }
  }
}
