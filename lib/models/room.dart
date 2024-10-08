import '../services/clock.dart';
import 'record.dart';

class Room {
  final String id;
  final String topic;
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
    required this.topic,
    required this.userId,
    required this.userName,
    required this.userCode,
    required this.languageCode,
    required this.createdAt,
    required this.updatedAt,
    required this.closedAt,
    required this.filter,
  });

  Room copyWith({
    String? id,
    String? topic,
    String? userId,
    String? userName,
    String? userCode,
    String? languageCode,
    int? createdAt,
    int? updatedAt,
    int? closedAt,
    String? filter,
  }) {
    return Room(
      id: id ?? this.id,
      topic: topic ?? this.topic,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userCode: userCode ?? this.userCode,
      languageCode: languageCode ?? this.languageCode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      closedAt: closedAt ?? this.closedAt,
      filter: filter ?? this.filter,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'topic': topic,
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
      topic: json['topic'] as String,
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
      topic: value.topic,
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
      topic: record.roomTopic,
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

  static dummyDeletedRoom() {
    return Room(
      id: 'id',
      topic: 'topic',
      userId: 'userId',
      userName: 'userName',
      userCode: 'userCode',
      languageCode: 'languageCode',
      createdAt: 0,
      updatedAt: 0,
      closedAt: 0,
      filter: '-dddd',
    );
  }

  bool get isNew => filter.endsWith('-nnnn');

  bool get isClosed => isMarkedClosed || closedAt <= Clock().serverNow();

  bool get isMarkedClosed => filter == '-cccc';

  bool get isDeleted => filter == '-dddd';

  bool get isFromRecord => filter == '-rrrr';
}

class RoomStub {
  final String topic;
  final String userId;
  final String userName;
  final String userCode;
  final String languageCode;
  final int createdAt;
  final int updatedAt;
  final int closedAt;
  final String filter;

  RoomStub({
    required this.topic,
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
      'topic': topic,
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
      topic: json['topic'] as String,
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
