import 'package:cloud_firestore/cloud_firestore.dart';

/// Public user profile for leaderboards.
class PublicUser {
  const PublicUser({
    required this.uid,
    required this.displayName,
    required this.xp,
    required this.streakCurrent,
    required this.streakBest,
  });

  final String uid;
  final String displayName;
  final int xp;
  final int streakCurrent;
  final int streakBest;

  factory PublicUser.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return PublicUser(
      uid: (data['uid'] as String?)?.trim() ?? doc.id,
      displayName: (data['displayName'] as String?)?.trim() ?? 'Player',
      xp: (data['xp'] as num?)?.toInt() ?? 0,
      streakCurrent: (data['streakCurrent'] as num?)?.toInt() ?? 0,
      streakBest: (data['streakBest'] as num?)?.toInt() ?? 0,
    );
  }
}
