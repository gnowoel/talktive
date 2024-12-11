import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

import '../helpers/exception.dart';
import '../models/chat.dart';
import '../models/message.dart';
import '../models/text_message.dart';
import '../models/user.dart';

class Firedata {
  final FirebaseDatabase instance;

  Firedata(this.instance);

  Stream<int> subscribeToClockSkew() {
    final ref = instance.ref('.info/serverTimeOffset');

    final stream = ref.onValue.map((event) {
      return (event.snapshot.value as num? ?? 0.0).toInt();
    });

    return stream;
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
        createdAt: 0,
        updatedAt: 0,
        partner: UserStub.fromJson(partner.toJson()),
        messageCount: json['messageCount'] as int,
      );
      final chat = Chat.fromStub(key: snapshot.key!, value: stub);

      return chat;
    } catch (e) {
      throw AppException(e.toString());
    }
  }

  Future<void> sendTextMessage(
    Chat chat,
    String userId,
    String userDisplayName,
    String userPhotoURL,
    String content,
  ) async {
    try {
      final messageRef = instance.ref('messages/${chat.id}').push();

      await messageRef.set({
        'type': 'text',
        'userId': userId,
        'userDisplayName': userDisplayName,
        'userPhotoURL': userPhotoURL,
        'content': content,
        'createdAt': ServerValue.timestamp,
      });
    } catch (e) {
      throw AppException(e.toString());
    }
  }

  Future<void> sendImageMessage(
    Chat chat,
    String userId,
    String userDisplayName,
    String userPhotoURL,
    String uri,
  ) async {
    try {
      final messageRef = instance.ref('messages/${chat.id}').push();

      await messageRef.set({
        'type': 'image',
        'userId': userId,
        'userDisplayName': userDisplayName,
        'userPhotoURL': userPhotoURL,
        'content': '[Image]',
        'uri': uri,
        'createdAt': ServerValue.timestamp,
      });
    } catch (e) {
      throw AppException(e.toString());
    }
  }

  Stream<User?> subscribeToUser(String userId) {
    final ref = instance.ref('users/$userId');

    final stream = ref.onValue.map((event) {
      final snapshot = event.snapshot;

      if (!snapshot.exists) {
        return null;
      }

      final value = snapshot.value;
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
        'filter': null, // Remove the `temp-*` or `perm-*` marker
      });
    } catch (e) {
      throw AppException(e.toString());
    }
  }

  Future<void> setUserFcmToken(String? userId, String? fcmToken) async {
    if (userId == null || fcmToken == null) return;
    final ref = instance.ref('users/$userId/fcmToken');
    await ref.set(fcmToken);
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
      late Chat chat;

      final snapshot = event.snapshot;

      if (snapshot.exists) {
        final value = snapshot.value;
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

  Future<void> updateChat(
    String userId,
    String chatId, {
    int? readMessageCount,
    bool? mute,
  }) async {
    try {
      final ref = instance.ref('chats/$userId/$chatId');

      await ref.runTransaction((chat) {
        if (chat == null) return Transaction.abort();

        final json = Map<String, dynamic>.from(chat as Map);

        json['readMessageCount'] = readMessageCount ?? json['readMessageCount'];
        json['mute'] = mute ?? json['mute'];

        return Transaction.success(json);
      });
    } catch (e) {
      throw AppException(e.toString());
    }
  }

  Stream<List<Message>> subscribeToMessages(String chatId) {
    final messages = <Message>[];

    final ref = instance.ref('messages/$chatId');
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
            if (current.createdAt - last.createdAt < 1 * 1000) {
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
      final now = DateTime.now();
      final users = <User>[];
      final minNumber = kDebugMode ? 8 : 16;
      final limit = minNumber * 2;

      int endBefore = now.add(const Duration(days: 365)).millisecondsSinceEpoch;
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

  Future<User?> fetchUser(String userId) async {
    try {
      final ref = instance.ref('users/$userId');
      final snapshot = await ref.get();

      if (!snapshot.exists) {
        return null;
      }

      final value = snapshot.value;
      final json = Map<String, dynamic>.from(value as Map);
      final stub = UserStub.fromJson(json);
      return User.fromStub(key: userId, value: stub);
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
      final query = ref
          .orderByChild('updatedAt')
          .startAt(0)
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
}
