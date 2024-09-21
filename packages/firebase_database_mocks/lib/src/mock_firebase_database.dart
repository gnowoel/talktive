import 'package:firebase_database/firebase_database.dart';
import 'package:mockito/mockito.dart';

import 'mock_database_reference.dart';

class MockFirebaseDatabase extends Mock implements FirebaseDatabase {
  static FirebaseDatabase get instance => MockFirebaseDatabase();

  static get persistData => _persistData;

  final _volatileData = <String, dynamic>{};

  @override
  DatabaseReference ref([String? path]) {
    if (path != null) {
      return MockDatabaseReference(_volatileData).child(path);
    }
    return MockDatabaseReference(_volatileData);
  }

  static bool _persistData = true;

  //Todo support non persistence.
  static void setDataPersistenceEnabled({bool enabled = true}) {
    _persistData = enabled;
  }
}
