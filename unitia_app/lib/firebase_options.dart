// Firebase config — proyecto: unitia-57f59
// Android e iOS: configurados. Web: pendiente si se requiere Flutter Web.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError('DefaultFirebaseOptions are not supported for this platform.');
    }
  }

  // Web: obtener en Firebase Console → Project Settings → Your apps → Web app
  // Si no usas Flutter Web puedes ignorar esto.
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'YOUR_WEB_API_KEY',
    appId: '1:864683113445:web:YOUR_WEB_APP_ID',
    messagingSenderId: '864683113445',
    projectId: 'unitia-57f59',
    storageBucket: 'unitia-57f59.firebasestorage.app',
    authDomain: 'unitia-57f59.firebaseapp.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD25NUKcwsalRlJpZFr0jeYaSsKcoFILQA',
    appId: '1:864683113445:android:34250c920636799c830d0c',
    messagingSenderId: '864683113445',
    projectId: 'unitia-57f59',
    storageBucket: 'unitia-57f59.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDxl4r7S2sxFat-GMZSHMmtE4gOa7_NmPQ',
    appId: '1:864683113445:ios:667459348eca7120830d0c',
    messagingSenderId: '864683113445',
    projectId: 'unitia-57f59',
    storageBucket: 'unitia-57f59.firebasestorage.app',
    iosClientId: '864683113445-9f53u4odq4o3q2dimuvdmufsf76795pt.apps.googleusercontent.com',
    iosBundleId: 'com.unitia.unitiaApp',
  );

}