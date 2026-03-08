import 'package:cloud_firestore/cloud_firestore.dart';

enum ActivityType {
  quiz,
  audio,
  reflection,
}

ActivityType activityTypeFromString(String raw) {
  final v = raw.trim().toLowerCase();
  return switch (v) {
    'audio' => ActivityType.audio,
    'reflection' => ActivityType.reflection,
    _ => ActivityType.quiz,
  };
}

/// A playable piece of content.
///
/// For MVP, we support a quiz-style activity.
class Activity {
  const Activity({
    required this.id,
    required this.segmentId,
    required this.title,
    required this.type,
    required this.order,
    required this.isActive,
    this.prompt,
    this.options,
    this.correctIndex,
    this.explanation,
    this.durationMinutes,
    this.xpReward = 10,
    this.mediaUrl,
  });

  final String id;
  final String segmentId;
  final String title;
  final ActivityType type;
  final int order;
  final bool isActive;

  // Quiz fields
  final String? prompt;
  final List<String>? options;
  final int? correctIndex;
  final String? explanation;

  // Generic fields
  final int? durationMinutes;
  final int xpReward;
  final String? mediaUrl;

  factory Activity.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    final opts = (data['options'] as List?)?.map((e) => e.toString()).toList();
    return Activity(
      id: doc.id,
      segmentId: (data['segmentId'] as String?)?.trim() ?? '',
      title: (data['title'] as String?)?.trim() ?? '',
      type: activityTypeFromString((data['type'] as String?) ?? 'quiz'),
      order: (data['order'] as num?)?.toInt() ?? 0,
      isActive: data['isActive'] == true,
      prompt: (data['prompt'] as String?)?.trim(),
      options: opts,
      correctIndex: (data['correctIndex'] as num?)?.toInt(),
      explanation: (data['explanation'] as String?)?.trim(),
      durationMinutes: (data['durationMinutes'] as num?)?.toInt(),
      xpReward: (data['xpReward'] as num?)?.toInt() ?? 10,
      mediaUrl: (data['mediaUrl'] as String?)?.trim(),
    );
  }
}
