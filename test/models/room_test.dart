import 'package:flutter_test/flutter_test.dart';
import 'package:talktive/models/room.dart';

import '../mock.dart';

void main() {
  setupMocks();

  Map<String, dynamic> generateJson() {
    return <String, dynamic>{
      'id': 'id',
      'topic': 'topic',
      'userId': 'userId',
      'userName': 'userName',
      'userCode': 'userCode',
      'languageCode': 'languageCode',
      'createdAt': 0,
      'updatedAt': 0,
      'closedAt': 0,
      'filter': 'filter',
    };
  }

  group('Room', () {
    test('constructor', () {
      final json = generateJson();

      final room = Room(
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

      expect(room, isA<Room>());
    });

    test('fromJson()', () {
      final json = generateJson();

      final room = Room.fromJson(json);

      expect(room, isA<Room>());
    });

    test('copyWith()', () {
      final json = generateJson();
      final room = Room.fromJson(json);

      final room1 = room.copyWith(topic: 'topic1');
      final room2 = room.copyWith(topic: 'topic2');

      expect(room1.id, equals(room2.id));
      expect(room1.topic, isNot(equals(room2.topic)));
    });

    test('toJson()', () {
      final json = generateJson();

      final roomObject = Room.fromJson(json);
      final roomJson = roomObject.toJson();

      expect(roomJson['id'], equals(json['id']));
    });
  });

  group('RoomStub', () {
    test('constructor', () {
      final json = generateJson();
      json['id'] = null;

      final roomStub = RoomStub(
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

      expect(roomStub, isA<RoomStub>());
    });

    test('fromJson()', () {
      final json = generateJson();
      json['id'] = null;

      final roomStub = RoomStub.fromJson(json);

      expect(roomStub, isA<RoomStub>());
    });

    test('toJson()', () {
      final json = generateJson();
      json['id'] = null;

      final roomStubObject = RoomStub.fromJson(json);
      final roomStubJson = roomStubObject.toJson();

      expect(roomStubJson['id'], isNull);
      expect(roomStubJson['userId'], equals(json['userId']));
    });

    test('Room.fromStub()', () {
      final json = generateJson();
      json['id'] = null;

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

  group('utils', () {
    final json = generateJson();

    test('isNew', () {
      final room = Room.fromJson(json);
      final roomNew = room.copyWith(filter: 'en-nnnn');

      expect(room.isNew, isFalse);
      expect(roomNew.isNew, isTrue);
    });

    test('isMarkedClosed', () {
      final room = Room.fromJson(json);
      final roomMarkedClosed = room.copyWith(filter: '-cccc');

      expect(room.isMarkedClosed, isFalse);
      expect(roomMarkedClosed.isMarkedClosed, isTrue);
    });

    test('isClosed', () {
      final past = DateTime.now().subtract(const Duration(days: 1));
      final future = DateTime.now().add(const Duration(days: 1));

      final room = Room.fromJson(json);
      final roomMarkedClosed = room.copyWith(filter: '-cccc');
      final roomClosed = room.copyWith(closedAt: past.millisecondsSinceEpoch);
      final roomOpen = room.copyWith(closedAt: future.millisecondsSinceEpoch);

      expect(room.isClosed, isTrue);
      expect(roomMarkedClosed.isClosed, isTrue);
      expect(roomClosed.isClosed, isTrue);
      expect(roomOpen.isClosed, isFalse);
    });

    test('isDeleted', () {
      final room = Room.fromJson(json);
      final roomDeleted = room.copyWith(filter: '-dddd');

      expect(room.isDeleted, isFalse);
      expect(roomDeleted.isDeleted, isTrue);
    });

    test('isFromRecord', () {
      final room = Room.fromJson(json);
      final roomFromRecord = room.copyWith(filter: '-rrrr');

      expect(room.isFromRecord, isFalse);
      expect(roomFromRecord.isFromRecord, isTrue);
    });
  });
}
