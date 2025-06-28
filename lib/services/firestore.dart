import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../helpers/time.dart';
import '../models/follow.dart';
import '../models/topic.dart';
import '../models/topic_message.dart';
import '../models/tribe.dart';
import '../models/user.dart';
import '../helpers/exception.dart';
import 'report_cache.dart';

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
  final List<Topic> _cachedTopics = [];
  final Map<String, List<Topic>> _cachedTopicsByTribe = {};
  int? _lastUserUpdatedAt;
  int? _lastTopicUpdatedAt;
  final Map<String, int?> _lastTribeTopicUpdatedAt = {};

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

  Future<Topic> createTopic({
    required User user,
    required String title,
    required String message,
    String? tribeId,
    bool isPublic = true,
  }) async {
    try {
      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('createTopic');

      final response = await callable.call({
        'userId': user.id,
        'title': title,
        'message': message,
        'tribeId': tribeId,
        'isPublic': isPublic,
      });

      final result = response.data;

      if (result['success'] != true) {
        throw Exception(result['error'] ?? 'Failed to create topic');
      }

      final topicId = result['topicId'];

      // Invalidate relevant caches since a new topic was created
      clearTopicsCache();
      if (tribeId != null) {
        clearTribeTopicsCache(tribeId);
      }

      return _createInitialDummyTopic(topicId, user, isPublic);
    } catch (e) {
      throw AppException(e.toString());
    }
  }

  Topic _createInitialDummyTopic(String topicId, User user, bool isPublic) {
    return Topic(
      id: topicId,
      createdAt: 0,
      updatedAt: 0,
      title: '',
      creator: user,
      messageCount: 1,
      tribeId: null,
      isPublic: isPublic,
    );
  }

  Future<List<Tribe>> fetchTribes() async {
    try {
      final snapshot = await instance
          .collection('tribes')
          .orderBy('sort') // Primary sort by sort field
          .orderBy('topicCount',
              descending: true) // Secondary sort by popularity
          .limit(100)
          .get();

      return snapshot.docs
          .map((doc) => Tribe.fromJson(doc.id, doc.data()))
          .toList();
    } catch (e) {
      throw AppException(e.toString());
    }
  }

  Future<List<Topic>> fetchTopicsByTribe(
    String tribeId,
    int serverNow, {
    bool noCache = false,
  }) async {
    try {
      // Clear cache if it's too old or explicitly requested
      if (noCache || _shouldRefreshTribeTopicsCache(tribeId, serverNow)) {
        clearTribeTopicsCache(tribeId);
      }

      final activePeriodAgo = serverNow - activePeriod;
      final timestamp = Timestamp.fromMillisecondsSinceEpoch(activePeriodAgo);

      var query = instance
          .collection('topics')
          .where('tribeId', isEqualTo: tribeId)
          .where('updatedAt', isGreaterThan: timestamp)
          .where('isPublic', isEqualTo: true)
          .orderBy('updatedAt', descending: true);

      // If we have cached data, only fetch topics updated since our last fetch
      final lastTribeUpdate = _lastTribeTopicUpdatedAt[tribeId];
      if (lastTribeUpdate != null) {
        final lastTimestamp = Timestamp.fromMillisecondsSinceEpoch(
          lastTribeUpdate,
        );
        query = query.where('updatedAt', isGreaterThan: lastTimestamp);
      }

      // Limit the result set size
      query = query.limit(32);

      // Execute the query
      final snapshot = await query.get();
      final fetchedTopics = snapshot.docs.map((doc) {
        return Topic.fromJson(doc.id, doc.data());
      }).toList();

      // Get existing cached topics for this tribe
      final cachedTopics = _cachedTopicsByTribe[tribeId] ?? [];

      // Merge fetched topics with cached topics
      if (fetchedTopics.isNotEmpty) {
        // Remove any topics from cache that have been updated
        cachedTopics.removeWhere(
          (cachedTopic) => fetchedTopics.any(
            (fetchedTopic) => fetchedTopic.id == cachedTopic.id,
          ),
        );

        // Add the new topics to cache
        cachedTopics.addAll(fetchedTopics);

        // Sort by most recent first
        cachedTopics.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

        // Limit cache size
        if (cachedTopics.length > 32) {
          cachedTopics.removeRange(32, cachedTopics.length);
        }

        // Update the cache and timestamp
        _cachedTopicsByTribe[tribeId] = cachedTopics;
        if (cachedTopics.isNotEmpty) {
          _lastTribeTopicUpdatedAt[tribeId] = cachedTopics.first.updatedAt;
        }
      }

      // Filter out topics with null tribeId (redundant for tribe-specific fetch, but defensive)
      return cachedTopics
          .where((topic) =>
              topic.updatedAt > activePeriodAgo && topic.tribeId != null)
          .toList();
    } catch (e) {
      throw AppException(e.toString());
    }
  }

  Future<List<Topic>> fetchTopics(
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
          .where('updatedAt', isGreaterThan: timestamp)
          .where('isPublic', isEqualTo: true);

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
        return Topic.fromJson(doc.id, doc.data());
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

      // Filter out topics with null tribeId and apply time filter
      return _cachedTopics
          .where((topic) =>
              topic.updatedAt > activePeriodAgo && topic.tribeId != null)
          .toList();
    } catch (e) {
      throw AppException(e.toString());
    }
  }

  void clearTopicsCache() {
    _cachedTopics.clear();
    _lastTopicUpdatedAt = null;
  }

  void clearTribeTopicsCache(String tribeId) {
    _cachedTopicsByTribe.remove(tribeId);
    _lastTribeTopicUpdatedAt.remove(tribeId);
  }

  void clearAllTopicsCache() {
    clearTopicsCache();
    _cachedTopicsByTribe.clear();
    _lastTribeTopicUpdatedAt.clear();
  }

  /// Force refresh all topics caches
  Future<void> refreshAllTopicsCache(int serverNow) async {
    clearAllTopicsCache();
  }

  /// Force refresh tribe topics cache
  Future<void> refreshTribeTopicsCache(String tribeId, int serverNow) async {
    clearTribeTopicsCache(tribeId);
  }

  /// Get cached topics count for a specific tribe
  int getCachedTribeTopicsCount(String tribeId) {
    return _cachedTopicsByTribe[tribeId]?.length ?? 0;
  }

  /// Get total cached topics count across all tribes
  int getTotalCachedTopicsCount() {
    return _cachedTopics.length +
        _cachedTopicsByTribe.values
            .fold(0, (result, topics) => result + topics.length);
  }

  bool _shouldRefreshTopicsCache(int serverNow) {
    if (_cachedTopics.isEmpty) return true;

    final oneHour = 1 * 60 * 60 * 1000;
    final lastCacheTime = _lastTopicUpdatedAt ?? 0;
    return serverNow >= lastCacheTime + oneHour;
  }

  bool _shouldRefreshTribeTopicsCache(String tribeId, int serverNow) {
    final cachedTopics = _cachedTopicsByTribe[tribeId];
    if (cachedTopics == null || cachedTopics.isEmpty) return true;

    final oneHour = 1 * 60 * 60 * 1000;
    final lastCacheTime = _lastTribeTopicUpdatedAt[tribeId] ?? 0;
    return serverNow >= lastCacheTime + oneHour;
  }

  Stream<List<Topic>> subscribeToTopics(String userId) {
    try {
      final ref = instance.collection('users').doc(userId).collection('topics');
      final topics = <Topic>[];

      final controller = StreamController<List<Topic>>();

      ref.orderBy('updatedAt', descending: true).snapshots().listen((snapshot) {
        for (final change in snapshot.docChanges) {
          final topic = Topic.fromJson(
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
          controller.add(List<Topic>.from(topics));
        }
      });

      return controller.stream;
    } catch (e) {
      throw AppException(e.toString());
    }
  }

  Stream<Topic> subscribeToTopic(String userId, String topicId) {
    try {
      return instance
          .collection('users')
          .doc(userId)
          .collection('topics')
          .doc(topicId)
          .snapshots()
          .map((doc) {
        if (!doc.exists) {
          return Topic.dummy();
        }
        return Topic.fromJson(
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

  Future<Map<String, dynamic>> inviteFollowersToTopic(
      String userId, String topicId) async {
    try {
      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('inviteFollowersToTopic');

      final result = await callable.call({
        'userId': userId,
        'topicId': topicId,
      });

      if (result.data['success'] != true) {
        throw Exception(
            result.data['error'] ?? 'Failed to invite followers to topic');
      }

      return {
        'invitedCount': result.data['invitedCount'] ?? 0,
        'message': result.data['message'] ?? '',
      };
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

        transaction.set(
            userTopicRef,
            {
              'readMessageCount': readMessageCount,
              'updatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true));
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

  Future<void> reportMessage({
    required String chatId,
    required String messageId,
    required String reporterUserId,
  }) async {
    try {
      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('reportMessage');

      final response = await callable.call({
        'chatId': chatId,
        'messageId': messageId,
        'reporterUserId': reporterUserId,
      });

      final result = response.data;

      if (result['success'] != true) {
        throw Exception(result['error'] ?? 'Failed to report message');
      }

      // Cache the reported message ID
      final reportCache = ReportCacheService();
      await reportCache.addReportedMessage(messageId);
    } catch (e) {
      throw AppException(e.toString());
    }
  }

  Future<void> reportTopicMessage({
    required String topicId,
    required String messageId,
    required String reporterUserId,
  }) async {
    try {
      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('reportTopicMessage');

      final response = await callable.call({
        'topicId': topicId,
        'messageId': messageId,
        'reporterUserId': reporterUserId,
      });

      final result = response.data;

      if (result['success'] != true) {
        throw Exception(result['error'] ?? 'Failed to report topic message');
      }

      // Cache the reported message ID
      final reportCache = ReportCacheService();
      await reportCache.addReportedMessage(messageId);
    } catch (e) {
      throw AppException(e.toString());
    }
  }

  Future<void> blockUserFromTopic({
    required String topicId,
    required String userId,
  }) async {
    try {
      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('blockUserFromTopic');

      final response = await callable.call({
        'topicId': topicId,
        'userId': userId,
      });

      final result = response.data;

      if (result['success'] != true) {
        throw Exception(result['error'] ?? 'Failed to block user from topic');
      }
    } catch (e) {
      throw AppException(e.toString());
    }
  }

  /// Fetch a page of topic messages with pagination support
  Future<List<TopicMessage>> fetchTopicMessagesPage(
    String topicId, {
    int limit = 25,
    DocumentSnapshot? startAfterDoc,
    DocumentSnapshot? endBeforeDoc,
  }) async {
    try {
      var query = instance
          .collection('topics')
          .doc(topicId)
          .collection('messages')
          .orderBy('createdAt');

      // Apply pagination cursors
      if (startAfterDoc != null) {
        query = query.startAfterDocument(startAfterDoc);
      }
      if (endBeforeDoc != null) {
        query = query.endBeforeDocument(endBeforeDoc);
      }

      // Apply limit
      query = query.limit(limit);

      final snapshot = await query.get();
      final messages = <TopicMessage>[];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final type = data['type'] as String;

        if (type == 'image') {
          messages.add(TopicImageMessage.fromJson({'id': doc.id, ...data}));
        } else {
          messages.add(TopicTextMessage.fromJson({'id': doc.id, ...data}));
        }
      }

      messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return messages;
    } catch (e) {
      throw AppException(e.toString());
    }
  }

  /// Fetch topic messages before a specific timestamp (for loading older messages)
  Future<List<TopicMessage>> fetchTopicMessagesBeforeTimestamp(
    String topicId,
    DateTime beforeTimestamp, {
    int limit = 25,
  }) async {
    try {
      final timestamp = Timestamp.fromDate(beforeTimestamp);
      final query = instance
          .collection('topics')
          .doc(topicId)
          .collection('messages')
          .orderBy('createdAt', descending: true)
          .where('createdAt', isLessThan: timestamp)
          .limit(limit);

      final snapshot = await query.get();
      final messages = <TopicMessage>[];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final type = data['type'] as String;

        if (type == 'image') {
          messages.add(TopicImageMessage.fromJson({'id': doc.id, ...data}));
        } else {
          messages.add(TopicTextMessage.fromJson({'id': doc.id, ...data}));
        }
      }

      // Sort in ascending order (oldest first)
      messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return messages;
    } catch (e) {
      throw AppException(e.toString());
    }
  }

  /// Fetch topic messages after a specific timestamp (for loading newer messages)
  Future<List<TopicMessage>> fetchTopicMessagesAfterTimestamp(
    String topicId,
    DateTime afterTimestamp, {
    int limit = 25,
  }) async {
    try {
      final timestamp = Timestamp.fromDate(afterTimestamp);
      final query = instance
          .collection('topics')
          .doc(topicId)
          .collection('messages')
          .orderBy('createdAt')
          .where('createdAt', isGreaterThan: timestamp)
          .limit(limit);

      final snapshot = await query.get();
      final messages = <TopicMessage>[];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final type = data['type'] as String;

        if (type == 'image') {
          messages.add(TopicImageMessage.fromJson({'id': doc.id, ...data}));
        } else {
          messages.add(TopicTextMessage.fromJson({'id': doc.id, ...data}));
        }
      }

      messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return messages;
    } catch (e) {
      throw AppException(e.toString());
    }
  }

  /// Get the total count of messages in a topic
  Future<int> getTopicMessageCount(String topicId) async {
    try {
      final snapshot = await instance
          .collection('topics')
          .doc(topicId)
          .collection('messages')
          .get();

      return snapshot.docs.length;
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
