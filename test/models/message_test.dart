import 'package:flutter_test/flutter_test.dart';
import 'package:talktive/models/message.dart';

void main() {
  group('Message', () {
    final json = <String, dynamic>{
      'id': 'id',
      'userId': 'userId',
      'userName': 'userName',
      'userCode': 'userCode',
      'content': 'content',
      'createdAt': 0,
    };

    test('constructor', () {
      final message = Message(
        id: json['id'] as String?,
        userId: json['userId'] as String,
        userName: json['userName'] as String,
        userCode: json['userCode'] as String,
        content: json['content'] as String,
        createdAt: json['createdAt'] as int,
      );

      expect(message, isA<Message>());
    });

    test('fromJson()', () {
      final message = Message.fromJson(json);

      expect(message, isA<Message>());
    });

    test('copyWith()', () {
      final message = Message.fromJson(json);

      final message1 = message.copyWith(content: 'content1');
      final message2 = message.copyWith(content: 'content2');

      expect(message1.id, equals(message2.id));
      expect(message1.content, isNot(equals(message2.content)));
    });

    test('toJson()', () {
      final messageObject = Message.fromJson(json);
      final messageJson = messageObject.toJson();

      expect(messageJson['roomId'], equals(json['roomId']));
    });
  });
}
