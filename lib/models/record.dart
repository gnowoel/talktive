class Record {
  final String roomId;
  final String roomUserId;
  final String roomUserName;
  final String roomUserCode;
  final int createdAt;

  Record({
    required this.roomId,
    required this.roomUserId,
    required this.roomUserName,
    required this.roomUserCode,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'roomId': roomId,
      'roomUserId': roomUserId,
      'roomUserName': roomUserName,
      'roomUserCode': roomUserCode,
      'createdAt': createdAt,
    };
  }

  factory Record.fromJson(Map<String, dynamic> json) {
    return Record(
      roomId: json['roomId'] as String,
      roomUserId: json['roomUserId'] as String,
      roomUserName: json['roomUserName'] as String,
      roomUserCode: json['roomUserCode'] as String,
      createdAt: json['createdAt'] as int,
    );
  }
}
