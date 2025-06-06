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
    super.recalled = false,
    super.revivedAt,
    super.reportCount,
  }) : super(type: 'text');

  TextMessage copyWith({
    String? id,
    String? userId,
    String? userDisplayName,
    String? userPhotoURL,
    String? content,
    int? createdAt,
    bool? recalled,
    int? revivedAt,
    int? reportCount,
  }) {
    return TextMessage(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userDisplayName: userDisplayName ?? this.userDisplayName,
      userPhotoURL: userPhotoURL ?? this.userPhotoURL,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      recalled: recalled ?? this.recalled,
      revivedAt: revivedAt ?? this.revivedAt,
      reportCount: reportCount ?? this.reportCount,
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
      'recalled': recalled,
      'revivedAt': revivedAt,
      if (reportCount != null) 'reportCount': reportCount,
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
      recalled: json['recalled'] as bool? ?? false,
      revivedAt: json['revivedAt'] as int?,
      reportCount: json['reportCount'] as int?,
    );
  }
}
