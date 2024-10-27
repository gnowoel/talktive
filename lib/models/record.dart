class Record {
  final String roomId;
  final String roomTopic;
  final String roomUserId;
  final String roomUserName;
  final String roomUserCode;
  final int createdAt;
  final int messageCount;
  final double scrollOffset;
  final bool visible;

  Record({
    required this.roomId,
    required this.roomTopic,
    required this.roomUserId,
    required this.roomUserName,
    required this.roomUserCode,
    required this.createdAt,
    required this.messageCount,
    required this.scrollOffset,
    required this.visible,
  });

  Record copyWith({
    String? roomId,
    String? roomTopic,
    String? roomUserId,
    String? roomUserName,
    String? roomUserCode,
    int? createdAt,
    int? messageCount,
    double? scrollOffset,
    bool? visible,
  }) {
    return Record(
      roomId: roomId ?? this.roomId,
      roomTopic: roomTopic ?? this.roomTopic,
      roomUserId: roomUserId ?? this.roomUserId,
      roomUserName: roomUserName ?? this.roomUserName,
      roomUserCode: roomUserCode ?? this.roomUserCode,
      createdAt: createdAt ?? this.createdAt,
      messageCount: messageCount ?? this.messageCount,
      scrollOffset: scrollOffset ?? this.scrollOffset,
      visible: visible ?? this.visible,
    );
  }

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
      'visible': visible,
    };
  }

  factory Record.fromJson(Map<String, dynamic> json) {
    return Record(
      roomId: json['roomId'] as String,
      roomTopic: json['roomTopic'] as String,
      roomUserId: json['roomUserId'] as String,
      roomUserName: json['roomUserName'] as String,
      roomUserCode: json['roomUserCode'] as String,
      createdAt: json['createdAt'] as int,
      messageCount: json['messageCount'] as int,
      scrollOffset: json['scrollOffset'] as double,
      visible: json['visible'] as bool,
    );
  }
}
