import 'message.dart';

class TextMessage extends Message {
  final String userId;
  final String userDisplayName;
  final String userPhotoURL;
  final String content;

  const TextMessage({
    super.id,
    required super.createdAt,
    required this.userId,
    required this.userDisplayName,
    required this.userPhotoURL,
    required this.content,
  }) : super(type: 'text');

  TextMessage copyWith({
    String? id,
    String? userId,
    String? userDisplayName,
    String? userPhotoURL,
    String? content,
    int? createdAt,
  }) {
    return TextMessage(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userDisplayName: userDisplayName ?? this.userDisplayName,
      userPhotoURL: userPhotoURL ?? this.userPhotoURL,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userDisplayName': userDisplayName,
      'userPhotoURL': userPhotoURL,
      'content': content,
      'type': type,
      'createdAt': createdAt,
    };
  }

  factory TextMessage.fromJson(Map<String, dynamic> json) {
    return TextMessage(
      id: json['id'] as String?,
      userId: json['userId'] as String,
      userDisplayName: json['userDisplayName'] as String,
      userPhotoURL: json['userPhotoURL'] as String,
      content: json['content'] as String,
      createdAt: json['createdAt'] as int,
    );
  }
}
