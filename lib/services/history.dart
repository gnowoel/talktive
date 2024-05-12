import '../models/record.dart';

class History {
  final records = <Record>[];

  Future<void> saveRecord(Record record) async {
    records.removeWhere((element) => element.roomId == record.roomId);
    records.add(record);
  }
}
