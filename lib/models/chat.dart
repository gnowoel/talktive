import '../helpers/time.dart';
import '../services/cache.dart';
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
  final bool? mute;

  Chat({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.partner,
    required this.messageCount,
    this.readMessageCount,
    this.firstUserId,
    this.lastMessageContent,
    this.mute,
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
    bool? mute,
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
      mute: mute ?? this.mute,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'partner': partner.toJson(),
      'messageCount': messageCount,
      'readMessageCount': readMessageCount,
      'firstUserId': firstUserId,
      'lastMessageContent': lastMessageContent,
      'mute': mute,
    };
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
      mute: value.mute,
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
  bool get isNotNew => !isNew;

  bool get isClosed => updatedAt + delay <= Cache().now;
  bool get isNotClosed => !isClosed;

  // Does not exist (not created or deleted)
  bool get isDummy => createdAt == 0 && updatedAt == 0;
  bool get isNotDummy => !isDummy;

  bool get isMuted => mute ?? false;
  bool get isNotMuted => !isMuted;

  bool get isActive => isNotNew && isNotClosed && isNotMuted;
}

class ChatStub {
  final int createdAt;
  final int updatedAt;
  final UserStub partner;
  final int messageCount;
  final int? readMessageCount;
  final String? firstUserId;
  final String? lastMessageContent;
  final bool? mute;

  ChatStub({
    required this.createdAt,
    required this.updatedAt,
    required this.partner,
    required this.messageCount,
    this.readMessageCount,
    this.firstUserId,
    this.lastMessageContent,
    this.mute,
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
      mute: json['mute'] as bool?,
    );
  }
}
