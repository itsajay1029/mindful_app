import 'package:flutter/material.dart';

import '../tokens.dart';
import 'eo_glass.dart';

/// A glassy, blurred app bar surface that matches Stitch exports.
///
/// Use this instead of [AppBar] when you need the "floating HUD" look.
class EoGlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  const EoGlassAppBar({
    super.key,
    this.leading,
    this.title,
    this.trailing,
    this.height = 72,
    this.padding = const EdgeInsets.fromLTRB(24, 16, 24, 16),
  });

  final Widget? leading;
  final Widget? title;
  final Widget? trailing;
  final double height;
  final EdgeInsets padding;

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SafeArea(
      bottom: false,
      child: Padding(
        // Stitch exports use px-6 (24) and py-4 (16)
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
        child: EoGlass(
          blur: 24,
          borderRadius: BorderRadius.circular(EoRadii.xl),
          // Tailwind: bg-white/80 + backdrop-blur-xl
          color: EoColors.surfaceContainerLowest.withValues(alpha: 0.80),
          boxShadow: [
            BoxShadow(
              blurRadius: 32,
              offset: const Offset(0, 12),
              color: cs.primary.withValues(alpha: 0.10),
            ),
          ],
          // Stitch doesn't use an explicit border for this HUD style.
          padding: padding,
          child: Row(
            children: [
              SizedBox(width: 44, child: Align(alignment: Alignment.centerLeft, child: leading)),
              Expanded(child: Center(child: title)),
              SizedBox(width: 44, child: Align(alignment: Alignment.centerRight, child: trailing)),
            ],
          ),
        ),
      ),
    );
  }
}
