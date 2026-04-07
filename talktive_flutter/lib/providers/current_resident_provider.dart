import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:talktive_client/talktive_client.dart';
import '../serverpod_client.dart';
import '../../providers/client_provider.dart'; // Retained as it's a dependency and not explicitly removed
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import 'user_profile_provider.dart';

part 'current_resident_provider.g.dart';

/// Provider for the current logged-in resident's data.
@riverpod
class CurrentResident extends _$CurrentResident {
  @override
  FutureOr<Resident?> build() async {
    // Watch auth state to refresh when user logs in/out
    final authStateAsync = ref.watch(authProvider);

    // Check if auth state has loaded
    if (authStateAsync.isLoading || !authStateAsync.hasValue) {
      return null;
    }

    final authState = authStateAsync.value;
    if (authState is! Authenticated) {
      return null;
    }

    return fetchCurrentResident();
  }

  Future<Resident?> fetchCurrentResident() async {
    if (!sessionManager.isAuthenticated) return null;
    final client = ref.read(clientProvider);
    final authStateAsync = ref.read(authProvider);

    // Get the current auth state value
    if (!authStateAsync.hasValue) {
      return null;
    }

    final authState = authStateAsync.value;
    if (authState is! Authenticated) {
      return null;
    }

    try {
      // Get the current user's resident data using userId
      final resident = await client.resident.getResident();
      return resident;
    } catch (e) {
      debugPrint('CurrentResident: Fetch error: $e');
      // Return null instead of throwing to avoid breaking the UI
      return null;
    }
  }

  /// Refreshes the current resident's data.
  Future<void> refresh() async {
    if (!sessionManager.isAuthenticated) return;
    final oldResident = state.value;
    state = const AsyncValue.loading();
    try {
      final resident = await fetchCurrentResident();
      state = AsyncValue.data(resident);

      // Trigger level-up notification
      if (oldResident != null &&
          resident != null &&
          resident.level > oldResident.level) {
        ref
            .read(inAppNotificationProvider.notifier)
            .show(
              DuoNotification(
                title: 'Level Up! 🏢',
                message: "You've reached Floor ${resident.level}!",
                emoji: '🎉',
              ),
            );
      }

      // Also invalidate the profile view for the current user to refresh stats
      if (resident != null) {
        ref.invalidate(userProfileProvider(resident.userInfoId.toString()));
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

/// Provider to fetch a resident by their user ID.
@riverpod
Future<Resident?> residentById(Ref ref, String userId) async {
  final client = ref.read(clientProvider);
  try {
    return await client.resident.getResidentById(userId);
  } catch (e) {
    debugPrint('ResidentById: Fetch error for $userId: $e');
    return null;
  }
}
