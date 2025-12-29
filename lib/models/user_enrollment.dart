import 'package:cloud_firestore/cloud_firestore.dart';

class UserEnrollment {
  const UserEnrollment({
    required this.id,
    required this.userId,
    required this.pathId,
    required this.status,
    required this.enrolledAt,
  });

  final String id;
  final String userId;
  final String pathId;
  final String status;
  final DateTime? enrolledAt;

  factory UserEnrollment.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    final ts = data['enrolledAt'];
    return UserEnrollment(
      id: doc.id,
      userId: (data['userId'] as String?) ?? '',
      pathId: (data['pathId'] as String?) ?? '',
      status: (data['status'] as String?) ?? 'active',
      enrolledAt: ts is Timestamp ? ts.toDate() : null,
    );
  }
}

