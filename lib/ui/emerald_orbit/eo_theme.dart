import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'tokens.dart';

/// Emerald Orbit / "Tactile Playground" theme (from Stitch design exports).
class EmeraldOrbitTheme {
  static ThemeData light() {
    final cs = ColorScheme(
      brightness: Brightness.light,
      primary: EoColors.primary,
      onPrimary: EoColors.onPrimary,
      primaryContainer: EoColors.primaryContainer,
      onPrimaryContainer: EoColors.onPrimaryContainer,
      secondary: EoColors.secondary,
      onSecondary: EoColors.onSecondary,
      secondaryContainer: EoColors.secondaryContainer,
      onSecondaryContainer: EoColors.onSecondaryContainer,
      tertiary: EoColors.tertiary,
      onTertiary: EoColors.onTertiary,
      tertiaryContainer: EoColors.tertiaryContainer,
      onTertiaryContainer: EoColors.onTertiaryContainer,
      error: const Color(0xFFB31B25),
      onError: const Color(0xFFFFEFEE),
      surface: EoColors.surface,
      onSurface: EoColors.onSurface,
      surfaceContainerHighest: EoColors.surfaceContainerHighest,
      outline: EoColors.outline,
      outlineVariant: EoColors.outlineVariant,
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: const Color(0xFF0C0E11),
      onInverseSurface: const Color(0xFF9B9DA1),
      inversePrimary: const Color(0xFFBFFFDA),
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      scaffoldBackgroundColor: EoColors.background,
    );

    // IMPORTANT: Preserve the base text colors coming from ThemeData/ColorScheme.
    // If we create brand-new TextStyles (via GoogleFonts.plusJakartaSans(...))
    // we can accidentally drop the computed colors and end up with low-contrast
    // (often white) text on light surfaces.
    final textThemeBase = GoogleFonts.plusJakartaSansTextTheme(base.textTheme);
    final textTheme = textThemeBase
        .copyWith(
          displayLarge: textThemeBase.displayLarge?.copyWith(fontWeight: FontWeight.w800),
          displayMedium: textThemeBase.displayMedium?.copyWith(fontWeight: FontWeight.w800),
          displaySmall: textThemeBase.displaySmall?.copyWith(fontWeight: FontWeight.w800),
          headlineLarge: textThemeBase.headlineLarge?.copyWith(fontWeight: FontWeight.w800),
          headlineMedium: textThemeBase.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
          headlineSmall: textThemeBase.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          titleLarge: textThemeBase.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          titleMedium: textThemeBase.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          titleSmall: textThemeBase.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          bodyLarge: textThemeBase.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
          bodyMedium: textThemeBase.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
          bodySmall: textThemeBase.bodySmall?.copyWith(fontWeight: FontWeight.w500),
          labelLarge: textThemeBase.labelLarge?.copyWith(fontWeight: FontWeight.w800),
          labelMedium: textThemeBase.labelMedium?.copyWith(fontWeight: FontWeight.w800),
          labelSmall: textThemeBase.labelSmall?.copyWith(fontWeight: FontWeight.w700),
        )
        .apply(
          bodyColor: cs.onSurface,
          displayColor: cs.onSurface,
          decorationColor: cs.onSurface,
        );

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: cs.onSurface,
        centerTitle: true,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w900,
          fontStyle: FontStyle.italic,
          color: cs.onSurface,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: EoColors.onSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          textStyle: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: EoColors.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: EoColors.outlineVariant.withValues(alpha: 0.18), width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: EoColors.outlineVariant.withValues(alpha: 0.12), width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: cs.primary, width: 2),
        ),
        labelStyle: textTheme.labelMedium?.copyWith(
          color: EoColors.onSurfaceVariant,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.8,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(color: EoColors.onSurfaceVariant.withValues(alpha: 0.55)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      ),
    );
  }
}
