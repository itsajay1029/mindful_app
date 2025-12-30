import 'package:cloud_firestore/cloud_firestore.dart';

class LearningModule {
  const LearningModule({
    required this.id,
    required this.pathId,
    required this.title,
    required this.description,
    required this.contentType,
    required this.contentUrl,
    required this.durationMinutes,
    required this.xp,
    required this.order,
    required this.isActive,
  });

  final String id;
  final String pathId;
  final String title;
  final String description;
  final String contentType;
  final String contentUrl;
  final int durationMinutes;
  final int xp;
  final int order;
  final bool isActive;

  factory LearningModule.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return LearningModule(
      id: doc.id,
      pathId: (data['pathId'] as String?) ?? '',
      title: (data['title'] as String?) ?? '',
      description: (data['description'] as String?) ?? '',
      contentType: (data['contentType'] as String?) ?? 'video',
      contentUrl: (data['contentUrl'] as String?) ?? '',
      durationMinutes: (data['durationMinutes'] as num?)?.toInt() ?? 0,
      xp: (data['xp'] as num?)?.toInt() ?? 0,
      order: (data['order'] as num?)?.toInt() ?? 0,
      isActive: data['isActive'] == true,
    );
  }
}
