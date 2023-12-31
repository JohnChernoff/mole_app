// File generated by FlutterFire CLI.
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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
    apiKey: 'AIzaSyDOxDg-JBWLgpZeFRIdBkpLa14gQwPCG4I',
    appId: '1:855913827317:web:cef38e85fe888d53daeebc',
    messagingSenderId: '855913827317',
    projectId: 'molechess-bc009',
    authDomain: 'molechess-bc009.firebaseapp.com',
    storageBucket: 'molechess-bc009.appspot.com',
    measurementId: 'G-8LC9KN0C2G',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC1b4G1ZxhzBCRcJrauM-Jp0XqShaJ0MKI',
    appId: '1:855913827317:android:746800b196487559daeebc',
    messagingSenderId: '855913827317',
    projectId: 'molechess-bc009',
    storageBucket: 'molechess-bc009.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDLw5BlVkyzNjhmRucWjpelAH_WfpyAnDw',
    appId: '1:855913827317:ios:360b0f8338ffbfccdaeebc',
    messagingSenderId: '855913827317',
    projectId: 'molechess-bc009',
    storageBucket: 'molechess-bc009.appspot.com',
    iosBundleId: 'org.chernovia.moleApp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDLw5BlVkyzNjhmRucWjpelAH_WfpyAnDw',
    appId: '1:855913827317:ios:8dc7a0dac959ae89daeebc',
    messagingSenderId: '855913827317',
    projectId: 'molechess-bc009',
    storageBucket: 'molechess-bc009.appspot.com',
    iosBundleId: 'org.chernovia.moleApp.RunnerTests',
  );
}
