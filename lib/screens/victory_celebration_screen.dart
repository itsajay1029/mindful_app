import 'package:flutter/material.dart';

import '../ui/emerald_orbit/tokens.dart';
import '../ui/emerald_orbit/widgets/eo_tactile_button.dart';

/// Success/celebration screen rebuilt to match Stitch export
/// `screens/stitch/victory_celebration/code.html`.
class VictoryCelebrationScreen extends StatefulWidget {
  const VictoryCelebrationScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.xpRewardLabel,
    required this.streakLabel,
  });

  final String title;
  final String subtitle;
  final String xpRewardLabel;
  final String streakLabel;

  @override
  State<VictoryCelebrationScreen> createState() => _VictoryCelebrationScreenState();
}

class _VictoryCelebrationScreenState extends State<VictoryCelebrationScreen> {
  String _digitsOnly(String raw) {
    final m = RegExp(r'\d+').allMatches(raw).map((e) => e.group(0)!).join();
    return m.isEmpty ? '0' : m;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final streakNumber = _digitsOnly(widget.streakLabel);
    return Scaffold(
      backgroundColor: EoColors.surface,
      body: Stack(
        children: [
          // Subtle celebratory rays overlay.
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.0),
                    EoColors.secondaryContainer.withValues(alpha: 0.10),
                  ],
                ),
              ),
            ),
          ),
          // Static confetti pieces (Stitch uses a static representation).
          ..._confettiPieces(),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 10),
                      _MascotWithBadge(primary: cs.primary),
                      const SizedBox(height: 18),
                      Text(
                        widget.title,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.displayLarge?.copyWith(
                              fontSize: 56,
                              height: 1.0,
                              color: cs.primary,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1.0,
                            ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        widget.subtitle,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontSize: 18,
                              color: EoColors.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          Expanded(
                            child: _RewardCard(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      Icon(Icons.local_fire_department, size: 52, color: cs.tertiary),
                                      Positioned(
                                        top: -2,
                                        right: -2,
                                        child: Container(
                                          width: 16,
                                          height: 16,
                                          decoration: BoxDecoration(
                                            color: cs.tertiary,
                                            borderRadius: BorderRadius.circular(999),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    streakNumber,
                                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                          fontWeight: FontWeight.w900,
                                          color: EoColors.onSurface,
                                        ),
                                  ),
                                  const SizedBox(height: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: EoColors.tertiaryContainer.withValues(alpha: 0.20),
                                      borderRadius: BorderRadius.circular(EoRadii.full),
                                    ),
                                    child: Text(
                                      widget.streakLabel.toUpperCase(),
                                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                            color: EoColors.onTertiaryContainer,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 1.2,
                                          ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _RewardCard(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: EoColors.secondaryContainer,
                                      borderRadius: BorderRadius.circular(EoRadii.full),
                                      boxShadow: [
                                        BoxShadow(
                                          blurRadius: 20,
                                          offset: const Offset(0, 8),
                                          color: EoColors.secondary.withValues(alpha: 0.20),
                                        )
                                      ],
                                    ),
                                    child: Icon(Icons.monetization_on, color: EoColors.onSecondaryContainer, size: 26),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    widget.xpRewardLabel,
                                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                          fontWeight: FontWeight.w900,
                                          color: EoColors.onSurface,
                                        ),
                                  ),
                                  const SizedBox(height: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: EoColors.secondaryContainer.withValues(alpha: 0.20),
                                      borderRadius: BorderRadius.circular(EoRadii.full),
                                    ),
                                    child: Text(
                                      'VAULT REWARD',
                                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                            color: EoColors.onSecondaryContainer,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 1.2,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: EoTactileButton.primary(
                          label: 'Keep it going!',
                          icon: const Icon(Icons.arrow_forward),
                          onPressed: () => Navigator.of(context).maybePop(),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
                          radius: EoRadii.xl,
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: _SecondaryActionButton(
                          icon: Icons.share,
                          label: 'Share Achievement',
                          onTap: () {},
                        ),
                      ),
                      const SizedBox(height: 26),
                      const SizedBox.shrink(),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Background decorative blobs.
          Positioned(
            left: -40,
            bottom: -40,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Positioned(
            right: -40,
            top: -40,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                color: cs.secondary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static List<Widget> _confettiPieces() {
    Widget piece({required double top, required double left, required Color color, double size = 10, double w = 10, double h = 10, double angle = 0}) {
      return Positioned(
        top: top,
        left: left,
        child: Transform.rotate(
          angle: angle,
          child: Container(
            width: w,
            height: h,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      );
    }

    return [
      piece(top: 40, left: 40, color: EoColors.primary, angle: 0.2),
      piece(top: 160, left: 90, color: EoColors.tertiary, angle: -0.8),
      piece(top: 80, left: 260, color: EoColors.secondary, angle: 0.8),
      piece(top: 320, left: 24, color: EoColors.primaryContainer, angle: 0.2),
      piece(top: 240, left: 330, color: EoColors.tertiaryContainer, angle: -0.2),
      piece(top: 60, left: 360, color: EoColors.secondaryContainer, angle: 1.57),
      piece(top: 640, left: 170, color: EoColors.primary, w: 12, h: 12, angle: 0.2),
      piece(top: 600, left: 300, color: EoColors.secondary, w: 16, h: 8, angle: -0.2),
    ];
  }
}

class _RewardCard extends StatelessWidget {
  const _RewardCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: EoColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(EoRadii.lg),
        boxShadow: [
          BoxShadow(
            blurRadius: 32,
            offset: const Offset(0, 16),
            color: Colors.black.withValues(alpha: 0.04),
          )
        ],
      ),
      child: Center(child: child),
    );
  }
}

class _SecondaryActionButton extends StatelessWidget {
  const _SecondaryActionButton({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(EoRadii.xl),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        decoration: BoxDecoration(
          color: EoColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(EoRadii.xl),
          border: Border.all(color: Colors.transparent, width: 2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: EoColors.onSurfaceVariant),
            const SizedBox(width: 10),
            Text(
              label,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: EoColors.onSurfaceVariant,
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MascotWithBadge extends StatelessWidget {
  const _MascotWithBadge({required this.primary});
  final Color primary;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // halo
        Positioned(
          left: -20,
          right: -20,
          top: -20,
          bottom: -20,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: EoColors.secondary.withValues(alpha: 0.20),
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(
                  blurRadius: 60,
                  offset: const Offset(0, 0),
                  color: EoColors.secondary.withValues(alpha: 0.18),
                )
              ],
            ),
          ),
        ),
        Container(
          width: 220,
          height: 220,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: EoColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                blurRadius: 48,
                offset: const Offset(0, 32),
                color: primary.withValues(alpha: 0.10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Image.network(
              'https://lh3.googleusercontent.com/aida-public/AB6AXuAkII9dZAwOTcK2ucX0HmUO-JmoK2IGYMvboz2Sj95zB_ZSG6Lm8iDCQLp-jPNoYQf1BHd5dC9BwwCEvoQ1MA6nWT4x9Tw5EuUBQGdkjRK14kZg6zgQA6Svd8w0fFpVsU9QMotanMPQd-rUKepbBCMhczZr3fw7nnNkNOXUkRCwUz8-WDzny-KHW19A-EGwqMKX8-aKt8uXeRNTuHaWLlbHjGgES-zcEyhDto9qE75jn0X2fzOBTSS_4IwSsDNXqJxKnInkbV27mxcg',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Image.asset(
                'screens/stitch/victory_celebration/screen.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        Positioned(
          top: -10,
          right: -8,
          child: Transform.rotate(
            angle: 0.22,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: EoColors.tertiaryContainer,
                borderRadius: BorderRadius.circular(EoRadii.d),
                border: Border.all(color: EoColors.surfaceContainerLowest, width: 2),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 16,
                    offset: const Offset(0, 10),
                    color: Colors.black.withValues(alpha: 0.12),
                  )
                ],
              ),
              child: Icon(Icons.workspace_premium, color: EoColors.onTertiaryContainer),
            ),
          ),
        ),
      ],
    );
  }
}
