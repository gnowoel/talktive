String encodeChatRoute(String chatId, String chatCreatedAt) {
  final encodedChatCreatedAt = Uri.encodeComponent(chatCreatedAt);
  return '/chats/$chatId?chatCreatedAt=$encodedChatCreatedAt';
}

String encodeTopicRoute(String topicId, String topicCreatedAt) {
  final encodedTopicCreatedAt = Uri.encodeComponent(topicCreatedAt);
  return '/topics/$topicId?chatCreatedAt=$encodedTopicCreatedAt';
}

String encodeReportRoute(String userId, String chatId, String? chatCreatedAt) {
  final encodedUserId = Uri.encodeComponent(userId);
  final encodedChatCreatedAt = Uri.encodeComponent(chatCreatedAt ?? '0');
  return '/admin/reports/$chatId?userId=$encodedUserId&chatCreatedAt=$encodedChatCreatedAt';
}

String encodeLaunchRoute(String chatId, String chatCreatedAt) {
  final encodedChatCreatedAt = Uri.encodeComponent(chatCreatedAt);
  return '/launch/$chatId?chatCreatedAt=$encodedChatCreatedAt';
}
