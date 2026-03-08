import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A reusable, Material-friendly card surface that feels more interactive:
/// - ripple + highlight
/// - subtle scale-down on press
/// - shadow/elevation shift on press
class PressableCard extends StatefulWidget {
  const PressableCard({
    super.key,
    required this.child,
    this.onTap,
    this.borderRadius,
    this.padding,
    this.color = Colors.white,
    this.border,
    this.enableHaptics = true,
    this.pressedScale = 0.985,
    this.duration = const Duration(milliseconds: 130),
    this.shadow,
    this.pressedShadow,
  });

  final Widget child;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;
  final EdgeInsets? padding;
  final Color color;
  final BoxBorder? border;
  final bool enableHaptics;
  final double pressedScale;
  final Duration duration;
  final List<BoxShadow>? shadow;
  final List<BoxShadow>? pressedShadow;

  @override
  State<PressableCard> createState() => _PressableCardState();
}

class _PressableCardState extends State<PressableCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? BorderRadius.circular(18);
    final shadow =
        widget.shadow ?? [BoxShadow(blurRadius: 18, offset: const Offset(0, 10), color: Colors.black.withValues(alpha: 0.06))];
    final pressedShadow = widget.pressedShadow ??
        [BoxShadow(blurRadius: 10, offset: const Offset(0, 6), color: Colors.black.withValues(alpha: 0.05))];

    return AnimatedScale(
      scale: _pressed ? widget.pressedScale : 1,
      duration: widget.duration,
      curve: Curves.easeOutCubic,
      child: AnimatedContainer(
        duration: widget.duration,
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: radius,
          border: widget.border,
          boxShadow: _pressed ? pressedShadow : shadow,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onHighlightChanged: (v) {
              if (!mounted) return;
              setState(() => _pressed = v);
            },
            onTap: widget.onTap == null
                ? null
                : () {
                    if (widget.enableHaptics) {
                      HapticFeedback.lightImpact();
                    }
                    widget.onTap?.call();
                  },
            borderRadius: radius,
            child: Padding(
              padding: widget.padding ?? const EdgeInsets.all(14),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
