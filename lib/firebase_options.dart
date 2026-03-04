import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBeqoGtdFYvcUXEU9f4_9AjA_5XsSGnH5Y',
    appId: '1:697096459027:web:6f9a08bd4a6bd37a3400e6',
    messagingSenderId: '697096459027',
    projectId: 'papichulo-7346',
    authDomain: 'papichulo-7346.firebaseapp.com',
    storageBucket: 'papichulo-7346.firebasestorage.app',
    measurementId: 'G-D2P7NN75DG',
  );

  static FirebaseOptions get currentPlatform => web;
}
