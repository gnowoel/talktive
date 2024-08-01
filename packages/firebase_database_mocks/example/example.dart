import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database_mocks/firebase_database_mocks.dart';
import 'package:flutter_test/flutter_test.dart';

class UserRepository {
  UserRepository(this.firebaseDatabase);
  FirebaseDatabase firebaseDatabase;

  Future<String?> getUserName(String userId) async {
    final userNameReference =
        firebaseDatabase.ref().child('users').child(userId).child('name');
    final databaseEvent = await userNameReference.once();
    return databaseEvent.snapshot.value as String?;
  }

  Future<Map<String, dynamic>?> getUser(String userId) async {
    final userNode = firebaseDatabase.ref().child('users/$userId');
    final databaseEvent = await userNode.once();
    return databaseEvent.snapshot.value as Map<String, dynamic>?;
  }
}

void main() {
  FirebaseDatabase firebaseDatabase;
  late UserRepository userRepository;
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
  MockFirebaseDatabase.instance.ref().set(fakeData);
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
