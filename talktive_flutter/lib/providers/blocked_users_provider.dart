import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'client_provider.dart';

part 'blocked_users_provider.g.dart';

@riverpod
class BlockedUsers extends _$BlockedUsers {
  @override
  FutureOr<List<String>> build() async {
    return fetchBlockedUsers();
  }

  Future<List<String>> fetchBlockedUsers() async {
    try {
      final client = ref.read(clientProvider);
      return await client.userProfile.getBlockedUserIds();
    } catch (e) {
      return [];
    }
  }

  Future<void> block(String userId) async {
    final client = ref.read(clientProvider);
    await client.userProfile.blockUser(userId);
    ref.invalidateSelf();
  }

  Future<void> unblock(String userId) async {
    final client = ref.read(clientProvider);
    await client.userProfile.unblockUser(userId);
    ref.invalidateSelf();
  }
}
