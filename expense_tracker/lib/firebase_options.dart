import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Web not configured');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError('iOS not configured');
      default:
        throw UnsupportedError('Platform not supported');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAUQqOxVP1DKiND1UwriWneolPe4m7BGF0',
    appId: '1:1074986930486:android:8dc3ce50223103874da397',
    messagingSenderId: '1074986930486',
    projectId: 'expense-tracker-a2f8b',
    storageBucket: 'expense-tracker-a2f8b.firebasestorage.app',
  );
}
