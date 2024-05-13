import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/record.dart';
import '../models/room.dart';
import 'prefs.dart';

class History extends ChangeNotifier {
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

    notifyListeners();
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
    notifyListeners();
  }
}
