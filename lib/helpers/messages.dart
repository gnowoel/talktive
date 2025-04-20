import '../models/private_chat.dart';

int chatsUnreadMessageCount(List<PrivateChat> chats) {
  return chats
      .map((chat) => chatUnreadMessageCount(chat))
      .fold<int>(0, (sum, el) => sum + el);
}

int chatUnreadMessageCount(PrivateChat chat) {
  final diff = chat.messageCount - chat.readMessageCount!;
  return diff > 0 ? diff : 0;
}
