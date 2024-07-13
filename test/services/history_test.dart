import 'package:flutter_test/flutter_test.dart';
import 'package:talktive/models/room.dart';
import 'package:talktive/services/history.dart';

import '../mocks.dart';

void main() {
  setupMocks();

  final history = History();
  const currentUserId = 'currentUid';
  const messageCount = 0;
  const scrollOffset = 0.0;

  Room generateRoom(int number) {
    return Room(
      id: 'id-$number',
      userId: 'uid',
      userName: 'name',
      userCode: 'code',
      languageCode: 'lang',
      createdAt: 0,
      updatedAt: 0,
      closedAt: 0,
      deletedAt: 0,
      filter: 'filter',
    );
  }

  Future<void> saveHistoryRecord(int number) async {
    await history.saveRecord(
      room: generateRoom(number),
      currentUserId: currentUserId,
      messageCount: messageCount,
      scrollOffset: scrollOffset,
    );
  }

  group('History', () {
    test('can save records', () async {
      await saveHistoryRecord(1);
      await saveHistoryRecord(2);
      final recentRecords = history.recentRecords;
      expect(recentRecords, hasLength(2));
    });
  });
}
