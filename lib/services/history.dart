import 'dart:convert';

import '../models/record.dart';
import '../models/room.dart';
import 'prefs.dart';

class History {
  final prefs = Prefs();
  final records = <Record>[];

  Future<void> saveRecord(Room room) async {
    final record = Record(
      roomId: room.id,
      roomUserId: room.userId,
      roomUserName: room.userName,
      roomUserCode: room.userCode,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );

    records.removeWhere((element) => element.roomId == record.roomId);
    records.add(record);

    await prefs.setString('records', jsonEncode(records));
  }
}
