import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

class Storage {
  final FirebaseStorage instance;

  Storage(this.instance);

  Future<String> saveFile(String path, File file) async {
    final ref = instance.ref(path);
    await ref.putFile(file);
    final uri = await ref.getDownloadURL();
    return uri;
  }
}
