import '../models/chat.dart';

int chatsUnreadMessageCount(List<Chat> chats) {
  return chats
      .map((chat) => chatUnreadMessageCount(chat))
      .fold<int>(0, (sum, el) => sum + el);
}

int chatUnreadMessageCount(Chat chat) {
  final diff = chat.messageCount - chat.readMessageCount!;
  return diff > 0 ? diff : 0;
}
