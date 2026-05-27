import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/reset_item.dart';
import '../services/firestore_service.dart';
import '../ui/emerald_orbit/tokens.dart';
import '../ui/emerald_orbit/widgets/eo_card.dart';
import 'reset_studio_player_screen.dart';

/// Reset Studio (Stitch-inspired) backed by Firestore.
class ResetStudioScreen extends StatelessWidget {
  const ResetStudioScreen({super.key});

  IconData? _iconFromName(String? raw) {
    final v = (raw ?? '').trim();
    if (v.isEmpty) return null;
    return switch (v) {
      'self_improvement' => Icons.self_improvement_rounded,
      'air' => Icons.air_rounded,
      'center_focus' => Icons.center_focus_strong_rounded,
      'psychology' => Icons.psychology_rounded,
      'auto_awesome' => Icons.auto_awesome_rounded,
      _ => null,
    };
  }

  void _openPlayer(BuildContext context, {required String title, required String url}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ResetStudioPlayerScreen(title: title, url: url),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: EoColors.background,
      appBar: AppBar(
        title: const Text('Reset Studio'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirestoreService().queryActiveResetItems().snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = (snap.data?.docs ?? [])
              .map(ResetItem.fromDoc)
              .where((i) => i.isActive && i.mediaUrl.trim().isNotEmpty)
              .toList()
            ..sort((a, b) => a.order.compareTo(b.order));

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
            children: [
          // Hero
          EoCard(
            radius: EoRadii.lg,
            padding: const EdgeInsets.all(22),
            color: cs.primaryContainer,
            shadowColor: cs.primary.withValues(alpha: 0.18),
            child: Stack(
              children: [
                Positioned(
                  right: -22,
                  bottom: -18,
                  child: Icon(Icons.waves_rounded, size: 150, color: cs.primary.withValues(alpha: 0.18)),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: cs.primary,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'DAILY RITUAL',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: cs.onPrimary,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                            ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Quiet the noise,\nreclaim your flow.',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            height: 1.06,
                            color: EoColors.onPrimaryContainer,
                          ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: 220,
                      child: Text(
                        'Bite-sized mental resets designed for high-performers.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: EoColors.onPrimaryFixedVariant,
                              height: 1.25,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Quick resets header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Quick Resets',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              TextButton(
                onPressed: null,
                child: Text(
                  'See all',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'No resets available yet. Add documents to `reset_items` (isActive=true).',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: EoColors.onSurfaceVariant),
              ),
            ),

          ...items.map(
            (it) {
              final chipBg = it.chipBg != null ? Color(it.chipBg!) : cs.primaryContainer;
              final chipFg = it.chipFg != null ? Color(it.chipFg!) : cs.primary;
              final icon = _iconFromName(it.chipIcon);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _QuickResetRow(
                  item: _ResetItem(
                    title: it.title,
                    meta: it.meta,
                    url: it.mediaUrl,
                    chipBg: chipBg,
                    chipFg: chipFg,
                    chipText: it.chipText,
                    chipIcon: icon,
                  ),
                  onTap: () => _openPlayer(context, title: it.title, url: it.mediaUrl),
                ),
              );
            },
          ),
        ],
          );
        },
      ),
    );
  }
}

class _ResetItem {
  const _ResetItem({
    required this.title,
    required this.meta,
    required this.url,
    required this.chipBg,
    required this.chipFg,
    this.chipText,
    this.chipIcon,
  });

  final String title;
  final String meta;
  final String url;

  final Color chipBg;
  final Color chipFg;
  final String? chipText;
  final IconData? chipIcon;
}

class _QuickResetRow extends StatelessWidget {
  const _QuickResetRow({required this.item, required this.onTap});

  final _ResetItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(EoRadii.lg),
        child: Ink(
          decoration: BoxDecoration(
            color: EoColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(EoRadii.lg),
            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.10)),
            boxShadow: [
              BoxShadow(
                blurRadius: 24,
                offset: const Offset(0, 12),
                color: Colors.black.withValues(alpha: 0.04),
              )
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Row(
              children: [
                Container(
                  height: 52,
                  width: 52,
                  decoration: BoxDecoration(
                    color: item.chipBg,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Center(
                    child: item.chipText != null
                        ? Text(
                            item.chipText!,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: item.chipFg,
                                ),
                          )
                        : Icon(item.chipIcon, color: item.chipFg, size: 26),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.schedule_rounded, size: 16, color: EoColors.onSurfaceVariant),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              item.meta,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: EoColors.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  height: 44,
                  width: 44,
                  decoration: BoxDecoration(
                    color: cs.primary,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 18,
                        offset: const Offset(0, 10),
                        color: cs.primary.withValues(alpha: 0.22),
                      )
                    ],
                  ),
                  child: Icon(Icons.play_arrow_rounded, color: cs.onPrimary),
                ),
                const SizedBox(width: 10),
                Icon(Icons.chevron_right_rounded, color: EoColors.outlineVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }
}




