import 'message.dart';

class ImageMessage extends Message {
  String? id;
  final String userId;
  final String userName;
  final String userCode;
  final String content;
  final int createdAt;

  ImageMessage({
    this.id,
    required this.userId,
    required this.userName,
    required this.userCode,
    required this.content,
    required this.createdAt,
  }) : super(type: 'image');

  ImageMessage copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userCode,
    String? content,
    int? createdAt,
  }) {
    return ImageMessage(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userCode: userCode ?? this.userCode,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userCode': userCode,
      'content': content,
      'createdAt': createdAt,
    };
  }

  factory ImageMessage.fromJson(Map<String, dynamic> json) {
    return ImageMessage(
      id: json['id'] as String?,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      userCode: json['userCode'] as String,
      content: json['content'] as String,
      createdAt: json['createdAt'] as int,
    );
  }
}
