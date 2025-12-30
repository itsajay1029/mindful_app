import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Firestore/data service backed by Cloud Firestore.
class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _users => _db.collection('users');

  CollectionReference<Map<String, dynamic>> get _paths => _db.collection('learning_paths');
  CollectionReference<Map<String, dynamic>> get _modules => _db.collection('modules');
  CollectionReference<Map<String, dynamic>> get _enrollments => _db.collection('user_enrollments');
  CollectionReference<Map<String, dynamic>> get _progress => _db.collection('user_progress');

  String _userProgressDocId({
    required String uid,
    required String pathId,
    required String moduleId,
  }) {
    // Firestore doc IDs cannot contain '/', so joining like this is safe.
    return '${uid}_${pathId}_$moduleId';
  }

  DocumentReference<Map<String, dynamic>> userProgressDoc({
    required String uid,
    required String pathId,
    required String moduleId,
  }) {
    return _progress.doc(_userProgressDocId(uid: uid, pathId: pathId, moduleId: moduleId));
  }

  /// Ensure `users/{uid}` exists (create if missing).
  ///
  /// This is the backbone for the production flow:
  /// Auth -> user doc -> onboardingCompleted gate -> dashboard.
  Future<void> ensureUserDoc(User user) async {
    final ref = _users.doc(user.uid);
    final snap = await ref.get();

    final current = (snap.data() ?? <String, dynamic>{});

    final hasDisplayName = (current['displayName'] as String?)?.trim().isNotEmpty == true;
    final hasFirstName = (current['firstName'] as String?)?.trim().isNotEmpty == true;
    final hasLastName = (current['lastName'] as String?)?.trim().isNotEmpty == true;

    final authDisplayName = user.displayName?.trim();
    final shouldSetNameFromAuth =
        !hasDisplayName && !hasFirstName && (authDisplayName != null && authDisplayName.isNotEmpty);

    // Very simple parsing: first token => firstName, rest => lastName.
    String? parsedFirst;
    String? parsedLast;
    if (shouldSetNameFromAuth) {
      final parts = authDisplayName.split(RegExp(r'\s+')).where((p) => p.trim().isNotEmpty).toList();
      if (parts.isNotEmpty) {
        parsedFirst = parts.first;
        parsedLast = parts.length > 1 ? parts.sublist(1).join(' ') : null;
      }
    }

    await ref.set({
      'uid': user.uid,
      'email': user.email,
      // Initialize onboarding only if missing.
      if (!current.containsKey('onboardingCompleted')) 'onboardingCompleted': false,
      // Dashboard defaults
      if (!current.containsKey('xp')) 'xp': 0,
      if (!snap.exists) 'createdAt': FieldValue.serverTimestamp(),

      // Populate name from Google Auth only when user doc doesn't already have it.
      if (shouldSetNameFromAuth) 'displayName': authDisplayName,
      if (shouldSetNameFromAuth && parsedFirst != null) 'firstName': parsedFirst,
      if (shouldSetNameFromAuth && parsedLast != null && !hasLastName) 'lastName': parsedLast,
    }, SetOptions(merge: true));
  }

  /// Upsert basic profile fields (safe to call multiple times).
  Future<void> upsertUserProfile({
    required String uid,
    String? email,
    String? firstName,
    String? lastName,
  }) {
    final displayName = [firstName, lastName]
        .where((e) => e != null && e.trim().isNotEmpty)
        .map((e) => e!.trim())
        .join(' ');

    return _users.doc(uid).set({
      if (email != null) 'email': email,
      if (firstName != null) 'firstName': firstName.trim(),
      if (lastName != null) 'lastName': lastName.trim(),
      if (displayName.isNotEmpty) 'displayName': displayName,
      // Keep defaults present for the dashboard (won't overwrite existing values)
      'xp': FieldValue.increment(0),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Convenience helper to update XP.
  Future<void> addXp({required String uid, required int delta}) {
    return _users.doc(uid).set({
      'xp': FieldValue.increment(delta),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }


  /// ===== Phase 2 schema APIs =====

  Query<Map<String, dynamic>> queryActiveLearningPaths() {
    return _paths.where('isActive', isEqualTo: true).orderBy('order');
  }

  Query<Map<String, dynamic>> queryModulesForPath(String pathId) {
    return _modules
        .where('pathId', isEqualTo: pathId)
        .where('isActive', isEqualTo: true)
        .orderBy('order');
  }

  /// Stream user enrollments (active only).
  Query<Map<String, dynamic>> queryUserEnrollments(String uid) {
    return _enrollments
        .where('userId', isEqualTo: uid)
        .where('status', isEqualTo: 'active');
  }

  Future<void> enrollInPath({
    required String uid,
    required String pathId,
  }) async {
    // Avoid duplicates: if exists active enrollment, do nothing.
    final existing = await _enrollments
        .where('userId', isEqualTo: uid)
        .where('pathId', isEqualTo: pathId)
        .where('status', isEqualTo: 'active')
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) return;

    await _enrollments.add({
      'userId': uid,
      'pathId': pathId,
      'status': 'active',
      'enrolledAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> unenrollFromPath({
    required String uid,
    required String pathId,
  }) async {
    final existing = await _enrollments
        .where('userId', isEqualTo: uid)
        .where('pathId', isEqualTo: pathId)
        .where('status', isEqualTo: 'active')
        .limit(1)
        .get();

    if (existing.docs.isEmpty) return;
    await _enrollments.doc(existing.docs.first.id).set({
      'status': 'inactive',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Stream progress for a user within a specific path.
  Query<Map<String, dynamic>> queryUserProgressForPath({
    required String uid,
    required String pathId,
  }) {
    return _progress.where('userId', isEqualTo: uid).where('pathId', isEqualTo: pathId);
  }

  /// Stream all completed progress for a user (across all paths).
  Query<Map<String, dynamic>> queryCompletedUserProgress(String uid) {
    return _progress.where('userId', isEqualTo: uid).where('completed', isEqualTo: true);
  }

  /// Mark a module completed.
  ///
  /// Writes/merges a single deterministic document in `user_progress` to prevent duplicates.
  /// Returns `true` when this call performed the completion write, `false` if it was already completed.
  Future<bool> markModuleCompleted({
    required String uid,
    required String pathId,
    required String moduleId,
    String? reflection,
    int xpReward = 0,
  }) async {
    final ref = userProgressDoc(uid: uid, pathId: pathId, moduleId: moduleId);
    final snap = await ref.get();
    final alreadyCompleted = (snap.data()?['completed'] == true);
    if (alreadyCompleted) return false;

    await ref.set({
      'userId': uid,
      'pathId': pathId,
      'moduleId': moduleId,
      'completed': true,
      if (reflection != null && reflection.trim().isNotEmpty) 'reflection': reflection.trim(),
      'completedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // Phase 2 Step 3 said "No XP yet". Keep XP off by default unless a positive reward is supplied.
    if (xpReward > 0) {
      await addXp(uid: uid, delta: xpReward);
    }

    return true;
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
