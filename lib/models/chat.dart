class Chat {
  final String id;
  final int createdAt;
  final int updatedAt;
  final List<String> followers;
  final int messageCount;
  final String? firstUserId;
  final String? lastMessageContent;

  Chat({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.followers,
    required this.messageCount,
    this.firstUserId,
    this.lastMessageContent,
  });
}
