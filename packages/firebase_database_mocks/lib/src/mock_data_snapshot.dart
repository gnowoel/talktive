import 'package:firebase_database/firebase_database.dart';
import 'package:mockito/mockito.dart';

class MockDataSnapshot extends Mock implements DataSnapshot {
  final DatabaseReference _ref;
  final dynamic _value;

  MockDataSnapshot(this._ref, this._value);

  @override
  String? get key => _ref.key;

  @override
  DatabaseReference get ref => _ref;

  @override
  dynamic get value => _value;

  @override
  bool get exists => _value != null;

  @override
  bool hasChild(String path) {
    final value = _value;
    if (value is Map) {
      return value.containsKey(path);
    } else if (value is List) {
      int? index = int.tryParse(path);
      if (index != null) {
        return index >= 0 && index < value.length;
      }
    }
    return false;
  }

  @override
  DataSnapshot child(String path) {
    final value = _value;
    if (value is Map) {
      return MockDataSnapshot(_ref.child(path), value[path]);
    } else if (value is List) {
      int? index = int.tryParse(path);
      if (index != null && index >= 0 && index < value.length) {
        return MockDataSnapshot(_ref.child("$index"), value[index]);
      }
    }
    return MockDataSnapshot(_ref.child(path), null);
  }

  @override
  Iterable<DataSnapshot> get children {
    final value = _value;
    if (value is Map) {
      return value
          .map((key, value) =>
              MapEntry(key, MockDataSnapshot(_ref.child(key), value)))
          .values;
    } else if (value is List) {
      var index = 0;
      return value.map((e) => MockDataSnapshot(_ref.child("${index++}"), e));
    }
    return [];
  }
}
