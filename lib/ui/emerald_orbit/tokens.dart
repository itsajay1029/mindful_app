import 'package:flutter/material.dart';

/// Design tokens derived from `screens/stitch/emerald_orbit/DESIGN.md` and the
/// Tailwind color mappings embedded in Stitch exports.
class EoColors {
  static const primary = Color(0xFF2B664A);
  static const primaryDim = Color(0xFF1D5A3F);
  static const onPrimaryFixedVariant = Color(0xFF306C4F); // tailwind: on-primary-fixed-variant
  static const secondary = Color(0xFF745700);
  static const secondaryDim = Color(0xFF654C00);
  static const onSecondaryFixedVariant = Color(0xFF674D00); // tailwind: on-secondary-fixed-variant
  static const tertiary = Color(0xFF874E00);
  static const tertiaryDim = Color(0xFF764400);

  static const background = Color(0xFFF5F6FA);
  static const surface = Color(0xFFF5F6FA);
  static const surfaceContainerLowest = Color(0xFFFFFFFF);
  static const surfaceContainerLow = Color(0xFFEFF1F5);
  static const surfaceContainer = Color(0xFFE6E8ED);
  static const surfaceContainerHigh = Color(0xFFE0E2E8);
  static const surfaceContainerHighest = Color(0xFFDADDE2);

  static const primaryContainer = Color(0xFFBAF9D4);
  static const onPrimaryContainer = Color(0xFF256145);
  static const onPrimary = Color(0xFFC9FFDE);

  static const secondaryContainer = Color(0xFFFCCB52);
  static const onSecondaryContainer = Color(0xFF5B4400);
  static const onSecondary = Color(0xFFFFF1DA);

  static const tertiaryContainer = Color(0xFFFF9800);
  static const onTertiaryContainer = Color(0xFF4A2800);
  static const onTertiary = Color(0xFFFFF0E5);

  static const onSurface = Color(0xFF2C2F32);
  static const onSurfaceVariant = Color(0xFF595C5F);
  static const outline = Color(0xFF75777A);
  static const outlineVariant = Color(0xFFABADB1);

  // Tailwind palette convenience (used in Stitch exports, not in the Material mapping)
  static const emerald100 = Color(0xFFD1FAE5);
  static const emerald700 = Color(0xFF047857);
  static const emerald800 = Color(0xFF065F46);
  static const emerald900 = Color(0xFF064E3B);
  static const slate400 = Color(0xFF94A3B8);
  static const slate500 = Color(0xFF64748B);
}

class EoRadii {
  /// Matches Stitch Tailwind exports:
  /// - DEFAULT = 1rem (16)
  /// - lg      = 2rem (32)
  /// - xl      = 3rem (48)
  static const d = 16.0;
  static const lg = 32.0;
  static const xl = 48.0;
  static const full = 9999.0;
}

class EoSpacings {
  static const xxs = 6.0;
  static const xs = 10.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
}
