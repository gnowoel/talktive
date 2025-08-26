import 'package:flutter_test/flutter_test.dart';
import 'package:talktive/models/user.dart';

void main() {
  group('User Role Tests', () {
    test('isAdmin returns true for admin role', () {
      final user = User(
        id: 'test-user',
        createdAt: 1234567890,
        updatedAt: 1234567890,
        role: 'admin',
      );

      expect(user.isAdmin, true);
      expect(user.isModerator, false);
      expect(user.isAdminOrModerator, true);
    });

    test('isModerator returns true for moderator role', () {
      final user = User(
        id: 'test-user',
        createdAt: 1234567890,
        updatedAt: 1234567890,
        role: 'moderator',
      );

      expect(user.isAdmin, false);
      expect(user.isModerator, true);
      expect(user.isAdminOrModerator, true);
    });

    test('role methods return false for null role', () {
      final user = User(
        id: 'test-user',
        createdAt: 1234567890,
        updatedAt: 1234567890,
        role: null,
      );

      expect(user.isAdmin, false);
      expect(user.isModerator, false);
      expect(user.isAdminOrModerator, false);
    });

    test('role methods return false for other roles', () {
      final user = User(
        id: 'test-user',
        createdAt: 1234567890,
        updatedAt: 1234567890,
        role: 'user',
      );

      expect(user.isAdmin, false);
      expect(user.isModerator, false);
      expect(user.isAdminOrModerator, false);
    });

    test('toJson includes role property', () {
      final user = User(
        id: 'test-user',
        createdAt: 1234567890,
        updatedAt: 1234567890,
        role: 'admin',
        displayName: 'Test User',
      );

      final json = user.toJson();
      expect(json['role'], 'admin');
      expect(json['id'], 'test-user');
      expect(json['displayName'], 'Test User');
    });

    test('toJson handles null role', () {
      final user = User(
        id: 'test-user',
        createdAt: 1234567890,
        updatedAt: 1234567890,
        role: null,
      );

      final json = user.toJson();
      expect(json['role'], null);
    });
  });

  group('UserStub Role Tests', () {
    test('UserStub fromJson parses role correctly', () {
      final json = {
        'createdAt': 1234567890,
        'updatedAt': 1234567890,
        'role': 'moderator',
        'displayName': 'Test User',
      };

      final userStub = UserStub.fromJson(json);
      expect(userStub.role, 'moderator');
    });

    test('UserStub fromJson handles null role', () {
      final json = {
        'createdAt': 1234567890,
        'updatedAt': 1234567890,
        'role': null,
      };

      final userStub = UserStub.fromJson(json);
      expect(userStub.role, null);
    });

    test('UserStub toJson includes role', () {
      final userStub = UserStub(
        createdAt: 1234567890,
        updatedAt: 1234567890,
        role: 'admin',
      );

      final json = userStub.toJson();
      expect(json['role'], 'admin');
    });

    test('UserStub fromJson parses isPublic correctly when true', () {
      final json = {
        'createdAt': 1234567890,
        'updatedAt': 1234567890,
        'isPublic': true,
        'displayName': 'Test User',
      };

      final userStub = UserStub.fromJson(json);
      expect(userStub.isPublic, true);
    });

    test('UserStub fromJson parses isPublic correctly when false', () {
      final json = {
        'createdAt': 1234567890,
        'updatedAt': 1234567890,
        'isPublic': false,
        'displayName': 'Test User',
      };

      final userStub = UserStub.fromJson(json);
      expect(userStub.isPublic, false);
    });

    test('UserStub fromJson handles null isPublic', () {
      final json = {
        'createdAt': 1234567890,
        'updatedAt': 1234567890,
        'isPublic': null,
      };

      final userStub = UserStub.fromJson(json);
      expect(userStub.isPublic, null);
    });

    test('UserStub toJson includes isPublic', () {
      final userStub = UserStub(
        createdAt: 1234567890,
        updatedAt: 1234567890,
        isPublic: false,
      );

      final json = userStub.toJson();
      expect(json['isPublic'], false);
    });

    test('User.fromStub preserves role', () {
      final userStub = UserStub(
        createdAt: 1234567890,
        updatedAt: 1234567890,
        role: 'moderator',
        displayName: 'Test User',
      );

      final user = User.fromStub(key: 'test-user', value: userStub);

      expect(user.role, 'moderator');
      expect(user.isModerator, true);
      expect(user.isAdmin, false);
      expect(user.isAdminOrModerator, true);
    });

    test('User.fromStub preserves isPublic when true', () {
      final userStub = UserStub(
        createdAt: 1234567890,
        updatedAt: 1234567890,
        isPublic: true,
        displayName: 'Test User',
      );

      final user = User.fromStub(key: 'test-user', value: userStub);

      expect(user.isPublic, true);
    });

    test('User.fromStub preserves isPublic when false', () {
      final userStub = UserStub(
        createdAt: 1234567890,
        updatedAt: 1234567890,
        isPublic: false,
        displayName: 'Test User',
      );

      final user = User.fromStub(key: 'test-user', value: userStub);

      expect(user.isPublic, false);
    });

    test('User.fromStub defaults isPublic to true when null', () {
      final userStub = UserStub(
        createdAt: 1234567890,
        updatedAt: 1234567890,
        isPublic: null,
        displayName: 'Test User',
      );

      final user = User.fromStub(key: 'test-user', value: userStub);

      expect(user.isPublic, true);
    });

    test('User constructor defaults isPublic to true', () {
      final user = User(
        id: 'test-user',
        createdAt: 1234567890,
        updatedAt: 1234567890,
        displayName: 'Test User',
      );

      expect(user.isPublic, true);
    });
  });
}
