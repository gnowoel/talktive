import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../helpers/time.dart';
import '../models/follow.dart';
import '../models/public_topic.dart';
import '../models/topic_message.dart';
import '../models/tribe.dart';
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
  final List<PublicTopic> _cachedTopics = [];
  int? _lastUserUpdatedAt;
  int? _lastTopicUpdatedAt;

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
      if (noCache || _shouldRefreshUsersCache(serverNow)) {
        clearUsersCache();
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

      if (_lastUserUpdatedAt != null) {
        // query = query.where('updatedAt', isGreaterThan: _lastUserUpdatedAt);
        query = query.endBefore([_lastUserUpdatedAt]);
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

        if (_cachedUsers.isNotEmpty) {
          _lastUserUpdatedAt = _cachedUsers.first.updatedAt;
        }
      }

      return List<User>.from(_cachedUsers);
    } catch (e) {
      throw AppException(e.toString());
    } finally {
      _tryTouchUser(userId, serverNow);
    }
  }

  void clearUsersCache() {
    _cachedUsers.clear();
    _lastUserUpdatedAt = null;
  }

  bool _shouldRefreshUsersCache(int serverNow) {
    if (_cachedUsers.isEmpty) return true;

    final oneHour = 1 * 60 * 60 * 1000;
    final lastCacheTime = _lastUserUpdatedAt ?? 0;
    return serverNow >= lastCacheTime + oneHour;
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

          final followees = _followeesCache.values.toList()
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

          final followers = _followersCache.values.toList()
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
    String? tribeId,
  }) async {
    try {
      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('createTopic');

      final response = await callable.call({
        'userId': user.id,
        'title': title,
        'message': message,
        'tribeId': tribeId,
      });

      final result = response.data;

      if (result['success'] != true) {
        throw Exception(result['error'] ?? 'Failed to create topic');
      }

      final topicId = result['topicId'];

      return _createInitialDummyTopic(topicId, user);
    } catch (e) {
      throw AppException(e.toString());
    }
  }

  PublicTopic _createInitialDummyTopic(String topicId, User user) {
    return PublicTopic(
      id: topicId,
      createdAt: 0,
      updatedAt: 0,
      title: '',
      creator: user,
      messageCount: 1,
      tribeId: null,
    );
  }

  Future<List<Tribe>> fetchTribes() async {
    try {
      final snapshot = await instance
          .collection('tribes')
          .orderBy('sort')  // Primary sort by sort field
          .orderBy('topicCount', descending: true)  // Secondary sort by popularity
          .limit(100)
          .get();

      return snapshot.docs
          .map((doc) => Tribe.fromJson(doc.id, doc.data()))
          .toList();
    } catch (e) {
      throw AppException(e.toString());
    }
  }

  Future<Tribe> createTribe({
    required String name,
    String? description,
    String? iconEmoji,
  }) async {
    try {
      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('createTribe');

      final response = await callable.call({
        'name': name,
        'description': description,
        'iconEmoji': iconEmoji,
      });

      final result = response.data;

      if (result['success'] != true) {
        throw Exception(result['error'] ?? 'Failed to create tribe');
      }

      final tribeId = result['tribeId'];
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      return Tribe(
        id: tribeId,
        name: name,
        createdAt: timestamp,
        topicCount: 0,
        description: description,
        iconEmoji: iconEmoji,
      );
    } catch (e) {
      throw AppException(e.toString());
    }
  }

  Future<List<PublicTopic>> fetchTopicsByTribe(String tribeId) async {
    try {
      final snapshot = await instance
          .collection('topics')
          .where('tribeId', isEqualTo: tribeId)
          .orderBy('updatedAt', descending: true)
          .limit(32)
          .get();

      final topics = snapshot.docs
          .map((doc) => PublicTopic.fromJson(doc.id, doc.data()))
          .toList();

      return topics;
    } catch (e) {
      throw AppException(e.toString());
    }
  }

  Future<List<PublicTopic>> fetchPublicTopics(
    int serverNow, {
    bool noCache = false,
    String? tribeId,
  }) async {
    try {
      // Clear cache if it's too old or explicitly requested
      if (noCache || _shouldRefreshTopicsCache(serverNow)) {
        clearTopicsCache();
      }

      // Define the time threshold for active topics
      final activePeriodAgo = serverNow - activePeriod;
      final timestamp = Timestamp.fromMillisecondsSinceEpoch(activePeriodAgo);

      // Start building the query
      var query = instance
          .collection('topics')
          .where('updatedAt', isGreaterThan: timestamp);

      // Add order and pagination
      query = query.orderBy('updatedAt', descending: true);

      // If we have cached data, only fetch topics updated since our last fetch
      if (_lastTopicUpdatedAt != null) {
        final lastTimestamp = Timestamp.fromMillisecondsSinceEpoch(
          _lastTopicUpdatedAt!,
        );
        query = query.where('updatedAt', isGreaterThan: lastTimestamp);
      }

      // Limit the result set size
      query = query.limit(32);

      // Execute the query
      final snapshot = await query.get();
      final fetchedTopics = snapshot.docs.map((doc) {
        return PublicTopic.fromJson(doc.id, doc.data());
      }).toList();

      // Merge fetched topics with cached topics
      if (fetchedTopics.isNotEmpty) {
        // Remove any topics from cache that have been updated
        _cachedTopics.removeWhere(
          (cachedTopic) => fetchedTopics.any(
            (fetchedTopic) => fetchedTopic.id == cachedTopic.id,
          ),
        );

        // Add the new topics to cache
        _cachedTopics.addAll(fetchedTopics);

        // Sort by most recent first
        _cachedTopics.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

        // Limit cache size
        if (_cachedTopics.length > 32) {
          _cachedTopics.removeRange(32, _cachedTopics.length);
        }

        // Update the timestamp of the most recently updated topic
        if (_cachedTopics.isNotEmpty) {
          _lastTopicUpdatedAt = _cachedTopics.first.updatedAt;
        }
      }

      return _cachedTopics
          .where((topic) => topic.updatedAt > activePeriodAgo)
          .toList();
    } catch (e) {
      throw AppException(e.toString());
    }
  }

  void clearTopicsCache() {
    _cachedTopics.clear();
    _lastTopicUpdatedAt = null;
  }

  bool _shouldRefreshTopicsCache(int serverNow) {
    if (_cachedTopics.isEmpty) return true;

    final oneHour = 1 * 60 * 60 * 1000;
    final lastCacheTime = _lastTopicUpdatedAt ?? 0;
    return serverNow >= lastCacheTime + oneHour;
  }

  Stream<List<PublicTopic>> subscribeToTopics(String userId) {
    try {
      final ref = instance.collection('users').doc(userId).collection('topics');
      final topics = <PublicTopic>[];

      final controller = StreamController<List<PublicTopic>>();

      ref.orderBy('updatedAt', descending: true).snapshots().listen((snapshot) {
        for (final change in snapshot.docChanges) {
          final topic = PublicTopic.fromJson(
            change.doc.id,
            Map<String, dynamic>.from(change.doc.data()!),
          );

          switch (change.type) {
            case DocumentChangeType.added:
              final index = topics.indexWhere((t) => t.id == topic.id);
              if (index == -1) {
                topics.add(topic);
              } else {
                topics[index] = topic;
              }
              break;

            case DocumentChangeType.modified:
              final index = topics.indexWhere((t) => t.id == topic.id);
              if (index != -1) {
                topics[index] = topic;
              }
              break;

            case DocumentChangeType.removed:
              topics.removeWhere((t) => t.id == topic.id);
              break;
          }

          topics.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
          controller.add(List<PublicTopic>.from(topics));
        }
      });

      return controller.stream;
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
              return PublicTopic.dummy();
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

  Stream<List<TopicMessage>> subscribeToTopicMessages(
    String topicId,
    int? lastTimestamp,
  ) {
    try {
      var query = instance
          .collection('topics')
          .doc(topicId)
          .collection('messages')
          .orderBy('createdAt');

      if (lastTimestamp != null) {
        final timestamp = Timestamp.fromMillisecondsSinceEpoch(lastTimestamp);
        query = query.where('createdAt', isGreaterThan: timestamp);
      }

      return query.snapshots().map((snapshot) {
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

  Future<void> sendTopicTextMessage({
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

  Future<void> sendTopicImageMessage({
    required String topicId,
    required String userId,
    required String userDisplayName,
    required String userPhotoURL,
    required String uri,
  }) async {
    try {
      await instance
          .collection('topics')
          .doc(topicId)
          .collection('messages')
          .add({
            'type': 'image',
            'userId': userId,
            'userDisplayName': userDisplayName,
            'userPhotoURL': userPhotoURL,
            'content': '[Image]',
            'uri': uri,
            'createdAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      throw AppException(e.toString());
    }
  }

  Future<void> joinTopic(String userId, String topicId) async {
    try {
      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('joinTopic');

      final result = await callable.call({
        'userId': userId,
        'topicId': topicId,
      });

      if (result.data['success'] != true) {
        throw Exception(result.data['error'] ?? 'Failed to join topic');
      }
    } catch (e) {
      throw AppException(e.toString());
    }
  }

  Future<void> muteTopic(String userId, String topicId) async {
    try {
      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('muteTopic');

      final result = await callable.call({
        'userId': userId,
        'topicId': topicId,
      });

      if (result.data['success'] != true) {
        throw Exception(result.data['error'] ?? 'Failed to mute topic');
      }
    } catch (e) {
      throw AppException(e.toString());
    }
  }

  Future<void> updateTopicReadMessageCount(
    String userId,
    String topicId, {
    required int readMessageCount,
  }) async {
    try {
      final userTopicRef = instance
          .collection('users')
          .doc(userId)
          .collection('topics')
          .doc(topicId);

      await instance.runTransaction((transaction) async {
        final userTopicDoc = await transaction.get(userTopicRef);
        if (!userTopicDoc.exists) {
          return;
        }

        transaction.set(userTopicRef, {
          'readMessageCount': readMessageCount,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      });
    } catch (e) {
      throw AppException(e.toString());
    }
  }

  Future<void> recallTopicMessage({
    required String topicId,
    required String messageId,
  }) async {
    try {
      await instance
          .collection('topics')
          .doc(topicId)
          .collection('messages')
          .doc(messageId)
          .update({'recalled': true});
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
