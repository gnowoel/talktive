import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:talktive_client/talktive_client.dart';
import 'client_provider.dart';

part 'group_provider.g.dart';

/// Provider for listing all groups.
@riverpod
class GroupList extends _$GroupList {
  @override
  FutureOr<List<GroupWithMembership>> build() async {
    return fetchGroups();
  }

  Future<List<GroupWithMembership>> fetchGroups() async {
    final client = ref.read(clientProvider);
    try {
      return await client.group.listMyGroups(limit: 50, offset: 0);
    } catch (e) {
      debugPrint('GroupList: Fetch error: $e');
      rethrow;
    }
  }

  /// Creates a new group.
  Future<Group> createGroup(
    String name, {
    String? description,
    bool isPublic = false,
    int maxMembers = 50,
    List<String>? interests,
  }) async {
    final client = ref.read(clientProvider);
    try {
      final group = await client.group.createGroup(
        name,
        description: description,
        emoji: emoji,
        isPublic: isPublic,
        maxMembers: maxMembers,
        interests: interests,
      );

      // Refresh the list to include the new group
      ref.invalidateSelf();

      return group;
    } catch (e) {
      debugPrint('GroupList: Create group error: $e');
      rethrow;
    }
  }

  /// Applies to join a group.
  Future<void> applyToGroup(int groupId) async {
    final client = ref.read(clientProvider);
    try {
      await client.group.applyToGroup(groupId);

      // Refresh the list
      ref.invalidateSelf();
    } catch (e) {
      debugPrint('GroupList: Apply to group error: $e');
      rethrow;
    }
  }

  /// Responds to a group invite.
  Future<void> respondToInvite(int groupId, bool accept) async {
    final client = ref.read(clientProvider);
    try {
      await client.group.respondToGroupInvite(groupId, accept);
      
      // Refresh the list
      ref.invalidateSelf();
    } catch (e) {
      debugPrint('GroupList: Respond to invite error: $e');
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

/// Provider for getting members of a group with their profiles.
@riverpod
Future<List<GroupMemberWithProfile>> groupMembersWithProfiles(Ref ref, int groupId) async {
  final client = ref.read(clientProvider);
  try {
    return await client.group.getGroupMembersWithProfiles(groupId);
  } catch (e) {
    debugPrint('GroupMembersWithProfiles: Fetch error: $e');
    rethrow;
  }
}

/// Provider for getting pending applications of a group.
@riverpod
Future<List<GroupMemberWithProfile>> pendingApplications(Ref ref, int groupId) async {
  final client = ref.read(clientProvider);
  try {
    return await client.group.getPendingApplicationsWithProfiles(groupId);
  } catch (e) {
    debugPrint('PendingApplications: Fetch error: $e');
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
