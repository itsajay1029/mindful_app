import 'package:flutter/material.dart';

import '../tokens.dart';

/// Avatar with an outer progress ring (used in Stitch top bars).
class EoAvatarRing extends StatelessWidget {
  const EoAvatarRing({
    super.key,
    required this.photoUrl,
    required this.progress,
    this.size = 40,
    this.ringWidth = 3,
    this.ringColor,
  });

  final String? photoUrl;
  final double progress;
  final double size;
  final double ringWidth;
  final Color? ringColor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ring = ringColor ?? cs.primary;
    final value = progress <= 0 ? 0.02 : (progress >= 1 ? 1.0 : progress);

    return SizedBox(
      height: size,
      width: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: value,
            strokeWidth: ringWidth,
            backgroundColor: EoColors.primaryContainer,
            valueColor: AlwaysStoppedAnimation(ring),
          ),
          SizedBox(
            height: size - ringWidth * 2 - 4,
            width: size - ringWidth * 2 - 4,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: photoUrl == null || photoUrl!.trim().isEmpty
                  ? Container(
                      color: EoColors.surfaceContainerHigh,
                      child: const Icon(Icons.person_rounded, color: EoColors.onSurfaceVariant),
                    )
                  : Image.network(
                      photoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: EoColors.surfaceContainerHigh,
                        child: const Icon(Icons.person_rounded, color: EoColors.onSurfaceVariant),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
