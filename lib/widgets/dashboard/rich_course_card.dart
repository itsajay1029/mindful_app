import 'package:flutter/material.dart';

import '../../models/learning_path.dart';
import '../../ui/emerald_orbit/tokens.dart';
import '../../ui/emerald_orbit/widgets/eo_card.dart';
import '../../ui/emerald_orbit/widgets/eo_tactile_button.dart';

/// A Stitch-inspired course card for the Learning Hub.
///
/// Notes:
/// - We don't currently have cover images/progress per course in the data model,
///   so this card renders a themed placeholder hero area and (optionally) a
///   progress row if [progress01] is provided.
class RichCourseCard extends StatelessWidget {
  const RichCourseCard({
    super.key,
    required this.course,
    required this.primaryActionLabel,
    required this.onPrimaryAction,
    this.onTap,
    this.progress01,
    this.isNew = false,
    this.categoryLabel,
  });

  final LearningPath course;
  final String primaryActionLabel;
  final VoidCallback onPrimaryAction;
  final VoidCallback? onTap;

  /// 0..1 progress. When provided, shows Stitch-like progress row.
  final double? progress01;

  /// Shows the "New Release" sticker.
  final bool isNew;

  final String? categoryLabel;

  Color _categoryChipBg(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final c = (categoryLabel ?? course.category).trim().toLowerCase();
    return switch (c) {
      'mindset' => cs.tertiaryContainer,
      'business' => EoColors.secondaryContainer,
      'design' => cs.primaryContainer,
      _ => cs.tertiaryContainer,
    };
  }

  Color _categoryChipFg(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final c = (categoryLabel ?? course.category).trim().toLowerCase();
    return switch (c) {
      'business' => EoColors.onSecondaryContainer,
      'design' => cs.onPrimaryContainer,
      _ => cs.onTertiaryContainer,
    };
  }

  String _categoryText() {
    final raw = (categoryLabel ?? course.category).trim();
    if (raw.isEmpty) return 'COURSE';
    final v = raw.toUpperCase();
    return v;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return EoCard(
      radius: EoRadii.lg,
      padding: const EdgeInsets.all(16),
      border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.10)),
      onTap: onTap,
      shadowColor: Colors.black.withValues(alpha: 0.06),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero area (image placeholder)
          Stack(
            children: [
              Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      cs.primary.withValues(alpha: 0.22),
                      cs.primary.withValues(alpha: 0.06),
                    ],
                  ),
                ),
                child: Center(
                  child: Icon(Icons.auto_awesome, color: cs.primary.withValues(alpha: 0.35), size: 42),
                ),
              ),
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _categoryChipBg(context),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _categoryText(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.1,
                          color: _categoryChipFg(context),
                        ),
                  ),
                ),
              ),
              if (isNew)
                Positioned(
                  top: -8,
                  right: -8,
                  child: Transform.rotate(
                    angle: 0.22,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: cs.tertiary,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 18,
                            offset: const Offset(0, 10),
                            color: Colors.black.withValues(alpha: 0.10),
                          ),
                        ],
                      ),
                      child: Text(
                        'NEW RELEASE',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.1,
                              color: cs.onTertiary,
                            ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  course.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        height: 1.05,
                      ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: EoColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  children: [
                    Icon(Icons.schedule_rounded, size: 14, color: EoColors.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Text(
                      course.durationLabel,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: EoColors.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if ((course.description).trim().isNotEmpty && progress01 == null) ...[
            const SizedBox(height: 8),
            Text(
              course.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: EoColors.onSurfaceVariant,
                    height: 1.25,
                  ),
            ),
          ],

          if (progress01 != null) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Progress',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: cs.onPrimaryContainer,
                        fontWeight: FontWeight.w900,
                      ),
                ),
                Text(
                  '${(progress01!.clamp(0, 1) * 100).round()}%',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: cs.onPrimaryContainer,
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress01!.clamp(0, 1),
                minHeight: 8,
                backgroundColor: cs.primaryContainer,
                valueColor: AlwaysStoppedAnimation(cs.primary),
              ),
            ),
          ],

          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: progress01 != null
                ? EoTactileButton.primary(
                    label: primaryActionLabel,
                    icon: const Icon(Icons.play_circle_rounded),
                    onPressed: onPrimaryAction,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                    radius: 18,
                  )
                : EoTactileButton.tonal(
                    label: primaryActionLabel,
                    icon: const Icon(Icons.add_circle_rounded),
                    onPressed: onPrimaryAction,
                    toneColor: cs.primaryContainer,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                    radius: 18,
                  ),
          ),
        ],
      ),
    );
  }
}
