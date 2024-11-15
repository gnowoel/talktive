import 'message.dart';

class TextMessage extends Message {
  String? id;
  final String userId;
  final String userName;
  final String userCode;
  final String content;
  final int createdAt;

  TextMessage({
    this.id,
    required this.userId,
    required this.userName,
    required this.userCode,
    required this.content,
    required this.createdAt,
  }) : super(type: 'text');

  TextMessage copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userCode,
    String? content,
    int? createdAt,
  }) {
    return TextMessage(
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
      'type': type,
      'createdAt': createdAt,
    };
  }

  factory TextMessage.fromJson(Map<String, dynamic> json) {
    return TextMessage(
      id: json['id'] as String?,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      userCode: json['userCode'] as String,
      content: json['content'] as String,
      createdAt: json['createdAt'] as int,
    );
  }
}
