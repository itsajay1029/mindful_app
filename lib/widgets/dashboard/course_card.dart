import 'package:flutter/material.dart';

import '../../models/learning_path.dart';

class CourseCard extends StatelessWidget {
  const CourseCard({
    super.key,
    required this.course,
    this.onTap,
    this.compact = false,
    this.trailing,
  });

  final LearningPath course;
  final VoidCallback? onTap;
  final bool compact;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final accent = cs.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              blurRadius: 16,
              offset: const Offset(0, 10),
              color: Colors.black.withValues(alpha: 0.08),
            ),
          ],
          border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            Container(
              height: compact ? 44 : 56,
              width: compact ? 44 : 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [accent.withValues(alpha: 0.9), accent.withValues(alpha: 0.55)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.play_circle_fill,
                color: Colors.white.withValues(alpha: 0.95),
                size: compact ? 22 : 26,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _Pill(label: _prettyCategory(course.category)),
                      const SizedBox(width: 8),
                      _Pill(label: course.durationLabel),
                    ],
                  ),
                  if (!compact && course.description.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      course.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.black.withValues(alpha: 0.6),
                          ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 10),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.black.withValues(alpha: 0.7),
            ),
      ),
    );
  }
}

String _prettyCategory(String raw) {
  final v = raw.trim().toLowerCase();
  return switch (v) {
    'leadership' => 'Leadership',
    'wellbeing' => 'Well‑being',
    'sustainability' => 'Sustainability',
    'all' => 'All',
    _ => v.isEmpty ? 'All' : '${v[0].toUpperCase()}${v.substring(1)}',
  };
}
