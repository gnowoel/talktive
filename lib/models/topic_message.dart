import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/server_clock.dart';

abstract class TopicMessage {
  final String? id;
  final String userId;
  final String userDisplayName;
  final String userPhotoURL;
  final Timestamp createdAt;
  final bool? recalled;

  const TopicMessage({
    this.id,
    required this.userId,
    required this.userDisplayName,
    required this.userPhotoURL,
    required this.createdAt,
    this.recalled = false,
  });

  Map<String, dynamic> toJson();
}

class TopicTextMessage extends TopicMessage {
  final String content;

  const TopicTextMessage({
    super.id,
    required super.userId,
    required super.userDisplayName,
    required super.userPhotoURL,
    required super.createdAt,
    required this.content,
    super.recalled,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'text',
      'userId': userId,
      'userDisplayName': userDisplayName,
      'userPhotoURL': userPhotoURL,
      'content': content,
      'createdAt': createdAt,
      'recalled': recalled,
    };
  }

  factory TopicTextMessage.fromJson(Map<String, dynamic> json) {
    final timestamp = json['createdAt'];
    final createdAt =
        timestamp is Timestamp
            ? timestamp
            : Timestamp.fromMillisecondsSinceEpoch(
              ServerClock().now,
            ); // Fallback to local timestamp if null

    return TopicTextMessage(
      id: json['id'] as String?,
      userId: json['userId'] as String,
      userDisplayName: json['userDisplayName'] as String,
      userPhotoURL: json['userPhotoURL'] as String,
      content: json['content'] as String,
      createdAt: createdAt,
      recalled: json['recalled'] as bool? ?? false,
    );
  }
}

class TopicImageMessage extends TopicMessage {
  final String uri;
  final String content; // Usually '[Image]'

  const TopicImageMessage({
    super.id,
    required super.userId,
    required super.userDisplayName,
    required super.userPhotoURL,
    required super.createdAt,
    required this.uri,
    required this.content,
    super.recalled = false,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'image',
      'userId': userId,
      'userDisplayName': userDisplayName,
      'userPhotoURL': userPhotoURL,
      'uri': uri,
      'content': content,
      'createdAt': createdAt,
      'recalled': recalled,
    };
  }

  factory TopicImageMessage.fromJson(Map<String, dynamic> json) {
    final timestamp = json['createdAt'];
    final createdAt =
        timestamp is Timestamp
            ? timestamp
            : Timestamp.fromMillisecondsSinceEpoch(
              ServerClock().now,
            ); // Fallback to local timestamp if null

    return TopicImageMessage(
      id: json['id'] as String?,
      userId: json['userId'] as String,
      userDisplayName: json['userDisplayName'] as String,
      userPhotoURL: json['userPhotoURL'] as String,
      uri: json['uri'] as String,
      content: json['content'] as String,
      createdAt: createdAt,
      recalled: json['recalled'] as bool? ?? false,
    );
  }
}
