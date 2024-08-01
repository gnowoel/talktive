import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database_mocks/firebase_database_mocks.dart';
import 'package:firebase_database_mocks/src/mock_database_reference.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late DatabaseReference databaseReference;
  setUp(() {
    setupFirebaseMocks(); // Just to make sure it that no exception is thrown.
    MockFirebaseDatabase.setDataPersistenceEnabled(enabled: false);
    databaseReference = MockFirebaseDatabase.instance.ref();
  });

  group('Node path handling : ', () {
    test("Should get a reference with a initial path", () {
      expect(
        MockFirebaseDatabase.instance.ref("initialPath").path,
        MockDatabaseReference().child("initialPath").path,
      );
    });
    test('Should work with slash as prefix', () {
      expect(
        databaseReference.child('/test').path,
        equals(MockDatabaseReference().child('test').path),
      );
    });
    test('Should work with slash as suffix', () {
      expect(
        databaseReference.child('test/').path,
        equals(MockDatabaseReference().child('test').path),
      );
    });
    test('Should work with slash as prefix and suffix', () {
      expect(
        databaseReference.child('/test/').path,
        equals(MockDatabaseReference().child('test').path),
      );
    });
    test('Should work with nested nodes', () {
      expect(
        databaseReference.child('test').child('other').path,
        equals(MockDatabaseReference().child('test/other').path),
      );
      expect(
        databaseReference
            .child('path')
            .child('mock')
            .child('test')
            .child('other')
            .path,
        equals(MockDatabaseReference().child('path/mock/test/other').path),
      );
    });
    test('Should return null when a nonexistent path is given', () async {
      expect(
        (await databaseReference.child('fghgg').once()).snapshot.value,
        isNull,
      );
      expect(
        (await databaseReference.child('o_/therèè_/Test').once())
            .snapshot
            .value,
        isNull,
      );
    });
    test('Should set exists based on whether data exists at given path',
        () async {
      await databaseReference.child('existing_path').set('value');
      expect((await databaseReference.child('existing_path').get()).exists,
          isTrue);
      expect((await databaseReference.child('foobar').get()).exists, isFalse);
    });

    group('Should return null when a nonexistent path that', () {
      test('starts with existent node path is given', () async {
        await databaseReference.child('existing_path').set('snapshot.value');
        expect(
          (await databaseReference.child('existing_path/therèè_/Test').once())
              .snapshot
              .value,
          isNull,
        );
      });
      test('wrap existent node path is given', () async {
        await databaseReference.child('existing_path').set('snapshot.value');
        expect(
          (await databaseReference.child('any/existing_path/thè_/Tt').once())
              .snapshot
              .value,
          isNull,
        );
        await databaseReference
            .child('tteesstt')
            .set({'key': 'snapshot.value'});
        expect(
          (await databaseReference.child('tttttst/path/tteesstt/Test').once())
              .snapshot
              .value,
          isNull,
          reason: 'With Map as snapshot.value',
        );
      });
      test('end with existent node path is given', () async {
        await databaseReference.child('end').set('snapshot.value');
        expect(
          (await databaseReference.child('any/existing_path/Test/end').once())
              .snapshot
              .value,
          isNull,
        );
      });

      // Todo put any expect satement inside test function.
    });

    // test('Should work when wrapped in two slash or more', () {
    //   expect(
    //     databaseReference.child('//test//').path,
    //     equals(MockDatabaseReference().child('test').path),
    //   );
    //   expect(
    //     databaseReference.child('//test///').path,
    //     equals(MockDatabaseReference().child('test').path),
    //   );
    // });
  });
  group('Work with any type of data : ', () {
    test('Should set String', () async {
      await databaseReference.child('test').set('snapshot.value');
      expect(
        (await databaseReference.child('test').once()).snapshot.value,
        equals('snapshot.value'),
      );
      await databaseReference.child('otherTest/test').set('otherValue');
      expect(
        (await databaseReference.child('otherTest/test').once()).snapshot.value,
        equals('otherValue'),
      );
    });

    test('Should set data in nested nodes', () async {
      await databaseReference
          .child('path_')
          .child('mock_')
          .child('test_')
          .child('other_')
          .set("NESTED");

      expect(
        (await databaseReference
                .child('path_')
                .child('mock_')
                .child('test_')
                .child('other_')
                .once())
            .snapshot
            .value,
        equals("NESTED"),
      );
      expect(
        (await databaseReference.child('path_/mock_/test_/other_').once())
            .snapshot
            .value,
        equals("NESTED"),
      );
    });

    test('Should set Map', () async {
      await databaseReference.child('test').set({'key': 'snapshot.value'});
      expect((await databaseReference.child('test').once()).snapshot.value,
          equals({'key': 'snapshot.value'}));
    });

    test(
        'Should get nested Map even if the keys of maps was not set individually',
        () async {
      const nestedMap = {
        'key': {
          'nkey1': 'value1',
          'nkey2': {'otheNkey': 'nestedValue'}
        }
      };
      await databaseReference.child('tes').set(nestedMap);
      expect((await databaseReference.child('tes').once()).snapshot.value,
          equals(nestedMap));

      expect(
          (await databaseReference.child('tes/key').once()).snapshot.value,
          equals({
            'nkey1': 'value1',
            'nkey2': {'otheNkey': 'nestedValue'}
          }));

      expect(
          (await databaseReference.child('tes/key/nkey1').once())
              .snapshot
              .value,
          equals('value1'));

      expect(
          (await databaseReference.child('tes/key/nkey2').once())
              .snapshot
              .value,
          equals({'otheNkey': 'nestedValue'}));
    });
  });

  // group('Set data at any node reference :', null);

  group('Data persistence : ', () {
    tearDown(() {
      MockFirebaseDatabase.setDataPersistenceEnabled(enabled: true);
    });

    test('Should persist data while test running', () async {
      MockFirebaseDatabase.setDataPersistenceEnabled(enabled: true);
      MockDatabaseReference? _databaseReference = MockDatabaseReference();
      await _databaseReference.child('test1').set('value1');
      await _databaseReference.child('test2/test2').set('value2');
      await _databaseReference.child('test3/test_one').set('value3');
      _databaseReference = null;
      expect(_databaseReference, isNull);

      var newDatabaseReference = MockDatabaseReference();
      expect(
        (await newDatabaseReference.child('test1').once()).snapshot.value,
        equals('value1'),
      );
      print('test1 passed');
      expect(
        (await newDatabaseReference.child('test2/test2').once()).snapshot.value,
        equals('value2'),
      );
      expect(
        (await newDatabaseReference.child('test3/test_one').once())
            .snapshot
            .value,
        equals('value3'),
      );
    });
    test('Should not persist data', () async {
      MockFirebaseDatabase.setDataPersistenceEnabled(enabled: false);
      await databaseReference.child('test_').set('snapshot.value');
      expect(
        (await databaseReference.child('test_').once()).snapshot.value,
        equals('snapshot.value'),
      );
      await databaseReference.child('otherTest_/test').set('otherValue');
      expect(
        (await databaseReference.child('otherTest_/test').once())
            .snapshot
            .value,
        equals('otherValue'),
      );
      expect(
          (await MockFirebaseDatabase().ref().child('test_').once())
              .snapshot
              .value,
          isNull);
    });
  });

  test('Should return a stream of data', () async {
    await databaseReference.child('streamTest').set('StreamVal');
    final stream = databaseReference.child('streamTest').onValue;
    expect((await stream.first).snapshot.value, equals('StreamVal'));
  });

  group('Node key', () {
    test('Should return null for root reference', () {
      expect(databaseReference.key, isNull);
    });

    test('Should return last part of path as key', () {
      expect(databaseReference.child('foo').key, equals('foo'));
      expect(databaseReference.child('foo/bar').key, equals('bar'));
      expect(databaseReference.child('foo/bar/baz').key, equals('baz'));
    });
  });

  group('update', () {
    late DatabaseReference reference;

    setUp(() async {
      reference = databaseReference.child('update');
      await reference.set({
        'shallow': 'data',
        'nested': {
          'foo': {
            'bar': 'baz',
          },
        },
      });
    });

    test('should update shallow data', () async {
      await reference.update({'shallow': 'foo'});
      final snapshot = await reference.get();
      expect(
        snapshot.value,
        equals({
          'shallow': 'foo',
          'nested': {
            'foo': {
              'bar': 'baz',
            },
          },
        }),
      );
    });

    test('should update nested data', () async {
      await reference.update({
        'nested': {
          'foo': {'bar': 'foo'}
        }
      });
      final snapshot = await reference.get();
      expect(
        snapshot.value,
        equals({
          'shallow': 'data',
          'nested': {
            'foo': {
              'bar': 'foo',
            },
          },
        }),
      );
    });

    test('should update many locations simultaneously', () async {
      await reference.update({
        'shallow': 'foo',
        'nested': {
          'foo': {'bar': 'foo'}
        }
      });
      final snapshot = await reference.get();
      expect(
        snapshot.value,
        equals({
          'shallow': 'foo',
          'nested': {
            'foo': {
              'bar': 'foo',
            },
          },
        }),
      );
    });

    test('should work with slash separated keys', () async {
      await reference.update({
        'shallow': 'foo',
        'nested/foo/bar': 'foo',
      });
      final snapshot = await reference.get();
      expect(
        snapshot.value,
        equals({
          'shallow': 'foo',
          'nested': {
            'foo': {
              'bar': 'foo',
            },
          },
        }),
      );
    });

    test('should work on root reference', () async {
      await databaseReference.update({
        'update': 'foo',
      });
      final snapshot = await databaseReference.get();
      expect(
        snapshot.value,
        equals({
          'update': 'foo',
        }),
      );
    });
  });

  group('push', () {
    late DatabaseReference reference;

    setUp(() {
      reference = databaseReference.child('push');
    });

    test('Should return key of length 20', () {
      final newReference = reference.push();

      expect(newReference.key, hasLength(20));
    });

    test('Should return different keys if pushed at the same time', () {
      final reference1 = reference.push();
      final reference2 = reference.push();

      expect(reference1.key, isNot(reference2.key));
    });

    test('Should sort keys lexicographically', () {
      final reference1 = reference.push();
      final reference2 = reference.push();

      expect(reference1.key!.compareTo(reference2.key!), lessThan(0));
    });
  });

  group('remove', () {
    late DatabaseReference reference;
    late DatabaseReference shallowReference;
    late DatabaseReference nestedReference;

    setUp(() async {
      reference = databaseReference.child('remove');
      await reference.set({
        'shallow': 'data',
        'nested': {
          'foo': {
            'bar': 'baz',
          },
        },
      });
      shallowReference = reference.child('shallow');
      nestedReference = reference.child('nested');
    });

    test('should remove shallow data', () async {
      await shallowReference.remove();
      final snapshot = await reference.get();
      expect(
        snapshot.value,
        equals({
          'nested': {
            'foo': {
              'bar': 'baz',
            },
          },
        }),
      );
    });

    test('should remove nested data', () async {
      await nestedReference.remove();
      final snapshot = await reference.get();
      expect(
        snapshot.value,
        equals({
          'shallow': 'data',
        }),
      );
    });

    test('should work on root reference', () async {
      await databaseReference.remove();
      final snapshot = await databaseReference.get();
      expect(snapshot.value, isNull);
    });

    // todo: uncomment when fixed
    // test('should remove whole map if its only key is removed', () async {
    //   await nestedReference.child('foo/bar').remove();
    //   final snapshot = await nestedReference.get();
    //   print(snapshot.value);
    //   expect(snapshot.exists, isFalse);
    // });
  });

  // Todo implement all dataSnapshot, dbReference and fbDatabase getters and setters if possible.

  // test(
  //     'Should not persist data if setting "persistData" of MockFirebaseData is false',
  //     () async {
  //   MockFirebaseDatabase.settings(persistData: false);
  //   var databaseReference = MockDatabaseReference();
  //   var test = databaseReference.child('test1');
  //   await test.set('value1');
  //   await databaseReference.child('test2/test2').set('value2');
  //   await databaseReference.child('test1/test_one').set('value3');
  //   expect(
  //     (await test.once()).snapshot.value,
  //     equals('value1'),
  //   );
  //   databaseReference = null;
  //   expect(databaseReference, isNull);

  //   var newDatabaseReference = MockDatabaseReference();
  //   expect(
  //     (await newDatabaseReference.child('test1').once()).snapshot.value,
  //     isNull,
  //   );
  //   expect(
  //     (await newDatabaseReference.child('test2/test2').once()).snapshot.value,
  //     isNull,
  //   );
  //   expect(
  //     (await newDatabaseReference.child('test1/test_one').once()).snapshot.value,
  //     isNull,
  //   );
  // });
}
