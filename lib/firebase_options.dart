// File generated normally by the FlutterFire CLI (`flutterfire configure`).
// This is a PLACEHOLDER so the project compiles out of the box.
//
// IMPORTANT: Replace every value below with your own Firebase project's
// configuration. See the installation guide (README.md) for the exact
// steps, or simply run:
//
//   dart pub global activate flutterfire_cli
//   flutterfire configure
//
// ...from the project root, which will overwrite this file automatically
// with the correct values for Android, iOS, and (optionally) Web.

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBGqxXV_zhtoPRNkmApumjdmffpWhitf-E',
    appId: '1:108689523441:web:325b09bfe07a30e17a5f50',
    messagingSenderId: '108689523441',
    projectId: 'love-app-aee08',
    authDomain: 'love-app-aee08.firebaseapp.com',
    storageBucket: 'love-app-aee08.firebasestorage.app',
    measurementId: 'G-N67VHT90HB',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC1SHAGdLerVbDoPbFgAUGmB0q1kalwH8w',
    appId: '1:108689523441:android:3c047345fec1dc9b7a5f50',
    messagingSenderId: '108689523441',
    projectId: 'love-app-aee08',
    storageBucket: 'love-app-aee08.firebasestorage.app',
  );
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBuRgqhg5wNh79aCJA_BiU1zyLAOmEQPiQ',
    appId: '1:108689523441:ios:598784c412cf7c707a5f50',
    messagingSenderId: '108689523441',
    projectId: 'love-app-aee08',
    storageBucket: 'love-app-aee08.firebasestorage.app',
    iosBundleId: 'com.example.loveApp',
  );
}
