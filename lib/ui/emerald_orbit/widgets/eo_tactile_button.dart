import 'package:flutter/material.dart';

import '../tokens.dart';

/// A 3D "tactile" button: on press it moves down and loses the bottom border.
class EoTactileButton extends StatefulWidget {
  const EoTactileButton.primary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
    this.radius = EoRadii.xl,
  })  : variant = _Variant.primary,
        toneColor = null;

  const EoTactileButton.tonal({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    Color? toneColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
    this.radius = EoRadii.xl,
  })  : variant = _Variant.tonal,
        toneColor = toneColor;

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final bool isLoading;
  final _Variant variant;
  final Color? toneColor;
  final EdgeInsets padding;
  final double radius;

  @override
  State<EoTactileButton> createState() => _EoTactileButtonState();
}

enum _Variant { primary, tonal }

class _EoTactileButtonState extends State<EoTactileButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final enabled = widget.onPressed != null && !widget.isLoading;

    final bg = switch (widget.variant) {
      _Variant.primary => cs.primary,
      _Variant.tonal => widget.toneColor ?? cs.primaryContainer,
    };

    final fg = switch (widget.variant) {
      _Variant.primary => cs.onPrimary,
      _Variant.tonal => cs.onPrimaryContainer,
    };

    // Stitch “tactile” shadow is a hard bottom shadow, not a soft cloud.
    // Example: shadow-[0_8px_0_rgba(48,108,79,1)] and active:translate-y-2.
    final bottomShadowColor = widget.variant == _Variant.primary
        ? EoColors.onPrimaryFixedVariant
        : EoColors.onSecondaryFixedVariant;

    // Tailwind active:translate-y-2 (8px) but visually it reads like ~4px in Flutter;
    // we keep 4px to avoid clipping while still matching the pressed feel.
    final translateY = _pressed ? 4.0 : 0.0;
    final bottomShadow = _pressed ? 0.0 : 8.0;

    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
      onTapUp: enabled
          ? (_) {
              setState(() => _pressed = false);
              widget.onPressed?.call();
            }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, translateY, 0),
        decoration: BoxDecoration(
          color: enabled ? bg : bg.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(widget.radius),
          boxShadow: [
            BoxShadow(
              blurRadius: 0,
              spreadRadius: 0,
              offset: Offset(0, bottomShadow),
              color: bottomShadowColor,
            )
          ],
        ),
        child: Container(
          padding: widget.padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            // No explicit border; the hard shadow provides the 3D edge.
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.isLoading) ...[
                SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(fg)),
                ),
              ] else ...[
                if (widget.icon != null) ...[
                  IconTheme.merge(
                    data: IconThemeData(color: fg),
                    child: widget.icon!,
                  ),
                  const SizedBox(width: 10),
                ],
                Text(
                  widget.label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: fg,
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
