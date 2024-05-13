import 'record.dart';

class Room {
  final String id;
  final String userId;
  final String userName;
  final String userCode;
  final String languageCode;
  final int createdAt;
  final int updatedAt;

  Room({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userCode,
    required this.languageCode,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userCode': userCode,
      'languageCode': languageCode,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: json['id'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      userCode: json['userCode'] as String,
      languageCode: json['languageCode'] as String,
      createdAt: json['createdAt'] as int,
      updatedAt: json['updatedAt'] as int,
    );
  }

  factory Room.fromValue({
    required String key,
    required RoomValue value,
  }) {
    return Room(
      id: key,
      userId: value.userId,
      userName: value.userName,
      userCode: value.userCode,
      languageCode: value.languageCode,
      createdAt: value.createdAt,
      updatedAt: value.updatedAt,
    );
  }

  factory Room.fromRecord({required Record record}) {
    return Room(
      id: record.roomId,
      userId: record.roomUserId,
      userName: record.roomUserName,
      userCode: record.roomUserCode,
      languageCode: '',
      createdAt: 0,
      updatedAt: 0,
    );
  }
}

class RoomValue {
  final String userId;
  final String userName;
  final String userCode;
  final String languageCode;
  final int createdAt;
  final int updatedAt;

  RoomValue({
    required this.userId,
    required this.userName,
    required this.userCode,
    required this.languageCode,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'userCode': userCode,
      'languageCode': languageCode,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory RoomValue.fromJson(Map<String, dynamic> json) {
    return RoomValue(
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      userCode: json['userCode'] as String,
      languageCode: json['languageCode'] as String,
      createdAt: json['createdAt'] as int,
      updatedAt: json['updatedAt'] as int,
    );
  }
}
