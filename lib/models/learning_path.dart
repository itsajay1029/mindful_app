import 'package:cloud_firestore/cloud_firestore.dart';

class LearningPath {
  const LearningPath({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.totalDurationHours,
    required this.isActive,
    required this.order,
  });

  final String id;
  final String title;
  final String description;
  final String category;
  final int totalDurationHours;
  final bool isActive;
  final int order;

  String get durationLabel => '${totalDurationHours}h';

  factory LearningPath.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return LearningPath(
      id: doc.id,
      title: (data['title'] as String?) ?? '',
      description: (data['description'] as String?) ?? '',
      category: (data['category'] as String?) ?? '',
      totalDurationHours: (data['totalDurationHours'] as num?)?.toInt() ?? 0,
      isActive: data['isActive'] == true,
      order: (data['order'] as num?)?.toInt() ?? 0,
    );
  }
}

