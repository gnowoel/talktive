import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../models/follow.dart';
import '../models/public_topic.dart';
import '../models/topic_message.dart';
import '../models/user.dart';
import '../helpers/exception.dart';

class Firestore {
  final FirebaseFirestore instance;
  Firestore(this.instance);
  static final firebaseFirestore = FirebaseFirestore.instance;

  final Map<String, Follow> _followeesCache = {};
  StreamController<List<Follow>>? _followeesController;
  StreamSubscription? _followeesSubscription;

  final Map<String, Follow> _followersCache = {};
  StreamController<List<Follow>>? _followersController;
  StreamSubscription? _followersSubscription;

  int _lastTouchedUser = 0;
  final List<User> _cachedUsers = [];
  int? _lastUpdatedAt;

  final _userCache = <String, _CachedUser>{};

  Future<User?> fetchUser(String userId) async {
    try {
      _removeInvalidUsersFromCache();

      final cached = _userCache[userId];
      if (cached != null && cached.isValid) {
        return cached.user;
      }

      final doc = await instance.collection('users').doc(userId).get();

      if (!doc.exists) {
        return null;
      }

      final data = doc.data()!;
      if (!_isUserDataComplete(data)) {
        return null;
      }

      final userStub = UserStub.fromJson(data);
      final user = User.fromStub(key: doc.id, value: userStub);

      _userCache[userId] = _CachedUser(user);

      return user;
    } catch (e) {
      throw AppException(e.toString());
    }
  }

  void _removeInvalidUsersFromCache() {
    _userCache.removeWhere((_, cached) => !cached.isValid);
  }

  Future<List<User>> fetchUsers(
    String userId,
    int serverNow, {
    String? genderFilter,
    String? languageFilter,
    bool noCache = false,
  }) async {
    try {
      // Clear cache if it's too old
      if (noCache || _shouldRefreshCache(serverNow)) {
        clearCache();
      }

      // Start building the query
      var query = instance
          .collection('users')
          .where('revivedAt', isLessThan: serverNow); // Filter out banned users

      // Add gender filter if specified
      if (genderFilter != null) {
        query = query.where('gender', isEqualTo: genderFilter);
      }

      // Add language filter if specified
      if (languageFilter != null) {
        query = query.where('languageCode', isEqualTo: languageFilter);
      }

      // Complete the query with ordering and limit
      query = query
      // .orderBy('revivedAt') // Required when using where() with revivedAt
      .orderBy('updatedAt', descending: true);

      if (_lastUpdatedAt != null) {
        query = query.endBefore([_lastUpdatedAt]);
      }

      query = query.limit(32);

      final snapshot = await query.get();
      final fetchedUsers = <User>[];

      for (final doc in snapshot.docs) {
        final data = doc.data();

        if (!_isUserDataComplete(data)) continue;

        final userStub = UserStub.fromJson(data);
        final user = User.fromStub(key: doc.id, value: userStub);

        fetchedUsers.add(user);
      }

      // Merge fetched users with cached users
      if (fetchedUsers.isNotEmpty) {
        _cachedUsers.removeWhere(
          (cachedUser) => fetchedUsers.any(
            (fetchedUser) => fetchedUser.id == cachedUser.id,
          ),
        );
        _cachedUsers.addAll(fetchedUsers);
        _cachedUsers.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

        if (_cachedUsers.length > 32) {
          _cachedUsers.removeRange(32, _cachedUsers.length);
        }

        _lastUpdatedAt = _cachedUsers.first.updatedAt;
      }

      return List<User>.from(_cachedUsers);
    } catch (e) {
      throw AppException(e.toString());
    } finally {
      _tryTouchUser(userId, serverNow);
    }
  }

  void clearCache() {
    _cachedUsers.clear();
    _lastUpdatedAt = null;
  }

  bool _shouldRefreshCache(int serverNow) {
    if (_cachedUsers.isEmpty) return true;

    final twelveHours = 1 * 60 * 60 * 1000;
    final lastCacheTime = _lastUpdatedAt ?? 0;
    return serverNow >= lastCacheTime + twelveHours;
  }

  bool _isUserDataComplete(Map<String, dynamic> data) {
    const requiredFields = ['createdAt', 'updatedAt'];
    return requiredFields.every(data.containsKey);
  }

  Future<void> _tryTouchUser(String userId, int serverNow) async {
    try {
      final oneMinute = 1 * 60 * 1000;
      final shouldTouch = serverNow >= _lastTouchedUser + oneMinute;

      if (!shouldTouch) return;

      await instance.collection('users').doc(userId).set({
        'updatedAt': serverNow,
        // Workaround to make sure `revivedAt` is not `null`.
        // A better way would be update Realtime Database instead.
        'revivedAt': FieldValue.increment(1),
      }, SetOptions(merge: true));

      _lastTouchedUser = serverNow;
    } catch (e) {
      throw AppException(e.toString());
    }
  }

  Stream<List<Follow>> subscribeToFollowees(String userId) {
    _followeesController?.close();
    _followeesController = StreamController<List<Follow>>();

    _followeesSubscription?.cancel();

    _followeesSubscription = instance
        .collection('users')
        .doc(userId)
        .collection('followees')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((event) {
          for (final change in event.docChanges) {
            final follow = Follow.fromJson({
              'id': change.doc.id,
              ...change.doc.data()!,
            });

            switch (change.type) {
              case DocumentChangeType.added:
                _followeesCache[follow.id] = follow;
                break;
              case DocumentChangeType.modified:
                _followeesCache[follow.id] = follow;
                break;
              case DocumentChangeType.removed:
                _followeesCache.removeWhere((id, _) => id == follow.id);
                break;
            }
          }

          final followees =
              _followeesCache.values.toList()
                ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

          _followeesController?.add(followees);
        });

    return _followeesController!.stream;
  }

