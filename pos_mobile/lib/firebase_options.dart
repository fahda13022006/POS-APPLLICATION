// File generated manually based on android/app/google-services.json for project pos-pinkpoint.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'you can reconfigure this by running the FlutterFire CLI.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCd_UGRuqnlH3MoG2XED4eN7sZAEonks60',
    appId: '1:750881375240:android:50d8b10b482852601e7dbd',
    messagingSenderId: '750881375240',
    projectId: 'pos-pinkpoint',
    storageBucket: 'pos-pinkpoint.firebasestorage.app',
  );
}
