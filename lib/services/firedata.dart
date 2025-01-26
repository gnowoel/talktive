import 'dart:async';
import 'dart:math';

import 'package:async/async.dart' show StreamGroup;
import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction, Query;
import 'package:firebase_database/firebase_database.dart';

import '../helpers/exception.dart';
import '../models/admin.dart';
import '../models/chat.dart';
import '../models/message.dart';
import '../models/report.dart';
import '../models/text_message.dart';
import '../models/user.dart';
import 'messaging.dart';

class Firedata {
  final FirebaseDatabase instance;
  final FirebaseFirestore firestore;

  static const String _usersCollection = 'users';

  Firedata(this.instance) : firestore = FirebaseFirestore.instance;

  static final firebaseDatabase = FirebaseDatabase.instance;

  int _lastTouchedUser = 0;

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
        messageCount: json['messageCount'] as int, // 0
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

  Future<void> storeFcmToken(String userId) async {
    try {
      final messaging = Messaging();
      final fcmToken = await messaging.instance.getToken();
      await setUserFcmToken(userId, fcmToken);
    } catch (e) {
      throw AppException(e.toString());
    }
  }

  Future<void> setUserFcmToken(String? userId, String? fcmToken) async {
    try {
      if (userId == null || fcmToken == null) return;
      final ref = instance.ref('users/$userId/fcmToken');
      await ref.set(fcmToken);
    } catch (e) {
      throw AppException(e.toString());
    }
  }

