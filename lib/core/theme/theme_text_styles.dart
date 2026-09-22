import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Text theme definitions for the Honeyday app.
///
/// Uses Fraunces for display/headline styles (serif, warm aesthetic)
/// and Plus Jakarta Sans for body text (clean, readable).
/// Text themes are applied on top of a base [TextTheme] so that
/// light and dark modes can share the same font configuration.
TextTheme buildHoneydayTextTheme(TextTheme base, Color textColor) {
  return base.copyWith(
    displayLarge: GoogleFonts.fraunces(
      textStyle: base.displayLarge,
      fontWeight: FontWeight.w700,
      color: textColor,
      letterSpacing: -0.5,
    ),
    displayMedium: GoogleFonts.fraunces(
      textStyle: base.displayMedium,
      fontWeight: FontWeight.w700,
      color: textColor,
      letterSpacing: -0.5,
    ),
    headlineLarge: GoogleFonts.fraunces(
      textStyle: base.headlineLarge,
      fontWeight: FontWeight.w700,
      color: textColor,
    ),
    headlineMedium: GoogleFonts.fraunces(
      textStyle: base.headlineMedium,
      fontWeight: FontWeight.w600,
      color: textColor,
    ),
    headlineSmall: GoogleFonts.fraunces(
      textStyle: base.headlineSmall,
      fontWeight: FontWeight.w600,
      color: textColor,
    ),
    titleLarge: GoogleFonts.fraunces(
      textStyle: base.titleLarge,
      fontWeight: FontWeight.w600,
      color: textColor,
    ),
  );
}
