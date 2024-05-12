class Message {
  String? id;
  final String roomId;
  final String userId;
  final String userName;
  final String userCode;
  final String content;
  final int createdAt;

  Message({
    this.id,
    required this.roomId,
    required this.userId,
    required this.userName,
    required this.userCode,
    required this.content,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'roomId': roomId,
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
      roomId: json['roomId'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      userCode: json['userCode'] as String,
      content: json['content'] as String,
      createdAt: json['createdAt'] as int,
    );
  }
}
