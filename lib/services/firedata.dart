import 'dart:async';
import 'dart:math';

import 'package:async/async.dart' show StreamGroup;
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_database/firebase_database.dart';

import '../helpers/exception.dart';
import '../helpers/platform.dart';
import '../models/admin.dart';
import '../models/message.dart';
import '../models/private_chat.dart';
import '../models/report.dart';
// import '../models/text_message.dart';
import '../models/user.dart';
import 'messaging.dart';
import 'server_clock.dart';

class Firedata {
  final FirebaseDatabase instance;
  Firedata(this.instance);
  static final firebaseDatabase = FirebaseDatabase.instance;

  Stream<int> subscribeToClockSkew() {
    final ref = instance.ref('.info/serverTimeOffset');

    final stream = ref.onValue.map((event) {
      return (event.snapshot.value as num? ?? 0.0).toInt();
    });

    return stream;
  }

  Future<void> sendTextMessage(
    PrivateChat chat,
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
    PrivateChat chat,
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

  Future<void> storeFcmToken(String userId, [String? fcmToken]) async {
    if (!isAndroid) return; // TODO: Support other platforms

    try {
      final messaging = Messaging();
      final token = fcmToken ?? await messaging.instance.getToken();
      final ref = instance.ref('users/$userId/fcmToken');
      await ref.set(token);
    } catch (e) {
      throw AppException(e.toString());
    }
  }

  Stream<List<PrivateChat>> subscribeToChats(String userId) {
    try {
      final ref = instance.ref('chats/$userId');
      final chats = <PrivateChat>[];

      final Stream<List<PrivateChat>> stream = StreamGroup.merge([
        // Handle added chats
        ref.onChildAdded.map((event) {
          final json = Map<String, dynamic>.from(event.snapshot.value as Map);
          final chatStub = ChatStub.fromJson(json);
          final chat = PrivateChat.fromStub(
            key: event.snapshot.key!,
            value: chatStub,
          );

          final index = chats.indexWhere((c) => c.id == chat.id);
          if (index == -1) {
            chats.add(chat);
          } else {
            chats[index] = chat;
          }

          chats.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
          return List<PrivateChat>.from(chats);
        }),

        // Handle changed chats
        ref.onChildChanged.map((event) {
          final json = Map<String, dynamic>.from(event.snapshot.value as Map);
          final chatStub = ChatStub.fromJson(json);
          final chat = PrivateChat.fromStub(
            key: event.snapshot.key!,
            value: chatStub,
          );

          final index = chats.indexWhere((c) => c.id == chat.id);
          if (index != -1) {
            chats[index] = chat;
          }

          chats.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
          return List<PrivateChat>.from(chats);
        }),

        // Handle removed chats
        ref.onChildRemoved.map((event) {
          final index = chats.indexWhere((c) => c.id == event.snapshot.key);
          if (index != -1) {
            chats.removeAt(index);
          }
          return List<PrivateChat>.from(chats);
        }),
      ]);

      return stream;
    } catch (e) {
      throw AppException(e.toString());
    }
  }

  Stream<PrivateChat> subscribeToChat(String userId, String chatId) {
    final ref = instance.ref('chats/$userId/$chatId');

    final stream = ref.onValue.map((event) {
      late PrivateChat chat;

      final snapshot = event.snapshot;

      if (snapshot.exists) {
        final value = snapshot.value;
        final json = Map<String, dynamic>.from(value as Map);
        final stub = ChatStub.fromJson(json);
        chat = PrivateChat.fromStub(key: chatId, value: stub);
      } else {
        chat = PrivateChat.dummy();
      }

      return chat;
    });

    return stream;
  }

  Future<void> muteChat(String userId, String chatId) async {
    try {
      final ref = instance.ref('chats/$userId/$chatId');
      await ref.update({'mute': true});
    } catch (e) {
      throw AppException(e.toString());
    }
  }

  Future<void> updateChat(
    String userId,
    String chatId, {
    int? readMessageCount,
    bool? reported,
  }) async {
    try {
      final ref = instance.ref('chats/$userId/$chatId');

      await ref.runTransaction((chat) {
        if (chat == null) return Transaction.abort();

        final json = Map<String, dynamic>.from(chat as Map);

        json['readMessageCount'] = readMessageCount ?? json['readMessageCount'];
        json['reported'] = reported ?? json['reported'];

        return Transaction.success(json);
      });
    } catch (e) {
      throw AppException(e.toString());
    }
  }

  Stream<List<Message>> subscribeToMessages(String chatId, int? lastTimestamp) {
    try {
      final messages = <Message>[];
      final ref = instance.ref('messages/$chatId');
      final query =
          ref.orderByChild('createdAt').startAfter(lastTimestamp ?? 0);

      final Stream<List<Message>> stream = StreamGroup.merge([
        // Handle added messages
        query.onChildAdded.map((event) {
          final json = Map<String, dynamic>.from(event.snapshot.value as Map);
          final message = Message.fromJson({
            'id': event.snapshot.key!,
            ...json,
          });

          final index = messages.indexWhere((m) => m.id == message.id);
          if (index == -1) {
            messages.add(message);
          } else {
            messages[index] = message;
          }

          messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          return List<Message>.from(messages);
        }),

        // Handle changed messages (We may need this for hiding messages.)
        query.onChildChanged.map((event) {
          final json = Map<String, dynamic>.from(event.snapshot.value as Map);
          final message = Message.fromJson({
            'id': event.snapshot.key!,
            ...json,
          });

          final index = messages.indexWhere((m) => m.id == message.id);
          if (index != -1) {
            messages[index] = message;
          }

          messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          return List<Message>.from(messages);
        }),

        // Handle removed messages (We need this to remove outdated data fetched
        // from Firebase offline cache.)
        query.onChildRemoved.map((event) {
          final index = messages.indexWhere((m) => m.id == event.snapshot.key);
          if (index != -1) {
            messages.removeAt(index);
          }
          return List<Message>.from(messages);
        }),
      ]);

      return stream;
    } catch (e) {
      throw AppException(e.toString());
    }
  }

  Future<PrivateChat> greetUser(User self, User other, String message) async {
    try {
      final chatId = ([self.id, other.id]..sort()).join();

      // Call the Cloud Function
      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('initiateConversation');

      final response = await callable.call({
        'senderId': self.id,
        'receiverId': other.id,
        'message': message,
      });

      final result = response.data;

      if (result['success'] != true) {
        throw Exception(result['error'] ?? 'Failed to create conversation');
      }

      final chatCreatedAt = result['chatCreatedAt'];

      return _createInitialDummyChat(chatId, chatCreatedAt, other);
    } catch (e) {
      throw AppException(e.toString());
    }
  }

  PrivateChat _createInitialDummyChat(
    String chatId,
    String chatCreatedAt,
    User other,
  ) {
    final stub = ChatStub(
      createdAt: int.tryParse(chatCreatedAt) ?? 0,
      updatedAt: 0,
      partner: UserStub.fromJson(other.toJson()),
      messageCount: 1,
    );
    return PrivateChat.fromStub(key: chatId, value: stub);
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
      final now = ServerClock().now;
      final twelveHoursAgo = now - 12 * 60 * 60 * 1000;

      final query = ref.orderByChild('createdAt').startAt(twelveHoursAgo);

      final reports = <Report>[];

      final Stream<List<Report>> stream = StreamGroup.merge([
        // Handle added reports
        query.onChildAdded.map((event) {
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
        query.onChildChanged.map((event) {
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
        query.onChildRemoved.map((event) {
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
      int? revivedAt;

      if (days != 0) {
        final milliseconds = days * 24 * 60 * 60 * 1000;
        final partnerRef = instance.ref('users/$partnerId');

        await partnerRef.runTransaction((partner) {
          if (partner == null) return Transaction.abort();

          final json = Map<String, dynamic>.from(partner as Map);
          final oldRevivedAt = json['revivedAt'] as int?;
          final startAt = max(oldRevivedAt ?? 0, serverNow);
          revivedAt = startAt + milliseconds;

          json['revivedAt'] = revivedAt;

          return Transaction.success(json);
        });
      }

      await _updateReportStatusAndRevivedAt(
        reportId: report.id,
        revivedAt: revivedAt,
      );
    } catch (e) {
      throw AppException(e.toString());
    }
  }

  Future<void> _updateReportStatusAndRevivedAt({
    required String reportId,
    required int? revivedAt,
  }) async {
    try {
      final reportRef = instance.ref('reports/$reportId');
      await reportRef.update({
        'status': 'resolved',
        if (revivedAt != null) ...{'revivedAt': revivedAt},
      });
    } catch (e) {
      throw AppException(e.toString());
    }
  }

  Future<void> recallMessage(String chatId, String messageId) async {
    try {
      final ref = instance.ref('messages/$chatId/$messageId');
      await ref.update({'recalled': true});
    } catch (e) {
      throw AppException(e.toString());
    }
  }
}
