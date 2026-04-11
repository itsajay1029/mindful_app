import 'package:flutter/material.dart';

import '../ui/emerald_orbit/tokens.dart';
import '../ui/emerald_orbit/widgets/eo_card.dart';
import 'reset_studio_player_screen.dart';

/// Reset Studio (Stitch-inspired, mock data).
///
/// Designed to feel premium/appealing even before real content is wired.
class ResetStudioScreen extends StatelessWidget {
  const ResetStudioScreen({super.key});

  static const _xpToday = 48;

  static const _quickResets = <_ResetItem>[
    _ResetItem(
      title: 'Instant Clarity',
      meta: '3 mins • Guided Breathing',
      chipText: '3',
      chipBg: Color(0xFFBAF9D4),
      chipFg: EoColors.primary,
      url: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
    ),
    _ResetItem(
      title: 'Focus Realignment',
      meta: '5 mins • Visual Scanning',
      chipIcon: Icons.center_focus_strong_rounded,
      chipBg: Color(0xFFFCCB52),
      chipFg: EoColors.secondary,
      url: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
    ),
    _ResetItem(
      title: 'The 60-Second Stop',
      meta: '1 min • Micro-Meditation',
      chipIcon: Icons.self_improvement_rounded,
      chipBg: Color(0xFFFFE1BA),
      chipFg: EoColors.tertiary,
      url: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/Sintel.mp4',
    ),
    _ResetItem(
      title: 'Brain Flush',
      meta: '8 mins • White Noise Mix',
      chipIcon: Icons.air_rounded,
      chipBg: Color(0xFFE7EAEE),
      chipFg: EoColors.onSurfaceVariant,
      url: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerJoyrides.mp4',
    ),
  ];

  static const _bento = <_BentoItem>[
    _BentoItem(
      title: 'Mind Scan',
      subtitle: 'Deep emotional check-in',
      icon: Icons.psychology_rounded,
      bg: Color(0x33FCCB52),
      fg: EoColors.onSecondaryContainer,
      url: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/TearsOfSteel.mp4',
    ),
    _BentoItem(
      title: 'Energy Spike',
      subtitle: 'Quick CNS activation',
      icon: Icons.auto_awesome_rounded,
      bg: Color(0x1AFF9800),
      fg: EoColors.onTertiaryContainer,
      url: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
    ),
  ];

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
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: cs.tertiaryContainer.withValues(alpha: 0.28),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                children: [
                  Icon(Icons.bolt_rounded, size: 16, color: cs.tertiary),
                  const SizedBox(width: 8),
                  Text(
                    '$_xpToday XP',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: cs.tertiary,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: ListView(
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
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('See all coming soon')),
                  );
                },
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

          ..._quickResets.map(
            (it) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _QuickResetRow(
                item: it,
                onTap: () => _openPlayer(context, title: it.title, url: it.url),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Bento
          Row(
            children: [
              Expanded(
                child: _BentoCard(
                  item: _bento[0],
                  onTap: () => _openPlayer(context, title: _bento[0].title, url: _bento[0].url),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _BentoCard(
                  item: _bento[1],
                  onTap: () => _openPlayer(context, title: _bento[1].title, url: _bento[1].url),
                ),
              ),
            ],
          ),
        ],
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

class _BentoItem {
  const _BentoItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.bg,
    required this.fg,
    required this.url,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color bg;
  final Color fg;
  final String url;
}

class _BentoCard extends StatelessWidget {
  const _BentoCard({required this.item, required this.onTap});

  final _BentoItem item;
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
          height: 150,
          decoration: BoxDecoration(
            color: item.bg,
            borderRadius: BorderRadius.circular(EoRadii.lg),
            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.10)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(item.icon, size: 34, color: item.fg),
                const Spacer(),
                Text(
                  item.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: item.fg,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  item.subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: item.fg.withValues(alpha: 0.70),
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
