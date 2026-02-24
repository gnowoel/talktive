import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'client_provider.dart';

part 'user_likes_provider.g.dart';

@riverpod
class UserLikes extends _$UserLikes {
  @override
  FutureOr<List<String>> build() async {
    return fetchLikes();
  }

  Future<List<String>> fetchLikes() async {
    try {
      final client = ref.read(clientProvider);
      return await client.userLike.getMyLikedUserIds();
    } catch (e) {
      return [];
    }
  }

  Future<void> likeUser(String userId) async {
    final client = ref.read(clientProvider);
    await client.userLike.likeUser(userId);

    // Refresh the list from server to ensure accuracy
    ref.invalidateSelf();
    await future;
  }

  Future<void> unlikeUser(String userId) async {
    final client = ref.read(clientProvider);
    await client.userLike.unlikeUser(userId);

    // Refresh the list from server to ensure accuracy
    ref.invalidateSelf();
    await future;
  }
}
