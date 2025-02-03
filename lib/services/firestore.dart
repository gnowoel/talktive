import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user.dart';
import '../helpers/exception.dart';

class Firestore {
  final FirebaseFirestore instance;

  Firestore(this.instance);

  static final firebaseFirestore = FirebaseFirestore.instance;

  int _lastTouchedUser = 0;

  Future<List<User>> fetchUsers(String userId, int serverNow) async {
    try {
      final users = <User>[];

      final snapshot = await instance
          .collection('users')
          .orderBy('updatedAt', descending: true)
          .limit(32)
          .get();

      for (final doc in snapshot.docs) {
        final data = doc.data();

        if (_isUserDataComplete(data)) {
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

      return users;
    } catch (e) {
      throw AppException(e.toString());
    } finally {
      _tryTouchUser(userId, serverNow);
    }
  }

  bool _isUserDataComplete(Map<String, dynamic> data) {
    const requiredFields = ['createdAt', 'updatedAt'];
    return requiredFields.every(data.containsKey);
  }

  Future<void> _tryTouchUser(String userId, int serverNow) async {
    try {
      final threeMinutes = 3 * 60 * 1000;
      final shouldTouch = serverNow >= _lastTouchedUser + threeMinutes;

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