  void _disposeFollowees() {
    _followeesSubscription?.cancel();
    _followeesController?.close();
    _followeesCache.clear();
  }

  Stream<List<Follow>> subscribeToFollowers(String userId) {
    _followersController?.close();
    _followersController = StreamController<List<Follow>>();

    _followersSubscription?.cancel();

    _followersSubscription = instance
        .collection('users')
        .doc(userId)
        .collection('followers')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((event) {
          for (final change in event.docChanges) {
            final follow = Follow.fromJson({
              'id': change.doc.id,
              ...change.doc.data()!,
            });

            switch (change.type) {
              case DocumentChangeType.added:
                _followersCache[follow.id] = follow;
                break;
              case DocumentChangeType.modified:
                _followersCache[follow.id] = follow;
                break;
              case DocumentChangeType.removed:
                _followersCache.removeWhere((id, _) => id == follow.id);
                break;
            }
          }

          final followers =
              _followersCache.values.toList()
                ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

          _followersController?.add(followers);
        });

    return _followersController!.stream;
  }

  void _disposeFollowers() {
    _followersSubscription?.cancel();
    _followersController?.close();
    _followersCache.clear();
  }

  void dispose() {
    _disposeFollowers();
    _disposeFollowees();
  }

  Future<void> followUser(String followerId, String followeeId) async {
    try {
      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('follow');

      final result = await callable.call({
        'followerId': followerId,
        'followeeId': followeeId,
      });

      if (result.data['success'] != true) {
        throw Exception(result.data['error'] ?? 'Failed to follow user');
      }
    } catch (e) {
      throw AppException(e.toString());
    }
  }

  Future<void> unfollowUser(String followerId, String followeeId) async {
    try {
      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('unfollow');

      final result = await callable.call({
        'followerId': followerId,
        'followeeId': followeeId,
      });

      if (result.data['success'] != true) {
        throw Exception(result.data['error'] ?? 'Failed to unfollow user');
      }
    } catch (e) {
      throw AppException(e.toString());
    }
  }

  Future<PublicTopic> createTopic({
    required User user,
    required String title,
    required String message,
  }) async {
    try {
      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('createTopic');

      final response = await callable.call({
        'userId': user.id,
        'title': title,
        'message': message,
      });

      final result = response.data;

      if (result['success'] != true) {
        throw Exception(result['error'] ?? 'Failed to create topic');
      }

      final topicId = result['topicId'];
      final topicCreatedAt = result['topicCreatedAt'];

      return _createInitialDummyTopic(topicId, topicCreatedAt, user);
    } catch (e) {
      throw AppException(e.toString());
    }
  }

  PublicTopic _createInitialDummyTopic(
    String topicId,
    String topicCreatedAt,
    User user,
  ) {
    return PublicTopic(
      id: topicId,
      createdAt: int.tryParse(topicCreatedAt) ?? 0,
      updatedAt: 0,
      title: '',
      creator: user,
      messageCount: 1,
    );
  }

  Stream<List<PublicTopic>> subscribeToTopics(String userId) {
    try {
      final ref = instance.collection('users').doc(userId).collection('topics');

      final topics = <PublicTopic>[];

      final Stream<List<PublicTopic>> stream = ref
          .orderBy('updatedAt', descending: true)
          .snapshots()
          .map((snapshot) {
            topics.clear();

            for (final doc in snapshot.docs) {
              final topic = PublicTopic.fromJson(
                doc.id,
                Map<String, dynamic>.from(doc.data()),
              );
              topics.add(topic);
            }

            return topics;
          });

      return stream;
    } catch (e) {
      throw AppException(e.toString());
    }
  }

  Stream<PublicTopic> subscribeToTopic(String userId, String topicId) {
    try {
      return instance
          .collection('users')
          .doc(userId)
          .collection('topics')
          .doc(topicId)
          .snapshots()
          .map((doc) {
            if (!doc.exists) {
              throw AppException('Topic not found');
            }
            return PublicTopic.fromJson(
              doc.id,
              Map<String, dynamic>.from(doc.data()!),
            );
          });
    } catch (e) {
      throw AppException(e.toString());
    }
  }

  Stream<List<TopicMessage>> subscribeToTopicMessages(String topicId) {
    try {
      return instance
          .collection('topics')
          .doc(topicId)
          .collection('messages')
          .orderBy('createdAt')
          .snapshots()
          .map((snapshot) {
            return snapshot.docs.map((doc) {
              final data = doc.data();
              final type = data['type'] as String;

              if (type == 'image') {
                return TopicImageMessage.fromJson({'id': doc.id, ...data});
              }

              return TopicTextMessage.fromJson({'id': doc.id, ...data});
            }).toList();
          });
    } catch (e) {
      throw AppException(e.toString());
    }
  }

  Future<void> sendTopicMessage({
    required String topicId,
    required String userId,
    required String userDisplayName,
    required String userPhotoURL,
    required String content,
  }) async {
    try {
      await instance
          .collection('topics')
          .doc(topicId)
          .collection('messages')
          .add({
            'type': 'text',
            'userId': userId,
            'userDisplayName': userDisplayName,
            'userPhotoURL': userPhotoURL,
            'content': content,
            'createdAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      throw AppException(e.toString());
    }
  }
}

class _CachedUser {
  final User user;
  final DateTime timestamp;

  _CachedUser(this.user) : timestamp = DateTime.now();

  bool get isValid => DateTime.now().difference(timestamp).inMinutes < 10;
}
