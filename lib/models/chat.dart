import '../services/clock.dart';
import 'user.dart';

class Chat {
  final String id;
  final int createdAt;
  final int updatedAt;
  final UserStub partner;
  final int messageCount;
  final int? readMessageCount;
  final String? firstUserId;
  final String? lastMessageContent;

  Chat({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.partner,
    required this.messageCount,
    this.readMessageCount,
    this.firstUserId,
    this.lastMessageContent,
  });

  Chat copyWith({
    String? id,
    int? createdAt,
    int? updatedAt,
    UserStub? partner,
    int? messageCount,
    int? readMessageCount,
    String? firstUserId,
    String? lastMessageContent,
  }) {
    return Chat(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      partner: partner ?? this.partner,
      messageCount: messageCount ?? this.messageCount,
      readMessageCount: readMessageCount ?? this.readMessageCount,
      firstUserId: firstUserId ?? this.firstUserId,
      lastMessageContent: lastMessageContent ?? this.lastMessageContent,
    );
  }

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
      readMessageCount: value.readMessageCount,
      firstUserId: value.firstUserId,
      lastMessageContent: value.lastMessageContent,
    );
  }

  static dummy() {
    return Chat(
      id: 'id',
      createdAt: 0,
      updatedAt: 0,
      partner: UserStub(
        createdAt: 0,
        updatedAt: 0,
      ),
      messageCount: 0,
    );
  }

  bool get isNew => firstUserId == null;

  bool get isClosed {
    const threeDays = 1000 * 3600 * 72;
    return updatedAt + threeDays <= Clock().serverNow();
  }

  bool get isDummy {
    return createdAt == 0 && updatedAt == 0;
  }
}

class ChatStub {
  final int createdAt;
  final int updatedAt;
  final UserStub partner;
  final int messageCount;
  final int? readMessageCount;
  final String? firstUserId;
  final String? lastMessageContent;

  ChatStub({
    required this.createdAt,
    required this.updatedAt,
    required this.partner,
    required this.messageCount,
    this.readMessageCount,
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
      readMessageCount: json['readMessageCount'] as int?,
      firstUserId: json['firstUserId'] as String?,
      lastMessageContent: json['lastMessageContent'] as String?,
    );
  }
}
