import 'package:firebase_database_mocks/firebase_database_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talktive/models/message.dart';
import 'package:talktive/models/room.dart';
import 'package:talktive/services/firedata.dart';

import '../mock.dart';

void main() {
  setupMocks();

  final database = MockFirebaseDatabase.instance;
  final firedata = Firedata(instance: database);

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
  });
}
