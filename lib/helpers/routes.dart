String encodeChatRoute(String chatId, String chatCreatedAt) {
  final encodedChatCreatedAt = Uri.encodeComponent(chatCreatedAt);
  return '/chats/chats/$chatId?chatCreatedAt=$encodedChatCreatedAt';
}

String encodeTopicRoute(String topicId, String topicCreatorId) {
  final encodedTopicCreatorId = Uri.encodeComponent(topicCreatorId);
  return '/chats/topics/$topicId?topicCreatorId=$encodedTopicCreatorId';
}

String encodeReportRoute(String userId, String chatId, String? chatCreatedAt) {
  final encodedUserId = Uri.encodeComponent(userId);
  final encodedChatCreatedAt = Uri.encodeComponent(chatCreatedAt ?? '0');
  return '/admin/reports/$chatId?userId=$encodedUserId&chatCreatedAt=$encodedChatCreatedAt';
}

String encodeChatLaunchRoute(String chatId, String chatCreatedAt) {
  final encodedChatCreatedAt = Uri.encodeComponent(chatCreatedAt);
  return '/launch/chat/$chatId?chatCreatedAt=$encodedChatCreatedAt';
}

String encodeTopicLaunchRoute(String topicId, String topicCreatorId) {
  final encodedTopicCreatorId = Uri.encodeComponent(topicCreatorId);
  return '/launch/topic/$topicId?topicCreatorId=$encodedTopicCreatorId';
}

String encodeTribeRoute(String tribeId) {
  return '/topics/tribe/$tribeId';
}

String encodeCreateTopicWithTribeRoute(String tribeId) {
  return '/topics/create?tribeId=$tribeId';
}
