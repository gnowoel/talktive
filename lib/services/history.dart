import 'dart:convert';

import '../models/record.dart';
import '../models/room.dart';
import 'firedata.dart';
import 'prefs.dart';

class History {
  final prefs = Prefs();
  final _records = <Record>[];

  Future<void> loadRecords() async {
    final string = await prefs.getString('records');
    final list = string == null
        ? <Map<String, dynamic>>[]
        : jsonDecode(string).cast<Map<String, dynamic>>();

    _records.clear();
    for (final entry in list) {
      _records.add(Record.fromJson(entry));
    }
  }

  Future<void> saveRecord({
    required Room room,
    required double scrollOffset,
  }) async {
    final record = Record(
      roomId: room.id,
      roomUserId: room.userId,
      roomUserName: room.userName,
      roomUserCode: room.userCode,
      createdAt: Firedata().now(),
      scrollOffset: scrollOffset,
    );

    _records.removeWhere((element) {
      return element.roomId == record.roomId || _isInvalid(element);
    });
    _records.sort((a, b) => b.createdAt.compareTo(a.createdAt)); // Just in case
    _records.insert(0, record);

    await prefs.setString('records', jsonEncode(_records));
  }

  List<String> get recentRoomIds {
    return recentRecords.map((record) => record.roomId).toList();
  }

  List<Record> get recentRecords {
    return _records.where((record) => _isValid(record)).toList();
  }

  bool _isValid(Record record) {
    final now = DateTime.fromMillisecondsSinceEpoch(Firedata().now());
    final oneDayAgo = now.subtract(const Duration(days: 1));
    final createdAt = DateTime.fromMillisecondsSinceEpoch(record.createdAt);
    return !createdAt.isBefore(oneDayAgo);
  }

  bool _isInvalid(Record record) => !_isValid(record);
}
