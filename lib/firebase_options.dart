// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
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
        return windows;
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
    apiKey: 'AIzaSyA0_-3GgPtgIl_EYacuYeMKzA1g33A2vfE',
    appId: '1:709984222631:web:e567afa56ea0ab55458a82',
    messagingSenderId: '709984222631',
    projectId: 'soma-buddy',
    authDomain: 'soma-buddy.firebaseapp.com',
    storageBucket: 'soma-buddy.firebasestorage.app',
    measurementId: 'G-10289XRETT',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDr__l6odHjqAFkxXbpPfKgnvM3eqssr6Y',
    appId: '1:709984222631:android:65578777273ff856458a82',
    messagingSenderId: '709984222631',
    projectId: 'soma-buddy',
    storageBucket: 'soma-buddy.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAD9ob-uFaxPiZO0zC6JtN73Qwe2Cn4EEg',
    appId: '1:709984222631:ios:ea68c246f09241f5458a82',
    messagingSenderId: '709984222631',
    projectId: 'soma-buddy',
    storageBucket: 'soma-buddy.firebasestorage.app',
    androidClientId: '709984222631-fjlu4mt1qlvluvv3rt7ptdf1sidcrgp3.apps.googleusercontent.com',
    iosClientId: '709984222631-ki8rso4uhai55c9f9gtgtese4k99js77.apps.googleusercontent.com',
    iosBundleId: 'com.example.somaBuddyLogin',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAD9ob-uFaxPiZO0zC6JtN73Qwe2Cn4EEg',
    appId: '1:709984222631:ios:ea68c246f09241f5458a82',
    messagingSenderId: '709984222631',
    projectId: 'soma-buddy',
    storageBucket: 'soma-buddy.firebasestorage.app',
    androidClientId: '709984222631-fjlu4mt1qlvluvv3rt7ptdf1sidcrgp3.apps.googleusercontent.com',
    iosClientId: '709984222631-ki8rso4uhai55c9f9gtgtese4k99js77.apps.googleusercontent.com',
    iosBundleId: 'com.example.somaBuddyLogin',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyA0_-3GgPtgIl_EYacuYeMKzA1g33A2vfE',
    appId: '1:709984222631:web:cc94bc0e512f5839458a82',
    messagingSenderId: '709984222631',
    projectId: 'soma-buddy',
    authDomain: 'soma-buddy.firebaseapp.com',
    storageBucket: 'soma-buddy.firebasestorage.app',
    measurementId: 'G-9PRP01EM1E',
  );

}