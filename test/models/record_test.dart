import 'package:flutter_test/flutter_test.dart';
import 'package:talktive/models/record.dart';

void main() {
  group('Record', () {
    final json = <String, dynamic>{
      'roomId': 'roomId',
      'roomUserId': 'roomUserId',
      'roomUserName': 'userName',
      'roomUserCode': 'userCode',
      'createdAt': 0,
      'messageCount': 0,
      'scrollOffset': 0.0,
    };

    test('constructor', () {
      final record = Record(
        roomId: json['roomId'] as String,
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
      final record = Record.fromJson(json);

      expect(record, isA<Record>());
    });

    test('toJson()', () {
      final recordObject = Record.fromJson(json);
      final recordJson = recordObject.toJson();

      expect(recordJson['roomId'], equals(json['roomId']));
    });
  });
}
