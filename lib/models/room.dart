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
  final String filter;

  Room({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userCode,
    required this.languageCode,
    required this.createdAt,
    required this.updatedAt,
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
      filter: '-zzzz',
    );
  }

  bool get isOpen {
    return isNew || isActive;
  }

  bool get isNew => createdAt > updatedAt;

  bool get isActive {
    final firedata = Firedata();
    final now = DateTime.fromMillisecondsSinceEpoch(firedata.now());
    final then = DateTime.fromMillisecondsSinceEpoch(updatedAt);
    return now.difference(then).inSeconds < 360; // TODO: 3600
  }
}

class RoomStub {
  final String userId;
  final String userName;
  final String userCode;
  final String languageCode;
  final int createdAt;
  final int updatedAt;
  final String filter;

  RoomStub({
    required this.userId,
    required this.userName,
    required this.userCode,
    required this.languageCode,
    required this.createdAt,
    required this.updatedAt,
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
      filter: json['filter'] as String,
    );
  }
}
