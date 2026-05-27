import 'package:flutter/material.dart';

import '../models/segment.dart';
import '../services/firestore_service.dart';
import '../ui/emerald_orbit/tokens.dart';
import 'segment_detail_screen.dart';

/// Segments catalog (Stitch-inspired).
///
/// Firestore-backed:
/// - `segments`
class SegmentsScreen extends StatelessWidget {
  const SegmentsScreen({super.key});

  IconData _iconForSegment(Segment s) {
    final raw = (s.icon ?? '').trim().toLowerCase();
    return switch (raw) {
      'communication' => Icons.chat_rounded,
      'leadership' => Icons.groups_rounded,
      'focus' => Icons.gps_fixed_rounded,
      'wellness' => Icons.self_improvement_rounded,
      'psychology' => Icons.psychology_rounded,
      _ => Icons.auto_awesome_rounded,
    };
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final headline = Theme.of(context).textTheme.headlineLarge ?? const TextStyle(fontSize: 34);
    final bodyLg = Theme.of(context).textTheme.bodyLarge ?? const TextStyle(fontSize: 16);

    return Scaffold(
      backgroundColor: EoColors.background,
      appBar: AppBar(
        title: const Text('Segments'),
      ),
      body: StreamBuilder(
        stream: FirestoreService().queryActiveSegments().snapshots(),
        builder: (context, AsyncSnapshot snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final segments = (snap.data?.docs ?? [])
              .map((d) => Segment.fromDoc(d))
              .where((s) => s.isActive && s.title.trim().isNotEmpty)
              .toList()
            ..sort((a, b) => a.order.compareTo(b.order));

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
            children: [
          Text(
            'The Skills Catalog',
            style: headline.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.4,
                  color: EoColors.onSurface,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose a path to master your grind and unlock your potential.',
            style: bodyLg.copyWith(
                  color: EoColors.onSurfaceVariant,
                  height: 1.25,
                ),
          ),
          const SizedBox(height: 18),
          if (segments.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                'No segments available yet. Add documents to `segments` (isActive=true).',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: EoColors.onSurfaceVariant),
              ),
            ),

          ...segments.map(
            (s) {
              // Use existing Stitch card UI but with Firestore content.
              final uiData = _SegmentMock(
                title: s.title,
                subtitle: (s.subtitle ?? '').isEmpty ? ' ' : s.subtitle!,
                badge: 'ACTIVE',
                icon: _iconForSegment(s),
                accent: cs.primary,
                iconBg: cs.primaryContainer,
                state: _SegmentState.nextLesson,
                nextLesson: 'OPEN',
              );

              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _SegmentCard(
                  data: uiData,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => SegmentDetailScreen(segment: s),
                      ),
                    );
                  },
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

enum _SegmentState { nextLesson, locked }

class _SegmentMock {
  const _SegmentMock({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.icon,
    required this.accent,
    required this.iconBg,
    required this.state,
    this.nextLesson,
  });

  final String title;
  final String subtitle;
  final String badge;
  final IconData icon;
  final Color accent;
  final Color iconBg;
  final _SegmentState state;
  final String? nextLesson;
}

class _SegmentCard extends StatelessWidget {
  const _SegmentCard({required this.data, required this.onTap});

  final _SegmentMock data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final titleLg = Theme.of(context).textTheme.titleLarge ?? const TextStyle(fontSize: 20);
    final labelSm = Theme.of(context).textTheme.labelSmall ?? const TextStyle(fontSize: 12);
    final bodyMd = Theme.of(context).textTheme.bodyMedium ?? const TextStyle(fontSize: 14);
    final isLocked = data.state == _SegmentState.locked;
    final bg = EoColors.surfaceContainerLowest;
    final opacity = isLocked ? 0.78 : 1.0;

    return Opacity(
      opacity: opacity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(EoRadii.lg),
          child: Container(
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(EoRadii.lg),
              border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.10)),
              boxShadow: [
                BoxShadow(
                  blurRadius: 48,
                  offset: const Offset(0, 18),
                  color: data.accent.withValues(alpha: 0.08),
                ),
              ],
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Left accent strip
                  Container(
                    width: 8,
                    decoration: BoxDecoration(
                      color: data.accent,
                      borderRadius: const BorderRadius.horizontal(left: Radius.circular(EoRadii.lg)),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 58,
                            width: 58,
                            decoration: BoxDecoration(
                              color: data.iconBg,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Icon(data.icon, color: isLocked ? EoColors.outline : data.accent, size: 30),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        data.title,
                                        style: titleLg.copyWith(
                                          fontWeight: FontWeight.w900,
                                          color: EoColors.onSurface,
                                        ),
                                      ),
                                    ),
                                    if (isLocked) ...[
                                      Icon(Icons.lock_rounded, color: EoColors.outlineVariant, size: 18),
                                    ] else ...[
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: data.iconBg,
                                          borderRadius: BorderRadius.circular(999),
                                        ),
                                        child: Text(
                                          data.badge,
                                          style: labelSm.copyWith(
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 1.0,
                                            color: data.accent,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  data.subtitle,
                                  style: bodyMd.copyWith(
                                    color: EoColors.onSurfaceVariant,
                                    height: 1.25,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                switch (data.state) {
                                  _SegmentState.nextLesson => _NextLesson(text: data.nextLesson ?? ''),
                                  _SegmentState.locked => const _LockedHint(text: 'Locked'),
                                },
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NextLesson extends StatelessWidget {
  const _NextLesson({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    if (text.trim().isEmpty) return const SizedBox.shrink();
    return Text(
      'NEXT LESSON: ${text.toUpperCase()}',
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: 1.4,
            color: EoColors.tertiary,
          ),
    );
  }
}

class _LockedHint extends StatelessWidget {
  const _LockedHint({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: EoColors.outline,
            fontWeight: FontWeight.w700,
          ),
    );
  }
}
