import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database_mocks/src/mock_database_event.dart';
import 'package:firebase_database_mocks/src/util.dart';
import 'package:mockito/mockito.dart';

import 'mock_data_snapshot.dart';
import 'mock_firebase_database.dart';

class MockDatabaseReference extends Mock implements DatabaseReference {
  var _nodePath = '/';

  // ignore: prefer_final_fields
  static Map<String, dynamic>? _persistedData = <String, dynamic>{};
  Map<String, dynamic>? _volatileData;

  MockDatabaseReference([this._volatileData]);

  MockDatabaseReference._(nodePath, [this._volatileData]) {
    _nodePath += nodePath;
  }

  /// TODO implement real [onchange] (should yield each change).
  Stream<DatabaseEvent> get onValue async* {
    yield await once();
  }

  Map<String, dynamic>? get _data {
    if (MockFirebaseDatabase.persistData) {
      return _persistedData;
    }
    return _volatileData;
  }

  set _data(data) {
    if (MockFirebaseDatabase.persistData) {
      _persistedData = data;
    } else
      return _volatileData = data;
  }

  @override
  String? get key {
    if (_nodePath == '/') {
      return null;
    }
    return _trimSlashes(_nodePath).split('/').last;
  }

  @override
  String get path => _nodePath;

  @override
  DatabaseReference child(String path) {
    if (!path.endsWith('/')) path += '/';
    path = (_nodePath + path).replaceAll(RegExp(r'^/+'), '');
    return MockDatabaseReference._(
      path,
      _data,
    );
  }

  @override
  DatabaseReference push() {
    final id = nextPushId(DateTime.now().millisecondsSinceEpoch);
    return child(id);
  }

  @override
  Future<void> set(dynamic value, {dynamic priority}) async {
    value = _parseValue(value);

    if (_nodePath == '/') {
      _data = value;
      return;
    }

    final data = _getDataHandle(_nodePath, _data, value != null);
    // todo: if null value is set on the only key of a Map, the map itself should be deleted
    // example:
    // { test: { a: { b: 1 } } }, removing b from test/a should remove test completely
    if (value == null) {
      data!.remove(key);
    } else {
      data![key!] = value;
    }
  }

  @override
  Future<void> update(Map<String, Object?> value) async {
    value = _parseValue(value);
    Map<String, dynamic> _baseData = _getDataHandle(_nodePath, _data, true)!;

    if (key != null && _baseData[key] == null) {
      _baseData[key!] = <String, dynamic>{};
    }

    if (key != null) {
      _baseData = _baseData[key]!;
    }

    for (var _key in value.keys) {
      final segments = _key.split('/');
      final innerKey = segments.isNotEmpty ? segments.last : _key;
      final _data = _getDataHandle(_key, _baseData, true)!;

      _data[innerKey] = value[_key];
    }
  }

  /// Recursively converts Maps into Map<String, dynamic>,
  /// so it is possible to change type later.
  dynamic _parseValue(dynamic value) {
    if (value is Map) {
      // todo: check if keys contain forbidden characters: '/', '.', '#', '$', '[', or ']'
      // additionally, in case of update '/' should be allowed
      return Map.fromEntries(
        value.entries
            .map((e) => MapEntry(e.key.toString(), _parseValue(e.value))),
      );
    }

    return value;
  }

  /// Removes slashes from start and end of given path.
  String _trimSlashes(String path) {
    if (path.startsWith('/')) {
      path = path.substring(1);
    }
    if (path.endsWith('/')) {
      path = path.substring(0, path.length - 1);
    }
    return path;
  }

  /// Gets the map containing value for given path,
  /// e.g. given the path foo/bar/baz it returns the map at foo/bar,
  /// which you can then use to access value at baz.
  /// If createIfMissing is set to true and nested map will not be found,
  /// it will be created, so null won't be returned.
  Map<String, dynamic>? _getDataHandle(
    String path,
    Map<String, dynamic>? data, [
    bool createIfMissing = false,
  ]) {
    path = _trimSlashes(path);
    final pathSegments = path.split('/');
    if (pathSegments.length == 1) {
      // nothing to traverse
      return data;
    }

    // The caller will access the value at key.
    final segmentsWithoutKey = pathSegments.take(pathSegments.length - 1);
    Map<String, dynamic>? _data = data;
    for (var segment in segmentsWithoutKey) {
      if (_data == null) {
        if (createIfMissing) {
          _data = <String, dynamic>{};
        } else {
          break;
        }
      }

      if (_data[segment] == null && createIfMissing) {
        _data[segment] = <String, dynamic>{};
      }

      _data = _data[segment];
    }

    return _data;
  }

  dynamic _getCurrentData() {
    if (_nodePath == '/') {
      return _data;
    }
    var tempData = _data;
    // remove start and end slashes.
    var nodePath = _trimSlashes(_nodePath);
    var nodeList = nodePath.split('/');
    if (nodeList.length > 1) {
      for (var i = 0; i < nodeList.length; i++) {
        nodePath = nodeList[i];
        var nonExistentNodeFound = tempData![nodePath] == null;
        if (nonExistentNodeFound || (i + 1) == nodeList.length) {
          break;
        }
        if (tempData[nodePath] is Map) {
          tempData = tempData[nodePath];
        }
      }
    }

    return tempData![nodePath];
  }

  @override

  /// __WARNING!__ For now only the DatabaseEventType.value event is supported.
  Future<DatabaseEvent> once(
      [DatabaseEventType eventType = DatabaseEventType.value]) {
    var tempData = _getCurrentData();
    return Future.value(MockDatabaseEvent(MockDataSnapshot(this, tempData)));
  }

  @override
  Future<DataSnapshot> get() {
    var tempData = _getCurrentData();
    return Future.value(MockDataSnapshot(this, tempData));
  }

  @override
  Future<void> remove() => set(null);
}

// Map<String, dynamic> _makeSupportGenericValue(Map<String, dynamic> data) {
//   var _dataWithGenericValue = {'__generic_mock_data_value__': Object()};
//   _dataWithGenericValue.addAll(data);
//   _dataWithGenericValue.forEach((key, value) {
//     if (value is Map) {
//       _dataWithGenericValue[key] = _makeSupportGenericValue(value);
//     }
//   });
//   return _dataWithGenericValue;
// }
