import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../models/follow.dart';
import '../models/user.dart';
import '../helpers/exception.dart';

class Firestore {
  final FirebaseFirestore instance;
  Firestore(this.instance);
  static final firebaseFirestore = FirebaseFirestore.instance;

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
    return instance
        .collection('users')
        .doc(userId)
        .collection('followees')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => Follow.fromJson({'id': doc.id, ...doc.data()}))
                  .toList(),
        );
  }

  Stream<List<Follow>> subscribeToFollowers(String userId) {
    return instance
        .collection('users')
        .doc(userId)
        .collection('followers')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => Follow.fromJson({'id': doc.id, ...doc.data()}))
                  .toList(),
        );
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
}

class _CachedUser {
  final User user;
  final DateTime timestamp;

  _CachedUser(this.user) : timestamp = DateTime.now();

  bool get isValid => DateTime.now().difference(timestamp).inMinutes < 10;
}
