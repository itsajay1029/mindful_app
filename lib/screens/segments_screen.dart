import 'package:flutter/material.dart';

import '../ui/emerald_orbit/tokens.dart';
import '../ui/emerald_orbit/widgets/eo_card.dart';
import '../ui/emerald_orbit/widgets/eo_tactile_button.dart';

/// Segments catalog (Stitch-inspired).
///
/// This screen intentionally uses **mock data** for now so the app feels
/// premium/appealing even before the Firestore-driven catalog is built.
class SegmentsScreen extends StatelessWidget {
  const SegmentsScreen({super.key});

  static const _mock = <_SegmentMock>[
    _SegmentMock(
      title: 'Leadership',
      subtitle: 'Master the art of influence, communication, and team synergy.',
      badge: 'PRO PATH',
      icon: Icons.groups_rounded,
      accent: EoColors.primary,
      iconBg: EoColors.primaryContainer,
      progress01: 0.65,
      state: _SegmentState.progress,
    ),
    _SegmentMock(
      title: 'Deep Focus',
      subtitle: 'Build unshakeable concentration and productivity workflows.',
      badge: 'UNLOCKED',
      icon: Icons.gps_fixed_rounded,
      accent: EoColors.secondary,
      iconBg: EoColors.secondaryContainer,
      state: _SegmentState.steps,
      stepsDone: 2,
      stepsTotal: 4,
    ),
    _SegmentMock(
      title: 'Wellness',
      subtitle: 'Habits for physical health, mental clarity, and sustainable energy.',
      badge: 'MINDFULNESS',
      icon: Icons.self_improvement_rounded,
      accent: EoColors.tertiary,
      iconBg: EoColors.tertiaryContainer,
      state: _SegmentState.nextLesson,
      nextLesson: 'Morning Flow',
    ),
    _SegmentMock(
      title: 'Cognitive Bias',
      subtitle: 'Understanding mental shortcuts to make better decisions.',
      badge: 'LOCKED',
      icon: Icons.psychology_rounded,
      accent: EoColors.outlineVariant,
      iconBg: EoColors.surfaceContainerHigh,
      state: _SegmentState.locked,
      lockedHint: 'Reach Level 5 to Unlock',
    ),
  ];

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
      body: ListView(
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
          ..._mock.map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _SegmentCard(
                data: s,
                onTap: () {
                  showModalBottomSheet<void>(
                    context: context,
                    showDragHandle: true,
                    builder: (ctx) => Padding(
                      padding: const EdgeInsets.fromLTRB(18, 6, 18, 18),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.title,
                            style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Segment experiences are coming soon.\n\nFor now this is mock data to make the app feel polished.',
                            style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(color: EoColors.onSurfaceVariant),
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: () => Navigator.of(ctx).pop(),
                              child: const Text('Got it'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 10),
          _MasteryCard(
            title: 'The Mastery Path',
            subtitle: 'Earn 500 more XP in Segments to unlock the Masterclass series.',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Progress view coming soon')),
              );
            },
            accent: cs.primary,
          ),
        ],
      ),
    );
  }
}

enum _SegmentState { progress, steps, nextLesson, locked }

class _SegmentMock {
  const _SegmentMock({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.icon,
    required this.accent,
    required this.iconBg,
    required this.state,
    this.progress01,
    this.stepsDone,
    this.stepsTotal,
    this.nextLesson,
    this.lockedHint,
  });

  final String title;
  final String subtitle;
  final String badge;
  final IconData icon;
  final Color accent;
  final Color iconBg;
  final _SegmentState state;

  final double? progress01;
  final int? stepsDone;
  final int? stepsTotal;
  final String? nextLesson;
  final String? lockedHint;
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
                                  _SegmentState.progress => _ProgressBar(color: data.accent, value: data.progress01 ?? 0),
                                  _SegmentState.steps => _StepsBar(color: data.accent, done: data.stepsDone ?? 0, total: data.stepsTotal ?? 4),
                                  _SegmentState.nextLesson => _NextLesson(text: data.nextLesson ?? ''),
                                  _SegmentState.locked => _LockedHint(text: data.lockedHint ?? 'Locked'),
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

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.color, required this.value});
  final Color color;
  final double value;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: LinearProgressIndicator(
        value: value.clamp(0, 1),
        minHeight: 8,
        backgroundColor: EoColors.surfaceContainer,
        valueColor: AlwaysStoppedAnimation(color),
      ),
    );
  }
}

class _StepsBar extends StatelessWidget {
  const _StepsBar({required this.color, required this.done, required this.total});
  final Color color;
  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    final clampedTotal = total <= 0 ? 1 : total;
    final clampedDone = done.clamp(0, clampedTotal);
    return Row(
      children: List.generate(clampedTotal, (i) {
        final filled = i < clampedDone;
        return Expanded(
          child: Container(
            height: 6,
            margin: EdgeInsets.only(right: i == clampedTotal - 1 ? 0 : 6),
            decoration: BoxDecoration(
              color: filled ? color : EoColors.surfaceContainer,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        );
      }),
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

class _MasteryCard extends StatelessWidget {
  const _MasteryCard({
    required this.title,
    required this.subtitle,
    required this.onPressed,
    required this.accent,
  });

  final String title;
  final String subtitle;
  final VoidCallback onPressed;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return EoCard(
      radius: EoRadii.lg,
      padding: const EdgeInsets.all(22),
      color: accent,
      shadowColor: accent.withValues(alpha: 0.22),
      child: Stack(
        children: [
          Positioned(
            right: -24,
            bottom: -24,
            child: Icon(Icons.emoji_events_rounded, size: 160, color: Colors.white.withValues(alpha: 0.12)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
              ),
              const SizedBox(height: 10),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.90),
                      height: 1.25,
                    ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: 190,
                child: EoTactileButton.tonal(
                  label: 'View Progress',
                  onPressed: onPressed,
                  toneColor: Theme.of(context).colorScheme.primaryContainer,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  radius: 18,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
