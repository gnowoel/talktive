import 'package:firebase_database/firebase_database.dart';
import 'package:mockito/mockito.dart';

class MockDatabaseEvent extends Mock implements DatabaseEvent {
  final DataSnapshot _snapshot;

  MockDatabaseEvent(this._snapshot);

  @override
  DataSnapshot get snapshot => _snapshot;

  @override
  DatabaseEventType get type => DatabaseEventType.value;
}
