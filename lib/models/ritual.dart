import 'package:cloud_firestore/cloud_firestore.dart';

/// A ritual tile shown on Home.
///
/// Firestore: `rituals/{id}`
class Ritual {
  const Ritual({
    required this.id,
    required this.title,
    required this.meta,
    required this.icon,
    required this.order,
    required this.isActive,
    this.action,
    this.actionTarget,
  });

  final String id;
  final String title;
  final String meta;
  final String icon;
  final int order;
  final bool isActive;

  /// e.g. `open_learning_hub`, `open_reset`, `open_url`
  final String? action;
  final String? actionTarget;

  factory Ritual.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return Ritual(
      id: doc.id,
      title: (data['title'] as String?)?.trim() ?? '',
      meta: (data['meta'] as String?)?.trim() ?? '',
      icon: (data['icon'] as String?)?.trim() ?? '',
      order: (data['order'] as num?)?.toInt() ?? 0,
      isActive: data['isActive'] == true,
      action: (data['action'] as String?)?.trim(),
      actionTarget: (data['actionTarget'] as String?)?.trim(),
    );
  }
}
