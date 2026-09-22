import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:honeyday/core/constants/preferences_keys.dart';
import 'package:honeyday/core/providers/shared_preferences_provider.dart';
import 'package:honeyday/core/theme/app_colors.dart';

/// Persisted theme mode (light / dark / system).
final themeModeProvider =
    AsyncNotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

class ThemeModeNotifier extends AsyncNotifier<ThemeMode> {
  @override
  Future<ThemeMode> build() async {
    final prefs = await ref.watch(sharedPreferencesProvider.future);
    final value = prefs.getString(PreferencesKeys.themeMode);
    return ThemeMode.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ThemeMode.system,
    );
  }

  Future<void> set(ThemeMode mode) async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setString(PreferencesKeys.themeMode, mode.name);
    ref.invalidateSelf();
  }
}

/// Persisted accent seed color as hex string.
final accentColorProvider =
    AsyncNotifierProvider<AccentColorNotifier, Color>(
  AccentColorNotifier.new,
);

class AccentColorNotifier extends AsyncNotifier<Color> {
  @override
  Future<Color> build() async {
    final prefs = await ref.watch(sharedPreferencesProvider.future);
    final hex = prefs.getString(PreferencesKeys.accentColor);
    if (hex != null) {
      try {
        return Color(int.parse('FF$hex', radix: 16));
      } on FormatException {
        return AppColors.honeyAmber;
      }
    }
    return AppColors.honeyAmber;
  }

  Future<void> set(Color color) async {
    final hex = color.toARGB32().toRadixString(16).substring(2).toUpperCase();
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setString(PreferencesKeys.accentColor, hex);
    ref.invalidateSelf();
  }
}
