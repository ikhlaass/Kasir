import 'package:flutter/material.dart';

/// AppFonts — pengganti GoogleFonts.poppins() yang menggunakan
/// font Poppins yang sudah di-bundle secara lokal di assets/fonts/.
/// Ini menghilangkan kebutuhan koneksi internet untuk memuat font.
class AppFonts {
  AppFonts._();

  static const String _family = 'Poppins';

  /// Setara dengan GoogleFonts.poppins(...)
  static TextStyle poppins({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
    double? height,
    TextDecoration? decoration,
  }) {
    return TextStyle(
      fontFamily: _family,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
      decoration: decoration,
    );
  }

  /// Setara dengan GoogleFonts.poppinsTextTheme()
  static TextTheme textTheme([TextTheme? base]) {
    final t = base ?? const TextTheme();
    return t.copyWith(
      displayLarge: t.displayLarge?.copyWith(fontFamily: _family),
      displayMedium: t.displayMedium?.copyWith(fontFamily: _family),
      displaySmall: t.displaySmall?.copyWith(fontFamily: _family),
      headlineLarge: t.headlineLarge?.copyWith(fontFamily: _family),
      headlineMedium: t.headlineMedium?.copyWith(fontFamily: _family),
      headlineSmall: t.headlineSmall?.copyWith(fontFamily: _family),
      titleLarge: t.titleLarge?.copyWith(fontFamily: _family),
      titleMedium: t.titleMedium?.copyWith(fontFamily: _family),
      titleSmall: t.titleSmall?.copyWith(fontFamily: _family),
      bodyLarge: t.bodyLarge?.copyWith(fontFamily: _family),
      bodyMedium: t.bodyMedium?.copyWith(fontFamily: _family),
      bodySmall: t.bodySmall?.copyWith(fontFamily: _family),
      labelLarge: t.labelLarge?.copyWith(fontFamily: _family),
      labelMedium: t.labelMedium?.copyWith(fontFamily: _family),
      labelSmall: t.labelSmall?.copyWith(fontFamily: _family),
    );
  }
}
