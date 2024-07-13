import 'package:flutter_test/flutter_test.dart';
import 'package:talktive/models/room.dart';
import 'package:talktive/services/history.dart';

import '../mocks.dart';

void main() {
  setupMocks();

  group('History', () {
    final history = History();
    final room = Room(
      id: 'id',
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
    const currentUserId = 'currentUid';
    const messageCount = 0;
    const scrollOffset = 0.0;

    test('.saveRecord()', () async {
      await history.saveRecord(
        room: room,
        currentUserId: currentUserId,
        messageCount: messageCount,
        scrollOffset: scrollOffset,
      );
      final recentRecords = history.recentRecords;
      expect(recentRecords.length, equals(1));
    });
  });
}
