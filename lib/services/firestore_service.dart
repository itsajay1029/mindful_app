import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Firestore/data service backed by Cloud Firestore.
class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _users => _db.collection('users');

  /// Ensure `users/{uid}` exists (create if missing).
  ///
  /// This is the backbone for the production flow:
  /// Auth -> user doc -> onboardingCompleted gate -> dashboard.
  Future<void> ensureUserDoc(User user) async {
    final ref = _users.doc(user.uid);
    final snap = await ref.get();

    if (snap.exists) return;

    await ref.set({
      'uid': user.uid,
      'email': user.email,
      'onboardingCompleted': false,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> streamUserDoc(String uid) {
    return _users.doc(uid).snapshots();
  }

  Future<void> setOnboardingCompleted({required String uid, required bool value}) {
    return _users.doc(uid).set({
      'onboardingCompleted': value,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> setOnboardingData({
    required String uid,
    required String role,
    required List<String> interests,
    required int minutesPerDay,
  }) {
    return _users.doc(uid).set({
      'role': role,
      'interests': interests,
      'minutesPerDay': minutesPerDay,
      'onboardingCompleted': true,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Writes a test document so you can verify Firestore works.
  ///
  /// Collection: `debug_pings`
  /// Document id: auto
  Future<DocumentReference<Map<String, dynamic>>> writeDebugPing({
    required String appName,
    String? uid,
  }) {
    return _db.collection('debug_pings').add({
      'app': appName,
      'uid': uid,
      'createdAt': FieldValue.serverTimestamp(),
      'createdAtClient': DateTime.now().toIso8601String(),
    });
  }
}
