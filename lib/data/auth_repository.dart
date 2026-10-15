import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../firebase_options.dart';

enum AuthErrorKind {
  invalidCredentials,
  emailInUse,
  weakPassword,
  invalidEmail,
  tooManyRequests,
  network,
  cancelled,
  unknown,
}

class AuthFailure implements Exception {
  const AuthFailure(this.kind);

  final AuthErrorKind kind;

  factory AuthFailure.fromCode(String code) => AuthFailure(switch (code) {
        'invalid-credential' || 'wrong-password' || 'user-not-found' || 'invalid-login-credentials' =>
          AuthErrorKind.invalidCredentials,
        'email-already-in-use' || 'account-exists-with-different-credential' => AuthErrorKind.emailInUse,
        'weak-password' => AuthErrorKind.weakPassword,
        'invalid-email' => AuthErrorKind.invalidEmail,
        'too-many-requests' => AuthErrorKind.tooManyRequests,
        'network-request-failed' => AuthErrorKind.network,
        _ => AuthErrorKind.unknown,
      });

  @override
  String toString() => 'AuthFailure($kind)';
}

/// Email/password and Google sign-in, plus the matching profile document.
class AuthRepository {
  AuthRepository(this._auth, this._db);

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;
  bool _googleReady = false;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<void> signIn({required String email, required String password}) =>
      _guard(() => _auth.signInWithEmailAndPassword(email: email.trim(), password: password));

  Future<void> signUp({required String name, required String email, required String password}) =>
      _guard(() async {
        final cred = await _auth.createUserWithEmailAndPassword(email: email.trim(), password: password);
        await cred.user!.updateDisplayName(name.trim());
        await _ensureProfile(cred.user!, name: name.trim());
      });

  Future<void> signInWithGoogle() => _guard(() async {
        final google = GoogleSignIn.instance;
        if (!_googleReady) {
          await google.initialize(serverClientId: DefaultFirebaseOptions.googleServerClientId);
          _googleReady = true;
        }
        final GoogleSignInAccount account;
        try {
          account = await google.authenticate();
        } on GoogleSignInException catch (e) {
          throw AuthFailure(e.code == GoogleSignInExceptionCode.canceled
              ? AuthErrorKind.cancelled
              : AuthErrorKind.unknown);
        }
        final credential = GoogleAuthProvider.credential(idToken: account.authentication.idToken);
        final result = await _auth.signInWithCredential(credential);
        await _ensureProfile(result.user!, name: account.displayName ?? result.user!.displayName);
      });

  Future<void> sendPasswordReset(String email) =>
      _guard(() => _auth.sendPasswordResetEmail(email: email.trim()));

  Future<void> signOut() async {
    if (_googleReady) await GoogleSignIn.instance.signOut();
    await _auth.signOut();
  }

  /// Creates users/{uid} the first time someone signs in.
  Future<void> _ensureProfile(User user, {String? name}) async {
    final ref = _db.collection('users').doc(user.uid);
    final snap = await ref.get();
    if (snap.exists) return;
    final display = (name?.trim().isNotEmpty ?? false) ? name!.trim() : user.email!.split('@').first;
    await ref.set({
      'name': display,
      'nameLower': display.toLowerCase(),
      'email': user.email,
      'about': '',
      'colorIndex': Random().nextInt(6),
      'online': true,
      'lastSeen': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on FirebaseAuthException catch (e) {
      throw AuthFailure.fromCode(e.code);
    }
  }
}
