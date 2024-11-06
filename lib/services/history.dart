import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/record.dart';
import '../models/room.dart';
import 'clock.dart';
import 'prefs.dart';

class History extends ChangeNotifier {
  History._();

  static final History _instance = History._();

  factory History() => _instance;

  final prefs = Prefs();
  final _records = <Record>[];

  Future<void> init() async {
    final string = await _getPref();
    final list = string == null
        ? <Map<String, dynamic>>[]
        : jsonDecode(string).cast<Map<String, dynamic>>();

    _records.clear();
    for (final entry in list) {
      try {
        _records.add(Record.fromJson(entry));
      } catch (e) {
        // Ignore the malformed entry, which might be
        // created from an older version of the app.
      }
    }
  }

  Future<void> saveRecord({
    required Room room,
    required String currentUserId,
    required int messageCount,
    required double scrollOffset,
    bool visible = true,
  }) async {
    final byMe = room.userId == 'me' || room.userId == currentUserId;

    final record = Record(
      roomId: room.id,
      roomTopic: room.topic,
      roomUserId: byMe ? 'me' : '',
      roomUserName: room.userName,
      roomUserCode: room.userCode,
      createdAt: Clock().serverNow(),
      messageCount: messageCount,
      scrollOffset: scrollOffset,
      visible: visible,
    );

    _records.removeWhere((element) {
      return element.roomId == record.roomId || _isInvalid(element);
    });
    _records.sort((a, b) => b.createdAt.compareTo(a.createdAt)); // Just in case
    _records.insert(0, record);

    await _setPref(jsonEncode(_records));
    notifyListeners();
  }

  Future<void> hideRecord({required String roomId}) async {
    final index = _records.indexWhere((record) => record.roomId == roomId);
    if (index >= 0) {
      _records[index] = _records[index].copyWith(visible: false);
    }
    await _setPref(jsonEncode(_records));
    notifyListeners();
  }

  List<String> get recentRoomIds {
    return recentRecords.map((record) => record.roomId).toList();
  }

  List<Record> get recentRecords {
    return _records.where((record) => _isValid(record)).toList();
  }

  List<Record> get visibleRecentRecords {
    return recentRecords.where((record) => _isVisible(record)).toList();
  }

  @visibleForTesting
  Future<void> clear() async {
    _records.clear();
    await _setPref(jsonEncode(_records));
    notifyListeners();
  }

  Future<void> _setPref(String? records) async {
    if (records == null) return;
    await prefs.setString('records', records);
  }

  Future<String?> _getPref() async {
    return await prefs.getString('records');
  }

  bool _isValid(Record record) {
    final now = DateTime.fromMillisecondsSinceEpoch(Clock().serverNow());
    final oneDayAgo = now.subtract(const Duration(days: 1));
    final createdAt = DateTime.fromMillisecondsSinceEpoch(record.createdAt);
    return !createdAt.isBefore(oneDayAgo);
  }

  bool _isInvalid(Record record) => !_isValid(record);

  bool _isVisible(Record record) => record.visible;
}
