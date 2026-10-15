// Firebase configuration for the Pulse Chat project (Android).
//
// These values identify the Firebase project; they are not secrets. Access to
// data is controlled by `firestore.rules`, and the API key is restricted to
// this app's package name and signing certificates.
import 'package:firebase_core/firebase_core.dart';

abstract final class DefaultFirebaseOptions {
  static const currentPlatform = FirebaseOptions(
    apiKey: 'AIzaSyCVlzxbTUsYa0aHkBbEWsR23OnE3yB9baU',
    appId: '1:422683119968:android:e251402b36beb7da284e05',
    messagingSenderId: '422683119968',
    projectId: 'pulse-chat-portfolio',
    storageBucket: 'pulse-chat-portfolio.firebasestorage.app',
  );

  /// OAuth "web" client id, required by Google Sign-In on Android.
  static const googleServerClientId =
      '422683119968-00luc1t6gf5b6uj1bvtfskiavhqtov2v.apps.googleusercontent.com';
}
