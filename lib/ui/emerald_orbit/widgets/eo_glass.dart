import 'dart:ui';

import 'package:flutter/material.dart';

import '../tokens.dart';

class EoGlass extends StatelessWidget {
  const EoGlass({
    super.key,
    required this.child,
    this.blur = 24,
    this.color,
    this.borderRadius,
    this.padding,
    this.border,
    this.boxShadow,
  });

  final Widget child;
  final double blur;
  final Color? color;
  final BorderRadius? borderRadius;
  final EdgeInsets? padding;
  final BoxBorder? border;
  final List<BoxShadow>? boxShadow;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(EoRadii.xl);
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: (color ?? EoColors.surfaceContainerLowest).withValues(alpha: 0.88),
            borderRadius: radius,
            border: border,
            boxShadow: boxShadow,
          ),
          child: child,
        ),
      ),
    );
  }
}
