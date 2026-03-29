import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:talktive_client/talktive_client.dart';
import 'client_provider.dart';
import 'auth_provider.dart';

part 'private_chat_provider.g.dart';

/// Provider for listing all private chats for the current user.
@riverpod
class PrivateChatList extends _$PrivateChatList {
  @override
  FutureOr<List<PrivateChatWithProfile>> build() async {
    final authState = ref.watch(authProvider);
    if (!authState.hasValue || authState.value is! Authenticated) {
      return const <PrivateChatWithProfile>[];
    }
    return fetchPrivateChats();
  }

  Future<List<PrivateChatWithProfile>> fetchPrivateChats() async {
    final client = ref.read(clientProvider);
    try {
      return await client.privateChat.listPrivateChats();
    } catch (e) {
      debugPrint('PrivateChatList: Fetch error: $e');
      rethrow;
    }
  }

  /// Creates or retrieves a private chat with another user.
  Future<PrivateChat> getOrCreateChat(
    String otherUserId, {
    String? initialMessage,
  }) async {
    final client = ref.read(clientProvider);
    try {
      final chat = await client.privateChat.getOrCreatePrivateChat(
        otherUserId,
        initialMessage: initialMessage,
      );

      // Refresh the list to include the new chat
      ref.invalidateSelf();

      return chat;
    } catch (e) {
      debugPrint('PrivateChatList: Create chat error: $e');
      rethrow;
    }
  }

  /// Leaves a private chat.
  Future<void> leaveChat(int channelId) async {
    final client = ref.read(clientProvider);
    try {
      await client.privateChat.leaveChat(channelId);
      // Refresh the local list
      ref.invalidateSelf();
    } catch (e) {
      debugPrint('PrivateChatList: Leave chat error: $e');
      rethrow;
    }
  }

  /// Refreshes the private chat list.
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final chats = await fetchPrivateChats();
      state = AsyncValue.data(chats);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Responds to a private chat invitation
  Future<void> respondToInvite(int channelId, bool accept) async {
    final client = ref.read(clientProvider);
    try {
      await client.privateChat.respondToChatInvite(channelId, accept);
      // Refresh the local list
      ref.invalidateSelf();
    } catch (e) {
      debugPrint('PrivateChatList: Error responding to invite: $e');
      rethrow;
    }
  }
}

/// Provider for getting details about a specific private chat.
@riverpod
Future<PrivateChatWithProfile?> privateChatDetails(
  Ref ref,
  int privateChatId,
) async {
  final client = ref.read(clientProvider);
  try {
    return await client.privateChat.getPrivateChatDetails(privateChatId);
  } catch (e) {
    debugPrint('PrivateChatDetails: Fetch error: $e');
    rethrow;
  }
}
