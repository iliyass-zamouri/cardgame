import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Android configuration matches Firebase project shadow-hand.
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
    apiKey: 'AIzaSyCd4UqXR94-odGwnlhsjupVMuwKMxaaO3o',
    appId: '1:52368643344:android:265f570ea20ac9bf510195',
    messagingSenderId: '52368643344',
    projectId: 'shadow-hand',
    storageBucket: 'shadow-hand.firebasestorage.app',
  );

  /// Mirrors `ios/Runner/GoogleService-Info.plist`.
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCd4UqXR94-odGwnlhsjupVMuwKMxaaO3o',
    appId: '1:52368643344:ios:3fb0be6fe2798b86510195',
    messagingSenderId: '52368643344',
    projectId: 'shadow-hand',
    storageBucket: 'shadow-hand.firebasestorage.app',
    iosBundleId: 'com.hailsom.shadowhand',
  );
}
