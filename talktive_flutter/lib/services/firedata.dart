import 'dart:async';

import 'package:firebase_database/firebase_database.dart';

import '../helpers/exception.dart';
import '../helpers/platform.dart';
import '../models/admin.dart';
import '../models/user.dart';
import 'messaging.dart';

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

  /// Updates a user's role in the database
  /// [userId] - The ID of the user to update
  /// [role] - The new role ('admin', 'moderator', or null to remove role)
  Future<void> updateUserRole(String userId, String? role) async {
    try {
      final ref = instance.ref('users/$userId');
      final serverTimestamp = ServerValue.timestamp;

      final updates = <String, dynamic>{'updatedAt': serverTimestamp};

      if (role != null) {
        updates['role'] = role;
      } else {
        // Remove the role field by setting it to null
        updates['role'] = null;
      }

      await ref.update(updates);
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
}
