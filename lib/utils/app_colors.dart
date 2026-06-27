import 'package:flutter/material.dart';

class ThemeManager {
  // Master Switch untuk Dark Mode!
  static final ValueNotifier<bool> isDark = ValueNotifier(false);
}

class AppColors {
  // Bikin warna berubah otomatis ngikutin Master Switch
  static bool get _dark => ThemeManager.isDark.value;

  // Primary Accent
  static Color get primary => _dark ? const Color(0xFFF97316) : const Color(0xFF09090B);
  static Color get primaryLight => _dark ? const Color(0xFFFDBA74) : const Color(0xFF27272A);

  // Backgrounds
  static Color get background => _dark ? const Color(0xFF09090B) : const Color(0xFFF8FAFC);
  static Color get surface => _dark ? const Color(0xFF18181B) : const Color(0xFFFFFFFF);
  static Color get cardColor => surface;

  // Text
  static Color get textDark => _dark ? const Color(0xFFFAFAFA) : const Color(0xFF0F172A);
  static Color get textMedium => _dark ? const Color(0xFFA1A1AA) : const Color(0xFF475569);
  static Color get textLight => _dark ? const Color(0xFF71717A) : const Color(0xFF64748B);

  // Borders
  static Color get border => _dark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0);
  static Color get divider => _dark ? const Color(0xFF27272A) : const Color(0xFFF1F5F9);

  // Status (Tetap sama)
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);
}
