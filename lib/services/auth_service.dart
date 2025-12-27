import 'package:firebase_auth/firebase_auth.dart';

import 'google_auth_service.dart';

/// Authentication service backed by Firebase Auth.
class AuthService {
  AuthService({FirebaseAuth? firebaseAuth, GoogleAuthService? googleAuthService})
      : _auth = firebaseAuth ?? FirebaseAuth.instance,
        _googleAuth = googleAuthService ?? GoogleAuthService();

  final FirebaseAuth _auth;
  final GoogleAuthService _googleAuth;

  User? get currentUser => _auth.currentUser;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  Future<UserCredential> signInAnonymously() {
    return _auth.signInAnonymously();
  }

  Future<UserCredential> signInWithEmail({required String email, required String password}) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> signUpWithEmail({required String email, required String password}) {
    return _auth.createUserWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> signInWithGoogle() {
    return _googleAuth.signInWithGoogle();
  }

  Future<void> signOut() async {
    // Sign out both from Firebase and Google session.
    await Future.wait([
      _auth.signOut(),
      _googleAuth.signOutGoogle(),
    ]);
  }
}