  Stream<List<Chat>> subscribeToChats(String userId) {
    try {
      final ref = instance.ref('chats/$userId');
      final chats = <Chat>[];

      final Stream<List<Chat>> stream = StreamGroup.merge([
        // Handle added chats
        ref.onChildAdded.map((event) {
          final json = Map<String, dynamic>.from(event.snapshot.value as Map);
          final chatStub = ChatStub.fromJson(json);
          final chat = Chat.fromStub(key: event.snapshot.key!, value: chatStub);

          final index = chats.indexWhere((c) => c.id == chat.id);
          if (index == -1) {
            chats.add(chat);
          } else {
            chats[index] = chat;
          }

          chats.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
          return List<Chat>.from(chats);
        }),

        // Handle changed chats
        ref.onChildChanged.map((event) {
          final json = Map<String, dynamic>.from(event.snapshot.value as Map);
          final chatStub = ChatStub.fromJson(json);
          final chat = Chat.fromStub(key: event.snapshot.key!, value: chatStub);

          final index = chats.indexWhere((c) => c.id == chat.id);
          if (index != -1) {
            chats[index] = chat;
          }

          chats.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
          return List<Chat>.from(chats);
        }),

        // Handle removed chats
        ref.onChildRemoved.map((event) {
          final index = chats.indexWhere((c) => c.id == event.snapshot.key);
          if (index != -1) {
            chats.removeAt(index);
          }
          return List<Chat>.from(chats);
        }),
      ]);

      return stream;
    } catch (e) {
      throw AppException(e.toString());
    }
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
    bool? reported,
  }) async {
    try {
      final ref = instance.ref('chats/$userId/$chatId');

      await ref.runTransaction((chat) {
        if (chat == null) return Transaction.abort();

        final json = Map<String, dynamic>.from(chat as Map);

        json['readMessageCount'] = readMessageCount ?? json['readMessageCount'];
        json['mute'] = mute ?? json['mute'];
        json['reported'] = reported ?? json['reported'];

        return Transaction.success(json);
      });
    } catch (e) {
      throw AppException(e.toString());
    }
  }

  Future<void> reportChat({
    required String userId,
    required String chatId,
    required String? partnerDisplayName,
  }) async {
    try {
      final ref = instance.ref('reports').push();

      await ref.set({
        'userId': userId,
        'chatId': chatId,
        'partnerDisplayName': partnerDisplayName,
        'createdAt': ServerValue.timestamp,
        'status': 'pending',
      });
    } catch (e) {
      throw AppException(e.toString());
    }
  }

  Stream<List<Message>> subscribeToNewMessages(
    String chatId,
    int? lastTimestamp,
  ) {
    final messages = <Message>[];
    final ref = instance.ref('messages/$chatId');

    Query query = ref.orderByChild('createdAt');
    if (lastTimestamp != null) {
      query = query.startAfter(lastTimestamp);
    }

    final stream = query.onChildAdded.map<List<Message>>((event) {
      final json = Map<String, dynamic>.from(event.snapshot.value as Map);
      json['id'] = event.snapshot.key;
      final message = Message.fromJson(json);

      messages.add(message);

      return List.from(messages);
    });

    return stream;
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

      // Handle message concatenation logic
      if (messages.isNotEmpty) {
        final last = messages.last;
        if (last is TextMessage && message is TextMessage) {
          if (last.userId == message.userId) {
            if (message.createdAt - last.createdAt < 1000) {
              messages.last =
                  last.copyWith(content: '${last.content}\n${message.content}');
              return List.from(messages);
            }
          }
        }
      }

      return messages..add(message);
    });

    return stream;
  }

  Future<List<User>> fetchUsers(String userId, int serverNow) async {
    try {
      final users = <User>[];

      final snapshot = await firestore
          .collection(_usersCollection)
          .orderBy('updatedAt', descending: true)
          .limit(32)
          .get();

      for (var doc in snapshot.docs) {
        final data = doc.data();

        if (_isUserDataValid(data)) {
          final user = User(
            id: doc.id,
            createdAt: data['createdAt'] as int,
            updatedAt: data['updatedAt'] as int,
            languageCode: data['languageCode'] as String?,
            photoURL: data['photoURL'] as String?,
            displayName: data['displayName'] as String?,
            description: data['description'] as String?,
            gender: data['gender'] as String?,
            revivedAt: data['revivedAt'] as int?,
          );
          users.add(user);
        }
      }

      if (users.isEmpty) {
        return _fetchUsersFallback();
      }

      return users;
    } catch (e) {
      // Fallback to RTDB if Firestore fails
      return _fetchUsersFallback();
    } finally {
      tryTouchUser(userId, serverNow); // No wait
    }
  }

  bool _isUserDataValid(Map<String, dynamic> data) {
    const requiredFields = [
      'createdAt',
      'updatedAt',
      'languageCode',
      'photoURL',
      'displayName',
      'description',
      'gender',
    ];

    return requiredFields.every(data.containsKey);
  }

  Future<void> tryTouchUser(String userId, int serverNow) async {
    try {
      final shouldTouch = serverNow >= _lastTouchedUser + 3 * 60 * 1000;

      if (!shouldTouch) return;

      await instance.ref('users/$userId').update({
        'updatedAt': serverNow,
      });

      _lastTouchedUser = serverNow;
    } catch (e) {
      throw AppException(e.toString());
    }
  }

  Future<List<User>> _fetchUsersFallback() async {
    try {
      final limit = 32;

      final ref = instance.ref('users');
      final query = ref.orderByPriority().endBefore(0).limitToFirst(limit);
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

  Future<Chat> greetUser(User self, User other, String message) async {
    try {
      final chat = await createPair(self.id, other);

      await sendTextMessage(
        chat,
        self.id,
        self.displayName!,
        self.photoURL!,
        message,
      );

      return chat;
    } catch (e) {
      throw AppException(e.toString());
    }
  }

  Future<Admin?> fetchAdmin(String? userId) async {
    try {
      if (userId == null) return null;

      final ref = instance.ref('admins/$userId');
      final snapshot = await ref.get();

      if (!snapshot.exists) return null;

      final json = Map<String, dynamic>.from(snapshot.value as Map);
      return Admin.fromJson({'id': userId, ...json});
    } catch (e) {
      throw AppException(e.toString());
    }
  }

  Stream<List<Report>> subscribeToReports() {
    try {
      final ref = instance.ref('reports');
      final reports = <Report>[];

      final Stream<List<Report>> stream = StreamGroup.merge([
        // Handle added reports
        ref.onChildAdded.map((event) {
          final json = Map<String, dynamic>.from(event.snapshot.value as Map);
          final report = Report.fromJson(event.snapshot.key!, json);

          final index = reports.indexWhere((r) => r.id == report.id);
          if (index == -1) {
            reports.add(report);
          } else {
            reports[index] = report;
          }

          reports.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return List<Report>.from(reports);
        }),

        // Handle changed reports
        ref.onChildChanged.map((event) {
          final json = Map<String, dynamic>.from(event.snapshot.value as Map);
          final report = Report.fromJson(event.snapshot.key!, json);

          final index = reports.indexWhere((r) => r.id == report.id);
          if (index != -1) {
            reports[index] = report;
          }

          reports.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return List<Report>.from(reports);
        }),

        // Handle removed reports
        ref.onChildRemoved.map((event) {
          final index = reports.indexWhere((r) => r.id == event.snapshot.key);
          if (index != -1) {
            reports.removeAt(index);
          }
          return List<Report>.from(reports);
        }),
      ]);

      return stream;
    } catch (e) {
      throw AppException(e.toString());
    }
  }

  Future<void> resolveReport({
    required Report report,
    required String resolution,
    required int serverNow,
  }) async {
    try {
      final chatId = report.chatId;
      final userId = report.userId;
      final partnerId = chatId.replaceFirst(userId, '');
      final days = int.tryParse(resolution) ?? 0;

      if (days != 0) {
        final milliseconds = days * 24 * 60 * 60 * 1000;

        final partnerRef = instance.ref('users/$partnerId');
        final snapshot = await partnerRef.get();

        if (snapshot.exists) {
          final json = Map<String, dynamic>.from(snapshot.value as Map);
          final stub = UserStub.fromJson(json);
          final partner = User.fromStub(key: partnerId, value: stub);
          final startAt = max(partner.revivedAt ?? 0, serverNow);
          final revivedAt = startAt + milliseconds;

          await partnerRef.update({
            'revivedAt': revivedAt,
            'updatedAt': serverNow, // Trigger updating Firestore cache
          });
        }
      }

      final reportRef = instance.ref('reports/${report.id}');
      reportRef.remove();
    } catch (e) {
      throw AppException(e.toString());
    }
  }
}
