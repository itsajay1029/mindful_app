import 'package:cloud_firestore/cloud_firestore.dart';

class UserProgress {
  const UserProgress({
    required this.id,
    required this.userId,
    required this.pathId,
    required this.moduleId,
    required this.completed,
    required this.reflection,
    required this.completedAt,
  });

  final String id;
  final String userId;
  final String pathId;
  final String moduleId;
  final bool completed;
  final String? reflection;
  final DateTime? completedAt;

  factory UserProgress.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    final ts = data['completedAt'];
    return UserProgress(
      id: doc.id,
      userId: (data['userId'] as String?) ?? '',
      pathId: (data['pathId'] as String?) ?? '',
      moduleId: (data['moduleId'] as String?) ?? '',
      completed: data['completed'] == true,
      reflection: (data['reflection'] as String?),
      completedAt: ts is Timestamp ? ts.toDate() : null,
    );
  }
}

