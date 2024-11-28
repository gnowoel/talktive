import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

import '../helpers/exception.dart';
import '../models/chat.dart';
import '../models/image_message.dart';
import '../models/message.dart';
import '../models/room.dart';
import '../models/text_message.dart';
import '../models/user.dart';
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

  Future<Chat> createPair(String userId, User partner) async {
    try {
      final userId1 = userId;
      final userId2 = partner.id;
      if (userId1 == userId2) {
        throw Exception("You can't talk to yourself");
      }
      final pairId = ([userId1, userId2]..sort()).join();
      final ref = instance.ref('pairs/$pairId');
      final result = await ref.runTransaction((pair) {
        if (pair != null) {
          return Transaction.abort();
        }
        return Transaction.success({
          'followers': [userId1, userId2],
          'firstUserId': null,
          'lastMessageContent': null,
          'messageCount': 0,
          'createdAt': ServerValue.timestamp,
          'updatedAt': ServerValue.timestamp,
        });
      }, applyLocally: false);

      final snapshot = result.snapshot;
      final value = snapshot.value;
      final json = Map<String, dynamic>.from(value as Map);
      final stub = ChatStub(
        createdAt: json['createdAt'] as int,
        updatedAt: json['updatedAt'] as int,
        partner: UserStub.fromJson(partner.toJson()),
        messageCount: json['messageCount'] as int,
      );
      final chat = Chat.fromStub(key: snapshot.key!, value: stub);

      return chat;
    } catch (e) {
      throw AppException(e.toString());
    }
  }

  Future<Message> sendTextMessage(
    Chat chat,
    String userId,
    String userName,
    String userCode,
    String content,
  ) async {
    try {
      final messageRef = instance.ref('messages/${chat.id}').push();
      final now = clock.serverNow(); // TODO: Use `ServerValue` instead

      final message = TextMessage(
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

  Future<Message> sendImageMessage(
    Chat chat,
    String userId,
    String userName,
    String userCode,
    String uri,
  ) async {
    try {
      final messageRef = instance.ref('messages/${chat.id}').push();
      final now = clock.serverNow(); // TODO: Use `ServerValue` instead

      final message = ImageMessage(
        userId: userId,
        userName: userName,
        userCode: userCode,
        content:
            '(Upgrade your app to see images.)', // TODO: Remove the `content` field
        uri: uri,
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

  Stream<User?> subscribeToUser(String userId) {
    final ref = instance.ref('users/$userId');

    final stream = ref.onValue.map((event) {
      final snapshot = event.snapshot;
      final value = snapshot.value;

      if (value == null) return null;

      final json = Map<String, dynamic>.from(value as Map);
      final stub = UserStub.fromJson(json);
      final user = User.fromStub(key: userId, value: stub);

      return user;
    });

    return stream;
  }

  Future<void> updateAvatar(String userId, String userCode) async {
    final ref = instance.ref('users/$userId');
    await ref.update({
      'photoURL': userCode,
      'updatedAt': ServerValue.timestamp,
    });
  }

  Future<void> updateProfile({
    required String userId,
    required String languageCode,
    required String photoURL,
    required String displayName,
    required String description,
    required String gender,
  }) async {
    try {
      final ref = instance.ref('users/$userId');

      await ref.update({
        'languageCode': languageCode,
        'photoURL': photoURL,
        'displayName': displayName,
        'description': description,
        'gender': gender,
        'updatedAt': ServerValue.timestamp,
      });
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

  Stream<List<Chat>> subscribeToChats(String userId) {
    final ref = instance.ref('chats/$userId');

    final stream = ref.onValue.map((event) {
      final snapshot = event.snapshot;

      if (!snapshot.exists) {
        return <Chat>[];
      }

      final listMap = Map<String, dynamic>.from(snapshot.value as Map);

      final chats = listMap.entries.map((entry) {
        final entryMap = Map<String, dynamic>.from(entry.value as Map);
        final chatStub = ChatStub.fromJson(entryMap);
        return Chat.fromStub(key: entry.key, value: chatStub);
      }).toList();

      chats.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return chats;
    });

    return stream;
  }

  Stream<Chat> subscribeToChat(String userId, String chatId) {
    final ref = instance.ref('chats/$userId/$chatId');

    final stream = ref.onValue.map((event) {
      final snapshot = event.snapshot;
      final value = snapshot.value;

      late Chat chat;

      if (value != null) {
        final json = Map<String, dynamic>.from(value as Map);
        final stub = ChatStub.fromJson(json);
        chat = Chat.fromStub(key: chatId, value: stub);
      } else {
        chat = Chat.dummy();
      }

      return chat;
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

        if (last is TextMessage && current is TextMessage) {
          if (last.userId == current.userId) {
            final lastTime =
                DateTime.fromMillisecondsSinceEpoch(last.createdAt);
            final currentTime =
                DateTime.fromMillisecondsSinceEpoch(current.createdAt);
            const interval = Duration(seconds: 1);

            if (lastTime.isAfter(currentTime.subtract(interval))) {
              final index = messages.length - 1;
              final content = '${last.content}\n${current.content}';

              messages[index] = last.copyWith(content: content);

              return messages;
            }
          }
        }
      }

      return messages..add(message);
    });

    return stream;
  }

  Future<List<User>> fetchUsers({
    required List<String> excludedUserIds,
  }) async {
    try {
      final users = <User>[];
      final minNumber = kDebugMode ? 8 : 16;
      final limit = minNumber * 2;

      int? endBefore;
      bool next = true;

      while (next) {
        final result = await _getUsers(
          endBefore: endBefore,
          limit: limit,
        );

        if (result.length < limit) {
          next = false;
        }

        for (final user in result) {
          if (!user.isNew && !excludedUserIds.contains(user.id)) {
            users.add(user);
          }
        }

        if (users.length >= minNumber) {
          next = false;
        }

        if (next) {
          endBefore = result.last.updatedAt;
        }
      }

      users.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      return users;
    } catch (e) {
      throw AppException(e.toString());
    }
  }

  Future<List<User>> _getUsers({
    required int? endBefore,
    required int limit,
  }) async {
    try {
      final ref = instance.ref('users');
      final query = endBefore == null
          ? ref.orderByChild('updatedAt').limitToLast(limit)
          : ref
              .orderByChild('updatedAt')
              .endBefore(endBefore)
              .limitToLast(limit);
      final snapshot = await query.get();

      if (!snapshot.exists) {
        return <User>[];
      }

      final listMap = Map<String, dynamic>.from(snapshot.value as Map);

      final users = listMap.entries.map((entry) {
        final entryMap = Map<String, dynamic>.from(entry.value as Map);
        final userStub = UserStub.fromJson(entryMap);
        return User.fromStub(key: entry.key, value: userStub);
      }).toList();

      return users;
    } catch (e) {
      throw AppException(e.toString());
    }
  }

  // Inactive rooms will be removed by scheduled Cloud Functions
  Future<List<Room>> fetchRooms(
    String languageCode,
    List<String> recentRoomIds,
  ) async {
    try {
      final rooms = <Room>[];
      final expired = <Room>[];
      var startAt = '$languageCode-0000';
      var limit = kDebugMode ? 2 : 16;
      var next = true;

      // TODO: Limit the number of retries if necessary
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

      return rooms;
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
