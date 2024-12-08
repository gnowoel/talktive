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

  Future<void> saveHistoryRecord(String roomId, [String? userId]) async {
    await history.saveRecord(
      room: generateRoom(roomId, userId),
      currentUserId: currentUserId,
      messageCount: messageCount,
      scrollOffset: scrollOffset,
    );
  }

  Future<void> hideHistoryRecord(String roomId) async {
    await history.hideRecord(roomId: roomId);
  }

  tearDown(() async {
    await history.clear();
  });

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

    test('can hide records', () async {
      await saveHistoryRecord('id-1');
      await saveHistoryRecord('id-2');

      final recentRecords1 = history.recentRecords;
      expect(recentRecords1, hasLength(2));

      await hideHistoryRecord('id-2');
      final recentRecords2 = history.recentRecords;
      expect(recentRecords2, hasLength(2));

      final visibleRecentRecords = history.visibleRecentRecords;
      expect(visibleRecentRecords, hasLength(1));
      expect(visibleRecentRecords.first.roomId, 'id-1');
    });
  });
}
