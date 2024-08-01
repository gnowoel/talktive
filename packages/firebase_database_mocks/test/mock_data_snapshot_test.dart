import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database_mocks/src/mock_data_snapshot.dart';
import 'package:firebase_database_mocks/src/mock_database_reference.dart';
import 'package:firebase_database_mocks/src/set_up_mocks.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late MockDatabaseReference databaseReference;
  late DatabaseReference reference;
  setUp(() {
    setupFirebaseMocks();
    databaseReference = MockDatabaseReference();
    reference = databaseReference.child('foo/bar');
  });

  test('Should return reference that was used for creation', () {
    expect(MockDataSnapshot(reference, null).ref, equals(reference));
  });

  test('Should return key that is the same as in reference', () {
    expect(MockDataSnapshot(reference, null).key, equals(reference.key));
  });

  group("child tests", () {
    late List<String> sampleList;
    late Map<String, dynamic> sampleMap;
    setUp(() {
      sampleList = ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j"];
      sampleMap = {"a": 2, "b": 5, "c": 0};
    });

    test('Should return the same updated list', () async {
      await reference.update({"list": sampleList});
      final dataSnapshot = await reference.child("list").get();

      expect(dataSnapshot.value, sampleList);
      expect(dataSnapshot.hasChild("1"), true);
      expect(dataSnapshot.hasChild("-1"), false);
      expect(dataSnapshot.child("1").value, "b");
      expect(dataSnapshot.child("-1").value, null);
      var children = dataSnapshot.children.toList();
      for (int i = 0; i < children.length; i++) {
        expect(children[i].value, sampleList[i]);
      }
    });

    test('Should return the same updated map', () async {
      await reference.update({"map": sampleMap});

      final MockDataSnapshot dataSnapshot =
          await reference.child("map").get() as MockDataSnapshot;
      expect(dataSnapshot.value, sampleMap);
      expect(dataSnapshot.hasChild("b"), true);
      expect(dataSnapshot.hasChild("foo"), false);
      expect(dataSnapshot.child("b").value, 5);
      expect(dataSnapshot.child("d").value, null);
      var children = dataSnapshot.children.toList();
      for (int i = 0; i < children.length; i++) {
        expect(children[i].value, sampleMap[children[i].key]);
      }
    });

    test('Should return the same single value', () async {
      await reference.update({"value": 42});
      var dataSnapshot = (await reference.child("value").get());
      expect(dataSnapshot.value, 42);
      expect(dataSnapshot.child("foo").value, null);

      await reference.set(100);
      dataSnapshot = (await reference.get());
      expect(dataSnapshot.value, 100);
      expect(dataSnapshot.children, []);
    });
  });
}
