import 'package:cloud_firestore/cloud_firestore.dart';

/// A skill area the user wants to improve (e.g. Problem Solving, Communication).
class Segment {
  const Segment({
    required this.id,
    required this.title,
    required this.order,
    required this.isActive,
    this.subtitle,
    this.icon,
  });

  final String id;
  final String title;
  final String? subtitle;
  final String? icon;
  final int order;
  final bool isActive;

  factory Segment.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return Segment(
      id: doc.id,
      title: (data['title'] as String?)?.trim() ?? '',
      subtitle: (data['subtitle'] as String?)?.trim(),
      icon: (data['icon'] as String?)?.trim(),
      order: (data['order'] as num?)?.toInt() ?? 0,
      isActive: data['isActive'] == true,
    );
  }
}
