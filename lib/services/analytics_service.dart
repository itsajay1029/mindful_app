import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Lightweight analytics/event tracking that writes to Firestore.
///
/// Goal (Sprint 1): "Every action = trackable event" without adding a backend.
///
/// Firestore collection:
///   events (auto id)
///
/// Event document shape (suggested fields):
/// - name: string
/// - userId: string
/// - sessionId: string
/// - ts: serverTimestamp
/// - clientTs: ISO string
/// - platform: string
/// - appVersion: string? (optional in future)
/// - props: map (string -> dynamic)
class AnalyticsService {
  AnalyticsService._({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        sessionId = _newSessionId();

  static final AnalyticsService instance = AnalyticsService._();

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  /// Stable for the current app run.
  final String sessionId;

  CollectionReference<Map<String, dynamic>> get _events => _db.collection('events');

  static String _newSessionId() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final rand = Random().nextInt(1 << 32);
    return '${now}_$rand';
  }

  /// Track a user event.
  ///
  /// - If the user is not signed in, we no-op (keeps rules simple).
  /// - Any error is swallowed in release builds.
  Future<void> track(
    String name, {
    Map<String, dynamic>? props,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _events.add({
        'name': name,
        'userId': user.uid,
        'sessionId': sessionId,
        'ts': FieldValue.serverTimestamp(),
        'clientTs': DateTime.now().toIso8601String(),
        'platform': defaultTargetPlatform.name,
        'props': props ?? <String, dynamic>{},
      });
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('Analytics track failed ($name): $e');
      }
    }
  }
}
