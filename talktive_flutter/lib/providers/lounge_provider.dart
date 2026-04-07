import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:talktive_client/talktive_client.dart';
import '../serverpod_client.dart';
import 'client_provider.dart';
import 'auth_provider.dart';

part 'lounge_provider.g.dart';

/// Provider for listing all lounges.
@riverpod
class LoungeList extends _$LoungeList {
  @override
  FutureOr<List<LoungeWithMembership>> build() async {
    final authState = ref.watch(authProvider);
    if (authState.isLoading ||
        !authState.hasValue ||
        authState.value is! Authenticated) {
      return const <LoungeWithMembership>[];
    }
    return fetchLounges();
  }

  Future<List<LoungeWithMembership>> fetchLounges() async {
    if (!canMakeAuthenticatedCalls) return const [];
    final client = ref.read(clientProvider);
    try {
      return await client.lounge.listMyLounges(limit: 50, offset: 0);
    } catch (e) {
      debugPrint('LoungeList: Fetch error: $e');
      rethrow;
    }
  }

  /// Creates a new lounge.
  Future<Lounge> createLounge(
    String name, {
    String? description,
    String? emoji,
    bool isPublic = false,
    int maxMembers = 50,
    List<String>? interests,
    List<String>? languages,
    String? country,
    String? rules,
  }) async {
    final client = ref.read(clientProvider);
    try {
      final lounge = await client.lounge.createLounge(
        name,
        description: description,
        emoji: emoji,
        isPublic: isPublic,
        maxMembers: maxMembers,
        interests: interests,
        languages: languages,
        country: country,
        rules: rules,
      );

      // Refresh the list to include the new lounge
      ref.invalidateSelf();

      return lounge;
    } catch (e) {
      debugPrint('LoungeList: Create lounge error: $e');
      rethrow;
    }
  }

  /// Updates an existing lounge.
  Future<Lounge> updateLounge(
    int loungeId, {
    String? name,
    String? description,
    String? emoji,
    bool? isPublic,
    int? maxMembers,
    List<String>? interests,
    List<String>? languages,
    String? country,
    String? rules,
  }) async {
    final client = ref.read(clientProvider);
    try {
      final lounge = await client.lounge.updateLounge(
        loungeId,
        name: name,
        description: description,
        emoji: emoji,
        isPublic: isPublic,
        maxMembers: maxMembers,
        interests: interests,
        languages: languages,
        country: country,
        rules: rules,
      );

      // Refresh the list to include the updated lounge
      ref.invalidateSelf();

      return lounge;
    } catch (e) {
      debugPrint('LoungeList: Update lounge error: $e');
      rethrow;
    }
  }

  /// Applies to join a lounge.
  Future<void> applyToLounge(int loungeId) async {
    final client = ref.read(clientProvider);
    try {
      await client.lounge.applyToLounge(loungeId);

      // Refresh the list
      ref.invalidateSelf();
    } catch (e) {
      debugPrint('LoungeList: Apply to lounge error: $e');
      rethrow;
    }
  }

  /// Responds to a lounge invite.
  Future<void> respondToInvite(int loungeId, bool accept) async {
    final client = ref.read(clientProvider);
    try {
      await client.lounge.respondToLoungeInvite(loungeId, accept);

      // Refresh the list
      ref.invalidateSelf();
    } catch (e) {
      debugPrint('LoungeList: Respond to invite error: $e');
      rethrow;
    }
  }

  /// Leaves a lounge.
  Future<void> leaveLounge(int loungeId) async {
    final client = ref.read(clientProvider);
    try {
      await client.lounge.leaveLounge(loungeId);

      // Refresh the list
      ref.invalidateSelf();
    } catch (e) {
      debugPrint('LoungeList: Leave lounge error: $e');
      rethrow;
    }
  }

  /// Toggles mute status for a lounge.
  Future<void> toggleMuteLounge(int loungeId, bool isMuted) async {
    final client = ref.read(clientProvider);
    try {
      await client.lounge.toggleMuteLounge(loungeId, isMuted);
      ref.invalidateSelf();
    } catch (e) {
      debugPrint('LoungeList: Toggle mute error: $e');
      rethrow;
    }
  }

  /// Refreshes the lounge list.
  Future<void> refresh() async {
    if (!canMakeAuthenticatedCalls) return;
    state = const AsyncValue.loading();
    try {
      final lounges = await fetchLounges();
      state = AsyncValue.data(lounges);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

/// Provider for getting details about a specific lounge.
@riverpod
Future<Lounge> loungeDetails(Ref ref, int loungeId) async {
  if (!canMakeAuthenticatedCalls) {
    throw Exception('User is not authenticated');
  }
  final client = ref.read(clientProvider);
  try {
    return await client.lounge.getLounge(loungeId);
  } catch (e) {
    debugPrint('LoungeDetails: Fetch error: $e');
    rethrow;
  }
}

/// Provider for getting members of a lounge with their profiles.
@riverpod
Future<List<LoungeMemberWithProfile>> loungeMembersWithProfiles(
  Ref ref,
  int loungeId,
) async {
  if (!canMakeAuthenticatedCalls) return const [];
  final client = ref.read(clientProvider);
  try {
    return await client.lounge.getLoungeMembers(loungeId);
  } catch (e) {
    debugPrint('LoungeMembersWithProfiles: Fetch error: $e');
    return const [];
  }
}

/// Provider for getting pending applications of a lounge.
@riverpod
Future<List<LoungeMemberWithProfile>> pendingApplications(
  Ref ref,
  int loungeId,
) async {
  if (!canMakeAuthenticatedCalls) return const [];
  final client = ref.read(clientProvider);
  try {
    return await client.lounge.getPendingApplications(loungeId);
  } catch (e) {
    debugPrint('PendingApplications: Fetch error: $e');
    return const [];
  }
}

/// Provider for getting members of a lounge.
@riverpod
Future<List<Resident>> loungeMembers(Ref ref, int loungeId) async {
  if (!canMakeAuthenticatedCalls) return const [];
  final client = ref.read(clientProvider);
  try {
    final members = await client.lounge.getLoungeMembers(loungeId);
    return members.map((m) => m.resident).toList();
  } catch (e) {
    debugPrint('LoungeMembers: Fetch error: $e');
    return const [];
  }
}

/// Provider for getting a single lounge with membership from the current user.
@riverpod
Future<LoungeWithMembership?> loungeWithMembership(
  Ref ref,
  int loungeId,
) async {
  final lounges = await ref.watch(loungeListProvider.future);
  final memberLounge = lounges
      .where((g) => g.lounge.id == loungeId)
      .firstOrNull;

  if (memberLounge != null) {
    return memberLounge;
  }

  // Fallback: If not found in list (e.g. deep link to a lounge not in main list),
  // we could try to fetch individual details, but LoungeWithMembership
  // is usually only returned from the listMyLounges endpoint for the current user.
  // Let's at least try to see if it's there by refreshing or just returning null.
  return null;
}
