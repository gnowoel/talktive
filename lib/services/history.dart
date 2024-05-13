import '../models/record.dart';
import '../models/room.dart';

class History {
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
  }
}
