import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:talktive_client/talktive_client.dart';
import 'client_provider.dart';

part 'group_provider.g.dart';

/// Provider for listing all groups.
@riverpod
class GroupList extends _$GroupList {
  @override
  FutureOr<List<Group>> build() async {
    return fetchGroups();
  }

  Future<List<Group>> fetchGroups() async {
    final client = ref.read(clientProvider);
    try {
      return await client.group.listGroups(limit: 50, offset: 0);
    } catch (e) {
      debugPrint('GroupList: Fetch error: $e');
      rethrow;
    }
  }

  /// Creates a new group.
  Future<Group> createGroup(
    String name, {
    String? description,
    String? emoji,
    bool isPublic = false,
    int maxMembers = 50,
  }) async {
    final client = ref.read(clientProvider);
    try {
      final group = await client.group.createGroup(
        name,
        description: description,
        emoji: emoji,
        isPublic: isPublic,
        maxMembers: maxMembers,
      );

      // Refresh the list to include the new group
      ref.invalidateSelf();

      return group;
    } catch (e) {
      debugPrint('GroupList: Create group error: $e');
      rethrow;
    }
  }

  /// Joins a group.
  Future<void> joinGroup(int groupId) async {
    final client = ref.read(clientProvider);
    try {
      await client.group.joinGroup(groupId);

      // Refresh the list
      ref.invalidateSelf();
    } catch (e) {
      debugPrint('GroupList: Join group error: $e');
      rethrow;
    }
  }

  /// Leaves a group.
  Future<void> leaveGroup(int groupId) async {
    final client = ref.read(clientProvider);
    try {
      await client.group.leaveGroup(groupId);

      // Refresh the list
      ref.invalidateSelf();
    } catch (e) {
      debugPrint('GroupList: Leave group error: $e');
      rethrow;
    }
  }

  /// Refreshes the group list.
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final groups = await fetchGroups();
      state = AsyncValue.data(groups);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

/// Provider for getting details about a specific group.
@riverpod
Future<Group> groupDetails(Ref ref, int groupId) async {
  final client = ref.read(clientProvider);
  try {
    return await client.group.getGroup(groupId);
  } catch (e) {
    debugPrint('GroupDetails: Fetch error: $e');
    rethrow;
  }
}

/// Provider for getting members of a group.
@riverpod
Future<List<Resident>> groupMembers(Ref ref, int groupId) async {
  final client = ref.read(clientProvider);
  try {
    return await client.group.getGroupMembers(groupId);
  } catch (e) {
    debugPrint('GroupMembers: Fetch error: $e');
    rethrow;
  }
}
