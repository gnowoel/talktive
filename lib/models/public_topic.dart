import 'package:cloud_firestore/cloud_firestore.dart';

import '../helpers/time.dart';
import '../services/server_clock.dart';
import 'chat.dart';
import 'user.dart';

class PublicTopic extends Chat {
  final String title;
  final User creator;
  final String? lastMessageContent;
  final bool? mute;

  const PublicTopic({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    required super.messageCount,
    required this.title,
    required this.creator,
    super.readMessageCount,
    this.lastMessageContent,
    this.mute,
  }) : super(type: 'topic');

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'createdAt': Timestamp.fromMillisecondsSinceEpoch(createdAt),
      'updatedAt': Timestamp.fromMillisecondsSinceEpoch(updatedAt),
      'creator': creator.toJson(),
      'messageCount': messageCount,
      'readMessageCount': readMessageCount,
      'lastMessageContent': lastMessageContent,
      'mute': mute,
    };
  }

  factory PublicTopic.fromJson(String id, Map<String, dynamic> json) {
    final creatorMap = Map<String, dynamic>.from(json['creator'] as Map);
    final creator = User.fromStub(
      key: creatorMap['id'] as String,
      value: UserStub.fromJson(creatorMap),
    );

    return PublicTopic(
      id: id,
      title: json['title'] as String,
      createdAt: (json['createdAt'] as Timestamp).millisecondsSinceEpoch,
      updatedAt: (json['updatedAt'] as Timestamp).millisecondsSinceEpoch,
      creator: creator,
      messageCount: json['messageCount'] as int,
      readMessageCount: json['readMessageCount'] as int?,
      lastMessageContent: json['lastMessageContent'] as String?,
      mute: json['mute'] as bool?,
    );
  }

  bool get isClosed => updatedAt + delay <= ServerClock().now;
  bool get isNotClosed => !isClosed;

  bool get isMuted => mute ?? false;
  bool get isNotMuted => !isMuted;

  bool get isActive => isNotClosed && isNotMuted;
}
