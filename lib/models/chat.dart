import 'user.dart';

class Chat {
  final String id;
  final int createdAt;
  final int updatedAt;
  final UserStub partner;
  final int messageCount;
  final String? firstUserId;
  final String? lastMessageContent;

  Chat({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.partner,
    required this.messageCount,
    this.firstUserId,
    this.lastMessageContent,
  });

  factory Chat.fromStub({
    required String key,
    required ChatStub value,
  }) {
    return Chat(
      id: key,
      createdAt: value.createdAt,
      updatedAt: value.updatedAt,
      partner: value.partner,
      messageCount: value.messageCount,
      firstUserId: value.firstUserId,
      lastMessageContent: value.lastMessageContent,
    );
  }
}

class ChatStub {
  final int createdAt;
  final int updatedAt;
  final UserStub partner;
  final int messageCount;
  final String? firstUserId;
  final String? lastMessageContent;

  ChatStub({
    required this.createdAt,
    required this.updatedAt,
    required this.partner,
    required this.messageCount,
    this.firstUserId,
    this.lastMessageContent,
  });

  factory ChatStub.fromJson(Map<String, dynamic> json) {
    return ChatStub(
      createdAt: json['createdAt'] as int,
      updatedAt: json['updatedAt'] as int,
      partner:
          UserStub.fromJson(Map<String, dynamic>.from(json['partner'] as Map)),
      messageCount: json['messageCount'] as int,
      firstUserId: json['firstUserId'] as String?,
      lastMessageContent: json['lastMessageContent'] as String?,
    );
  }
}
