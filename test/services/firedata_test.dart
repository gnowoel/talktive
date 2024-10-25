import 'package:fake_firebase_database/fake_firebase_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talktive/models/message.dart';
import 'package:talktive/models/room.dart';
import 'package:talktive/services/firedata.dart';

void main() {
  final database = FakeFirebaseDatabase.instance;
  final firedata = Firedata(database);

  const userId = 'uid';
  const userName = 'name';
  const userCode = 'code';
  const languageCode = 'lang';
  const content = 'content';

  tearDown(() {
    database.clear();
  });

  group('Firedata', () {
    test('can instantiate Firedata', () async {
      expect(firedata, isA<Firedata>());
    });

    test('can create a room', () async {
      final room = await firedata.createRoom(
        userId,
        userName,
        userCode,
        languageCode,
      );

      expect(room.userId, equals('uid'));
    });

    test('can send a message', () async {
      final room = await firedata.createRoom(
        userId,
        userName,
        userCode,
        languageCode,
      );

      expect(room, isA<Room>());
      expect(room.userId, equals('uid'));

      final message = await firedata.sendMessage(
        room,
        userId,
        userName,
        userCode,
        content,
      );

      expect(message, isA<Message>());
      expect(message.content, equals(content));
    });

    test('can set default room topic', () async {
      final room = await firedata.createRoom(
        userId,
        userName,
        userCode,
        languageCode,
      );

      expect(room, isA<Room>());
      expect(room.userId, equals('uid'));
      expect(room.topic, equals(room.userName));
    });

    test('can update the room topic', () async {
      final room = await firedata.createRoom(
        userId,
        userName,
        userCode,
        languageCode,
      );

      expect(room, isA<Room>());
      expect(room.userId, equals('uid'));
      expect(room.topic, equals(room.userName));

      await firedata.updateRoomTopic(room, 'new topic');

      final ref = database.ref('rooms/${room.id}');
      final snapshot = await ref.get();
      final json = Map<String, dynamic>.from(snapshot.value as Map);
      final roomStub = RoomStub.fromJson(json);
      final updatedRoom = Room.fromStub(key: snapshot.key!, value: roomStub);

      expect(updatedRoom.topic, isNot(equals(room.userName)));
      expect(updatedRoom.topic, equals('new topic'));
    });

    test('can create an `access` record', () async {
      await firedata.createAccess('roomId1');
      await firedata.createAccess('roomId2');

      final ref = database.ref('accesses');
      final snapshot = await ref.get();
      final children = snapshot.children.toList();

      expect(children.length, 2);
    });

    group('selectRoom()', () {
      test('selects a room based on `filter`', () async {
        await firedata.createRoom('2', '2', '2', 'en-2222');
        await firedata.createRoom('1', '1', '1', 'en-1111');
        await firedata.createRoom('3', '3', '3', 'en-3333');

        final room = await firedata.selectRoom('en', []);

        expect(room?.userId, '1');
      });

      test('can skip visited rooms', () async {
        final room1 = await firedata.createRoom('2', '2', '2', 'en-2222');
        final room2 = await firedata.createRoom('1', '1', '1', 'en-1111');
        final room3 = await firedata.createRoom('3', '3', '3', 'en-3333');

        final recentRoomIds = [room1.id, room2.id, room3.id];
        final room = await firedata.selectRoom('en', recentRoomIds);

        expect(room, null);
      });

      test('does not select empty rooms', () async {
        await firedata.createRoom('1', '1', '1', 'en');
        await firedata.createRoom('2', '2', '2', 'en');
        await firedata.createRoom('3', '3', '3', 'en');

        final room = await firedata.selectRoom('en', []);
        expect(room, null);
      });

      test('can create an `expires` record when needed', () async {
        final room = await firedata.createRoom('0', '0', '0', 'en-0000');

        final roomRef = database.ref('rooms/${room.id}');
        await roomRef.update({'closedAt': 0});

        final snapshot1 = await roomRef.get();
        final json = Map<String, dynamic>.from(snapshot1.value as Map);

        expect(json['closedAt'], 0);

        await firedata.selectRoom('en', []);

        final expiresRef = database.ref('expires');
        final snapshot2 = await expiresRef.get();
        final children = snapshot2.children.toList();

        expect(children.length, 1);
      });
    });
  });
}
