import 'package:cloud_firestore/cloud_firestore.dart';

/// A Reset Studio item (audio/video/mixed) playable inside the Reset tab.
///
/// Firestore: `reset_items/{id}`
class ResetItem {
  const ResetItem({
    required this.id,
    required this.title,
    required this.meta,
    required this.mediaUrl,
    required this.order,
    required this.isActive,
    this.xpReward,
    this.chipText,
    this.chipIcon,
    this.chipBg,
    this.chipFg,
  });

  final String id;
  final String title;
  final String meta;
  final String mediaUrl;
  final int order;
  final bool isActive;

  final int? xpReward;
  final String? chipText;
  final String? chipIcon;
  final int? chipBg;
  final int? chipFg;

  factory ResetItem.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return ResetItem(
      id: doc.id,
      title: (data['title'] as String?)?.trim() ?? '',
      meta: (data['meta'] as String?)?.trim() ?? '',
      mediaUrl: (data['mediaUrl'] as String?)?.trim() ?? '',
      order: (data['order'] as num?)?.toInt() ?? 0,
      isActive: data['isActive'] == true,
      xpReward: (data['xpReward'] as num?)?.toInt(),
      chipText: (data['chipText'] as String?)?.trim(),
      chipIcon: (data['chipIcon'] as String?)?.trim(),
      chipBg: (data['chipBg'] as num?)?.toInt(),
      chipFg: (data['chipFg'] as num?)?.toInt(),
    );
  }
}
