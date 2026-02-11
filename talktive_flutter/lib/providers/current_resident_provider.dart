import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:talktive_client/talktive_client.dart';
import 'client_provider.dart';
import 'auth_provider.dart';

part 'current_resident_provider.g.dart';

/// Provider for the current logged-in resident's data.
@riverpod
class CurrentResident extends _$CurrentResident {
  @override
  FutureOr<Resident?> build() async {
    // Watch auth state to refresh when user logs in/out
    final authStateAsync = ref.watch(authProvider);

    // Check if auth state has loaded
    if (!authStateAsync.hasValue) {
      return null;
    }

    final authState = authStateAsync.value;
    if (authState is! Authenticated) {
      return null;
    }

    return fetchCurrentResident();
  }

  Future<Resident?> fetchCurrentResident() async {
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
      print('CurrentResident: Fetch error: $e');
      // Return null instead of throwing to avoid breaking the UI
      return null;
    }
  }

  /// Refreshes the current resident's data.
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final resident = await fetchCurrentResident();
      state = AsyncValue.data(resident);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}
