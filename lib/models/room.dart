import '../services/firedata.dart';
import 'record.dart';

class Room {
  final String id;
  final String userId;
  final String userName;
  final String userCode;
  final String languageCode;
  final int createdAt;
  final int updatedAt;
  final int closedAt;
  final String filter;

  Room({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userCode,
    required this.languageCode,
    required this.createdAt,
    required this.updatedAt,
    required this.closedAt,
    required this.filter,
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
      'closedAt': closedAt,
      'filter': filter,
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
      closedAt: json['closedAt'] as int,
      filter: json['filter'] as String,
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
      createdAt: value.createdAt,
      updatedAt: value.updatedAt,
      closedAt: value.closedAt,
      filter: value.filter,
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
      closedAt: 0,
      filter: '-rrrr',
    );
  }

  bool get isNew => filter.endsWith('-aaaa');

  bool get isClosed => isMarkedClosed || closedAt <= Firedata().serverNow();

  bool get isMarkedClosed => filter.endsWith('-zzzz');

  bool get isDeleted => false; // TODO: need to implement

  bool get isFromRecord => filter == '-rrrr';
}

class RoomStub {
  final String userId;
  final String userName;
  final String userCode;
  final String languageCode;
  final int createdAt;
  final int updatedAt;
  final int closedAt;
  final String filter;

  RoomStub({
    required this.userId,
    required this.userName,
    required this.userCode,
    required this.languageCode,
    required this.createdAt,
    required this.updatedAt,
    required this.closedAt,
    required this.filter,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'userCode': userCode,
      'languageCode': languageCode,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'closedAt': closedAt,
      'filter': filter,
    };
  }

  factory RoomStub.fromJson(Map<String, dynamic> json) {
    return RoomStub(
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      userCode: json['userCode'] as String,
      languageCode: json['languageCode'] as String,
      createdAt: json['createdAt'] as int,
      updatedAt: json['updatedAt'] as int,
      closedAt: json['closedAt'] as int,
      filter: json['filter'] as String,
    );
  }
}
