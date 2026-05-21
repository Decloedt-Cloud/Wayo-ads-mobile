// File generated manually from google-services.json & Firebase Console
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for Wayo Ads mobile.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'you can reconfigure this by running the FlutterFire CLI again.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD-QZdQ9nI86mb0LKk2-l4ny4gn80H-b_0',
    appId: '1:540462242334:android:cf2c87b87a1433bed36c0f',
    messagingSenderId: '540462242334',
    projectId: 'wayo-ads-82232',
    storageBucket: 'wayo-ads-82232.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyC3tyTqXKSPEEC_pIf9mUTGhCEU441-y-I',
    appId: '1:540462242334:ios:573b7495d8122c34d36c0f',
    messagingSenderId: '540462242334',
    projectId: 'wayo-ads-82232',
    storageBucket: 'wayo-ads-82232.firebasestorage.app',
    iosBundleId: 'ma.wayo.wayoadsgo',
  );
}
