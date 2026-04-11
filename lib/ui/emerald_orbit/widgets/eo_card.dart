import 'package:flutter/material.dart';

import '../tokens.dart';

class EoCard extends StatelessWidget {
  const EoCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(24),
    this.radius = EoRadii.lg,
    this.color,
    this.shadowColor,
    this.border,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final double radius;
  final Color? color;
  final Color? shadowColor;
  final BoxBorder? border;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = color ?? EoColors.surfaceContainerLowest;
    final shadow = shadowColor ?? cs.primary.withValues(alpha: 0.10);

    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOutCubic,
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(radius),
        border: border,
        boxShadow: [
          BoxShadow(
            blurRadius: 48,
            offset: const Offset(0, 18),
            color: shadow,
          )
        ],
      ),
      child: child,
    );

    if (onTap == null) return card;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(radius),
      child: card,
    );
  }
}
