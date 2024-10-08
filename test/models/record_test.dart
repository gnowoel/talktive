import 'package:flutter_test/flutter_test.dart';
import 'package:talktive/models/record.dart';
import 'package:talktive/models/room.dart';

void main() {
  Map<String, dynamic> generateJson() {
    return <String, dynamic>{
      'roomId': 'roomId',
      'roomTopic': 'roomTopic',
      'roomUserId': 'roomUserId',
      'roomUserName': 'userName',
      'roomUserCode': 'userCode',
      'createdAt': 0,
      'messageCount': 0,
      'scrollOffset': 0.0,
    };
  }

  group('Record', () {
    test('constructor', () {
      final json = generateJson();

      final record = Record(
        roomId: json['roomId'] as String,
        roomTopic: json['roomTopic'] as String,
        roomUserId: json['roomUserId'] as String,
        roomUserName: json['roomUserName'] as String,
        roomUserCode: json['roomUserCode'] as String,
        createdAt: json['createdAt'] as int,
        messageCount: json['messageCount'] as int,
        scrollOffset: json['scrollOffset'] as double,
      );

      expect(record, isA<Record>());
    });

    test('fromJson()', () {
      final json = generateJson();

      final record = Record.fromJson(json);

      expect(record, isA<Record>());
    });

    test('toJson()', () {
      final json = generateJson();

      final recordObject = Record.fromJson(json);
      final recordJson = recordObject.toJson();

      expect(recordJson['roomId'], equals(json['roomId']));
    });

    test('Room.fromRecord()', () {
      final json = generateJson();

      final record = Record.fromJson(json);
      final room = Room.fromRecord(record: record);

      expect(room, isA<Room>());
      expect(room.id, equals(record.roomId));
    });
  });
}
