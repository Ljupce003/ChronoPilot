// This file generates Firebase configuration options for different platforms.
// To generate this file, run: `flutterfire configure`

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return android;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return ios;
    }
    throw UnsupportedError(
      'DefaultFirebaseOptions are not supported for this platform.',
    );
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB7pJ3Vtfuemh99HrvH3FIAJXZ4MZADx6E',
    appId: '1:185266213508:android:fbb425f8947c174b4768d1',
    messagingSenderId: '185266213508',
    projectId: 'chrono-pilot-firebase',
    storageBucket: 'chrono-pilot-firebase.firebasestorage.app',
  );
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDcrtbojJa21aZxv-23ilYnUfgFMMEG4gM',
    appId: '1:185266213508:ios:0528d75b3d498f674768d1',
    messagingSenderId: '185266213508',
    projectId: 'chrono-pilot-firebase',
    storageBucket: 'chrono-pilot-firebase.firebasestorage.app',
    iosClientId: '185266213508-vputkhdb5akufghtcqpvmnbhvs2qc4t6.apps.googleusercontent.com',
    iosBundleId: 'com.ljupchoangelovski.chronoPilot',
  );
}
