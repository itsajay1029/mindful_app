import 'package:flutter/material.dart';

class CategoryChips extends StatelessWidget {
  const CategoryChips({
    super.key,
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  final List<String> categories;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final c = categories[i];
          final isSelected = c == selected;

          return ChoiceChip(
            label: Text(_prettyCategory(c)),
            selected: isSelected,
            onSelected: (_) => onSelected(c),
            selectedColor: cs.primary,
            backgroundColor: Colors.white,
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : Colors.black.withValues(alpha: 0.75),
              fontWeight: FontWeight.w700,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
              side: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
            ),
          );
        },
      ),
    );
  }
}

String _prettyCategory(String raw) {
  final v = raw.trim().toLowerCase();
  return switch (v) {
    'all' => 'All Courses',
    'leadership' => 'Leadership',
    'wellbeing' => 'Well‑being',
    'sustainability' => 'Sustainability',
    _ => v.isEmpty ? 'All Courses' : '${v[0].toUpperCase()}${v.substring(1)}',
  };
}
