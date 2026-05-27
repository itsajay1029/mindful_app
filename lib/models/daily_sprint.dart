import 'package:cloud_firestore/cloud_firestore.dart';

/// Daily Sprint content for a given day.
///
/// Stored in Firestore at `daily_sprints/{yyyy-MM-dd}`.
class DailySprint {
  const DailySprint({
    required this.id,
    required this.prompt,
    required this.options,
    required this.correctIndex,
    required this.explanation,
    required this.xpAward,
    this.segmentId,
  });

  final String id; // dateKey
  final String prompt;
  final List<String> options;
  final int correctIndex;
  final String explanation;
  final int xpAward;
  final String? segmentId;

  factory DailySprint.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    final options = (data['options'] as List?)?.map((e) => e.toString()).toList() ?? const <String>[];
    return DailySprint(
      id: doc.id,
      prompt: (data['prompt'] as String?)?.trim() ?? '',
      options: options,
      correctIndex: (data['correctIndex'] as num?)?.toInt() ?? 0,
      explanation: (data['explanation'] as String?)?.trim() ?? '',
      xpAward: (data['xpAward'] as num?)?.toInt() ?? 0,
      segmentId: (data['segmentId'] as String?)?.trim(),
    );
  }
}
