// Generated from android/app/google-services.json & ios/Runner/GoogleService-Info.plist
// Firebase project: wayo-ads-27cbf (package ma.wayo.wayoadsgo)
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
    apiKey: 'AIzaSyBd3XYKwlz6udWKoPS4sBLHrjSxLT0djLo',
    appId: '1:458504508199:android:96028da30c62bf171a4f02',
    messagingSenderId: '458504508199',
    projectId: 'wayo-ads-27cbf',
    storageBucket: 'wayo-ads-27cbf.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyD5oFlFDVgNAiKT9gCYx78uYCbjulSVggI',
    appId: '1:458504508199:ios:5862a1b1dadc29831a4f02',
    messagingSenderId: '458504508199',
    projectId: 'wayo-ads-27cbf',
    storageBucket: 'wayo-ads-27cbf.firebasestorage.app',
    iosBundleId: 'ma.wayo.wayoadsgo',
  );
}
