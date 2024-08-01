# firebase_database_mocks

[![Pub Version](https://img.shields.io/pub/v/firebase_database_mocks)](https://pub.dev/packages/firebase_database_mocks)  [![test: passing](https://github.com/sitatec/firebase_database_mocks/actions/workflows/main.yml/badge.svg)](https://github.com/sitatec/firebase_database_mocks/actions) [![codecov](https://codecov.io/gh/sitatec/firebase_database_mocks/branch/main/graph/badge.svg?token=YLBE21OXGR)](https://codecov.io/gh/sitatec/firebase_database_mocks) 
[![style: effective dart](https://img.shields.io/badge/style-flutter--lint-blue)](https://pub.dev/packages/flutter_lints)

A library that makes it easy to write unit tests for FirebaseDatabase ([Realtime Database](https://firebase.google.com/docs/database?hl=en)).

## Usage
Get an instance of `MockFirebaseDatabase` like this : `MockFirebaseDatabase.instance`, then use it in your tests as if it was the real
`FirebaseDatabase.instance`. 

By default the library keeps the data in memory as long as the tests are running, but you can disable the data persistence as follow: 
`MockFirebaseDatabase.setDataPersistenceEnabled(ennabled: false);`.

If the data persistence is disabled, each time you create an instance of `MockDatabaseReference` either by using the constructor: `MockDatabaseReference()`, or by getting the root reference on `MockFirebaseDatabase` instance : `MockFirebaseDatabase.instance.ref()` a new data store is created instead of using the cached one.
> ___Note:___ The `MockFirebaseDatabase.setDataPersistenceEnabled()` function is currently experimental, so you might face some issues when you disable the data persitence.

### Code Sample
```dart
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database_mocks/firebase_database_mocks.dart';
import 'package:flutter_test/flutter_test.dart';

class UserRepository {
  UserRepository(this.firebaseDatabase);
  FirebaseDatabase firebaseDatabase;

  Future<String> getUserName(String userId) async {
    final userNameReference =
        firebaseDatabase.reference().child('users').child(userId).child('name');
    final dataSnapshot = await userNameReference.once();
    return dataSnapshot.value;
  }

  Future<Map<String, dynamic>> getUser(String userId) async {
    final userNode = firebaseDatabase.reference().child('users/$userId');
    final dataSnapshot = await userNode.once();
    return dataSnapshot.value;
  }
}

void main() {
  FirebaseDatabase firebaseDatabase;
  UserRepository userRepository;
  // Put fake data
  const userId = 'userId';
  const userName = 'Elon musk';
  const fakeData = {
    'users': {
      userId: {
        'name': userName,
        'email': 'musk.email@tesla.com',
        'photoUrl': 'url-to-photo.jpg',
      },
      'otherUserId': {
        'name': 'userName',
        'email': 'othermusk.email@tesla.com',
        'photoUrl': 'other_url-to-photo.jpg',
      }
    }
  };
  MockFirebaseDatabase.instance.reference().set(fakeData);
  setUp(() {
    firebaseDatabase = MockFirebaseDatabase.instance;
    userRepository = UserRepository(firebaseDatabase);
  });
  test('Should get userName ...', () async {
    final userNameFromFakeDatabase = await userRepository.getUserName(userId);
    expect(userNameFromFakeDatabase, equals(userName));
  });

  test('Should get user ...', () async {
    final userNameFromFakeDatabase = await userRepository.getUser(userId);
    expect(
      userNameFromFakeDatabase,
      equals({
        'name': userName,
        'email': 'musk.email@tesla.com',
        'photoUrl': 'url-to-photo.jpg',
      }),
    );
  });
}

```

As you can see you don't need to initialize firebase core for testing or call
`TestWidgetsFlutterBinding.ensureInitialized()` before using `MockFirebaseDatabase`,
but if you use another firebase service that needs it, you can simply call
the `setupFirebaseMocks()` top level function which performs all required operations 
for testing a firebase service that isn't fully mocked.

### Supported getters/methods
- ```MockFirebaseDatabase```
    - ```ref()```
    - ```reference()```
- ```MockDatabaseReference```
    - ```key```
    - ```path```
    - ```child()```
    - ```get()```
    - ```set()```
    - ```update()```
    - ```remove()```
    - ```once()``` (```DatabaseEventType.value``` only)
    - ```push()```
- ```MockDataSnapshot```
    - ```key```
    - ```ref```
    - ```value```
    - ```exists```
    - ```hasChild```
    - ```child```
    - ```children```


### Contributing
- [Issues](https://github.com/sitatec/firebase_database_mocks/issues)
- [Pull requests](https://github.com/sitatec/firebase_database_mocks/pulls)

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://flutter.dev/docs/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://flutter.dev/docs/cookbook)

For help getting started with Flutter, view our
[online documentation](https://flutter.dev/docs), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
