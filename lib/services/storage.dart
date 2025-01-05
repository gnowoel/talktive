import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

final storage = FirebaseStorage.instance;

class Storage {
  final FirebaseStorage instance;

  Storage(this.instance);

  Future<String> saveFile(String path, File file) async {
    final ref = instance.ref(path);
    await ref.putFile(file);
    final uri = await ref.getDownloadURL();
    return uri;
  }

  Future<String> saveData(String path, Uint8List data) async {
    final ref = instance.ref(path);
    await ref.putData(data);
    final uri = await ref.getDownloadURL();
    return uri;
  }
}
