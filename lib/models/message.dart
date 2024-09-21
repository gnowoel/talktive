class Message {
  String? id;
  final String userId;
  final String userName;
  final String userCode;
  final String content;
  final int createdAt;

  Message({
    this.id,
    required this.userId,
    required this.userName,
    required this.userCode,
    required this.content,
    required this.createdAt,
  });

  Message copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userCode,
    String? content,
    int? createdAt,
  }) {
    return Message(
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

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String?,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      userCode: json['userCode'] as String,
      content: json['content'] as String,
      createdAt: json['createdAt'] as int,
    );
  }
}
