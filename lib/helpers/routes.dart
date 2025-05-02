String encodeChatRoute(String chatId, String chatCreatedAt) {
  final encodedChatCreatedAt = Uri.encodeComponent(chatCreatedAt);
  return '/chats/$chatId?chatCreatedAt=$encodedChatCreatedAt';
}

String encodeTopicRoute(String topicId) {
  return '/topics/$topicId';
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

String encodeTopicLaunchRoute(String topicId) {
  return '/launch/topic/$topicId';
}
