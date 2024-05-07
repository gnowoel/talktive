import 'package:firebase_database/firebase_database.dart';

import '../models/room.dart';

class Firedata {
  final FirebaseDatabase instance = FirebaseDatabase.instance;

  Future<Room> createRoom(
    String userId,
    String userName,
    String userCode,
    String languageCode,
  ) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    final room = Room(
      userId: userId,
      userName: userName,
      userCode: userCode,
      languageCode: languageCode,
      createdAt: timestamp,
      updatedAt: 0,
    );

    final ref = instance.ref('rooms').push();

    await ref.set(room.toJson());

    return room..id = ref.key;
  }
}
