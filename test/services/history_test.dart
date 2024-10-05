import 'package:flutter_test/flutter_test.dart';
import 'package:talktive/models/room.dart';
import 'package:talktive/services/history.dart';

import '../mock.dart';

void main() {
  setupMocks();

  final history = History();
  const currentUserId = 'currentUserId';
  const messageCount = 0;
  const scrollOffset = 0.0;

  Map<String, dynamic> generateJson() {
    return <String, dynamic>{
      'topic': 'topic',
      'userId': 'uid',
      'userName': 'name',
      'userCode': 'code',
      'languageCode': 'lang',
      'createdAt': 0,
      'updatedAt': 0,
      'closedAt': 0,
      'filter': 'filter',
    };
  }

  Room generateRoom(String id, [String? userId]) {
    final json = generateJson();
    json['id'] = id;

    if (userId != null) {
      json['userId'] = userId;
    }

    return Room.fromJson(json);
  }

  Future<void> saveHistoryRecord(String id, [String? userId]) async {
    await history.saveRecord(
      room: generateRoom(id, userId),
      currentUserId: currentUserId,
      messageCount: messageCount,
      scrollOffset: scrollOffset,
    );
  }

  group('History', () {
    test('can save records', () async {
      await saveHistoryRecord('id-1');
      await saveHistoryRecord('id-2');
      final recentRecords = history.recentRecords;
      expect(recentRecords, hasLength(2));
    });

    test('can save records (by me)', () async {
      await saveHistoryRecord('id-3', 'me');
      await saveHistoryRecord('id-4', 'currentUserId');
      final recentRecords = history.recentRecords;
      expect(recentRecords[0].roomUserId, equals('me'));
      expect(recentRecords[1].roomUserId, equals('me'));
    });
  });
}
