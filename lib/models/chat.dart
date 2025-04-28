abstract class Chat {
  final String id;
  final int createdAt;
  final int updatedAt;
  final int messageCount;
  final String type; // 'chat' or 'topic'
  final int? readMessageCount;

  const Chat({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.messageCount,
    required this.type,
    this.readMessageCount,
  });

  int get unreadCount => (messageCount - (readMessageCount ?? 0));
}
