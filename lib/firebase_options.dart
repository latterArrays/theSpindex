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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAVOz9N1Hi97ZkSnHn-ZpERgQSM4bqDM4c',
    appId: '1:27603333905:web:e5606ed7164642e58e92b0',
    messagingSenderId: '27603333905',
    projectId: 'thespindex-d6b69',
    authDomain: 'thespindex-d6b69.firebaseapp.com',
    storageBucket: 'thespindex-d6b69.firebasestorage.app',
    measurementId: 'G-RH7SVV6PXB',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDhcFi2CTax_ZNdU7R-QrKXGZj2s5m6RLI',
    appId: '1:27603333905:android:007a7b14ae09eb328e92b0',
    messagingSenderId: '27603333905',
    projectId: 'thespindex-d6b69',
    storageBucket: 'thespindex-d6b69.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAHnkHqor4sgDcIly9rCWK3lj2uhFWin6U',
    appId: '1:27603333905:ios:5d175ef7603cb0b08e92b0',
    messagingSenderId: '27603333905',
    projectId: 'thespindex-d6b69',
    storageBucket: 'thespindex-d6b69.firebasestorage.app',
    iosBundleId: 'com.example.spindex',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAHnkHqor4sgDcIly9rCWK3lj2uhFWin6U',
    appId: '1:27603333905:ios:5d175ef7603cb0b08e92b0',
    messagingSenderId: '27603333905',
    projectId: 'thespindex-d6b69',
    storageBucket: 'thespindex-d6b69.firebasestorage.app',
    iosBundleId: 'com.example.spindex',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAVOz9N1Hi97ZkSnHn-ZpERgQSM4bqDM4c',
    appId: '1:27603333905:web:24b7958de46e495b8e92b0',
    messagingSenderId: '27603333905',
    projectId: 'thespindex-d6b69',
    authDomain: 'thespindex-d6b69.firebaseapp.com',
    storageBucket: 'thespindex-d6b69.firebasestorage.app',
    measurementId: 'G-70JSHJMFFP',
  );
}
