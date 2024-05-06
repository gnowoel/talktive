import 'package:firebase_database/firebase_database.dart';

import '../models/room.dart';

class Firedata {
  final FirebaseDatabase instance = FirebaseDatabase.instance;

  Future<Room> createRoom(userId, userName, userCode, languageCode) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    final seedRoom = SeedRoom(
      userId: userId,
      userName: userName,
      userCode: userCode,
      languageCode: languageCode,
      createdAt: timestamp,
      updatedAt: 0,
    );

    final ref = instance.ref('rooms').push();

    await ref.set(seedRoom.toJson());

    return Room.fromSeed(seedRoom: seedRoom, id: ref.key!);
  }
}
