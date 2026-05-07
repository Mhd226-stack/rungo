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
      case TargetPlatform.iOS:
        return ios;
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDqD2qeoQ0MGtf9lZy_6c-xE0ST5Fjt0ZU',
    appId: '1:698998642807:web:1910b73db6aa59f163ce72',
    messagingSenderId: '698998642807',
    projectId: 'rungo-598df',
    authDomain: 'rungo-598df.firebaseapp.com',
    databaseURL: 'https://rungo-598df-default-rtdb.firebaseio.com',
    storageBucket: 'rungo-598df.firebasestorage.app',
    measurementId: 'G-1QRDFJSNHB',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCL8xrdAx7kjfM9PqLyU3cEHWSZWMArdDA',
    appId: '1:698998642807:android:81089497f0b6f3b463ce72',
    messagingSenderId: '698998642807',
    projectId: 'rungo-598df',
    databaseURL: 'https://rungo-598df-default-rtdb.firebaseio.com',
    storageBucket: 'rungo-598df.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDqD2qeoQ0MGtf9lZy_6c-xE0ST5Fjt0ZU',
    appId: '1:698998642807:ios:1910b73db6aa59f163ce72',
    messagingSenderId: '698998642807',
    projectId: 'rungo-598df',
    databaseURL: 'https://rungo-598df-default-rtdb.firebaseio.com',
    storageBucket: 'rungo-598df.firebasestorage.app',
    iosBundleId: 'com.mhd.rungo',
  );
}