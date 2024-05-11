// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        return linux;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAY2BMh_r1MaYUMlmgfSjM_4U0zcmMGn98',
    appId: '1:466457538668:web:1977c3b4af68aeaf01e849',
    messagingSenderId: '466457538668',
    projectId: 'talktive3-58486',
    authDomain: 'talktive3-58486.firebaseapp.com',
    databaseURL: 'https://talktive3-58486-default-rtdb.firebaseio.com',
    storageBucket: 'talktive3-58486.appspot.com',
    measurementId: 'G-R613MNBPDC',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBGu44ShjvI_LUsJqgONu8uYC14ABgKcv4',
    appId: '1:466457538668:android:0a83323b2975233101e849',
    messagingSenderId: '466457538668',
    projectId: 'talktive3-58486',
    databaseURL: 'https://talktive3-58486-default-rtdb.firebaseio.com',
    storageBucket: 'talktive3-58486.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCW5oSx0c3hauf-M5jl9ewHIQoe8OhMEe0',
    appId: '1:466457538668:ios:83d1747e360adf4001e849',
    messagingSenderId: '466457538668',
    projectId: 'talktive3-58486',
    databaseURL: 'https://talktive3-58486-default-rtdb.firebaseio.com',
    storageBucket: 'talktive3-58486.appspot.com',
    iosBundleId: 'app.talktive',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCW5oSx0c3hauf-M5jl9ewHIQoe8OhMEe0',
    appId: '1:466457538668:ios:83d1747e360adf4001e849',
    messagingSenderId: '466457538668',
    projectId: 'talktive3-58486',
    databaseURL: 'https://talktive3-58486-default-rtdb.firebaseio.com',
    storageBucket: 'talktive3-58486.appspot.com',
    iosBundleId: 'app.talktive',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAY2BMh_r1MaYUMlmgfSjM_4U0zcmMGn98',
    appId: '1:466457538668:web:2f049bb88325708501e849',
    messagingSenderId: '466457538668',
    projectId: 'talktive3-58486',
    authDomain: 'talktive3-58486.firebaseapp.com',
    databaseURL: 'https://talktive3-58486-default-rtdb.firebaseio.com',
    storageBucket: 'talktive3-58486.appspot.com',
    measurementId: 'G-TQSPS89ZVH',
  );

  static const FirebaseOptions linux = FirebaseOptions(
    apiKey: 'AIzaSyAY2BMh_r1MaYUMlmgfSjM_4U0zcmMGn98',
    appId: '1:466457538668:web:1a413c08ed39a94901e849',
    messagingSenderId: '466457538668',
    projectId: 'talktive3-58486',
    authDomain: 'talktive3-58486.firebaseapp.com',
    databaseURL: 'https://talktive3-58486-default-rtdb.firebaseio.com',
    storageBucket: 'talktive3-58486.appspot.com',
    measurementId: 'G-QK8S12XL2Z',
  );

}