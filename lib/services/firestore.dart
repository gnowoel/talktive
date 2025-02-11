import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user.dart';
import '../helpers/exception.dart';

class Firestore {
  final FirebaseFirestore instance;
  Firestore(this.instance);
  static final firebaseFirestore = FirebaseFirestore.instance;

  int _lastTouchedUser = 0;
  final List<User> _cachedUsers = [];
  int? _lastUpdatedAt;

  Future<List<User>> fetchUsers(String userId, int serverNow) async {
    try {
      // Clear cache if it's too old
      if (_shouldRefreshCache(serverNow)) {
        clearCache();
      }

      var query = instance
          .collection('users')
          .orderBy('updatedAt', descending: true)
          .limit(32);

      if (_lastUpdatedAt != null) {
        query = query.endBefore([_lastUpdatedAt]);
      }

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
        _cachedUsers.removeWhere((cachedUser) =>
            fetchedUsers.any((fetchedUser) => fetchedUser.id == cachedUser.id));
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
      }, SetOptions(merge: true));

      _lastTouchedUser = serverNow;
    } catch (e) {
      throw AppException(e.toString());
    }
  }
}
