/// SharedPreferences keys used across the app.
abstract final class PreferencesKeys {
  /// Whether the user has completed onboarding.
  static const String onboardingComplete = 'onboarding_complete';

  /// Theme mode preference ('light' or 'dark').
  static const String themeMode = 'theme_mode';

  /// User-selected accent color hex value.
  static const String accentColor = 'accent_color';
}
