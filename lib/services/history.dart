import 'dart:convert';

import '../models/record.dart';
import '../models/room.dart';
import 'prefs.dart';

class History {
  final prefs = Prefs();
  final records = <Record>[];

  Future<void> loadRecords() async {
    final string = await prefs.getString('records');
    final list = string == null
        ? <Map<String, dynamic>>[]
        : jsonDecode(string).cast<Map<String, dynamic>>();

    records.clear();
    for (final entry in list) {
      records.add(Record.fromJson(entry));
    }
  }

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

  List<Record> get recentRecords {
    final oneDayAgo = DateTime.now().subtract(const Duration(days: 1));

    final list = records.where((record) {
      final createdAt = DateTime.fromMillisecondsSinceEpoch(record.createdAt);
      return !createdAt.isBefore(oneDayAgo);
    }).toList();

    return list.reversed.toList();
  }
}
