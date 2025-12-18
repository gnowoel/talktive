String encodeTopicRoute(String topicId, String topicCreatorId) {
  final encodedTopicCreatorId = Uri.encodeComponent(topicCreatorId);
  return '/chats/topics/$topicId?topicCreatorId=$encodedTopicCreatorId';
}

String encodeTopicLaunchRoute(String topicId, String topicCreatorId) {
  final encodedTopicCreatorId = Uri.encodeComponent(topicCreatorId);
  return '/launch/topic/$topicId?topicCreatorId=$encodedTopicCreatorId';
}

String encodeCreateTopicWithTribeRoute(String tribeId) {
  return '/topics/create?tribeId=$tribeId';
}
