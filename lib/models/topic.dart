import 'package:cloud_firestore/cloud_firestore.dart';

import '../helpers/time.dart';
import '../services/server_clock.dart';
import 'conversation.dart';
import 'user.dart';

class Topic extends Conversation {
  final String title;
  final User creator;
  final String? lastMessageContent;
  final bool? mute;
  final String? tribeId;
  final bool isPublic;

  const Topic({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    required super.messageCount,
    required this.title,
    required this.creator,
    super.readMessageCount,
    this.lastMessageContent,
    this.mute,
    this.tribeId,
    this.isPublic = true,
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
      'tribeId': tribeId,
      'isPublic': isPublic,
    };
  }

  Topic copyWith({
    String? id,
    int? createdAt,
    int? updatedAt,
    int? messageCount,
    String? title,
    User? creator,
    int? readMessageCount,
    String? lastMessageContent,
    bool? mute,
    String? tribeId,
    bool? isPublic,
  }) {
    return Topic(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      messageCount: messageCount ?? this.messageCount,
      title: title ?? this.title,
      creator: creator ?? this.creator,
      readMessageCount: readMessageCount ?? this.readMessageCount,
      lastMessageContent: lastMessageContent ?? this.lastMessageContent,
      mute: mute ?? this.mute,
      tribeId: tribeId ?? this.tribeId,
      isPublic: isPublic ?? this.isPublic,
    );
  }

  factory Topic.fromJson(String id, Map<String, dynamic> json) {
    final creatorMap = Map<String, dynamic>.from(json['creator'] as Map);
    final creator = User.fromStub(
      key: creatorMap['id'] as String,
      value: UserStub.fromJson(creatorMap),
    );

    final timestamp = json['updatedAt'];
    final updatedAt = timestamp is Timestamp
        ? timestamp.millisecondsSinceEpoch
        : ServerClock().now; // Fallback to local timestamp if null

    return Topic(
      id: id,
      title: json['title'] as String,
      createdAt: (json['createdAt'] as Timestamp).millisecondsSinceEpoch,
      updatedAt: updatedAt,
      creator: creator,
      messageCount: json['messageCount'] as int,
      readMessageCount: json['readMessageCount'] as int?,
      lastMessageContent: json['lastMessageContent'] as String?,
      mute: json['mute'] as bool?,
      tribeId: json['tribeId'] as String?,
      isPublic: json['isPublic'] as bool? ?? true,
    );
  }

  static Topic dummy() {
    return Topic(
      id: 'topicId',
      createdAt: 0,
      updatedAt: 0,
      title: '',
      creator: User.fromStub(
        key: 'userId',
        value: UserStub(createdAt: 0, updatedAt: 0),
      ),
      messageCount: 0,
      tribeId: null,
      isPublic: true,
    );
  }

  bool get isClosed => updatedAt + activePeriod <= ServerClock().now;
  bool get isNotClosed => !isClosed;

  bool get isDummy => updatedAt == 0;
  bool get isNotDummy => !isDummy;

  bool get isMuted => mute ?? false;
  bool get isNotMuted => !isMuted;

  bool get isActive => isNotClosed && isNotMuted;
}
