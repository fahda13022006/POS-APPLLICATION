// File generated manually based on android/app/google-services.json for project pos-pinkpoint.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
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
  
  static const FirebaseOptions web = FirebaseOptions (
    apiKey: "AIzaSyAk3gyUYq_R89B3MFW9sW1t66u6v1cZ2q4",
    authDomain: "pos-pinkpoint.firebaseapp.com",
    projectId: "pos-pinkpoint",
    storageBucket: "pos-pinkpoint.firebasestorage.app",
    messagingSenderId: "750881375240",
    appId: "1:750881375240:web:1b8c3d0fbfbf424f1e7dbd"
  );
}
