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

      final ref = firedata.instance.ref('rooms/${room.id}');
      final snapshot = await ref.get();
      final json = Map<String, dynamic>.from(snapshot.value as Map);
      final roomStub = RoomStub.fromJson(json);
      final updatedRoom = Room.fromStub(key: snapshot.key!, value: roomStub);

      expect(updatedRoom.topic, isNot(equals(room.userName)));
      expect(updatedRoom.topic, equals('new topic'));
    });

    test('can create an access', () async {
      await firedata.createAccess('roomId1');
      await firedata.createAccess('roomId2');

      final ref = firedata.instance.ref('accesses');
      final snapshot = await ref.get();
      final children = snapshot.children.toList();

      expect(children.length, 2);
    });
  });
}
