class Record {
  final String roomId;
  final String roomTopic;
  final String roomUserId;
  final String roomUserName;
  final String roomUserCode;
  final int createdAt;
  final int messageCount;
  final double scrollOffset;

  Record({
    required this.roomId,
    required this.roomTopic,
    required this.roomUserId,
    required this.roomUserName,
    required this.roomUserCode,
    required this.createdAt,
    required this.messageCount,
    required this.scrollOffset,
  });

  Map<String, dynamic> toJson() {
    return {
      'roomId': roomId,
      'roomTopic': roomTopic,
      'roomUserId': roomUserId,
      'roomUserName': roomUserName,
      'roomUserCode': roomUserCode,
      'createdAt': createdAt,
      'messageCount': messageCount,
      'scrollOffset': scrollOffset,
    };
  }

  factory Record.fromJson(Map<String, dynamic> json) {
    return Record(
      roomId: json['roomId'] as String,
      // TODO: Just use `topic` after waiting for a while
      roomTopic: (json['roomTopic'] ?? json['roomUserName']) as String,
      roomUserId: json['roomUserId'] as String,
      roomUserName: json['roomUserName'] as String,
      roomUserCode: json['roomUserCode'] as String,
      createdAt: json['createdAt'] as int,
      messageCount: json['messageCount'] as int,
      scrollOffset: json['scrollOffset'] as double,
    );
  }
}
