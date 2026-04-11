import 'dart:ui';

import 'package:flutter/material.dart';

import '../tokens.dart';

class EoBottomNav extends StatelessWidget {
  const EoBottomNav({
    super.key,
    required this.index,
    required this.onSelected,
  });

  final int index;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(EoRadii.xl),
        topRight: Radius.circular(EoRadii.xl),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 18),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.90),
            boxShadow: [
              BoxShadow(
                blurRadius: 40,
                offset: const Offset(0, -10),
                color: Colors.black.withValues(alpha: 0.08),
              )
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _Item(
                selected: index == 0,
                icon: Icons.home_rounded,
                label: 'Home',
                onTap: () => onSelected(0),
                selectedColor: cs.primary,
              ),
              _Item(
                selected: index == 1,
                icon: Icons.category_rounded,
                label: 'Segments',
                onTap: () => onSelected(1),
                selectedColor: cs.primary,
              ),
              _Item(
                selected: index == 2,
                icon: Icons.waves_rounded,
                label: 'Reset',
                onTap: () => onSelected(2),
                selectedColor: cs.primary,
              ),
              _Item(
                selected: index == 3,
                icon: Icons.emoji_events_rounded,
                label: 'Board',
                onTap: () => onSelected(3),
                selectedColor: cs.primary,
              ),
              _Item(
                selected: index == 4,
                icon: Icons.smart_toy_rounded,
                label: 'Coach',
                onTap: () => onSelected(4),
                selectedColor: cs.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
    required this.selectedColor,
  });

  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color selectedColor;

  @override
  Widget build(BuildContext context) {
    // Stitch: unselected is slate-400-ish, selected is emerald-800-ish
    final fg = selected ? EoColors.emerald800 : EoColors.slate400;
    final bg = selected ? EoColors.emerald100.withValues(alpha: 0.85) : Colors.transparent;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(32),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutBack,
        padding: EdgeInsets.symmetric(horizontal: selected ? 18 : 10, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(32),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: fg, size: 22),
            const SizedBox(height: 4),
            Text(
              label.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.9,
                    fontSize: 10,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
