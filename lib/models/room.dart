import 'record.dart';

class Room {
  final String id;
  final String userId;
  final String userName;
  final String userCode;
  final String languageCode;
  final bool isOpen;
  final int createdAt;
  final int updatedAt;

  Room({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userCode,
    required this.languageCode,
    required this.isOpen,
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
      isOpen: json['isOpen'] as bool,
      createdAt: json['createdAt'] as int,
      updatedAt: json['updatedAt'] as int,
    );
  }

  factory Room.fromStub({
    required String key,
    required RoomStub value,
  }) {
    return Room(
      id: key,
      userId: value.userId,
      userName: value.userName,
      userCode: value.userCode,
      languageCode: value.languageCode,
      isOpen: value.isOpen,
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
      isOpen: true,
      createdAt: 0,
      updatedAt: 0,
    );
  }

  bool isNew() {
    return createdAt > updatedAt;
  }

  bool isActive([DateTime? now]) {
    now = now ?? DateTime.now();
    final then = DateTime.fromMillisecondsSinceEpoch(updatedAt);
    return now.difference(then).inSeconds < 360; // TODO: 3600
  }
}

class RoomStub {
  final String userId;
  final String userName;
  final String userCode;
  final String languageCode;
  final bool isOpen;
  final int createdAt;
  final int updatedAt;

  RoomStub({
    required this.userId,
    required this.userName,
    required this.userCode,
    required this.languageCode,
    required this.isOpen,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'userCode': userCode,
      'languageCode': languageCode,
      'isOpen': isOpen,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory RoomStub.fromJson(Map<String, dynamic> json) {
    return RoomStub(
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      userCode: json['userCode'] as String,
      languageCode: json['languageCode'] as String,
      isOpen: json['isOpen'] as bool,
      createdAt: json['createdAt'] as int,
      updatedAt: json['updatedAt'] as int,
    );
  }
}
