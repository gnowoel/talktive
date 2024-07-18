import 'package:flutter_test/flutter_test.dart';
import 'package:talktive/models/room.dart';

void main() {
  group('Room', () {
    final json = <String, dynamic>{
      'id': 'id',
      'userId': 'userId',
      'userName': 'userName',
      'userCode': 'userCode',
      'languageCode': 'languageCode',
      'createdAt': 0,
      'updatedAt': 0,
      'closedAt': 0,
      'deletedAt': 0,
      'filter': 'filter',
    };

    test('constructor', () {
      final room = Room(
        id: json['id'] as String,
        userId: json['userId'] as String,
        userName: json['userName'] as String,
        userCode: json['userCode'] as String,
        languageCode: json['languageCode'] as String,
        createdAt: json['createdAt'] as int,
        updatedAt: json['updatedAt'] as int,
        closedAt: json['closedAt'] as int,
        deletedAt: json['deletedAt'] as int,
        filter: json['filter'] as String,
      );

      expect(room, isA<Room>());
    });

    test('fromJson()', () {
      final room = Room.fromJson(json);

      expect(room, isA<Room>());
    });

    test('toJson()', () {
      final roomObject = Room.fromJson(json);
      final roomJson = roomObject.toJson();

      expect(roomJson['id'], equals(json['id']));
    });
  });

  group('RoomStub', () {
    final json = <String, dynamic>{
      'userId': 'userId',
      'userName': 'userName',
      'userCode': 'userCode',
      'languageCode': 'languageCode',
      'createdAt': 0,
      'updatedAt': 0,
      'closedAt': 0,
      'deletedAt': 0,
      'filter': 'filter',
    };

    test('constructor', () {
      final roomStub = RoomStub(
        userId: json['userId'] as String,
        userName: json['userName'] as String,
        userCode: json['userCode'] as String,
        languageCode: json['languageCode'] as String,
        createdAt: json['createdAt'] as int,
        updatedAt: json['updatedAt'] as int,
        closedAt: json['closedAt'] as int,
        deletedAt: json['deletedAt'] as int,
        filter: json['filter'] as String,
      );

      expect(roomStub, isA<RoomStub>());
    });

    test('fromJson()', () {
      final roomStub = RoomStub.fromJson(json);

      expect(roomStub, isA<RoomStub>());
    });

    test('toJson()', () {
      final roomStubObject = RoomStub.fromJson(json);
      final roomStubJson = roomStubObject.toJson();

      expect(roomStubJson['id'], isNull);
      expect(roomStubJson['userId'], equals(json['userId']));
    });

    test('Room.fromStub()', () {
      const key = 'key';
      final roomStub = RoomStub.fromJson(json);
      final room = Room.fromStub(
        key: key,
        value: roomStub,
      );

      expect(room, isA<Room>());
      expect(room.id, equals(key));
    });
  });
}
