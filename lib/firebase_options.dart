// File generated by FlutLab.
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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for iOS - '
          'try to add using FlutLab Firebase Configuration',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'it not supported by FlutLab yet, but you can add it manually',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'it not supported by FlutLab yet, but you can add it manually',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'it not supported by FlutLab yet, but you can add it manually',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBPttYRtZd6RZIBEp20tIZPExY8ujpYwsQ',
    appId: '1:443806245910:android:a935b7d8ded3362e80c137',
    messagingSenderId: '443806245910',
    projectId: 'repetitor-resourses',
    storageBucket: 'repetitor-resourses.firebasestorage.app'
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCGDk6ivBGgOlqRfDjcptI825Yv_jTlf78',
    authDomain: 'repetitor-resourses.firebaseapp.com',
    projectId: 'repetitor-resourses',
    storageBucket: 'repetitor-resourses.firebasestorage.app',
    messagingSenderId: '443806245910',
    appId: '1:443806245910:web:d26e7797a27781bf80c137',
    measurementId: 'G-10BHY1PY2T'
  );
}
