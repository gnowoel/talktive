import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:serverpod_client/serverpod_client.dart';
import '../serverpod_client.dart';
import 'client_provider.dart';
import 'auth_provider.dart';

part 'social_relationships_provider.g.dart';

class SocialRelationships {
  final List<String> likedUserIds;
  final List<String> blockedUserIds;

  SocialRelationships({
    required this.likedUserIds,
    required this.blockedUserIds,
  });

  bool isLiked(String userId) => likedUserIds.contains(userId);
  bool isBlocked(String userId) => blockedUserIds.contains(userId);

  SocialRelationships copyWith({
    List<String>? likedUserIds,
    List<String>? blockedUserIds,
  }) {
    return SocialRelationships(
      likedUserIds: likedUserIds ?? this.likedUserIds,
      blockedUserIds: blockedUserIds ?? this.blockedUserIds,
    );
  }
}

@riverpod
class SocialRelationshipsState extends _$SocialRelationshipsState {
  @override
  FutureOr<SocialRelationships> build() async {
    final authState = ref.watch(authProvider);
    if (authState.isLoading ||
        !authState.hasValue ||
        authState.value is! Authenticated) {
      return SocialRelationships(likedUserIds: [], blockedUserIds: []);
    }

    final results = await Future.wait([fetchLikes(), fetchBlockedUsers()]);

    return SocialRelationships(
      likedUserIds: results[0],
      blockedUserIds: results[1],
    );
  }

  Future<List<String>> fetchLikes() async {
    if (!sessionManager.isAuthenticated) return [];
    try {
      final client = ref.read(clientProvider);
      return await client.resident.getMyLikedResidentIds();
    } catch (e) {
      return [];
    }
  }

  Future<List<String>> fetchBlockedUsers() async {
    if (!sessionManager.isAuthenticated) return [];
    try {
      final client = ref.read(clientProvider);
      return await client.resident.getBlockedResidentIds();
    } catch (e) {
      return [];
    }
  }

  Future<void> likeUser(String userId) async {
    final client = ref.read(clientProvider);
    await client.resident.vouchForResident(UuidValue.fromString(userId));
    ref.invalidateSelf();
  }

  Future<void> unlikeUser(String userId) async {
    final client = ref.read(clientProvider);
    await client.resident.removeResidentVouch(UuidValue.fromString(userId));
    ref.invalidateSelf();
  }

  Future<void> blockUser(String userId) async {
    final client = ref.read(clientProvider);
    await client.resident.blockResident(userId);
    ref.invalidateSelf();
  }

  Future<void> unblockUser(String userId) async {
    final client = ref.read(clientProvider);
    await client.resident.unblockResident(userId);
    ref.invalidateSelf();
  }

  Future<void> reportUser(
    String userId,
    String reason, {
    int? channelId,
    int? messageId,
  }) async {
    final client = ref.read(clientProvider);
    await client.resident.reportResident(
      targetUserId: userId,
      reason: reason,
      channelId: channelId,
      messageId: messageId,
    );
  }
}
